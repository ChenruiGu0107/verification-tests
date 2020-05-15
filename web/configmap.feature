Feature: ConfigMap related features
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

