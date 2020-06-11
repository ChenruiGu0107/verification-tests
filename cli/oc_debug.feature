Feature: oc debug related scenarios

  # @author xiaocwan@redhat.com
  # @case_id OCP-9854
  Scenario: Debug pod with oc debug
    Given I have a project
    Given I obtain test data file "deployment/dc-with-two-containers.yaml"
    When I run the :create client command with:
      | f | dc-with-two-containers.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=dctest-1 |
    When I run the :debug client command with:
      | resource      | dc/dctest   |
      | _timeout      | 10          |
    Then the output should match:
      | (Waiting for\|Starting) pod |
      | [Rr]emoving debug pod       |
    When I run the :debug client command with:
      | t                 |             |
      | resource          | dc/dctest   |
      | oc_opts_end       |             |
      | exec_command      | sleep       |
      | exec_command_arg  | 5           |
    Then the output should match "(Waiting for|Starting) pod"
    And the output should not match:
      | [Pp]anic  |

  # @author xiaocwan@redhat.com
  # @case_id OCP-9855
  Scenario: Debug the resource with keeping the original pod info
    Given I have a project
    When I run the :run client command with:
      | name      | hello                            |
      | image     | openshift/hello-openshift:latest |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=hello-1 |
    When I run the :debug client command with:
      | resource         | dc/hello |
      | keep_annotations |          |
      | o                | yaml     |
    Then the step should succeed
    And the output should match:
      | openshift.io/deployment-config.latest-version:.*1 |
      | openshift.io/deployment-config.name:\\s+hello     |
      | openshift.io/deployment.name:\\s+hello-1          |

    Given I obtain test data file "pods/pod-with-probe.yaml"
    When I run the :create client command with:
      | f | pod-with-probe.yaml |
    Then the step should succeed
    When the pod named "hello-openshift" status becomes :running
    And I run the :debug client command with:
      | resource       | pod/hello-openshift |
      | keep_liveness  | |
      | keep_readiness | |
      | o              | yaml               |
    Then the step should succeed
    And the output should match:
      | livenessProbe:\\s+failureThreshold: |

  # @author xiaocwan@redhat.com
  # @case_id OCP-9857
  Scenario: Use oc debug with misc flags
    Given I have a project
    Given I obtain test data file "deployment/dc-with-two-containers.yaml"
    When I run the :create client command with:
      | f | dc-with-two-containers.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=dctest-1 |
    When I run the :debug client command with:
      | resource       | dc/dctest       |
      | c              | dctest-2        |
      | one_container  | true            |
      | o              | json            |
    Then the step should succeed
    And the output should match:
      |  "name":\\s+"dctest-2" |
    And the output should not match:
      |  "name":\\s+"dctest-1" |
    When I run the :debug client command with:
      | resource       | dc/dctest            |
      | node_name      | <%= pod.node_name(user: user) %>|
      | oc_opts_end    | |
      | exec_command   | /bin/env             |
    Then the output should match:
      | PATH=                                 |
      | HOSTNAME=                             |
      | [Rr]emoving debug pod                 |
    When I run the :debug client command with:
      | resource       | dc/dctest            |
      | node_name      | invalidnode          |
      | oc_opts_end    | |
      | exec_command   | /bin/env             |
    Then the output should match:
      | [Ee]rror                                  |
      | [Ii]nvalid.*[Nn]ode\|unable.*create.*pod  |
    Given I get project pod as YAML
    And I save the output to file> pod.yaml
    When I run the :debug client command with:
      | f              | pod.yaml             |
      | oc_opts_end    | |
      | exec_command   | /bin/env             |
    Then the step should succeed
    And the output should match:
      | (Waiting for\|Starting) pod |
      | [Rr]emoving debug pod       |

  # @author cryan@redhat.com
  # @case_id OCP-10220
  Scenario: oc debug with or without init container for pod
    Given I log the message> Script uses initContainer.yaml in which spec.initContainers is only supported since 3.6
    And I log the message> Because case is non-critical importance, no scripts for less than 3.6
    And the master version >= "3.6"
    Given I have a project
    Given I obtain test data file "pods/initContainers/initContainer.yaml"
    When I run the :create client command with:
      | f | initContainer.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=hello-pod |
    When I run the :debug background client command with:
      | resource             | pod/hello-pod |
      | keep_init_containers | true          |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod             |
      | name     | hello-pod-debug |
    Then the step should succeed
    And the output should contain:
      | Init Containers: |
      | Command:         |
      | /bin/sh          |
      | -c               |
      | sleep 30         |
    """
    Given I ensure "hello-pod-debug" pod is deleted
    When I run the :debug background client command with:
      | resource             | pod/hello-pod |
      | keep_init_containers | false         |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod             |
      | name     | hello-pod-debug |
    Then the output should not contain "Init Containers"
    """
