import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import resolvers from '../shared/graphql/resolvers';
import App from './components/app.vue';

export const initOrganizationsNew = () => {
  const el = document.getElementById('js-organizations-new');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const { organizationsPath, rootUrl } = convertObjectPropsToCamelCase(JSON.parse(appData));

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers),
  });

  return new Vue({
    el,
    name: 'OrganizationNewRoot',
    apolloProvider,
    provide: {
      organizationsPath,
      rootUrl,
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
