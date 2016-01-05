Feature: Check deployments function
  #@author: yapei@redhat.com
  #@case_id: 501003
  Scenario: make deployment from web console
    # create a project on web console
    When I create a new project via web
    Then the step should succeed

    # create app from template on web console
    Given I wait for the :create_app_from_image web console action to succeed with:
      | project_name  | <%= project.name %> |
      | image_name    | nodejs |
      | image_tag     | 0.10   |
      | namespace     | openshift |
      | app_name      | ndapp  |
      | source_url    | https://github.com/openshift/nodejs-ex.git |
    And evaluation of `"ndapp"` is stored in the :app_name clipboard
    # check dc detail info
    When I perform the :check_deploymentconfigs_info web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.app_name %>  |
    Then the step should succeed
    And I get the html of the web page
    Then the output should match "oc deploy <%= cb.app_name %> --latest -n <%= project.name %>"
    When I perform the :wait_latest_deployments_to_status web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.app_name %>  |
      | status_name  | Deployed |
    Then the step should succeed
    # manually trigger deploy after deployments is "Deployed" 
    When I run the :manually_deploy web console action
    Then the step should succeed
    When I perform the :wait_latest_deployments_to_status web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.app_name %>  |
      | status_name  | Running |
    Then the step should succeed
    And I get the "disabled" attribute of the "button" web element:
      | text | Deploy |
    Then the output should contain "true"
    When I perform the :wait_latest_deployments_to_status web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.app_name %>  |
      | status_name  | Deployed |
    Then the step should succeed
    # cancel deployments
    When I run the :manually_deploy web console action
    Then the step should succeed
    When I perform the :wait_latest_deployments_to_status web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.app_name %>  |
      | status_name  | Running |
    Then the step should succeed
    When I perform the :cancel_deployments web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.app_name %>  |
      | dc_number    | 3 |
    Then the step should succeed
    When I perform the :wait_latest_deployments_to_status web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.app_name %>  |
      | status_name  | Cancelled           |
    Then the step should succeed
