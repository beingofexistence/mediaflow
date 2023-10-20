# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class PullRequestImporter
        include Loggable
        include ErrorTracking

        def initialize(project, hash)
          @project = project
          @formatter = Gitlab::ImportFormatter.new
          @user_finder = UserFinder.new(project)
          @object = hash.with_indifferent_access
        end

        def execute
          log_info(import_stage: 'import_pull_request', message: 'starting', iid: object[:iid])

          description = ''
          description += author_line
          description += object[:description] if object[:description]

          attributes = {
            iid: object[:iid],
            title: object[:title],
            description: description,
            source_project_id: project.id,
            source_branch: Gitlab::Git.ref_name(object[:source_branch_name]),
            source_branch_sha: source_branch_sha,
            target_project_id: project.id,
            target_branch: Gitlab::Git.ref_name(object[:target_branch_name]),
            target_branch_sha: object[:target_branch_sha],
            state_id: MergeRequest.available_states[object[:state]],
            author_id: author_id,
            created_at: object[:created_at],
            updated_at: object[:updated_at]
          }

          creator = Gitlab::Import::MergeRequestCreator.new(project)

          merge_request = creator.execute(attributes)

          if merge_request
            merge_request.assignee_ids = [author_id]
            merge_request.reviewer_ids = reviewers
            merge_request.save!
          end

          log_info(import_stage: 'import_pull_request', message: 'finished', iid: object[:iid])
        rescue StandardError => e
          track_import_failure!(project, exception: e)
        end

        private

        attr_reader :object, :project, :formatter, :user_finder

        def author_line
          return '' if find_user_id

          formatter.author_line(object[:author])
        end

        def find_user_id
          user_finder.find_user_id(object[:author])
        end

        def author_id
          user_finder.gitlab_user_id(project, object[:author])
        end

        def reviewers
          return [] unless object[:reviewers].present?

          object[:reviewers].filter_map do |reviewer|
            user_finder.find_user_id(reviewer)
          end
        end

        def source_branch_sha
          project.repository.commit(object[:source_branch_sha])&.sha ||
            project.repository.commit(object[:merge_commit_sha])&.sha ||
            object[:source_branch_sha]
        end
      end
    end
  end
end