Feature: ConfigMap related features

  # @author yapei@redhat.com
  # @case_id OCP-11859
  Scenario: Create ConfigMap with invalid value on web console
    Given the master version >= "3.5"
    Given I have a project
    When I perform the :check_unable_to_create_config_map_without_value web console action with:
      | project_name           | <%= project.name %> |
      | config_map_key         | my.key              |
      | target_config_map_name | -my                 |
    Then the step should succeed
    When I run the :confirm_error_for_invalid_config_map_name web console action
    Then the step should succeed
    When I perform the :check_unable_to_create_config_map_without_value web console action with:
      | project_name           | <%= project.name %> |
      | config_map_key         | my.key              |
      | target_config_map_name | my-                 |
    Then the step should succeed
    When I run the :confirm_error_for_invalid_config_map_name web console action
    Then the step should succeed
    When I perform the :check_unable_to_create_config_map_without_value web console action with:
      | project_name           | <%= project.name %> |
      | config_map_key         | my.key              |
      | target_config_map_name | TEST                |
    Then the step should succeed
    When I run the :confirm_error_for_invalid_config_map_name web console action
    Then the step should succeed
    When I perform the :check_unable_to_create_config_map_without_value web console action with:
      | project_name           | <%= project.name %> |
      | config_map_key         | my.key              |
      | target_config_map_name | test##              |
    Then the step should succeed
    When I run the :confirm_error_for_invalid_config_map_name web console action
    Then the step should succeed
    Given an 254 characters random string of type :dns is stored into the :long_configmap clipboard
    When I perform the :check_unable_to_create_config_map_without_value web console action with:
      | project_name           | <%= project.name %>      |
      | config_map_key         | my.key                   |
      | target_config_map_name | <%= cb.long_configmap %> |
    Then the step should succeed
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
    When I perform the :check_configmap_specified_key_and_path_in_volume_on_dc web console action with:
      | project_name   | <%= project.name %> |
      | dc_name        | myrun               |
      | specified_key  | special.how         |
      | specified_path | prop/configmap.how  |
    Then the step should succeed
    When I perform the :check_configmap_specified_key_and_path_in_volume web console action with:
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

  # @author yapei@redhat.com
  # @case_id OCP-11410
  Scenario: Add values from secret as volume
    Given the master version >= "3.5"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/OCP-11410/mysecret-1.yaml |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/OCP-11410/mysecret-2.yaml |
    Then the step should succeed
    When I run the :run client command with:
      | name  | myrun                 |
      | image | aosqe/hello-openshift |
    Then the step should succeed
    # Add Config Files from dc/myrun page
    Given I wait until the status of deployment "myrun" becomes :complete
    When I perform the :click_add_config_file_from_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
    Then the step should succeed
    When I perform the :add_values_from_secret_as_volume web console action with:
      | target_secret_name | mysecret1    |
      | config_mount_path  | /data/secret |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=myrun-2 |
    When I run the :exec client command with:
      | pod              | <%= pod.name %> |
      | exec_command     | ls              |
      | exec_command_arg | /data/secret    |
    Then the step should succeed
    And the output should contain:
      | password |
      | username |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>           |
      | exec_command     | cat                       |
      | exec_command_arg | /data/secret/password     |
    Then the step should succeed
    And the output should contain:
      | admin123 |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>           |
      | exec_command     | cat                       |
      | exec_command_arg | /data/secret/username     |
    Then the step should succeed
    And the output should contain:
      | admin |
    # check volume info on dc/myrun page
    When I perform the :check_volume_from_secret_on_dc web console action with:
      | project_name   | <%= project.name %> |
      | dc_name        | myrun               |
      | secret_name    | mysecret1           |
    Then the step should succeed
    When I perform the :check_volume_info_in_pod_template_on_dc web console action with:
      | project_name   | <%= project.name %> |
      | dc_name        | myrun               |
      | mount_path     | /data/secret        |
    Then the step should succeed
    When I perform the :click_on_secret_name web console action with:
      | secret_name | mysecret1 |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Given the expression should be true> browser.url.include? "/browse/secrets/mysecret1"
    """
    # Add Config Files from secret with specified path and key
    When I perform the :click_add_config_file_from_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
    Then the step should succeed
    When I perform the :add_values_from_secret_as_volume_with_specific_keys_and_paths web console action with:
      | target_secret_name | mysecret2   |
      | config_mount_path  | /datasecret |
    Then the step should succeed
    When I perform the :pick_key_and_set_path web console action with:
      | specified_key     | city              |
      | specified_path    | prop/secret.city  |
    Then the step should succeed
    When I perform the :pick_another_key_and_set_another_path web console action with:
      | specified_key     | country             |
      | specified_path    | prop/secret.country |
    Then the step should succeed
    When I run the :click_add_button web console action
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=myrun-3 |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>  |
      | exec_command     | ls               |
      | exec_command_arg | /datasecret/prop |
    Then the step should succeed
    And the output should contain:
      | secret.city    |
      | secret.country |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>              |
      | exec_command     | cat                          |
      | exec_command_arg | /datasecret/prop/secret.city |
    Then the step should succeed
    And the output should contain:
      | BeiJing |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>                 |
      | exec_command     | cat                             |
      | exec_command_arg | /datasecret/prop/secret.country |
    Then the step should succeed
    And the output should contain:
      | China |
    # Check volumn info from secret with path and key
    When I perform the :check_secret_specified_key_and_path_in_volume_on_dc web console action with:
      | project_name   | <%= project.name %> |
      | dc_name        | myrun               |
      | specified_key  | city                |
      | specified_path | prop/secret.city    |
    Then the step should succeed
    When I perform the :check_secret_specified_key_and_path_in_volume web console action with:
      | specified_key  | country             |
      | specified_path | prop/secret.country |
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id OCP-11674
  Scenario: Create ConfigMap on web console
    Given the master version >= "3.5"
    Given a "configmap.txt" file is created with the following lines:
      | charm |
    Given I have a project
    When I perform the :goto_configmaps_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :click_create_config_map_link web console action
    Then the step should succeed
    When I perform the :set_config_map_name web console action with:
      | target_config_map_name | specific-config-map |
    Then the step should succeed
    When I perform the :add_configmap_key_value_pairs web console action with:
      | config_map_key   | special.how |
      | config_map_value | very        |
    Then the step should succeed
    When I run the :click_to_add_configmap_item web console action
    Then the step should succeed
    When I perform the :add_configmap_key_value_pairs_from_file web console action with:
      | config_map_key | special.type                        |
      | file_path      | <%= expand_path("configmap.txt") %> |
    Then the step should succeed
    When I run the :click_to_add_configmap_item web console action
    Then the step should succeed
    When I perform the :add_configmap_key_value_pairs web console action with:
      | config_map_key   | special.who |
      | config_map_value | you         |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    When I perform the :click_to_goto_one_configmap_page web console action with:
      | config_map_name | specific-config-map |
    Then the step should succeed
    When I perform the :check_key_value_pairs_on_configmap_page web console action with:
      | configmap_key   | special.how |
      | configmap_value | very        |
    Then the step should succeed
    When I perform the :check_key_value_pairs_on_configmap_page web console action with:
      | configmap_key   | special.type |
      | configmap_value | charm        |
    Then the step should succeed
    When I perform the :check_key_value_pairs_on_configmap_page web console action with:
      | configmap_key   | special.who |
      | configmap_value | you         |
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id OCP-12006
  Scenario: Edit ConfigMap on web console
    Given the master version >= "3.5"
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml" replacing paths:
      | ["data"]["special.who"] | you |
    Then the step should succeed
    When I perform the :goto_configmaps_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_to_goto_edit_configmap_page web console action with:
      | config_map_name | special-config |
    Then the step should succeed
    When I perform the :edit_configmap_value web console action with:
      | config_map_key       | special.how    |
      | new_config_map_value | very very very |
    Then the step should succeed
    When I perform the :remove_configmap_item web console action with:
      | config_map_key | special.who |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_key_value_pairs_on_configmap_page web console action with:
      | configmap_key   | special.how    |
      | configmap_value | very very very |
    Then the step should succeed
    When I perform the :check_key_value_pairs_on_configmap_page web console action with:
      | configmap_key   | special.type |
      | configmap_value | charm        |
    Then the step should succeed
    When I perform the :check_missing_key_value_pairs_on_configmap_page web console action with:
      | configmap_key   | special.who |
      | configmap_value | you         |
    Then the step should succeed
    When I run the :click_to_goto_edit_page web console action
    Then the step should succeed
    When I run the :click_to_add_configmap_item web console action
    Then the step should succeed
    When I perform the :add_configmap_key_value_pairs web console action with:
      | config_map_key   | special.how |
      | config_map_value | very        |
    Then the step should succeed
    When I run the :check_configmap_error_indicating_duplicate_key web console action
    Then the step should succeed
    When I run the :check_save_button_disabled web console action
    Then the step should succeed
    When I perform the :goto_one_configmap_page web console action with:
      | project_name    | <%= project.name %> |
      | config_map_name | special-config      |
    Then the step should succeed
    When I run the :delete_resource web console action
    Then the step should succeed
    When I perform the :goto_one_configmap_page web console action with:
      | project_name    | <%= project.name %> |
      | config_map_name | special-config      |
    Then the step should succeed
    When I run the :check_empty_configmap_page_loaded_error web console action
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id OCP-12184
  Scenario: Show envs from a ConfigMap for Pods
    Given the master version > "3.4"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml         |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-env.yaml |
    Then the step should succeed
    Given the pod named "dapi-test-pod" status becomes :succeeded
    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | dapi-test-pod       |
    Then the step should succeed
    When I run the :click_on_environment_tab web console action
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | SPECIAL_LEVEL_KEY                                       |
      | env_var_value | Set to the key special.how in config map special-config |
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | SPECIAL_TYPE_KEY                                         |
      | env_var_value | Set to the key special.type in config map special-config |
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id OCP-12108
  Scenario: Filter on ConfigMap page
    Given the master version > "3.4"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml         |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap-example.yaml |
    Then the step should succeed
    When I run the :label client command with:
      | resource | configmap      |
      | name     | example-config |
      | key_val  | example=yes    |
    Then the step should succeed
    When I run the :label client command with:
      | resource | configmap      |
      | name     | special-config |
      | key_val  | special=yes    |
      | key_val  | example=no     |
    Then the step should succeed
    When I perform the :goto_configmaps_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :filter_resources_with_exists_option web console action with:
      | label_key     | example |
      | filter_action | exists  |
    Then the step should succeed
    When I perform the :check_filtered_resource_entry web console action with:
      | resource_name | example-config |
    Then the step should succeed
    When I perform the :check_filtered_resource_entry web console action with:
      | resource_name | special-config |
    Then the step should succeed
    When I run the :clear_all_filters web console action
    Then the step should succeed
    When I perform the :filter_resources web console action with:
      | label_key     | special |
      | label_value   | yes     |
      | filter_action | in ...  |
    Then the step should succeed
    When I perform the :check_filtered_resource_entry web console action with:
      | resource_name | special-config |
    Then the step should succeed
    When I perform the :check_filtered_resource_entry_missing web console action with:
      | resource_name | example-config |
    Then the step should succeed
    When I run the :clear_all_filters web console action
    Then the step should succeed
    When I perform the :filter_resources_with_exists_option web console action with:
      | label_key     | example        |
      | filter_action | does not exist |
    Then the step should succeed
    When I run the :check_no_configmap_to_show_warnings web console action
    Then the step should succeed
    When I run the :clear_all_filters web console action
    Then the step should succeed
    When I perform the :filter_resources web console action with:
      | label_key     | example    |
      | label_value   | yes        |
      | filter_action | not in ... |
    Then the step should succeed
    When I perform the :filter_resources web console action with:
      | label_key     | special |
      | label_value   | yes     |
      | filter_action | in ...  |
    Then the step should succeed
    When I perform the :check_filtered_resource_entry web console action with:
      | resource_name | special-config |
    Then the step should succeed
    When I perform the :check_filtered_resource_entry_missing web console action with:
      | resource_name | example-config |
    Then the step should succeed
