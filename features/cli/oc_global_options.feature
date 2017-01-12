Feature: oc global options (oc options) related scenarios
  # @author xxia@redhat.com
  # @case_id 509019
  Scenario: Use '--loglevel' global option to see the sent API info for any oc command
    Given I have a project
    And I run the :run client command with:
      | name  | mydc |
      | image | <%= project_docker_repo %>openshift/hello-openshift |
    Then the step should succeed

    Given I wait until the status of deployment "mydc" becomes :running
    When I run the :get client command with:
      | resource  | dc    |
      | loglevel  | 0     |
    Then the step should succeed

    When I run the :get client command with:
      | resource  | dc    |
      | loglevel  | 6     |
    Then the step should succeed
    And the output should match:
      | GET https://.+/deploymentconfigs |
      | NAME          |
      | mydc          |
    And the output should not contain:
      | Response Headers  |
      | Response Body     |

    When I run the :get client command with:
      | resource  | dc    |
      | loglevel  | 7     |
    Then the step should succeed
    And the output should match:
      | GET https://.+/deploymentconfigs |
      | Request Headers   |
      | Response Status   |
      | NAME          |
      | mydc          |

    When I run the :get client command with:
      | resource  | dc    |
      | loglevel  | 8     |
    Then the step should succeed
    And the output should match:
      | GET https://.+/deploymentconfigs |
      | Request Headers   |
      | Response Status   |
      | Response Headers  |
      | Response Body     |
      | NAME          |
      | mydc          |

    When I run the :create client command with:
      | f        | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
      | loglevel | 6   |
    Then the step should succeed
    And the output should match:
      | POST https://.+/pods |

    When I run the :get client command with:
      | resource  | dc    |
      | loglevel  | @#    |
    Then the step should fail
    When I run the :get client command with:
      | resource  | dc    |
      | loglevel  | abc   |
    Then the step should fail
    And the output should contain "invalid argument"

  # @author xxia@redhat.com
  # @case_id 509017
  Scenario: Check the empty values for kubeconfig options
    Given I have a project
    And I run the :run client command with:
      | name  | mydc |
      | image | <%= project_docker_repo %>openshift/hello-openshift |
    Then the step should succeed

    Given I wait until the status of deployment "mydc" becomes :running
    When I run the :get client command with:
      | resource  | dc |
      | context   |    |
      | user      |    |
      | cluster   |    |
    Then the step should succeed
    And the output should contain:
      | mydc |

  # @author xxia@redhat.com
  # @case_id 509022
  Scenario: Use invalid values in kubeconfig-related global options -- negative
    Given I have a project
    And I run the :run client command with:
      | name  | mydc |
      | image | <%= project_docker_repo %>openshift/hello-openshift |
    Then the step should succeed

    And I run the :config client command with:
      | subcommand  | view |
    Then the step should succeed

    Given the output is parsed as YAML
    And evaluation of `@result[:parsed]['contexts'][1]` is stored in the :context clipboard
    And I wait until the status of deployment "mydc" becomes :running
    When I run the :get client command with:
      | resource       | dc    |
      | resource_name  | mydc  |
      | user           | <%= cb.context['context']['user'] %>      |
      | cluster        | <%= cb.context['context']['cluster'] %>   |
      | n              | <%= cb.context['context']['namespace'] %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource       | dc    |
      | resource_name  | mydc  |
      | context        | <%= cb.context['name'] %> |
    Then the step should succeed

    When I run the :get client command with:
      | resource       | dc    |
      | cluster        | no-this-cluster |
    Then the step should fail
    When I run the :get client command with:
      | resource       | dc    |
      | user           | no-this-user    |
    Then the step should fail
    And the output should match "[Ee]rror"
    When I run the :get client command with:
      | resource       | dc    |
      | context        | no-this-context |
    Then the step should fail

  # @author xxia@redhat.com
  # @case_id 509018
  Scenario: Check the secure/insecure connection option for oc command - negative
    Given I have a project
    # Get master ca.crt
    When I run the :run client command with:
      | name      | mypod         |
      | image     | <%= project_docker_repo %>openshift/origin-base        |
      | generator | run-pod/v1    |
      | command   | true          |
      | cmd       | sleep         |
      | cmd       | 3600          |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    # ca.crt (https://docs.openshift.org/latest/dev_guide/service_accounts.html#using-a-service-accounts-credentials-inside-a-container)
    When I execute on the pod:
      | cat  | /var/run/secrets/kubernetes.io/serviceaccount/ca.crt |
    Then the step should succeed
    And I save the output to file> ca.crt

    Given I find a bearer token of the default service account
    And I switch to the default service account
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %>         |
      | token    | <%= user.get_bearer_token.token %>  |
      | ca       | ca.crt      |
      | skip_tls_verify | true |
      | config   | new.config  |
    Then the step should succeed
    When I run the :config_view client command with:
      | config   | new.config  |
    Then the step should succeed
    And the output should match "certificate-authority: .*ca.crt"

    When I run the :whoami client command with:
      | skip_tls_verify | true |
      | config   | new.config  |
    Then the step should succeed

    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %>         |
      | token    | <%= user.get_bearer_token.token %>  |
      | skip_tls_verify | true |
      | config   | 2.config    |
    Then the step should succeed

    When I run the :whoami client command with:
      | ca       | ca.crt      |
      | config   | 2.config    |
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id 509020
  Scenario: Use global options to choose kubeconfig for any oc commands
    Given I have a project
    When I run the :create client command with:
      | f        | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed

    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %>         |
      | token    | <%= user.get_bearer_token.token %>  |
      | skip_tls_verify | true |
      | config   | new.config  |
    Then the step should succeed

    When I run the :config client command with:
      | subcommand  | view        |
      | config      | new.config  |
    Then the step should succeed
    Given the output is parsed as YAML
    # Cache the context as 'previous' context
    And evaluation of `@result[:parsed]['contexts'].find { |c| c['name'] == @result[:parsed]['current-context'] }` is stored in the :prev_c clipboard

    Given I switch to the second user
    And I create a new project
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %>         |
      | token    | <%= user.get_bearer_token.token %>  |
      | skip_tls_verify | true |
      | config   | new.config  |
    Then the step should succeed
    # The current context is replaced, i.e., is not 'previous' context any more

    When I run the :get client command with:
      | resource | pod/hello-openshift                      |
      | user     | <%= cb.prev_c['context']['user'] %>      |
      | cluster  | <%= cb.prev_c['context']['cluster'] %>   |
      | n        | <%= cb.prev_c['context']['namespace'] %> |
      | config   | new.config  |
    Then the step should succeed

    # Without -n
    When I run the :get client command with:
      | resource | pod/hello-openshift                      |
      | user     | <%= cb.prev_c['context']['user'] %>      |
      | cluster  | <%= cb.prev_c['context']['cluster'] %>   |
      | config   | new.config  |
    Then the step should fail
    And the output should contain "cannot get pods in project "<%= project.name %>""

    # --context
    When I run the :get client command with:
      | resource | pod/hello-openshift      |
      | context  | <%= cb.prev_c['name'] %> |
      | config   | new.config  |
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id 509016
  Scenario: Check server version to match client version
    Given I have a project

    # The following steps are workaround that can provide client oc with different version from server.
    # "different" is ensured, because in regular test run, server is ose, while this workaround's client oc is origin oc.
    When I run the :run client command with:
      | name      | mydc   |
      | image     | <%= project_docker_repo %>openshift/origin  |
      | env       | KUBECONFIG=/tmp/cfg  |
      | dry_run   |        |
      | -o        | yaml   |
      | command   | true   |
      | cmd       | sleep  |
      | cmd       | 3600   |
    Then the step should succeed
    And I save the output to file> dc.yaml

    # The following oc set volume is to make sure the openshift/origin image pod
    # can be running in Online test due to Online limitation (https://bugzilla.redhat.com/show_bug.cgi?id=1336318#c1)
    When I run the :set_volume client command with:
      | f         | dc.yaml   |
      | action    | --add     |
      | mount-path| /var/lib/origin |
      | o         | yaml      |
    Then the step should succeed
    And I save the output to file> dc_volume.yaml

    When I run the :create client command with:
      | f         | dc_volume.yaml   |
    Then the step should succeed
    # So far, the above steps are just for creating a pod.
    # That pod is for containing old oc for testing "--match-server-version"

    When I run the :config_view client command
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :cfg clipboard

    Given a pod becomes ready with labels:
      | deploymentconfig=mydc |
    # Write current kube config into the file specified in above env var KUBECONFIG
    # This KUBECONFIG file is prepared for below CLI execution
    When I execute on the pod:
      | sh | -c | echo '<%= cb.cfg %>' > /tmp/cfg |
    Then the step should succeed

    # Get oc that has different version from server side
    When I execute on the pod:
      | wget | https://github.com/openshift/origin/releases/download/v1.0.6/openshift-origin-v1.0.6-2695cdc-linux-amd64.tar.gz | -O | /tmp/oc_old.tgz |
    Then the step should succeed
    When I execute on the pod:
      | mkdir  | /tmp/oc_old |
    Then the step should succeed
    When I execute on the pod:
      | tar  | xzf | /tmp/oc_old.tgz | -C | /tmp/oc_old |
    Then the step should succeed
    # So far all above steps are just workaound for preparing a place old oc can be run

    # Kubernetes resource
    When I execute on the pod:
      | /tmp/oc_old/oc  | get | pod | --match-server-version |
    Then the step should fail
    And the output should match "server version.*differs from client version"
    # OpenShift resource
    When I execute on the pod:
      | /tmp/oc_old/oc  | get | dc  | --match-server-version |
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id 536512
  Scenario: Check the timeout for API request within oc/oadm command
    Given I have a project
    # Prepare a DC for below test
    When I run the :run client command with:
      | name  | mydc       |
      | image | <%= project_docker_repo %>aosqe/hello-openshift |
    Then the step should succeed

    When I run the :create client command with:
      | f                | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
      | request-timeout  | 1ms                                                                                               |
    Then the step should fail
    And the output should match "request canceled.*imeout"

    Given a pod becomes ready with labels:
      | deployment=mydc-1 |
    When I run the :scale client command with:
      | resource         | dc    |
      | name             | mydc  |
      | replicas         | 2     |
      | request-timeout  | 1ms   |
    Then the step should fail
    And the output should match "request canceled.*imeout"

    When I run the :oadm_add_role_to_user client command with:
      | role_name        | view               |
      | user_name        | <%= user.name %>   |
      | request-timeout  | 1ms                |
    Then the step should fail
    And the output should match "request canceled.*imeout"

    When I run the :port_forward client command with:
      | request-timeout  | 60s                |
      | pod              | <%= pod.name %>    |
      | port_spec        | :8080              |
      | _timeout         | 70                 |
    # Choose _timeout > 60s, which means the cmd does not timeout within 60s
    Then the step should have timed out

