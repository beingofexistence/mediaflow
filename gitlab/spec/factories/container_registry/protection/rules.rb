# frozen_string_literal: true

FactoryBot.define do
  factory :container_registry_protection_rule, class: 'ContainerRegistry::Protection::Rule' do
    project
    container_path_pattern { '@my_scope/my_container' }
    delete_protected_up_to_access_level { :developer }
    push_protected_up_to_access_level { :developer }
  end
end
