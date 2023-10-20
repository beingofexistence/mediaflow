# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TasksToBeDone::CreateWorker, feature_category: :onboarding do
  let_it_be(:current_user) { create(:user) }

  let(:assignee_ids) { [1, 2] }
  let(:job_args) { [123, current_user.id, assignee_ids] }

  describe '.perform' do
    it 'executes the task services for all tasks to be done', :aggregate_failures do
      expect { described_class.new.perform(*job_args) }.not_to change { Issue.count }
    end
  end

  include_examples 'an idempotent worker' do
    it 'creates 3 task issues' do
      expect { subject }.not_to change { Issue.count }
    end
  end
end
