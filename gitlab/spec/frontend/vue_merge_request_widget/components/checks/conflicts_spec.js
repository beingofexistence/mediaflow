import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ConflictsComponent from '~/vue_merge_request_widget/components/checks/conflicts.vue';
import conflictsStateQuery from '~/vue_merge_request_widget/queries/states/conflicts.query.graphql';

Vue.use(VueApollo);

let wrapper;
let apolloProvider;

function factory({
  result = 'passed',
  canMerge = true,
  pushToSourceBranch = true,
  shouldBeRebased = false,
  sourceBranchProtected = false,
  mr = {},
} = {}) {
  apolloProvider = createMockApollo([
    [
      conflictsStateQuery,
      jest.fn().mockResolvedValue({
        data: {
          project: {
            id: 1,
            mergeRequest: {
              id: 1,
              shouldBeRebased,
              sourceBranchProtected,
              userPermissions: { canMerge, pushToSourceBranch },
            },
          },
        },
      }),
    ],
  ]);

  wrapper = mountExtended(ConflictsComponent, {
    apolloProvider,
    propsData: {
      mr,
      check: { result, failureReason: 'Conflicts message' },
    },
  });
}

describe('Merge request merge checks conflicts component', () => {
  afterEach(() => {
    apolloProvider = null;
  });

  it('renders failure reason text', () => {
    factory();

    expect(wrapper.text()).toEqual('Conflicts message');
  });

  it.each`
    conflictResolutionPath  | pushToSourceBranch | sourceBranchProtected | rendersConflictButton | rendersConflictButtonText
    ${'https://gitlab.com'} | ${true}            | ${false}              | ${true}               | ${'renders'}
    ${undefined}            | ${true}            | ${false}              | ${false}              | ${'does not render'}
    ${'https://gitlab.com'} | ${false}           | ${false}              | ${false}              | ${'does not render'}
    ${'https://gitlab.com'} | ${true}            | ${true}               | ${false}              | ${'does not render'}
    ${'https://gitlab.com'} | ${false}           | ${false}              | ${false}              | ${'does not render'}
    ${undefined}            | ${false}           | ${false}              | ${false}              | ${'does not render'}
  `(
    '$rendersConflictButtonText the conflict button for $conflictResolutionPath $pushToSourceBranch $sourceBranchProtected $rendersConflictButton',
    async ({
      conflictResolutionPath,
      pushToSourceBranch,
      sourceBranchProtected,
      rendersConflictButton,
    }) => {
      factory({ mr: { conflictResolutionPath }, pushToSourceBranch, sourceBranchProtected });

      await waitForPromises();

      expect(wrapper.findAllByTestId('extension-actions-button').length).toBe(
        rendersConflictButton ? 2 : 1,
      );

      expect(wrapper.findAllByTestId('extension-actions-button').at(-1).text()).toBe(
        rendersConflictButton ? 'Resolve conflicts' : 'Resolve locally',
      );
    },
  );
});
