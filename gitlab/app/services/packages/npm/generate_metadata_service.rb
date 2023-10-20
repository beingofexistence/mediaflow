# frozen_string_literal: true

module Packages
  module Npm
    class GenerateMetadataService
      include API::Helpers::RelatedResourcesHelpers
      include Gitlab::Utils::StrongMemoize

      # Allowed fields are those defined in the abbreviated form
      # defined here: https://github.com/npm/registry/blob/master/docs/responses/package-metadata.md#abbreviated-version-object
      # except: name, version, dist, dependencies and xDependencies. Those are generated by this service.
      PACKAGE_JSON_ALLOWED_FIELDS = %w[deprecated bin directories dist engines _hasShrinkwrap].freeze

      def initialize(name, packages)
        @name = name
        @packages = packages
        @dependencies = {}
        @dependency_ids = Hash.new { |h, key| h[key] = {} }
      end

      def execute(only_dist_tags: false)
        ServiceResponse.success(payload: metadata(only_dist_tags))
      end

      private

      attr_reader :name, :packages, :dependencies, :dependency_ids

      def metadata(only_dist_tags)
        result = { dist_tags: dist_tags }

        unless only_dist_tags
          result[:name] = name
          result[:versions] = versions
        end

        result
      end

      def versions
        package_versions = {}

        packages.each_batch do |relation|
          load_dependencies(relation)
          load_dependency_ids(relation)

          batched_packages = relation.preload_files
                             .preload_npm_metadatum

          batched_packages.each do |package|
            package_file = package.installable_package_files.last

            next unless package_file

            package_versions[package.version] = build_package_version(package, package_file)
          end
        end

        package_versions
      end

      def dist_tags
        build_package_tags.tap { |t| t['latest'] ||= sorted_versions.last }
      end

      def build_package_tags
        package_tags.to_h { |tag| [tag.name, tag.package.version] }
      end

      def build_package_version(package, package_file)
        abbreviated_package_json(package).merge(
          name: package.name,
          version: package.version,
          dist: {
            shasum: package_file.file_sha1,
            tarball: tarball_url(package, package_file)
          }
        ).tap do |package_version|
          package_version.merge!(build_package_dependencies(package))
        end
      end

      def tarball_url(package, package_file)
        expose_url api_v4_projects_packages_npm_package_name___file_name_path(
          { id: package.project_id, package_name: package.name, file_name: package_file.file_name }, true
        )
      end

      def build_package_dependencies(package)
        dependency_ids[package.id].each_with_object(Hash.new { |h, key| h[key] = {} }) do |(type, ids), memo|
          ids.each do |id|
            memo[inverted_dependency_types[type]].merge!(dependencies[id])
          end
        end
      end

      def inverted_dependency_types
        Packages::DependencyLink.dependency_types.invert.stringify_keys
      end
      strong_memoize_attr :inverted_dependency_types

      def sorted_versions
        versions = packages.pluck_versions.compact
        VersionSorter.sort(versions)
      end

      def package_tags
        Packages::Tag.for_package_ids(packages)
                     .preload_package
      end

      def abbreviated_package_json(package)
        json = package.npm_metadatum&.package_json || {}
        json.slice(*PACKAGE_JSON_ALLOWED_FIELDS)
      end

      def load_dependencies(packages)
        Packages::Dependency
          .id_in(
            Packages::DependencyLink
              .for_packages(packages)
              .select_dependency_id
          )
          .id_not_in(dependencies.keys)
          .each_batch do |relation|
            relation.each do |dependency|
              dependencies[dependency.id] = { dependency.name => dependency.version_pattern }
            end
          end
      end

      def load_dependency_ids(packages)
        Packages::DependencyLink
          .dependency_ids_grouped_by_type(packages)
          .each_batch(column: :package_id) do |relation|
            relation.each do |dependency_link|
              dependency_ids[dependency_link.package_id] = dependency_link.dependency_ids_by_type
            end
          end
      end
    end
  end
end