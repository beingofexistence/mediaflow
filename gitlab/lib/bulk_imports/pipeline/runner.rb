# frozen_string_literal: true

module BulkImports
  module Pipeline
    module Runner
      extend ActiveSupport::Concern

      MarkedAsFailedError = Class.new(StandardError)

      def run
        raise MarkedAsFailedError if context.entity.failed?

        info(message: 'Pipeline started')

        extracted_data = extracted_data_from

        if extracted_data
          extracted_data.each_with_index do |entry, index|
            raw_entry = entry.dup
            next if Feature.enabled?(:bulk_import_idempotent_workers) && already_processed?(raw_entry, index)

            transformers.each do |transformer|
              entry = run_pipeline_step(:transformer, transformer.class.name) do
                transformer.transform(context, entry)
              end
            end

            run_pipeline_step(:loader, loader.class.name) do
              loader.load(context, entry)
            end

            save_processed_entry(raw_entry, index) if Feature.enabled?(:bulk_import_idempotent_workers)
          end

          tracker.update!(
            has_next_page: extracted_data.has_next_page?,
            next_page: extracted_data.next_page
          )

          run_pipeline_step(:after_run) do
            after_run(extracted_data)
          end
        end

        info(message: 'Pipeline finished')
      rescue MarkedAsFailedError
        skip!('Skipping pipeline due to failed entity')
      end

      private # rubocop:disable Lint/UselessAccessModifier

      def run_pipeline_step(step, class_name = nil)
        raise MarkedAsFailedError if context.entity.failed?

        info(pipeline_step: step, step_class: class_name)

        yield
      rescue MarkedAsFailedError
        skip!(
          'Skipping pipeline due to failed entity',
          pipeline_step: step,
          step_class: class_name,
          importer: 'gitlab_migration'
        )
      rescue BulkImports::NetworkError => e
        raise BulkImports::RetryPipelineError.new(e.message, e.retry_delay) if e.retriable?(context.tracker)

        log_and_fail(e, step)
      rescue BulkImports::RetryPipelineError
        raise
      rescue StandardError => e
        log_and_fail(e, step)
      end

      def extracted_data_from
        run_pipeline_step(:extractor, extractor.class.name) do
          extractor.extract(context)
        end
      end

      def cache_key
        batch_number = context.extra[:batch_number] || 0

        "#{self.class.name.underscore}/#{tracker.bulk_import_entity_id}/#{batch_number}"
      end

      # Overridden by child pipelines with different caching strategies
      def already_processed?(*)
        false
      end

      def save_processed_entry(*); end

      def after_run(extracted_data)
        run if extracted_data.has_next_page?
      end

      def log_and_fail(exception, step)
        log_import_failure(exception, step)

        if abort_on_failure?
          tracker.fail_op!

          warn(message: 'Aborting entity migration due to pipeline failure')
          context.entity.fail_op!
        end

        nil
      end

      def skip!(message, extra = {})
        warn({ message: message }.merge(extra))

        tracker.skip!
      end

      def log_import_failure(exception, step)
        failure_attributes = {
          bulk_import_entity_id: context.entity.id,
          pipeline_class: pipeline,
          pipeline_step: step,
          exception_class: exception.class.to_s,
          exception_message: exception.message.truncate(255),
          correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id
        }

        log_exception(
          exception,
          log_params(
            {
              bulk_import_id: context.bulk_import_id,
              pipeline_step: step,
              message: 'An object of a pipeline failed to import'
            }
          )
        )

        BulkImports::Failure.create(failure_attributes)
      end

      def info(extra = {})
        logger.info(log_params(extra))
      end

      def warn(extra = {})
        logger.warn(log_params(extra))
      end

      def log_params(extra)
        defaults = {
          bulk_import_id: context.bulk_import_id,
          bulk_import_entity_id: context.entity.id,
          bulk_import_entity_type: context.entity.source_type,
          source_full_path: context.entity.source_full_path,
          pipeline_class: pipeline,
          context_extra: context.extra,
          source_version: context.entity.bulk_import.source_version_info.to_s,
          importer: 'gitlab_migration'
        }

        defaults
          .merge(extra)
          .reject { |_key, value| value.blank? }
      end

      def logger
        @logger ||= Gitlab::Import::Logger.build
      end

      def log_exception(exception, payload)
        Gitlab::ExceptionLogFormatter.format!(exception, payload)
        logger.error(structured_payload(payload))
      end

      def structured_payload(payload = {})
        context = Gitlab::ApplicationContext.current.merge(
          'class' => self.class.name
        )

        payload.stringify_keys.merge(context)
      end
    end
  end
end
