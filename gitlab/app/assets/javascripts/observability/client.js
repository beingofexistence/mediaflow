import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';

function reportErrorAndThrow(e) {
  Sentry.captureException(e);
  throw e;
}
// Provisioning API spec: https://gitlab.com/gitlab-org/opstrace/opstrace/-/blob/main/provisioning-api/pkg/provisioningapi/routes.go#L59
async function enableTraces(provisioningUrl) {
  try {
    // Note: axios.put(url, undefined, {withCredentials: true}) does not send cookies properly, so need to use the API below for the correct behaviour
    return await axios(provisioningUrl, {
      method: 'put',
      withCredentials: true,
    });
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

// Provisioning API spec: https://gitlab.com/gitlab-org/opstrace/opstrace/-/blob/main/provisioning-api/pkg/provisioningapi/routes.go#L37
async function isTracingEnabled(provisioningUrl) {
  try {
    const { data } = await axios.get(provisioningUrl, { withCredentials: true });
    if (data && data.status) {
      // we currently ignore the 'status' payload and just check if the request was successful
      // We might improve this as part of https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2315
      return true;
    }
  } catch (e) {
    if (e.response.status === 404) {
      return false;
    }
    return reportErrorAndThrow(e);
  }
  return reportErrorAndThrow(new Error('Failed to check provisioning')); // eslint-disable-line @gitlab/require-i18n-strings
}

async function fetchTrace(tracingUrl, traceId) {
  try {
    if (!traceId) {
      throw new Error('traceId is required.');
    }

    const { data } = await axios.get(tracingUrl, {
      withCredentials: true,
      params: {
        trace_id: traceId,
      },
    });

    if (!Array.isArray(data.traces) || data.traces.length === 0) {
      throw new Error('traces are missing/invalid in the response'); // eslint-disable-line @gitlab/require-i18n-strings
    }

    return data.traces[0];
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

/**
 * Filters (and operators) allowed by tracing query API
 */
const SUPPORTED_FILTERS = {
  durationMs: ['>', '<'],
  operation: ['=', '!='],
  serviceName: ['=', '!='],
  period: ['='],
  traceId: ['=', '!='],
  // free-text 'search' temporarily ignored https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2309
};

/**
 * Mapping of filter name to query param
 */
const FILTER_TO_QUERY_PARAM = {
  durationMs: 'duration_nano',
  operation: 'operation',
  serviceName: 'service_name',
  period: 'period',
  traceId: 'trace_id',
};

const FILTER_OPERATORS_PREFIX = {
  '!=': 'not',
  '>': 'gt',
  '<': 'lt',
};

/**
 * Builds the query param name for the given filter and operator
 *
 * @param {String} filterName - The filter name
 * @param {String} operator - The operator
 * @returns String | undefined - Query param name
 */
function getFilterParamName(filterName, operator) {
  const paramKey = FILTER_TO_QUERY_PARAM[filterName];
  if (!paramKey) return undefined;

  if (operator === '=') {
    return paramKey;
  }

  const prefix = FILTER_OPERATORS_PREFIX[operator];
  if (prefix) {
    return `${prefix}[${paramKey}]`;
  }

  return undefined;
}

/**
 * Builds URLSearchParams from a filter object of type { [filterName]: undefined | null | Array<{operator: String, value: any} }
 *  e.g:
 *
 *  filterObj =  {
 *      durationMs: [{operator: '>', value: '100'}, {operator: '<', value: '1000' }],
 *      operation: [{operator: '=', value: 'someOp' }],
 *      serviceName: [{operator: '!=', value: 'foo' }]
 *    }
 *
 * It handles converting the filter to the proper supported query params
 *
 * @param {Object} filterObj : An Object representing filters
 * @returns URLSearchParams
 */
function filterObjToQueryParams(filterObj) {
  const filterParams = new URLSearchParams();

  Object.keys(SUPPORTED_FILTERS).forEach((filterName) => {
    const filterValues = filterObj[filterName] || [];
    const supportedFilters = filterValues.filter((f) =>
      SUPPORTED_FILTERS[filterName].includes(f.operator),
    );
    supportedFilters.forEach(({ operator, value: rawValue }) => {
      const paramName = getFilterParamName(filterName, operator);

      let value = rawValue;
      if (filterName === 'durationMs') {
        // converting durationMs to duration_nano
        value *= 1000000;
      }

      if (paramName && value) {
        filterParams.append(paramName, value);
      }
    });
  });
  return filterParams;
}

/**
 * Fetches traces with given tracing API URL and filters
 *
 * @param {String} tracingUrl : The API base URL
 * @param {Object} filters : A filter object of type: { [filterName]: undefined | null | Array<{operator: String, value: String} }
 *  e.g:
 *
 *    {
 *      durationMs: [ {operator: '>', value: '100'}, {operator: '<', value: '1000'}],
 *      operation: [ {operator: '=', value: 'someOp}],
 *      serviceName: [ {operator: '!=', value: 'foo}]
 *    }
 *
 * @returns Array<Trace> : A list of traces
 */
async function fetchTraces(tracingUrl, { filters = {}, pageToken, pageSize } = {}) {
  const params = filterObjToQueryParams(filters);
  if (pageToken) {
    params.append('page_token', pageToken);
  }
  if (pageSize) {
    params.append('page_size', pageSize);
  }

  try {
    const { data } = await axios.get(tracingUrl, {
      withCredentials: true,
      params,
    });
    if (!Array.isArray(data.traces)) {
      throw new Error('traces are missing/invalid in the response'); // eslint-disable-line @gitlab/require-i18n-strings
    }
    return data;
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

async function fetchServices(servicesUrl) {
  try {
    const { data } = await axios.get(servicesUrl, {
      withCredentials: true,
    });

    if (!Array.isArray(data.services)) {
      throw new Error('failed to fetch services. invalid response'); // eslint-disable-line @gitlab/require-i18n-strings
    }

    return data.services;
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

async function fetchOperations(operationsUrl, serviceName) {
  try {
    if (!serviceName) {
      throw new Error('fetchOperations() - serviceName is required.');
    }
    if (!operationsUrl.includes('$SERVICE_NAME$')) {
      throw new Error('fetchOperations() - operationsUrl must contain $SERVICE_NAME$');
    }
    const url = operationsUrl.replace('$SERVICE_NAME$', serviceName);
    const { data } = await axios.get(url, {
      withCredentials: true,
    });

    if (!Array.isArray(data.operations)) {
      throw new Error('failed to fetch operations. invalid response'); // eslint-disable-line @gitlab/require-i18n-strings
    }

    return data.operations;
  } catch (e) {
    return reportErrorAndThrow(e);
  }
}

export function buildClient({ provisioningUrl, tracingUrl, servicesUrl, operationsUrl } = {}) {
  if (!provisioningUrl || !tracingUrl || !servicesUrl || !operationsUrl) {
    throw new Error(
      'missing required params. provisioningUrl, tracingUrl, servicesUrl, operationsUrl are required',
    );
  }
  return {
    enableTraces: () => enableTraces(provisioningUrl),
    isTracingEnabled: () => isTracingEnabled(provisioningUrl),
    fetchTraces: (filters) => fetchTraces(tracingUrl, filters),
    fetchTrace: (traceId) => fetchTrace(tracingUrl, traceId),
    fetchServices: () => fetchServices(servicesUrl),
    fetchOperations: (serviceName) => fetchOperations(operationsUrl, serviceName),
  };
}
