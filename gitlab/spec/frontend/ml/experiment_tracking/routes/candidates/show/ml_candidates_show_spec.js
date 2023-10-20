import { GlAvatarLabeled, GlLink, GlTableLite } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MlCandidatesShow from '~/ml/experiment_tracking/routes/candidates/show';
import DetailRow from '~/ml/experiment_tracking/routes/candidates/show/components/candidate_detail_row.vue';
import {
  TITLE_LABEL,
  NO_PARAMETERS_MESSAGE,
  NO_METRICS_MESSAGE,
  NO_METADATA_MESSAGE,
  NO_CI_MESSAGE,
} from '~/ml/experiment_tracking/routes/candidates/show/translations';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import { stubComponent } from 'helpers/stub_component';
import { newCandidate } from './mock_data';

describe('MlCandidatesShow', () => {
  let wrapper;
  const CANDIDATE = newCandidate();
  const USER_ROW = 1;

  const INFO_SECTION = 0;
  const CI_SECTION = 1;
  const PARAMETER_SECTION = 2;
  const METADATA_SECTION = 3;

  const createWrapper = (createCandidate = () => CANDIDATE) => {
    wrapper = shallowMountExtended(MlCandidatesShow, {
      propsData: { candidate: createCandidate() },
      stubs: {
        GlTableLite: { ...stubComponent(GlTableLite), props: ['items', 'fields'] },
      },
    });
  };

  const findDeleteButton = () => wrapper.findComponent(DeleteButton);
  const findHeader = () => wrapper.findComponent(ModelExperimentsHeader);
  const findSection = (section) => wrapper.findAll('section').at(section);
  const findRowInSection = (section, row) =>
    findSection(section).findAllComponents(DetailRow).at(row);
  const findLinkAtRow = (section, rowIndex) =>
    findRowInSection(section, rowIndex).findComponent(GlLink);
  const findNoDataMessage = (label) => wrapper.findByText(label);
  const findLabel = (label) => wrapper.find(`[label='${label}']`);
  const findCiUserDetailRow = () => findRowInSection(CI_SECTION, USER_ROW);
  const findCiUserAvatar = () => findCiUserDetailRow().findComponent(GlAvatarLabeled);
  const findCiUserAvatarNameLink = () => findCiUserAvatar().findComponent(GlLink);
  const findMetricsTable = () => wrapper.findComponent(GlTableLite);

  describe('Header', () => {
    beforeEach(() => createWrapper());

    it('shows delete button', () => {
      expect(findDeleteButton().exists()).toBe(true);
    });

    it('passes the delete path to delete button', () => {
      expect(findDeleteButton().props('deletePath')).toBe('path_to_candidate');
    });

    it('passes the right title', () => {
      expect(findHeader().props('pageTitle')).toBe(TITLE_LABEL);
    });
  });

  describe('Detail Table', () => {
    describe('All info available', () => {
      beforeEach(() => createWrapper());

      const mrText = `!${CANDIDATE.info.ci_job.merge_request.iid} ${CANDIDATE.info.ci_job.merge_request.title}`;
      const expectedTable = [
        [INFO_SECTION, 0, 'ID', CANDIDATE.info.iid],
        [INFO_SECTION, 1, 'MLflow run ID', CANDIDATE.info.eid],
        [INFO_SECTION, 2, 'Status', CANDIDATE.info.status],
        [INFO_SECTION, 3, 'Experiment', CANDIDATE.info.experiment_name],
        [INFO_SECTION, 4, 'Artifacts', 'Artifacts'],
        [CI_SECTION, 0, 'Job', CANDIDATE.info.ci_job.name],
        [CI_SECTION, 1, 'Triggered by', 'CI User'],
        [CI_SECTION, 2, 'Merge request', mrText],
        [PARAMETER_SECTION, 0, CANDIDATE.params[0].name, CANDIDATE.params[0].value],
        [PARAMETER_SECTION, 1, CANDIDATE.params[1].name, CANDIDATE.params[1].value],
        [METADATA_SECTION, 0, CANDIDATE.metadata[0].name, CANDIDATE.metadata[0].value],
        [METADATA_SECTION, 1, CANDIDATE.metadata[1].name, CANDIDATE.metadata[1].value],
      ];

      it.each(expectedTable)('row %s is created correctly', (section, rowIndex, label, text) => {
        const row = findRowInSection(section, rowIndex);

        expect(row.props()).toMatchObject({ label });
        expect(row.text()).toBe(text);
      });

      describe('Table links', () => {
        const linkRows = [
          [INFO_SECTION, 3, CANDIDATE.info.path_to_experiment],
          [INFO_SECTION, 4, CANDIDATE.info.path_to_artifact],
          [CI_SECTION, 0, CANDIDATE.info.ci_job.path],
          [CI_SECTION, 2, CANDIDATE.info.ci_job.merge_request.path],
        ];

        it.each(linkRows)('row %s is created correctly', (section, rowIndex, href) => {
          expect(findLinkAtRow(section, rowIndex).attributes().href).toBe(href);
        });
      });

      describe('Metrics table', () => {
        it('computes metrics table items correctly', () => {
          expect(findMetricsTable().props('items')).toEqual([
            { name: 'AUC', 0: '.55' },
            { name: 'Accuracy', 1: '.99', 2: '.98', 3: '.97' },
            { name: 'F1', 3: '.1' },
          ]);
        });

        it('computes metrics table fields correctly', () => {
          expect(findMetricsTable().props('fields')).toEqual([
            expect.objectContaining({ key: 'name', label: 'Metric' }),
            expect.objectContaining({ key: '0', label: 'Step 0' }),
            expect.objectContaining({ key: '1', label: 'Step 1' }),
            expect.objectContaining({ key: '2', label: 'Step 2' }),
            expect.objectContaining({ key: '3', label: 'Step 3' }),
          ]);
        });
      });

      describe('CI triggerer', () => {
        it('renders user row', () => {
          const avatar = findCiUserAvatar();
          expect(avatar.props()).toMatchObject({
            label: '',
          });
          expect(avatar.attributes().src).toEqual('/img.png');
        });

        it('renders user name', () => {
          const nameLink = findCiUserAvatarNameLink();

          expect(nameLink.attributes().href).toEqual('path/to/ci/user');
          expect(nameLink.text()).toEqual('CI User');
        });
      });
    });

    describe('No artifact path', () => {
      beforeEach(() =>
        createWrapper(() => {
          const candidate = newCandidate();
          delete candidate.info.path_to_artifact;
          return candidate;
        }),
      );

      it('does not render artifact row', () => {
        expect(findLabel('Artifacts').exists()).toBe(false);
      });
    });

    describe('No params, metrics, ci or metadata available', () => {
      beforeEach(() =>
        createWrapper(() => {
          const candidate = newCandidate();
          delete candidate.params;
          delete candidate.metrics;
          delete candidate.metadata;
          delete candidate.info.ci_job;
          return candidate;
        }),
      );

      it('does not render params', () => {
        expect(findNoDataMessage(NO_PARAMETERS_MESSAGE).exists()).toBe(true);
      });

      it('does not render metadata', () => {
        expect(findNoDataMessage(NO_METADATA_MESSAGE).exists()).toBe(true);
      });

      it('does not render metrics', () => {
        expect(findNoDataMessage(NO_METRICS_MESSAGE).exists()).toBe(true);
      });

      it('does not render CI info', () => {
        expect(findNoDataMessage(NO_CI_MESSAGE).exists()).toBe(true);
      });
    });

    describe('Has CI, but no user or mr', () => {
      beforeEach(() =>
        createWrapper(() => {
          const candidate = newCandidate();
          delete candidate.info.ci_job.user;
          delete candidate.info.ci_job.merge_request;
          return candidate;
        }),
      );

      it('does not render MR info', () => {
        expect(findLabel('Merge request').exists()).toBe(false);
      });

      it('does not render CI user info', () => {
        expect(findLabel('Triggered by').exists()).toBe(false);
      });
    });
  });
});
