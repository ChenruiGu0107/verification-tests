Feature: oc global options (oc options) related scenarios
  # @author xxia@redhat.com
  # @case_id 509019
  Scenario: Use '--v' global option to see the sent API info for any oc command
    Given I have a project
    And I run the :run client command with:
      | name  | mydc |
      | image | <%= project_docker_repo %>openshift/hello-openshift |
    Then the step should succeed

    Given I wait until the status of deployment "mydc" becomes :running
    When I run the :get client command with:
      | resource  | dc    |
      | v         | 0     |
    Then the step should succeed

    When I run the :get client command with:
      | resource  | dc    |
      | v         | 6     |
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
      | v         | 7     |
    Then the step should succeed
    And the output should match:
      | GET https://.+/deploymentconfigs |
      | Request Headers   |
      | Response Status   |
      | NAME          |
      | mydc          |

    When I run the :get client command with:
      | resource  | dc    |
      | v         | 8     |
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
      | f  | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
      | v  | 6     |
    Then the step should succeed
    And the output should match:
      | POST https://.+/pods |

    When I run the :get client command with:
      | resource  | dc    |
      | v         | @#    |
    Then the step should fail
    When I run the :get client command with:
      | resource  | dc    |
      | v         | abc   |
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
    And evaluation of `""` is stored in the :empty_value clipboard
    When I run the :get client command with:
      | resource  | dc                     |
    # Simply using | context |  |, or | context | "" | does not work
      | context   | <%= cb.empty_value %>  |
      | user      | <%= cb.empty_value %>  |
      | cluster   | <%= cb.empty_value %>  |
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
    And the output should contain ""system:anonymous" cannot list"
    When I run the :get client command with:
      | resource       | dc    |
      | context        | no-this-context |
    Then the step should fail
