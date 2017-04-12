Feature: Check deployments function
  # @author yapei@redhat.com
  # @case_id OCP-10679
  Scenario: make deployment from web console
    # create a project on web console
    When I create a new project via web
    Then the step should succeed
    # create dc
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/cancel-deployment-gracefully.json |
    Then the step should succeed
    And evaluation of `"hooks"` is stored in the :dc_name clipboard
    When I perform the :wait_latest_deployments_to_deployed web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>   |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
    # manually trigger deploy after deployments is "Deployed"
    When I perform the :manually_deploy web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>   |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :running
    When I get the "disabled" attribute of the "button" web element:
      | text | Deploy |
    Then the output should contain "true"
    When I perform the :wait_latest_deployments_to_deployed web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>   |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
    # cancel deployments
    When I perform the :manually_deploy web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>   |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :running
    When I perform the :cancel_deployments web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>   |
      | dc_number    | 3                   |
    Then the step should succeed
    When I perform the :wait_latest_deployments_to_status web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | <%= cb.dc_name %>   |
      | status_name  | Cancelled           |
    Then the step should succeed

  # @author wsun@redhat.com
  # @case_id OCP-10749
  Scenario: Scale the application by changing replicas in deployment config
    Given I login via web console
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    Given I wait for the pod named "hooks-1-deploy" to die
    When I perform the :edit_replicas_on_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks               |
      | replicas     | 2                   |
    Then the step should succeed
    And I wait until number of replicas match "2" for replicationController "hooks-1"
    When I perform the :edit_replicas_on_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks               |
      | replicas     | -2                  |
    When I get the html of the web page
    Then the output should match:
      | Replicas can't be negative. |
    When I run the :cancel_edit_replicas_on_dc_page web console action
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
  # @case_id OCP-12417
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
  # @case_id OCP-11198
  Scenario: View deployments streaming logs
    Given I create a new project via web
    When I run the :new_app client command with:
      | name  | mytest                |
      | image | mysql                 |
      | env   | MYSQL_USER=test       |
      | env   | MYSQL_PASSWORD=redhat |
      | env   | MYSQL_DATABASE=testdb |
    Then the step should succeed

    And I wait until the status of deployment "mytest" becomes :complete
    Given 1 pods become ready with labels:
      | deploymentconfig=mytest |

    When I perform the :check_log_context_on_deployed_deployment_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | mytest              |
      | dc_number    | 1                   |
    Then the step should succeed

    When I run the :follow_log web console action
    Then the step should succeed

    When I run the :go_to_top_log web console action
    Then the step should succeed

    When I perform the :open_full_view_log web console action with:
      | log_context | mysql |
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
  # @case_id OCP-10937
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
      | donut_text   | 1                   |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-11631
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
      | donut_text   | 2                   |
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-12350
  Scenario: Check k8s deployments on Overview and Monitoring page
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc536600/hello-deployment-1.yaml |
      | record | true                                                                                                           |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_overview_tile web console action with:
      | resource_type | Deployment                |
      | resource_name | hello-openshift           |
      | image_name    | openshift/hello-openshift |
      | scaled_number | 4                         |
    Then the step should succeed
    When I perform the :check_latest_deployment_version_on_overview web console action with:
      | resource_type | Deployment      |
      | resource_name | hello-openshift |
      | version       | #1              |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | deployment                                                                                                  |
      | resource_name | hello-openshift                                                                                             |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"yapei/hello-openshift", "name":"hello-openshift"}]}}}} |
    Then the step should succeed
    Given 4 pods become ready with labels:
      | app=hello-openshift |
    When I perform the :check_overview_tile web console action with:
      | resource_type | Deployment            |
      | resource_name | hello-openshift       |
      | image_name    | yapei/hello-openshift |
      | scaled_number | 4                     |
    Then the step should succeed
    When I perform the :check_latest_deployment_version_on_overview web console action with:
      | resource_type | Deployment      |
      | resource_name | hello-openshift |
      | version       | #2              |
    Then the step should succeed
    Given I run the steps 2 times:
    """
    When I run the :scale_up_once web console action
    Then the step should succeed
    """
    When I perform the :check_pod_scaled_numbers web console action with:
      | scaled_number | 6 |
    Then the step should succeed

    Given I run the steps 4 times:
    """
    When I run the :scale_down_once web console action
    Then the step should succeed
    """
    Given 2 pods become ready with labels:
      | app=hello-openshift |
    When I perform the :check_pod_scaled_numbers web console action with:
      | scaled_number | 2 |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | deployment                                                                                                       |
      | resource_name | hello-openshift                                                                                                  |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"yapei/hello-openshift-test", "name":"hello-openshift"}]}}}} |
    Then the step should succeed
    When I perform the :goto_monitoring_page web console action with:
      | project_name  | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_image_name_on_monitoring web console action with:
      | resource_type | Deployments               |
      | image_name    | openshift/hello-openshift |
    Then the step should fail
    When I perform the :check_image_name_on_monitoring web console action with:
      | resource_type | Deployments           |
      | image_name    | yapei/hello-openshift |
    Then the step should fail
    When I perform the :check_image_name_on_monitoring web console action with:
      | resource_type | Deployments                |
      | image_name    | yapei/hello-openshift-test |
    Then the step should succeed
    When I run the :click_on_hide_older_resources web console action
    Then the step should succeed
    When I perform the :check_image_name_on_monitoring web console action with:
      | resource_type | Deployments               |
      | image_name    | openshift/hello-openshift |
    Then the step should succeed
    When I perform the :check_image_name_on_monitoring web console action with:
      | resource_type | Deployments           |
      | image_name    | yapei/hello-openshift |
    Then the step should succeed
    When I perform the :check_image_name_on_monitoring web console action with:
      | resource_type | Deployments                |
      | image_name    | yapei/hello-openshift-test |
    Then the step should succeed
    When I perform the :expand_resource_logs_by_image web console action with:
      | resource_type | Deployments           |
      | image_name    | yapei/hello-openshift |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should contain:
      | Logs are not available for replica sets. |
    When I perform the :expand_resource_logs_by_image web console action with:
      | resource_type | Deployments                |
      | image_name    | yapei/hello-openshift-test |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should contain:
      | To see application logs, view the logs for one of the replica set's |
    And I click the following "a" element:
      | text  | pods |
    Then the step should succeed
    Given the expression should be true> browser.url.start_with? "#{browser.base_url}/console/project/#{project.name}/browse/pods"

  # @author yapei@redhat.com
  # @case_id OCP-11593
  Scenario: Create,Edit and Delete HPA from the deployment config page
    Given the master version >= "3.3"
    Given I have a project
    When I run the :run client command with:
      | name         | myrun                 |
      | image        | aosqe/hello-openshift |
    Then the step should succeed
    Given I wait until the status of deployment "myrun" becomes :running
    # create autoscaler
    When I perform the :add_autoscaler_set_max_pod_and_cpu_req_per_from_dc_page web console action with:
      | project_name  | <%= project.name %> |
      | dc_name       | myrun               |
      | max_pods      | 10                  |
      | cpu_req_per   | 60                  |
    Then the step should succeed
    When I perform the :check_autoscaler_min_pods_for_dc web console action with:
      | min_pods      | 1                   |
    Then the step should succeed
    When I perform the :check_autoscaler_max_pods web console action with:
      | max_pods      | 10                  |
    Then the step should succeed
    When I perform the :check_autoscaler_cpu_request_target web console action with:
      | cpu_request_target  | 60%                 |
    Then the step should succeed
    When I perform the :check_autoscaler_min_pods_on_rc_page web console action with:
      | project_name  | <%= project.name %> |
      | dc_name       | myrun               |
      | dc_number     | 1                   |
      | min_pods      | 1                   |
    Then the step should succeed
    When I perform the :check_autoscaler_max_pods_on_rc_page web console action with:
      | project_name  | <%= project.name %> |
      | dc_name       | myrun               |
      | dc_number     | 1                   |
      | max_pods      | 10                  |
    Then the step should succeed
    When I perform the :check_autoscaler_cpu_request_target_on_rc_page web console action with:
      | project_name        | <%= project.name %> |
      | dc_name             | myrun               |
      | dc_number           | 1                   |
      | cpu_request_target  | 60                  |
    Then the step should succeed
    When I perform the :check_dc_link_in_autoscaler_on_rc_page web console action with:
      | project_name        | <%= project.name %> |
      | dc_name             | myrun               |
      | dc_number           | 1                   |
    Then the step should succeed
    # update autoscaler
    When I perform the :update_min_max_cpu_request_for_autoscaler_from_dc_page web console action with:
      | project_name       | <%= project.name %> |
      | dc_name            | myrun               |
      | min_pods           |  2                  |
      | max_pods           | 15                  |
      | cpu_req_per        | 85                  |
    Then the step should succeed
    When I perform the :check_autoscaler_min_pod_on_overview_page web console action with:
      | project_name  | <%= project.name %> |
      | min_pods      | 2                   |
    Then the step should succeed
    When I perform the :check_autoscaler_max_pod_on_overview_page web console action with:
      | project_name  | <%= project.name %> |
      | max_pods      | 15                  |
    Then the step should succeed
    When I perform the :manually_deploy web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
    Then the step should succeed
    When I perform the :wait_latest_deployments_to_status web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
      | status_name  | Active              |
    Then the step should succeed
    When I perform the :check_autoscaler_min_pods_on_rc_page web console action with:
      | project_name  | <%= project.name %> |
      | dc_name       | myrun               |
      | dc_number     | 2                   |
      | min_pods      | 2                   |
    Then the step should succeed
    When I perform the :check_autoscaler_max_pods_on_rc_page web console action with:
      | project_name  | <%= project.name %> |
      | dc_name       | myrun               |
      | dc_number     | 2                   |
      | max_pods      | 15                  |
    Then the step should succeed
    When I perform the :check_autoscaler_cpu_request_target_on_rc_page web console action with:
      | project_name        | <%= project.name %> |
      | dc_name             | myrun               |
      | dc_number           | 2                   |
      | cpu_request_target  | 85                  |
    Then the step should succeed
    # delete autoscaler
    When I perform the :delete_autoscaler_from_dc_page web console action with:
      | project_name       | <%= project.name %> |
      | dc_name            | myrun               |
    Then the step should succeed
    When I run the :get client command with:
      | resource  | hpa |
    Then the step should succeed
    And the output should not contain "myrun"

  # @author etrott@redhat.com
  # @case_id OCP-12375
  Scenario: Check ReplicaSet on Overview and ReplicaSet page
    Given the master version >= "3.4"
    Given I create a new project via web
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/replicaSet/tc536601/replicaset.yaml |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_overview_tile web console action with:
      | resource_type | Replica Set               |
      | resource_name | frontend                  |
      | image_name    | openshift/hello-openshift |
      | scaled_number | 3                         |
    Then the step should succeed
    And I click the following "a" element:
      | text  | frontend |
    Then the step should succeed
    Given the expression should be true> browser.url =~ /browse\/rs/
    When I perform the :click_to_goto_one_replicaset_page web console action with:
      | project_name         | <%= project.name %> |
      | k8s_replicasets_name | frontend            |
    Then the step should succeed
    When I perform the :check_label web console action with:
      | label_key   | app       |
      | label_value | guestbook |
    Then the step should succeed
    When I perform the :check_label web console action with:
      | label_key   | tier     |
      | label_value | frontend |
    Then the step should succeed
    When I perform the :check_rs_details web console action with:
      | project_name       | <%= project.name %>   |
      | rs_selectors_key   | tier                  |
      | rs_selectors_value | frontend              |
      | replicas           | 3 current / 3 desired |
    Then the step should succeed
    When I perform the :check_pods_number_in_table web console action with:
      | pods_number | 3 |
    Then the step should succeed
    When I run the :scale_up_once web console action
    Then the step should succeed
    When I perform the :check_replicas web console action with:
      | replicas | 4 current / 4 desired |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_pod_scaled_numbers web console action with:
      | scaled_number | 4 |
    Then the step should succeed
    When I perform the :click_to_goto_one_replicaset_page web console action with:
      | project_name         | <%= project.name %> |
      | k8s_replicasets_name | frontend            |
    Then the step should succeed
    Given I run the steps 2 times:
    """
    When I run the :scale_down_once web console action
    Then the step should succeed
    """
    Given 2 pods become ready with labels:
      | app=guestbook |
    When I perform the :check_replicas web console action with:
      | replicas | 2 current / 2 desired |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_pod_scaled_numbers web console action with:
      | scaled_number | 2 |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-12394
  Scenario: Pause and Resume Deployment Configuration
    Given the master version >= "3.4"
    Given I have a project
    When I run the :run client command with:
      | name         | myrun                 |
      | image        | aosqe/hello-openshift |
    Then the step should succeed
    Given I wait until the status of deployment "myrun" becomes :complete
    When I perform the :check_latest_deployment_version web console action with:
      | project_name              | <%= project.name %> |
      | dc_name                   | myrun               |
      | latest_deployment_version | 1                   |
    Then the step should succeed
    When I perform the :pause_deployment_configuration web console action with:
      | project_name       | <%= project.name %> |
      | dc_name            | myrun               |
    Then the step should succeed
    When I perform the :check_pause_message_on_dc_page web console action with:
      | project_name       | <%= project.name %> |
      | dc_name            | myrun               |
    Then the step should succeed
    When I perform the :check_pause_message_on_overview_page web console action with:
      | project_name       | <%= project.name %> |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | dc/myrun  |
      | e        | test=1234 |
    Then the step should succeed
    When I perform the :check_latest_deployment_version web console action with:
      | project_name              | <%= project.name %> |
      | dc_name                   | myrun               |
      | latest_deployment_version | 1                   |
    Then the step should succeed
    When I perform the :click_resume_on_overview_page web console action with:
      | project_name              | <%= project.name %> |
    Then the step should succeed
    Given the pod named "myrun-2-deploy" becomes ready
    And I wait for the pod named "myrun-2-deploy" to die
    And a pod becomes ready with labels:
      | deployment=myrun-2 |
    When I perform the :check_latest_deployment_version web console action with:
      | project_name              | <%= project.name %> |
      | dc_name                   | myrun               |
      | latest_deployment_version | 2                   |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | dc/myrun  |
      | e        | value=ago |
    Then the step should succeed
    Given the pod named "myrun-3-deploy" becomes ready
    And I wait for the pod named "myrun-3-deploy" to die
    When I perform the :check_latest_deployment_version web console action with:
      | project_name              | <%= project.name %> |
      | dc_name                   | myrun               |
      | latest_deployment_version | 3                   |
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-12004
  Scenario: DC Image Configuration on web console
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml |
    Then the step should succeed
    Given I wait until the status of deployment "dctest" becomes :complete
    When I perform the :goto_one_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | dctest              |
    Then the step should succeed
    When I run the :click_to_goto_edit_page web console action
    Then the step should succeed
    When I perform the :update_container_image_name web console action with:
      | container_name | dctest-1              |
      | image_name     | aosqe/hello-openshift |
    Then the step should succeed
    When I perform the :set_autostart_deployment_checkbox web console action with:
      | container_name       | dctest-2 |
      | deployment_autostart | true     |
    Then the step should succeed
    When I perform the :set_image_change_trigger web console action with:
      | container_name | dctest-2  |
      | namespace      | openshift |
      | image_stream   | php       |
      | tag            | 5.5       |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_dc_image_stream web console action with:
      | project_name   | <%= project.name %>   |
      | dc_name        | dctest                |
      | container_name | dctest-1              |
      | image_stream   | aosqe/hello-openshift |
    Then the step should succeed
    When I perform the :check_dc_image_stream web console action with:
      | project_name   | <%= project.name %>     |
      | dc_name        | dctest                  |
      | container_name | dctest-2                |
      | image_stream   | openshift3/php-55-rhel7 |
    Then the step should succeed
    When I perform the :check_dc_image_trigger web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | dctest              |
      | dc_image     | openshift/php:5.5   |
    Then the step should succeed
    Given I wait until the status of deployment "dctest" becomes :complete
    When I run the :click_to_goto_edit_page web console action
    Then the step should succeed
    When I perform the :set_autostart_deployment_checkbox web console action with:
      | container_name       | dctest-1 |
      | deployment_autostart | true     |
    Then the step should succeed
    When I perform the :set_image_change_trigger web console action with:
      | container_name | dctest-1  |
      | namespace      | openshift |
      | image_stream   | nodejs    |
      | tag            | 0.10      |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_dc_image_trigger web console action with:
      | project_name | <%= project.name %>   |
      | dc_name      | dctest                |
      | dc_image     | openshift/nodejs:0.10 |
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id OCP-10990
  Scenario: Environment handling on DC edit page
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml |
    Then the step should succeed
    Given I wait until the status of deployment "dctest" becomes :complete
    # Add env var for each container
    When I perform the :goto_edit_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | dctest              |
    Then the step should succeed
    When I perform the :add_env_var_for_dc_container web console action with:
      | container_name | dctest-1 |
      | env_var_key    | env1     |
      | env_var_value  | value1   |
    Then the step should succeed
    When I perform the :add_env_var_for_dc_container web console action with:
      | container_name | dctest-2 |
      | env_var_key    | _TEST    |
      | env_var_value  | 2        |
    Then the step should succeed
    When I perform the :add_env_var_for_dc_container web console action with:
      | container_name | dctest-2 |
      | env_var_key    | env21    |
      | env_var_value  | value21  |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # Check Environment tab
    When I run the :goto_environment_tab web console action
    Then the step should succeed
    When I perform the :check_env_tab_for_dc_container web console action with:
      | container_name | dctest-1 |
      | env_var_key    | env1     |
      | env_var_value  | value1   |
    Then the step should succeed
    When I perform the :check_env_tab_for_dc_container web console action with:
      | container_name | dctest-2 |
      | env_var_key    | env21    |
      | env_var_value  | value21  |
    Then the step should succeed
    When I perform the :check_env_tab_for_dc_container web console action with:
      | container_name | dctest-2 |
      | env_var_key    | _TEST    |
      | env_var_value  | 2        |
    Then the step should succeed
    Given I wait until the status of deployment "dctest" becomes :complete
    # Update & delete env var
    When I run the :click_to_goto_edit_page web console action
    Then the step should succeed
    When I perform the :edit_env_var_value web console action with:
      | env_variable_name | env1 |
      | new_env_value     | value1update |
    Then the step should succeed
    When I perform the :delete_env_var web console action with:
      | env_var_key | env21 |
    Then the step should succeed
    When I perform the :edit_env_var_key web console action with:
      | env_var_value | value1update |
      | new_env_key   | env11        |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # Check Environment tab
    When I run the :goto_environment_tab web console action
    Then the step should succeed
    When I perform the :check_env_tab_for_dc_container web console action with:
      | container_name | dctest-1       |
      | env_var_key    | env11          |
      | env_var_value  | value1update   |
    Then the step should succeed
    When I perform the :check_env_tab_for_dc_container web console action with:
      | container_name | dctest-2 |
      | env_var_key    | env21    |
      | env_var_value  | value21  |
    Then the step should fail
    When I perform the :check_env_tab_for_dc_container web console action with:
      | container_name | dctest-2 |
      | env_var_key    | _TEST    |
      | env_var_value  | 2        |
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id OCP-11406
  Scenario: Change Deployment Stategy from Rolling to Custom on web console
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/rolling.json |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
    When I perform the :goto_edit_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks               |
    Then the step should succeed
    When I perform the :select_dc_strategy_type web console action with:
      | strategy_type | Custom |
    Then the step should succeed
    When I run the :check_dc_custom_strategy_settings web console action
    Then the step should succeed
    When I perform the :click_add_lifecycle_hook web console action with:
      | hook_type | pre |
    Then the step should fail
    When I perform the :set_dc_custom_strategy_settings web console action with:
      | image_name    | aosqe/hello-openshift |
      | cmd_line      | echo "hello"          |
      | env_var_key   | env1                  |
      | env_var_value | value1                |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_dc_strategy_on_dc_page web console action with:
      | dc_strategy | Custom |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain "Hooks"
    When I run the :describe client command with:
      | resource | deploymentConfig |
      | name     | hooks            |
    Then the step should succeed
    And the output should match:
      | Strategy:\s+Custom             |
      | Image:\s+aosqe/hello-openshift |
      | Environment:\s+env1=value1     |
      | Command:\s+echo "hello"        |

  # @author etrott@redhat.com
  # @case_id OCP-12329
  Scenario: Check k8s deployments on Deployments page
    Given the master version >= "3.4"
    Given I create a new project
    When I perform the :goto_deployments_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :check_no_dc_to_show web console action
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc536600/hello-deployment-1.yaml |
    Then the step should succeed
    And I run the :run client command with:
      | name  | testdc                |
      | image | aosqe/hello-openshift |
    Then the step should succeed
    When I run the :get client command with:
      | resource | dc |
    Then the output should contain:
      | testdc |
    When I run the :get client command with:
      | resource | rc |
    Then the output should contain:
      | testdc-1 |
    When I run the :get client command with:
      | resource | deployment |
    Then the output should contain:
      | hello-openshift |
    When I run the :get client command with:
      | resource | replicaset |
    Then the output should contain:
      | hello-openshift |
    When I perform the :check_resource_on_deployment_page web console action with:
      | project_name  | <%= project.name %>       |
      | resource      | dc                        |
      | resource_type | Deployment Configurations |
      | resource_name | testdc                    |
      | last_version  | #1                        |
    Then the step should succeed
    When I perform the :check_deployment_on_deployment_page web console action with:
      | project_name  | <%= project.name %>                                                                  |
      | resource      | deployment                                                                           |
      | resource_type | Deployments                                                                          |
      | resource_name | hello-openshift                                                                      |
      | last_version  | #1                                                                                   |
      | replicas      | <%= deployment("hello-openshift").replicas(user:user) %> replicas                    |
      | strategy_type | <%= deployment("hello-openshift").props[:spec]["strategy"]["type"].sub('U', ' u') %> |
    Then the step should succeed
    When I perform the :click_on_deployment_last_version_on_deployments_page web console action with:
      | resource_name | hello-openshift |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | deployment                                                                                                 |
      | resource_name | hello-openshift                                                                                            |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hello-openshift","image":"yapei/hello-openshift"}]}}}} |
    Then the step should succeed
    When I perform the :check_replicas_less_than web console action with:
      | replicas | <%= deployment("hello-openshift").props[:spec]["strategy"]["rollingUpdate"]["maxUnavailable"] %> |
    Then the step should succeed
    When I perform the :goto_deployments_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_deployment_on_deployment_page web console action with:
      | project_name  | <%= project.name %> |
      | resource      | deployment          |
      | resource_type | Deployments         |
      | resource_name | hello-openshift     |
      | last_version  | #2                  |
      | replicas      | 4 replicas          |
      | strategy_type | Rolling update      |
    Then the step should succeed
    When I perform the :click_on_one_deployment web console action with:
      | k8s_deployments_name | hello-openshift |
    Then the step should succeed
    When I perform the :edit_replicas_on_deployment_page web console action with:
      | replicas | 3 |
    Then the step should succeed
    When I perform the :check_rs_on_one_deployment_page web console action with:
      | rs_name  | hello-openshift |
      | version  | #2              |
      | replicas | 3               |
    Then the step should succeed
    When I perform the :edit_replicas_on_deployment_page web console action with:
      | replicas | 5 |
    Then the step should succeed
    When I perform the :check_rs_on_one_deployment_page web console action with:
      | rs_name  | hello-openshift |
      | version  | #2              |
      | replicas | 5               |
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-11382
  Scenario: AutoScale management for k8s deployment
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc536600/hello-deployment-1.yaml |
    Then the step should succeed
    Given I wait until number of replicas match "4" for deployment "hello-openshift"
    When I perform the :add_label_on_edit_autoscaler_page_for_k8s_deployment web console action with:
      | project_name        | <%= project.name %> |
      | k8s_deployment_name | hello-openshift     |
      | min_pods            | 1                   |
      | max_pods            | 10                  |
      | cpu_req_per         | 50                  |
      | label_key           | autoscaler          |
      | label_value         | deployment          |
    Then the step should succeed
    When I perform the :check_autoscaler_info web console action with:
      | min_pods           | 1  |
      | max_pods           | 10 |
      | cpu_request_target | 50 |
    Then the step should succeed
    When I perform the :check_hpa_labels_on_other_resources_page web console action with:
      | project_name | <%= project.name %> |
      | hpa_name     | hello-openshift     |
      | label_key    | autoscaler          |
      | label_value  | deployment          |
    Then the step should succeed
    When I perform the :update_min_max_cpu_request_for_autoscaler_from_k8s_deployment_page web console action with:
      | project_name        | <%= project.name %> |
      | k8s_deployment_name | hello-openshift     |
      | min_pods            | 1                   |
      | max_pods            | 15                  |
      | cpu_req_per         | 50                  |
    Then the step should succeed
    When I perform the :check_autoscaler_info web console action with:
      | min_pods           | 1  |
      | max_pods           | 15 |
      | cpu_request_target | 50 |
    Then the step should succeed
    When I run the :delete_autoscaler web console action
    Then the step should succeed
    When I perform the :check_autoscaler_info web console action with:
      | min_pods           | 1  |
      | max_pods           | 15 |
      | cpu_request_target | 50 |
    Then the step should fail
    When I run the :click_add_autoscaler_link web console action
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-11653
  Scenario: AutoScale management for k8s ReplicaSets
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/extensions/replicas-set.yaml |
    Then the step should succeed
    When I perform the :add_autoscaler_set_max_pod_from_k8s_rs_page web console action with:
      | project_name         | <%= project.name %> |
      | k8s_replicasets_name | frontend            |
      | max_pods             | 10                  |
    Then the step should succeed
    When I perform the :check_autoscaler_info web console action with:
      | min_pods           | 1  |
      | max_pods           | 10 |
      | cpu_request_target | 80 |
    Then the step should succeed
    When I perform the :update_min_max_cpu_request_for_autoscaler web console action with:
      | project_name         | <%= project.name %> |
      | k8s_replicasets_name | frontend            |
      | min_pods             | 2                   |
      | max_pods             | 10                  |
      | cpu_req_per          | 55                  |
    Then the step should succeed
    When I perform the :check_autoscaler_info web console action with:
      | min_pods           | 2  |
      | max_pods           | 10 |
      | cpu_request_target | 55 |
    Then the step should succeed
    When I run the :delete_autoscaler web console action
    Then the step should succeed
    When I perform the :check_autoscaler_info web console action with:
      | min_pods           | 2  |
      | max_pods           | 10 |
      | cpu_request_target | 55 |
    Then the step should fail
    When I run the :click_add_autoscaler_link web console action
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-12301
  Scenario: Check Events and Environment handling for k8s deployment
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc536600/hello-deployment-1.yaml |
    Then the step should succeed
    When I perform the :goto_deployments_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_on_one_deployment web console action with:
      | k8s_deployments_name | hello-openshift |
    Then the step should succeed
    When I run the :check_event_tab web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource | rs   |
      | o        | json |
    Then the step succeeded
    Given evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :rs_name clipboard
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Scaling replica set                          |
      | message | Scaled up replica set <%= cb.rs_name %> to 4 |
    Then the step should succeed
    When I run the :goto_environment_tab web console action
    Then the step should succeed
    When I perform the :add_env_vars web console action with:
      | env_var_key   | deployment1 |
      | env_var_value | value1      |
    Then the step should succeed
    When I perform the :add_env_vars web console action with:
      | env_var_key   | deployment2 |
      | env_var_value | value2      |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :check_event_tab web console action
    Then the step should succeed
    # https://bugzilla.redhat.com/show_bug.cgi?id=1423461
    When I perform the :check_event_message web console action with:
      | reason  | Scaling replica set                            |
      | message | Scaled down replica set <%= cb.rs_name %> to 0 |
    Then the step should succeed
    When I run the :get client command with:
      | resource | rs   |
      | o        | json |
    Then the step succeeded
    Given evaluation of `@result[:parsed]['items'][1]['metadata']['name']` is stored in the :rs_name_new clipboard
    When I perform the :check_event_message web console action with:
      | reason  | Scaling replica set                              |
      | message | Scaled up replica set <%= cb.rs_name_new %> to 4 |
    Then the step should succeed

    When I perform the :filter_by_keyword_on_events_tab web console action with:
      | keyword | <%= cb.rs_name %> |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Scaling replica set                          |
      | message | Scaled up replica set <%= cb.rs_name %> to 4 |
    Then the step should succeed
    When I perform the :check_event_message_missing web console action with:
      | reason  | Scaling replica set                              |
      | message | Scaled up replica set <%= cb.rs_name_new %> to 4 |
    Then the step should succeed

    When I perform the :filter_by_keyword_on_events_tab web console action with:
      | keyword | <%= cb.rs_name_new %> |
    Then the step should succeed
    When I perform the :check_event_message_missing web console action with:
      | reason  | Scaling replica set                          |
      | message | Scaled up replica set <%= cb.rs_name %> to 4 |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Scaling replica set                              |
      | message | Scaled up replica set <%= cb.rs_name_new %> to 4 |
    Then the step should succeed

    When I perform the :filter_by_keyword_on_events_tab web console action with:
      | keyword | test |
    Then the step should succeed
    When I run the :check_all_events_hidden_by_filter web console action
    Then the step should succeed

    When I run the :goto_environment_tab web console action
    Then the step should succeed

    When I perform the :check_environment_tab web console action with:
      | env_var_key   | deployment1 |
      | env_var_value | value1      |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | deployment2 |
      | env_var_value | value2      |
    Then the step should succeed

    When I perform the :change_env_vars web console action with:
      | env_variable_name | deployment1   |
      | new_env_value     | value1updated |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | deployment1   |
      | env_var_value | value1updated |
    Then the step should succeed

    When I perform the :delete_env_var web console action with:
      | env_var_key | deployment2 |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | deployment2 |
      | env_var_value | value2      |
    Then the step should fail

  # @author etrott@redhat.com
  # @case_id OCP-11844
  Scenario: Check Events and Environment handling for ReplicaSet
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/extensions/replicas-set.yaml |
    Then the step should succeed
    When I perform the :click_to_goto_one_replicaset_page web console action with:
      | project_name         | <%= project.name %> |
      | k8s_replicasets_name | frontend            |
    Then the step should succeed
    When I run the :goto_environment_tab web console action
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | GET_HOSTS_FROM |
      | env_var_value | dns            |
    Then the step should succeed

    When I perform the :add_env_vars web console action with:
      | env_var_key   | replicasets |
      | env_var_value | value1      |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | GET_HOSTS_FROM |
      | env_var_value | dns            |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | replicasets |
      | env_var_value | value1      |
    Then the step should succeed

    When I perform the :change_env_vars web console action with:
      | env_variable_name | replicasets   |
      | new_env_value     | value1updated |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | GET_HOSTS_FROM |
      | env_var_value | dns            |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | replicasets   |
      | env_var_value | value1updated |
    Then the step should succeed

    When I perform the :delete_env_var web console action with:
      | env_var_key | replicasets |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | GET_HOSTS_FROM |
      | env_var_value | dns            |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | replicasets   |
      | env_var_value | value1updated |
    Then the step should fail

    Given I run the steps 2 times:
    """
    When I run the :scale_down_once_on_rs_page web console action
    Then the step should succeed
    """
    When I perform the :check_ready_pods_number_in_table web console action with:
      | pods_number | 1 |
    Then the step should succeed
    When I run the :check_event_tab web console action
    Then the step should succeed
    When I perform the :filter_by_keyword_on_events_tab web console action with:
      | keyword | delete |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Successful delete |
      | message | Deleted pod:      |
    Then the step should succeed

    When I run the :scale_up_once_on_rs_page web console action
    Then the step should succeed
    When I perform the :check_ready_pods_number_in_table web console action with:
      | pods_number | 2 |
    Then the step should succeed
    When I run the :check_event_tab web console action
    Then the step should succeed
    When I perform the :filter_by_keyword_on_events_tab web console action with:
      | keyword | create |
    Then the step should succeed
    When I perform the :check_event_message web console action with:
      | reason  | Successful create |
      | message | Created pod:      |
    Then the step should succeed
