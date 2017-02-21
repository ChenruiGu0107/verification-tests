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

  # @author yapei@redhat.com
  # @case_id OCP-11031
  Scenario: Add values from config map as volume
    Given the master version >= "3.5"
    Given I have a project
    # create configmap and DC
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap-example.yaml |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml         |
    Then the step should succeed
    When I run the :run client command with:
      | name  | myrun                 |
      | image | aosqe/hello-openshift |
    Then the step should succeed
    # check there is Add Config Files link for dc and rc
    When I perform the :check_there_is_add_config_file_for_dc web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
    Then the step should succeed
    When I perform the :check_there_is_add_config_file_for_rc web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
      | dc_number    | 1                   |
    Then the step should succeed
    # Add Config Files from rc/myrun-1 page
    Given I wait until the status of deployment "myrun" becomes :complete
    When I perform the :click_add_config_file_from_rc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
      | dc_number    | 1                   |
    Then the step should succeed
    When I perform the :add_values_from_configmap_as_volume web console action with:
      | target_config_map | example-config |
      | config_mount_path | /data          |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=myrun-2 |
    When I run the :exec client command with:
      | pod              | <%= pod.name %> |
      | exec_command     | ls              |
      | exec_command_arg | /data           |
    Then the step should succeed
    And the output should contain:
      | example.property.1    |
      | example.property.2    |
      | example.property.file |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>          |
      | exec_command     | cat                      |
      | exec_command_arg | /data/example.property.1 |
    Then the step should succeed
    And the output should contain:
      | hello |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>          |
      | exec_command     | cat                      |
      | exec_command_arg | /data/example.property.2 |
    Then the step should succeed
    And the output should contain:
      | world |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>             |
      | exec_command     | cat                         |
      | exec_command_arg | /data/example.property.file |
    Then the step should succeed
    And the output should contain:
      | property.1=value-1 |
      | property.2=value-2 |
      | property.3=value-3 |
    When I perform the :check_volume_from_configmap_on_dc web console action with:
      | project_name   | <%= project.name %> |
      | dc_name        | myrun               |
      | configmap_name | example-config      |
    Then the step should succeed
    When I perform the :check_volume_info_in_pod_template_on_dc web console action with:
      | project_name   | <%= project.name %> |
      | dc_name        | myrun               |
      | mount_path     | /data               |
    Then the step should succeed
    When I perform the :click_on_configmap_name web console action with:
      | configmap_name | example-config |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Given the expression should be true> browser.url.include? "/browse/config-maps/example-config"
    """
    # Add Config Files from dc/myrun
    When I perform the :click_add_config_file_from_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
    Then the step should succeed
    When I perform the :add_values_from_configmap_as_volume_with_specific_keys_and_paths web console action with:
      | target_config_map | special-config  |
      | config_mount_path | /data/configmap |
    Then the step should succeed
    When I perform the :pick_key_and_set_path web console action with:
      | specified_key     | special.how     |
      | specified_path    | /configmap.how  |
    Then the step should succeed
    When I run the :check_error_for_invalid_specified_path web console action
    Then the step should succeed
    When I perform the :pick_key_and_set_path web console action with:
      | specified_key     | special.how       |
      | specified_path    | configmap/../how  |
    Then the step should succeed
    When I run the :check_error_for_invalid_specified_path web console action
    Then the step should succeed
    When I perform the :pick_key_and_set_path web console action with:
      | specified_key     | special.how         |
      | specified_path    | prop/configmap.how  |
    Then the step should succeed
    When I perform the :pick_another_key_and_set_another_path web console action with:
      | specified_key     | special.type        |
      | specified_path    | prop/configmap.type |
    Then the step should succeed
    When I run the :click_add_button web console action
    Then the step should succeed
    # check volume with specified keys and path
    Given a pod becomes ready with labels:
      | deployment=myrun-3 |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>          |
      | exec_command     | ls                       |
      | exec_command_arg | /data/configmap/prop     |
    Then the step should succeed
    And the output should contain:
      | configmap.how  |
      | configmap.type |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>                    |
      | exec_command     | cat                                |
      | exec_command_arg | /data/configmap/prop/configmap.how |
    Then the step should succeed
    And the output should contain:
      | very |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>                     |
      | exec_command     | cat                                 |
      | exec_command_arg | /data/configmap/prop/configmap.type |
    Then the step should succeed
    And the output should contain:
      | charm |
    When I perform the :check_specified_key_and_path_in_volume_on_dc web console action with:
      | project_name   | <%= project.name %> |
      | dc_name        | myrun               |
      | specified_key  | special.how         |
      | specified_path | prop/configmap.how  |
    Then the step should succeed
    When I perform the :check_specified_key_and_path_in_volume web console action with:
      | specified_key  | special.type        |
      | specified_path | prop/configmap.type |
    Then the step should succeed
    When I perform the :remove_volume_created_from_configmap_on_dc web console action with:
      | project_name   | <%= project.name %> |
      | dc_name        | myrun               |
      | configmap_name | example-config      |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=myrun-4 |
    When I perform the :check_volume_from_configmap_on_dc web console action with:
      | project_name   | <%= project.name %> |
      | dc_name        | myrun               |
      | configmap_name | example-config      |
    Then the step should fail
