Feature: Health related feature on web console
  # @author xxia@redhat.com
  # @case_id OCP-12423
  Scenario Outline: Check, set and remove readiness and liveness probe for dc and standalone rc in web
    # One case, 2 scenarios: dc and standalone rc
    Given I have a project
    When I run the :create client command with:
      | f    |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/<kind>-with-two-containers.yaml |
    Then the step should succeed

    Given a pod becomes ready with labels:
      | run |
    When I perform the :<action_name> web console action with:
      | project_name   | <%= project.name %> |
      | <kind>_name    | <resource_name>     |
    Then the step should succeed
    When I run the :<switch_configuration_tab> web console action
    Then the step should succeed
    When I run the :check_health_alert web console action
    Then the step should succeed

    When I run the :goto_health_check_page web console action
    Then the step should succeed
    # Add readiness probe of http type in container #1
    When I perform the :add_http_probe web console action with:
      | container_name | <cont_1>    |
      | health_kind    | readiness   |
      | probe_type     | HTTP        |
      | path           | /healthz    |
      | port           | 8080        |
    Then the step should succeed
    # Add readiness probe of command type in container #2
    When I perform the :add_command_probe web console action with:
      | container_name | <cont_2>          |
      | health_kind    | readiness         |
      | probe_type     | Container Command |
      | command_arg    | ls                |
    Then the step should succeed
    When I perform the :add_another_arg_of_command_probe web console action with:
      | container_name | <cont_2>          |
      | health_kind    | readiness         |
      | command_arg    | /etc              |
    Then the step should succeed

    # Add liveness probe of socket type in container #1
    When I perform the :add_socket_probe web console action with:
      | container_name | <cont_1>    |
      | health_kind    | liveness    |
      | probe_type     | TCP Socket  |
      | port           | 8080        |
    Then the step should succeed

    When I run the :click_save_button web console action
    Then the step should succeed

    # Check above save takes effect via CLI
    # Need wait because auto step interval is too fast
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | <kind>             |
      | resource_name | <resource_name>    |
      | o             | yaml               |
    Then the step should succeed
    And the output should contain "nessProbe"
    """

    Then the expression should be true> h = @result[:parsed]['spec']['template']['spec']['containers'][0]; h1 = h['readinessProbe']['httpGet']; h2 = h['livenessProbe']; '/healthz' == h1['path'] and 8080 == h1['port'] and 8080 == h2['tcpSocket']['port']
    And the expression should be true> ['ls', '/etc'] == @result[:parsed]['spec']['template']['spec']['containers'][1]['readinessProbe']['exec']['command']

    # Was on DC/RC page after above Save
    When I run the :<switch_configuration_tab> web console action
    Then the step should succeed
    When I perform the :check_health_probe web console action with:
      | container_name   | <cont_1>                                   |
      | readiness_probe  | Readiness Probe: GET /healthz on port 8080 |
      | liveness_probe   | Liveness Probe: Open socket on port 8080   |
    Then the step should succeed
    When I perform the :check_health_probe web console action with:
      | container_name   | <cont_2>                                   |
      | readiness_probe  | Readiness Probe: ls /etc                   |
      | liveness_probe   |                                            |
    Then the step should succeed

    # Below remove probes.
    # Before do remove operation, wait some time so that the DC/RC update is done.
    # Otherwise next Save operation may FAIL with error in page like 'the object has
    # been modified; please apply your changes to the latest version and try again'.
    # Use step '60 seconds have passed' because no better way
    Given 60 seconds have passed
    When I run the :goto_health_check_page web console action
    Then the step should succeed
    When I perform the :remove_probe web console action with:
      | container_name | <cont_1>    |
      | health_kind    | readiness   |
    Then the step should succeed
    When I perform the :remove_probe web console action with:
      | container_name | <cont_2>    |
      | health_kind    | readiness   |
    Then the step should succeed
    When I perform the :remove_probe web console action with:
      | container_name | <cont_1>    |
      | health_kind    | liveness    |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed

    # Check above save takes effect via CLI
    # Need wait because auto step interval is too fast
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | <kind>             |
      | resource_name | <resource_name>    |
      | o             | yaml               |
    Then the step should succeed
    And the output should not contain "nessProbe"
    """

    Examples:
      | kind | resource_name | cont_1           | cont_2                 | action_name                 | switch_configuration_tab   |
      | dc   | dctest        | dctest-1         | dctest-2               | goto_one_dc_page            | switch_dc_health_check_tab |
      | rc   | rctest        | hello-openshift  | hello-openshift-fedora | goto_one_standalone_rc_page | null                       |

  # @author yapei@redhat.com
  # @case_id OCP-11993
  Scenario: Health Check for k8s deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc536593/deployment-with-two-containers.yaml |
    Then the step should succeed
    Given 4 pods become ready with labels:
      | app=hello-openshift |
    When I perform the :goto_k8s_deployment_health_check_page web console action with:
      | project_name        | <%= project.name %> |
      | k8s_deployment_name | hello-openshift     |
    Then the step should succeed
    # Add 'TCP Socket' type Readiness Probe for container 'hello-openshift'
    When I perform the :add_socket_probe_and_define_delay_and_timeout web console action with:
      | container_name        | hello-openshift |
      | health_kind           | readiness       |
      | probe_type            | TCP Socket      |
      | port                  | 80              |
      | initial_delay_seconds | 5               |
      | timeout               | 10              |
    Then the step should succeed
    # Add 'Container Command' type Liveness Probe for container 'hello-openshift'
    When I perform the :add_command_probe web console action with:
      | container_name | hello-openshift   |
      | health_kind    | liveness          |
      | probe_type     | Container Command |
      | command_arg    | cd /etc           |
    Then the step should succeed
    When I perform the :add_another_arg_of_command_probe web console action with:
      | container_name | hello-openshift   |
      | health_kind    | liveness          |
      | command_arg    | ls /etc/hosts     |
    Then the step should succeed
    # Add 'HTTP' Readiness Probe for container 'hello-openshift-fedora'
    When I perform the :add_http_probe web console action with:
      | container_name | hello-openshift-fedora |
      | health_kind    | readiness              |
      | probe_type     | HTTP                   |
      | path           | /health                |
      | port           | 8080                   |
    Then the step should succeed
    # Add 'Container Command' Liveness Probe for container 'hello-openshift-fedora'
    When I perform the :add_command_probe web console action with:
      | container_name | hello-openshift-fedora |
      | health_kind    | liveness               |
      | probe_type     | Container Command      |
      | command_arg    | ls                     |
    Then the step should succeed
    When I perform the :add_another_arg_of_command_probe web console action with:
      | container_name | hello-openshift-fedora |
      | health_kind    | liveness               |
      | command_arg    | -l                     |
    Then the step should succeed
    When I perform the :add_another_arg_of_command_probe web console action with:
      | container_name | hello-openshift-fedora |
      | health_kind    | liveness               |
      | command_arg    | /usr/bin/sh            |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # check Readiness and Liveness Probe on k8s deployment page
    When I run the :goto_check_k8s_deployment_health_probe web console action
    Then the step should succeed
    When I perform the :check_health_probe web console action with:
      | container_name   | hello-openshift                                               |
      | readiness_probe  | Readiness Probe: Open socket on port 80 5s delay, 10s timeout |
      | liveness_probe   | Liveness Probe: cd /etc ls /etc/hosts                         |
    Then the step should succeed
    When I perform the :check_health_probe web console action with:
      | container_name   | hello-openshift-fedora                         |
      | readiness_probe  | Readiness Probe: GET /health on port 8080      |
      | liveness_probe   | Liveness Probe: ls -l /usr/bin/sh              |
    Then the step should succeed
    When I perform the :goto_k8s_deployment_health_check_page web console action with:
      | project_name        | <%= project.name %> |
      | k8s_deployment_name | hello-openshift     |
    Then the step should succeed
    When I perform the :remove_probe web console action with:
      | container_name | hello-openshift |
      | health_kind    | readiness       |
    Then the step should succeed
    When I perform the :remove_probe web console action with:
      | container_name | hello-openshift-fedora |
      | health_kind    | liveness               |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # Check info after remove
    When I run the :goto_check_k8s_deployment_health_probe web console action
    Then the step should succeed
    When I perform the :check_readiness_probe web console action with:
      | container_name   | hello-openshift                                               |
      | readiness_probe  | Readiness Probe: Open socket on port 80 5s delay, 10s timeout |
    Then the step should fail
    When I perform the :check_liveness_probe web console action with:
      | container_name   | hello-openshift-fedora            |
      | liveness_probe   | Liveness Probe: ls -l /usr/bin/sh |
    Then the step should fail

  # @author yapei@redhat.com
  # @case_id OCP-12100
  Scenario: Health Check for k8s replicaset
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/replicaSet/tc536594/replicaset-with-two-containers.yaml" replacing paths:
      | ["spec"]["replicas"] | 2 |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | app=guestbook |
    When I perform the :goto_k8s_replicaset_health_check_page web console action with:
      | project_name         | <%= project.name %> |
      | k8s_replicaset_name  | frontend            |
    Then the step should succeed
    # Add 'Container Command' type Liveness Probe for container 'hello-openshift'
    When I perform the :add_command_probe web console action with:
      | container_name | hello-openshift   |
      | health_kind    | liveness          |
      | probe_type     | Container Command |
      | command_arg    | cd /etc           |
    Then the step should succeed
    When I perform the :add_another_arg_of_command_probe web console action with:
      | container_name | hello-openshift   |
      | health_kind    | liveness          |
      | command_arg    | ls /etc/hosts     |
    Then the step should succeed
    # Add 'HTTP' Readiness Probe for container 'hello-openshift-fedora'
    When I perform the :add_http_probe web console action with:
      | container_name | hello-openshift-fedora |
      | health_kind    | readiness              |
      | probe_type     | HTTP                   |
      | path           | /health                |
      | port           | 8080                   |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # check Readiness and Liveness Probe on k8s replicaset page
    When I perform the :check_liveness_probe web console action with:
      | container_name   | hello-openshift                       |
      | liveness_probe   | Liveness Probe: cd /etc ls /etc/hosts |
    Then the step should succeed
    When I perform the :check_readiness_probe web console action with:
      | container_name   | hello-openshift-fedora                    |
      | readiness_probe  | Readiness Probe: GET /health on port 8080 |
    Then the step should succeed
    When I perform the :goto_k8s_replicaset_health_check_page web console action with:
      | project_name        | <%= project.name %> |
      | k8s_replicaset_name | frontend            |
    Then the step should succeed
    When I perform the :remove_probe web console action with:
      | container_name | hello-openshift |
      | health_kind    | liveness        |
    Then the step should succeed
    When I perform the :remove_probe web console action with:
      | container_name | hello-openshift-fedora |
      | health_kind    | readiness              |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # Check info after remove
    When I perform the :check_liveness_probe web console action with:
      | container_name   | hello-openshift                       |
      | readiness_probe  | Liveness Probe: cd /etc ls /etc/hosts |
    Then the step should fail
    When I perform the :check_readiness_probe web console action with:
      | container_name   | hello-openshift-fedora                    |
      | liveness_probe   | Readiness Probe: GET /health on port 8080 |
    Then the step should fail
