Feature: oc idle
  # @author chezhang@redhat.com
  # @case_id 533688
  Scenario: CLI - Idle all the service in the same project
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/rc/idle-rc-1.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/rc/idle-rc-2.yaml |
    Then the step should succeed
    Given I wait until replicationController "hello-pod" is ready
    And I wait until number of replicas match "2" for replicationController "hello-pod"
    Given 2 pods become ready with labels:
      | name=hello-pod  |
    Given I wait until replicationController "hello-idle" is ready
    And I wait until number of replicas match "2" for replicationController "hello-idle"
    Given 2 pods become ready with labels:
      | name=hello-idle |
    When I run the :idle client command with:
      | all | true      |
    Then the step should succeed
    And the output should match:
      | Idled ReplicationController.*hello-idle |
      | Idled ReplicationController.*hello-pod  |
    And I wait until number of replicas match "0" for replicationController "hello-pod"
    And I wait until number of replicas match "0" for replicationController "hello-idle"
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | hello-idle.*none |
      | hello-svc.*none  |
    When I get project rc named "hello-pod" as YAML
    Then the output should match:
      | idling.*openshift.io/idled-at  |
    When I get project rc named "hello-idle" as YAML
    Then the output should match:
      | idling.*openshift.io/idled-at  |

  # @author chezhang@redhat.com
  # @case_id 533690
  Scenario: CLI - Idle service by label
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/rc/idle-rc-2.yaml |
    Then the step should succeed
    Given I wait until replicationController "hello-pod" is ready
    And I wait until number of replicas match "2" for replicationController "hello-pod"
    Given 2 pods become ready with labels:
      | name=hello-pod |
    When I run the :label client command with:
      | resource | svc/hello-svc |
      | key_val  | idle=true     |
    Then the step should succeed
    When I run the :idle client command with:
      | l | idle=false |
    Then the step should succeed
    And I wait until number of replicas match "2" for replicationController "hello-pod"
    When I run the :idle client command with:
      | l | idle=true  |
    Then the step should succeed
    And the output should match:
      | Idled ReplicationController.*hello-pod  |
    And I wait until number of replicas match "0" for replicationController "hello-pod"
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | hello-svc.*none |
    When I get project rc named "hello-pod" as YAML
    Then the output should match:
      | idling.*openshift.io/idled-at |

  # @author chezhang@redhat.com
  # @case_id 533691
  Scenario: CLI - Idle service from file
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/rc/idle-rc-2.yaml |
    Then the step should succeed
    Given I wait until replicationController "hello-pod" is ready
    And I wait until number of replicas match "2" for replicationController "hello-pod"
    Given 2 pods become ready with labels:
      | name=hello-pod |
    Given a "idle1.txt" file is created with the following lines:
    """
    hello-svc
    """
    Given a "idle2.txt" file is created with the following lines:
    """
    noexist-svc
    """
    When I run the :idle client command with:
      | resource-names-file | idle1.txt |
    Then the step should succeed
    And the output should match:
      | Idled ReplicationController.*hello-pod |
    And I wait until number of replicas match "0" for replicationController "hello-pod"
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | hello-svc.*none |
    When I get project rc named "hello-pod" as YAML
    Then the output should match:
      | idling.*openshift.io/idled-at   |
    When I run the :idle client command with:
      | resource-names-file | idle2.txt |
    Then the step should fail
    And the output should match:
      | no valid scalable resources found to idle: endpoints "noexist-svc" not found |

  # @author chezhang@redhat.com
  # @case_id 533692
  Scenario: CLI - Idle service with dry-run
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/rc/idle-rc-2.yaml |
    Then the step should succeed
    Given I wait until replicationController "hello-pod" is ready
    And I wait until number of replicas match "2" for replicationController "hello-pod"
    Given 2 pods become ready with labels:
      | name=hello-pod |
    When I run the :idle client command with:
      | svc_name | hello-svc |
      | dry-run  | true      |
    Then the step should succeed
    And the output should match:
      | Idled ReplicationController.*hello-pod |
    And I wait until number of replicas match "2" for replicationController "hello-pod"
    And 2 pods become ready with labels:
      | name=hello-pod  |
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should not match:
      | hello-svc.*none |
    When I get project rc named "hello-pod" as YAML
    Then the output should not match:
      | idling.*openshift.io/idled-at |
