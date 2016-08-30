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
    When I perform the :wait_latest_deployments_to_deployed web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>  |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
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
    When I perform the :wait_latest_deployments_to_deployed web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>  |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
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
    When I perform the :wait_latest_deployments_to_deployed web console action with:
      | project_name | <%= project.name %>    |
      | dc_name      | hooks                  |
    Then the step should succeed
    When I perform the :check_specific_deploy_selector web console action with:
      | project_name | <%= project.name %>    |
      | dc_name      | hooks                  |
      | dc_number    | 2                      |
      | specific_deployment_selector | deployment=hooks-2 |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id 510377
  Scenario: View deployments streaming logs
    Given I create a new project via web
    When I run the :run client command with:
      | name  | mytest             |
      | image | openshift/mysql-55-centos7:latest |
      | env   | MYSQL_USER=test,MYSQL_PASSWORD=redhat,MYSQL_DATABASE=testdb |
    Then the step should succeed

    # Check deploy pod log
    When I perform the :check_log_context_on_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | mytest-1-deploy |
      | status       | Running |
    Then the step should succeed

    And I wait until the status of deployment "mytest" becomes :complete
    When I perform the :manually_deploy web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | mytest       |
    Then the step should succeed

    # Check deployment log
    When I perform the :check_log_context_on_running_deployment_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | mytest    |
      | dc_number    | 2         |
    Then the step should succeed

    And I wait until the status of deployment "mytest" becomes :complete
    Given 1 pods become ready with labels:
      | run=mytest |

    When I perform the :check_log_context_on_deployed_deployment_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | mytest    |
      | dc_number    | 2         |
    Then the step should succeed

    When I run the :follow_log web console action
    Then the step should succeed

    When I run the :go_to_top_log web console action
    Then the step should succeed

    When I perform the :open_full_view_log web console action with:
      | log_context | PLEASE REMEMBER TO SET A PASSWORD FOR THE MySQL root USER |
    Then the step should succeed

    #Compare the latest deployment log with the running pod log
    When I run the :logs client command with:
      | resource_name    | dc/mytest |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :output clipboard
    When I run the :logs client command with:
      | resource_name    | <%= pod.name %> |
    Then the step should succeed
    And the output should equal "<%= cb.output %>"

  # @author yapei@redhat.com
  # @case_id 533674
  Scenario: Idled DC handling on web console
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-with-service.yaml |
    Then the step should succeed
    Given I wait until the status of deployment "hello-openshift" becomes :complete
    When I run the :idle client command with:
      | svc_name | hello-openshift |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "hello-openshift-1"
    # check replicas after idle
    When I perform the :check_dc_replicas web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hello-openshift     |
      | dc_replicas  | 0                   |
    Then the step should succeed
    When I perform the :check_deployment_idle_text web console action with:
      | project_name      | <%= project.name %> |
      | dc_name           | hello-openshift     |
      | dc_number         |   1                 |
      | previous_replicas |   1                 |
    Then the step should succeed
    When I perform the :check_dc_idle_text_on_overview web console action with:
      | project_name      | <%= project.name %> |
      | dc_name           | hello-openshift     |
      | previous_replicas |   1                 |
    Then the step should succeed
    When I perform the :check_idle_donut_text_on_overview web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hello-openshift     |
    Then the step should succeed
    # check replicas after wake up
    When I perform the :click_wake_up_option_on_overview web console action with:
      | project_name      | <%= project.name %> |
      | dc_name           | hello-openshift     |
      | previous_replicas |   1                 |
    Then the step should succeed
    Given I wait until number of replicas match "1" for replicationController "hello-openshift-1"
    When I perform the :check_dc_replicas web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hello-openshift     |
      | dc_replicas  | 1                   |
    Then the step should succeed
    When I perform the :check_donut_text_on_overview web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hello-openshift     |
      | donut_text   | 1pod                |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id 533676
  Scenario: Idled RC handling on web console
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/mdshuai/testfile-openshift/master/k8s/rc-and-svc-list.yaml |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=hello-pod |
    When I run the :idle client command with:
      | svc_name | hello-svc |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "hello-pod"
    When I perform the :check_standalone_rc_idle_text web console action with:
      | project_name      | <%= project.name %> |
      | rc_name           | hello-pod           |
      | previous_replicas |  2                  |
    Then the step should succeed
    When I perform the :check_dc_idle_text_on_overview web console action with:
      | project_name      | <%= project.name %> |
      | dc_name           | hello-pod           |
      | previous_replicas |   2                 |
    Then the step should succeed
    When I perform the :check_idle_donut_text_on_overview web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hello-pod           |
    Then the step should succeed
    # check replicas after wake up
    When I perform the :click_wake_up_option_on_rc_page web console action with:
      | project_name      | <%= project.name %> |
      | rc_name           | hello-pod           |
      | previous_replicas |  2                  |
    Then the step should succeed
    Given I wait until number of replicas match "2" for replicationController "hello-pod"
    When I perform the :check_standalone_rc_replicas web console action with:
      | project_name      | <%= project.name %> |
      | rc_name           | hello-pod           |
      | rc_replicas       | 2                   |
    Then the step should succeed
    When I perform the :check_donut_text_on_overview web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hello-pod           |
      | donut_text   | 2pods               |
    Then the step should succeed
