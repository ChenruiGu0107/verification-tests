Feature: ConfigMap related features
  
  # @author yapei@redhat.com
  # @case_id OCP-11859
  Scenario: Create ConfigMap with invalid value on web console
    Given the master version >= "3.5"
    Given I have a project
    When I perform the :create_config_map_without_value web console action with:
      | project_name           | <%= project.name %> |
      | config_map_key         | my.key              |
      | target_config_map_name | -my                 |
    Then the step should fail
    When I run the :confirm_error_for_invalid_config_map_name web console action
    Then the step should succeed
    When I perform the :create_config_map_without_value web console action with:
      | project_name           | <%= project.name %> |
      | config_map_key         | my.key              |
      | target_config_map_name | my-                 |
    Then the step should fail
    When I run the :confirm_error_for_invalid_config_map_name web console action
    Then the step should succeed
    When I perform the :create_config_map_without_value web console action with:
      | project_name           | <%= project.name %> |
      | config_map_key         | my.key              |
      | target_config_map_name | TEST                |
    Then the step should fail
    When I run the :confirm_error_for_invalid_config_map_name web console action
    Then the step should succeed
    When I perform the :create_config_map_without_value web console action with:
      | project_name           | <%= project.name %> |
      | config_map_key         | my.key              |
      | target_config_map_name | test##              |
    Then the step should fail
    When I run the :confirm_error_for_invalid_config_map_name web console action
    Then the step should succeed
    Given an 254 characters random string of type :dns is stored into the :long_configmap clipboard
    When I perform the :create_config_map_without_value web console action with:
      | project_name           | <%= project.name %>      |
      | config_map_key         | my.key                   |
      | target_config_map_name | <%= cb.long_configmap %> |
    Then the step should fail
    When I run the :confirm_error_for_long_config_map_name web console action
    Then the step should succeed
    When I perform the :create_config_map_without_value web console action with:
       | project_name           | <%= project.name %> |
       | target_config_map_name | test                |
       | config_map_key         | my.key              |
    Then the step should succeed
    When I perform the :check_config_map_with_empty_value web console action with:
       | project_name           | <%= project.name %> |
       | config_map_name        | test                |
    Then the step should succeed
