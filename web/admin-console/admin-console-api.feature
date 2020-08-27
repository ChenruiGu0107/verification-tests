Feature: admin console api related

  # @author yapei@redhat.com
  # @case_id OCP-25816
  @admin
  Scenario: Expose console_url metrics in console-operator metric
    Given the master version >= "4.2"
    Given I open admin console in a browser
    And the first user is cluster-admin

    # get sa/prometheus-k8s token
    When I run the :serviceaccounts_get_token admin command with:
      | serviceaccount_name | prometheus-k8s |
      | n | openshift-monitoring |
    Then the step should succeed
    And evaluation of `@result[:stdout]` is stored in the :sa_token clipboard

    # get console route host and operator pod
    And I use the "openshift-console" project
    Given evaluation of `route('console').spec.host` is stored in the :console_route clipboard

    And I use the "openshift-console-operator" project
    Given a pod becomes ready with labels:
      | name=console-operator |
    Then evaluation of `pod.ip` is stored in the :console_operator_pod_id clipboard

    # check metrics exposed
    When I run the :exec admin command with:
      | n                | openshift-console-operator |
      | pod              | <%= pod.name %>            |
      | oc_opts_end      |                            |
      | exec_command     | sh                         |
      | exec_command_arg | -c                         |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://<%= cb.console_operator_pod_id %>:8443/metrics |
    Then the step should succeed
    And the output should match 1 times:
      | ^console_url |
    And the output should match 1 times:
      | ^console_url.*url.*https://<%= cb.console_route %>.*1 |

    When I run the :goto_monitoring_metrics_page web action
    Then the step should succeed
    When I perform the :query_metrics web action with:
      | metrics_name | console_url |
    Then the step should succeed
    When I perform the :check_metrics_query_result web action with:
      | metrics_name | console_url |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-27901
  @admin
  Scenario: Console backend should proxy requests for config maps for dashboard configuration
    Given the master version >= "4.4"

    # grant normal user auto-test-metrics-reader cluster role
    Given admin ensures "auto-test-metrics-reader" cluster_role is deleted after scenario
    Given I obtain test data file "rbac/metrics-reader-cluster-role.yaml"
    When I run the :create admin command with:
      | f | metrics-reader-cluster-role.yaml |
    Then the step should succeed
    Given cluster role "auto-test-metrics-reader" is added to the "first" user

    # normal user with metrics-reader role can view all Dashboards
    Given I open admin console in a browser
    When I perform the :click_secondary_menu web action with:
      | primary_menu   | Monitoring |
      | secondary_menu | Dashboards |
    Then the step should succeed
    When I run the :check_grafana_dashboard_body_loaded web action
    Then the step should succeed
    When I run the :check_dashboard_dropdown_items web action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-23012
  Scenario: Copy login command from console
    Given the master version >= "4.2"
    Given I open admin console in a browser

    When I run the :goto_command_line_tools web action
    Then the step should succeed
    When I run the :browse_to_copy_login_command web action
    Then the step should succeed
    # This step is to store the redirecting url of new window, does not check anything
    And I wait up to 15 seconds for the steps to pass:
    """
    When I perform the :check_page_contains web action in ":url=>oauth" window with:
      | content | |
    Then the step should succeed
    And evaluation of `@result[:url]` is stored in the :oauth_login clipboard
    """
    When I perform the :login_if_need web action in ":url=>oauth" window with:
      | username    | <%= user.auth_name %> |
      | password    | <%= user.password  %> |
      | idp         | <%= env.idp  %>       |
      | console_url | <%= cb.oauth_login %> |
    Then the step should succeed
    When I perform the :display_token web action in ":url=>oauth" window with:
      | button_text | Display |
    Then the step should succeed
    And evaluation of `@result[:text].split('--token=')[1].split()[0]` is stored in the :token clipboard
    And evaluation of `@result[:text].split('--server=')[1].split()[0]` is stored in the :server clipboard

    Given I have a project
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl | -kH | Authorization: Bearer <%= cb.token %> | <%= cb.server %>/apis/user.openshift.io/v1/users/~ |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-20748
  Scenario: Restrict XSS Vulnerability in K8s API proxy
    Given I have a project
    Given I obtain test data file "templates/ui/httpd-example.yaml"
    When I run the :new_app client command with:
      | file | httpd-example.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=httpd-example |
    Given I open admin console in a browser
    When I access the "<%= browser.base_url %>api/kubernetes/api/v1/namespaces/<%= project.name %>/services/httpd-example:8080/proxy/" url in the web browser
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | Welcome to your static httpd application |
    Then the step should succeed