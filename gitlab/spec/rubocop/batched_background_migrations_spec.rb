# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../rubocop/batched_background_migrations'

RSpec.describe RuboCop::BatchedBackgroundMigrations, feature_category: :database do
  let(:bbm_dictionary_file_name) { "#{described_class::DICTIONARY_BASE_DIR}/test_migration.yml" }
  let(:migration_version) { 20230307160250 }
  let(:finalized_by_version) { 20230307160255 }
  let(:bbm_dictionary_data) do
    {
      migration_job_name: 'TestMigration',
      feature_category: :database,
      introduced_by_url: 'https://test_url',
      milestone: 16.5,
      queued_migration_version: migration_version,
      finalized_by: finalized_by_version
    }
  end

  before do
    File.open(bbm_dictionary_file_name, 'w') do |file|
      file.write(bbm_dictionary_data.stringify_keys.to_yaml)
    end
  end

  after do
    FileUtils.rm(bbm_dictionary_file_name)
  end

  subject(:batched_background_migration) { described_class.new(migration_version) }

  describe '#finalized_by' do
    it 'returns the finalized_by version of the bbm with given version' do
      expect(batched_background_migration.finalized_by).to eq(finalized_by_version.to_s)
    end

    it 'returns nothing for non-existing bbm dictionary' do
      expect(described_class.new('random').finalized_by).to be_nil
    end
  end
end
