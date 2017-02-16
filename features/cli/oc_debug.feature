Feature: oc debug related scenarios

  # @author xiaocwan@redhat.com
  # @case_id OCP-9854
  Scenario: Debug pod with oc debug
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=dctest-1 |
    When I run the :debug client command with:
      | resource      | dc/dctest   |
    Then the step should succeed
    And the output should match:
      | [Dd]ebugging with pod.*     |
      | [Ww]aiting for pod to start |
      | [Rr]emoving debug pod       |

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
      | keep_annotations |        |
      | o                | yaml   |
    Then the step should succeed
    And the output should match:
      | openshift.io/deployment-config.latest-version:.*1 |
      | openshift.io/deployment-config.name:\\s+hello     |
      | openshift.io/deployment.name:\\s+hello-1          |

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/pod-with-probe.yaml |
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml |
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
      | [Dd]ebugging with pod                 |
      | [Ww]aiting for pod to start           |
      | PATH=                                 |
      | HOSTNAME=                             |
      | [Rr]emoving debug pod                 |
    When I run the :debug client command with:
      | resource       | dc/dctest            |
      | node_name      | invalidnode          |
      | oc_opts_end    | |
      | exec_command   | /bin/env             |
    Then the output should match:
      | [Ee]rror                              |
      | [Uu]nable to create.*dctest-debug.*invalidnode" |
    Given I get project pod as YAML
    And I save the output to file>pod.yaml
    When I run the :debug client command with:
      | f              | pod.yaml             |
      | oc_opts_end    | |
      | exec_command   | /bin/env             |
    Then the step should succeed
    And the output should match:
      | [Dd]ebugging with pod                 |
      | [Ww]aiting for pod to start           |
      | PATH=                                 |
      | HOSTNAME=                             |
      | [Rr]emoving debug pod                 |

  # @author cryan@redhat.com
  # @case_id OCP-10220
  Scenario: oc debug with or without init container for pod
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/testfile-openshift/master/initContainer/init-containers-success.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=hello-pod |
    When I run the :debug background client command with:
      | resource             | pod/hello-pod |
      | keep_init_containers | true          |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod             |
      | name     | hello-pod-debug |
    Then the step should succeed
    And the output should contain:
      | Init Containers: |
      | success          |
      | /bin/true        |
    When I run the :debug background client command with:
      | resource             | pod/hello-pod |
      | keep_init_containers | false         |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod             |
      | name     | hello-pod-debug |
    Then the output should not contain "Init Containers"
