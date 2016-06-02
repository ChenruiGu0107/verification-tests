Feature: Check deployments function
  # @author yapei@redhat.com
  # @case_id 501003
  Scenario: make deployment from web console
    # create a project on web console
    When I create a new project via web
    Then the step should succeed
    # create dc
    Given I use the "<%= project.name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    And evaluation of `"hooks"` is stored in the :dc_name clipboard
    When I perform the :wait_latest_deployments_to_status web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>  |
      | status_name  | Deployed |
    Then the step should succeed
    # manually trigger deploy after deployments is "Deployed"
    When I perform the :manually_deploy web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>  |
    Then the step should succeed
    When I perform the :wait_latest_deployments_to_status web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>  |
      | status_name  | Running |
    Then the step should succeed
    And I get the "disabled" attribute of the "button" web element:
      | text | Deploy |
    Then the output should contain "true"
    When I perform the :wait_latest_deployments_to_status web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>  |
      | status_name  | Deployed |
    Then the step should succeed
    # cancel deployments
    When I perform the :manually_deploy web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>  |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :running
    When I perform the :cancel_deployments web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>  |
      | dc_number    | 3 |
    Then the step should succeed
    When I perform the :wait_latest_deployments_to_status web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>  |
      | status_name  | Cancelled           |
    Then the step should succeed

  # @author wsun@redhat.com
  # @case_id 515434
  Scenario: Scale the application by changing replicas in deployment config
    Given I login via web console
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    Given I wait for the pod named "hooks-1-deploy" to die
    When I perform the :edit_replicas_on_deployment_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks               |
      | replicas     | 2                   |
    Then the step should succeed
    And I wait until number of replicas match "2" for replicationController "hooks-1"
    When I perform the :edit_replicas_on_deployment_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks               |
      | replicas     | -2                  |
    When I get the html of the web page
    Then the output should match:
      | Replicas can't be negative. |
    When I run the :cancel_edit_replicas_on_deployment_page web console action
    Then the step should succeed
    When I perform the :edit_replicas_on_rc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks               |
      | dc_number    | 1                   |
      | replicas     | 1                   |
    And I wait until number of replicas match "1" for replicationController "hooks-1"
    Then the step should succeed
    When I perform the :edit_replicas_on_rc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks               |
      | dc_number    | 1                   |
      | replicas     | -1                  |
    When I get the html of the web page
    Then the output should match:
      | Replicas can't be negative. |
    When I run the :cancel_edit_replicas_on_rc_page web console action
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest ||
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :running
    When  I run the :deploy client command with:
      | deployment_config | hooks |
      | cancel            ||
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :failed
    When I perform the :edit_replicas_on_rc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks               |
      | dc_number    | 2                   |
      | replicas     | 2                   |
    Then the step should fail

  # @author yapei@redhat.com
  # @case_id 483174
  Scenario: Check deployment info on web console
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    # check dc detail info
    When I perform the :check_dc_strategy web console action with:
      | project_name | <%= project.name %>   |
      | dc_name      | hooks                 |
      | dc_strategy  | <%= dc.strategy(user:user)["type"] %> |
    Then the step should succeed
    When I perform the :check_dc_manual_cli_trigger web console action with:
      | project_name | <%= project.name %>   |
      | dc_name      | hooks                 |
      | dc_manual_trigger_cli | oc deploy hooks --latest -n <%= project.name %> |
    Then the step should succeed
    When I perform the :check_dc_config_trigger web console action with:
      | project_name | <%= project.name %>   |
      | dc_name      | hooks                 |
      | dc_config_change | Config            |
    Then the step should succeed
    When I perform the :check_dc_selector web console action with:
      | project_name | <%= project.name %>    |
      | dc_name      | hooks                  |
      | dc_selectors_key | <%= dc.selector(user:user).keys[0] %> |
      | dc_selectors_value | <%= dc.selector(user:user).values[0] %> |
    Then the step should succeed
    When I perform the :check_dc_replicas web console action with:
      | project_name | <%= project.name %>    |
      | dc_name      | hooks                  |
      | dc_replicas  | <%= dc.replicas(user:user) %>  |
    Then the step should succeed
    # check #1 deployment info
    When I perform the :check_specific_deploy_selector web console action with:
      | project_name | <%= project.name %>    |
      | dc_name      | hooks                  |
      | dc_number    | 1                      |
      | specific_deployment_selector | deployment=hooks-1 |
    Then the step should succeed
    # check #2 deployment info
    When I perform the :manually_deploy web console action with:
      | project_name | <%= project.name %>    |
      | dc_name      | hooks                  |
    Then the step should succeed
    When I perform the :wait_latest_deployments_to_status web console action with:
      | project_name | <%= project.name %>    |
      | dc_name      | hooks                  |
      | status_name  | Deployed               |
    Then the step should succeed
    When I perform the :check_specific_deploy_selector web console action with:
      | project_name | <%= project.name %>    |
      | dc_name      | hooks                  |
      | dc_number    | 2                      |
      | specific_deployment_selector | deployment=hooks-2 |
    Then the step should succeed
