Feature: check event feature on web console
  # @author yanpzhan@redhat.com
  # @case_id OCP-10783
  Scenario: Check events tab on individual resource pages
    Given I have a project
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | latest                                     |
      | namespace    | openshift                                  |
      | app_name     | nodejs-sample                              |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should succeed

    Given the "nodejs-sample-1" build completed
    And I perform the :check_event_tab_on_build_page web console action with:
      | project_name      | <%= project.name %>           |
      | bc_and_build_name | nodejs-sample/nodejs-sample-1 |
    Then the step should succeed

    When I perform the :check_event_tab_on_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | nodejs-sample       |
    Then the step should succeed

    When I perform the :check_event_tab_on_deployment_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | nodejs-sample       |
      | dc_number    | 1                   |
    Then the step should succeed

    When I perform the :check_event_tab_on_pod_page web console action with:
      | project_name | <%= project.name %>   |
      | pod_name     | nodejs-sample-1-build |
    Then the step should succeed

    When I perform the :check_event_tab_on_service_page web console action with:
      | project_name | <%= project.name %> |
      | service_name | nodejs-sample       |
    Then the step should succeed

    When I run the :run client command with:
      | name         | testpod               |
      | image        | aosqe/hello-openshift |
      | generator    | run/v1                |
    Then the step should succeed

    When I perform the :check_event_tab_on_standalone_rc_page web console action with:
      | project_name | <%= project.name %> |
      | rc_name      | testpod             |
    Then the step should succeed
