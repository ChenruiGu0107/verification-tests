Feature: ConfigMap related features
  # @author xxing@redhat.com
  # @case_id OCP-12184
  Scenario: Show envs from a ConfigMap for Pods
    Given the master version > "3.4"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap.yaml         |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/pod-configmap-env.yaml |
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap.yaml         |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap-example.yaml |
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

  # @author yanpzhan@redhat.com
  # @case_id OCP-12232
  Scenario: Create new config maps and secrets when adding config files
    Given the master version >= "3.5"
    Given I have a project
    When I run the :run client command with:
      | name       | myrun                 |
      | image      | aosqe/hello-openshift |
      | limits     | memory=256Mi          |
    Then the step should succeed

    When I perform the :click_add_config_file_from_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
    Then the step should succeed

    When I perform the :create_config_map_without_value web console action with:
       | project_name           | <%= project.name %> |
       | target_config_map_name | test12232           |
       | item_key               | my.key              |
    Then the step should succeed

    When I run the :click_create_secret_link web console action
    Then the step should succeed

    When I perform the :create_source_secret_with_basic_authentication web console action with:
      | new_secret_name | secret12232          |
      | auth_type       | Basic Authentication |
      | username        | gituser              |
      | password_token  | 12345678             |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed

    When I perform the :add_values_from_configmap_as_volume web console action with:
      | target_config_map | test12232 |
      | config_mount_path | /testdate |
    Then the step should succeed

    When I perform the :click_add_config_file_from_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
    Then the step should succeed

    When I perform the :add_values_from_secret_as_volume web console action with:
      | target_secret_name | secret12232 |
      | config_mount_path  | /date       |
    Then the step should succeed

    When I run the :get client command with:
      | resource      | configmap,secret   |
    Then the step should succeed
    And the output should contain:
      | test12232     |
      | secret12232   |

    When I run the :policy_add_role_to_user client command with:
      | role      | view                                |
      | user_name | <%= user(1, switch: false).name  %> |
    Then the step should succeed
    Given I switch to the second user
    Given I login via web console

    When I access the "/console/project/<%= project.name %>/add-config-volume?kind=DeploymentConfig&name=myrun" path in the web console
    Then the step should succeed

    Given I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should contain:
      | Error |
      | Access denied |
      | You do not have authority to update deployment config myrun |
    """


  # @author hasha@redhat.com
  # @case_id OCP-15973
  Scenario: Add configmap to application from the configmap page
    Given the master version >= "3.7"
    Given I create a new project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap.yaml |
    Then the step should succeed
    When I run the :run client command with:
      | name       | testdc                |
      | image      | aosqe/hello-openshift |
    Then the step should succeed
    When I perform the :add_configmap_to_application_as_env web console action with:
      | project_name    | <%= project.name %> |
      | app_name        | testdc              |
      | config_map_name | special-config      |
    Then the step should succeed
    When I run the :check_successful_info_for_adding web console action
    Then the step should succeed
    When I perform the :check_env_from_configmap_or_secret_on_dc_page web console action with:
      | project_name  | <%= project.name %> |
      | dc_name       | testdc              |
      | resource_name | special-config      |
      | resource_type | Config Map          |
    Then the step should succeed
    Given I wait until the status of deployment "testdc" becomes :complete
    When I perform the :add_configmap_to_application_as_volume web console action with:
      | project_name    | <%= project.name %> |
      | app_name        | testdc              |
      | config_map_name | special-config      |
      | mount_path      | /data               |
    Then the step should succeed
    When I run the :check_successful_info_for_adding web console action
    Then the step should succeed
    When I perform the :check_volume_from_configmap_on_dc web console action with:
      | project_name   | <%= project.name %> |
      | dc_name        | testdc              |
      | configmap_name | special-config      |
    Then the step should succeed

