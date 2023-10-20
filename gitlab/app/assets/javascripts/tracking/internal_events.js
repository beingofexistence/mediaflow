import API from '~/api';

import Tracking from './tracking';
import {
  GITLAB_INTERNAL_EVENT_CATEGORY,
  LOAD_INTERNAL_EVENTS_SELECTOR,
  SERVICE_PING_SCHEMA,
} from './constants';
import { Tracker } from './tracker';
import { InternalEventHandler, createInternalEventPayload } from './utils';

const InternalEvents = {
  /**
   *
   * @param {string} event
   * @param {object} data
   */
  trackEvent(event, data = {}) {
    const { context, ...rest } = data;

    const defaultContext = {
      schema: SERVICE_PING_SCHEMA,
      data: {
        event_name: event,
        data_source: 'redis_hll',
      },
    };
    const mergedContext = context ? [defaultContext, context] : defaultContext;

    API.trackInternalEvent(event);
    Tracking.event(GITLAB_INTERNAL_EVENT_CATEGORY, event, {
      context: mergedContext,
      ...rest,
    });
    this.trackBrowserSDK(event);
  },
  /**
   * Returns an implementation of this class in the form of
   * a Vue mixin.
   */
  mixin() {
    return {
      methods: {
        trackEvent(event, data = {}) {
          InternalEvents.trackEvent(event, data);
        },
      },
    };
  },
  /**
   * Attaches event handlers for data-attributes powered events.
   *
   * @param {HTMLElement} parent - element containing data-attributes
   * @returns {Object} handler - object containing name of the event and its corresponding function
   */
  bindInternalEventDocument(parent = document) {
    if (!Tracker.enabled() || parent.internalEventsTrackingBound) {
      return [];
    }

    // eslint-disable-next-line no-param-reassign
    parent.internalEventsTrackingBound = true;

    const handler = {
      name: 'click',
      func: (e) => InternalEventHandler(e, this.trackEvent.bind(this)),
    };
    parent.addEventListener(handler.name, handler.func);
    return handler;
  },
  /**
   * Attaches internal event handlers for load events.
   * @param {HTMLElement} parent - element containing event targets
   * @returns {Array}
   */
  trackInternalLoadEvents(parent = document) {
    if (!Tracker.enabled()) {
      return [];
    }

    const loadEvents = parent.querySelectorAll(LOAD_INTERNAL_EVENTS_SELECTOR);

    loadEvents.forEach((element) => {
      const action = createInternalEventPayload(element);
      if (action) {
        this.trackEvent(action);
      }
    });

    return loadEvents;
  },
  /**
   * Initialize browser sdk for product analytics
   */
  initBrowserSDK() {
    if (window.glClient) {
      window.glClient.setDocumentTitle('GitLab');
      window.glClient.page({
        title: 'GitLab',
      });
    }
  },
  /**
   * track events for Product Analytics
   * @param {string} event
   */
  trackBrowserSDK(event) {
    if (!Tracker.enabled()) {
      return;
    }

    window.glClient?.track(event);
  },
};

export default InternalEvents;
