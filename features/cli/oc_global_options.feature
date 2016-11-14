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
      | insecure | true        |
      | config   | new.config  |
    Then the step should succeed
    When I run the :config_view client command with:
      | config   | new.config  |
    Then the step should succeed
    And the output should match "certificate-authority: .*ca.crt"

    When I run the :whoami client command with:
      | insecure | true        |
      | config   | new.config  |
    Then the step should succeed

    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %>         |
      | token    | <%= user.get_bearer_token.token %>  |
      | insecure | true        |
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
      | insecure | true        |
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
      | insecure | true        |
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

    When I run the :policy_add_role_to_user client command with:
      | role           | view        |
      | serviceaccount | default     |
    Then the step should succeed
    # So far, the above steps are preparation steps

    Given a pod becomes ready with labels:
      | deploymentconfig=mydc |
    # Kubernetes resource
    When I execute on the pod:
      | oc  | get | pod | --match-server-version |
    Then the step should fail
    And the output should match "server version.*differs from client version"
    # OpenShift resource
    When I execute on the pod:
      | oc  | get | dc  | --match-server-version |
    Then the step should succeed
