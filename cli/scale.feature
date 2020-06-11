Feature: scaling related scenarios
  # @author yinzhou@redhat.com
  # @case_id OCP-9908
  Scenario: Only scale the dc can scale the active deployment
    Given I have a project
    Given I obtain test data file "deployment/testhook.json"
    When I run the :create client command with:
      | f | testhook.json |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    # Workaround: the below steps make a failed deployment instead of using cancel
    Given I successfully patch resource "dc/hooks" with:
      | {"spec":{"strategy":{"recreateParams":{"pre":{ "execNewPod": { "command": [ "/bin/false" ]}, "failurePolicy": "Abort" }}}}} |
    When I run the :rollout_latest client command with:
      | resource | dc/hooks |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :failed
    Then I run the :scale client command with:
      | resource | ReplicationController |
      | name     | hooks-1               |
      | replicas | 2                     |
    Given I wait until number of replicas match "1" for replicationController "hooks-1"
    Then I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | hooks            |
      | replicas | 1                |
    Given I wait until number of replicas match "1" for replicationController "hooks-1"

  # @author yinzhou@redhat.com
  # @case_id OCP-9862
  @admin
  Scenario: [openshift-sme]When rolling deployments the pod should shutdown gracefully
    Given I have a project
    Given I obtain test data file "deployment/deployment-with-shutdown-gracefully.json"
    When I run the :create client command with:
      | f | deployment-with-shutdown-gracefully.json |
    Then the step should succeed
    Given I wait until the status of deployment "nettest" becomes :complete
    And a pod becomes ready with labels:
      | app=nettest |
    Then evaluation of `pod.name` is stored in the :pod1_name clipboard
    Then evaluation of `pod.ip` is stored in the :pod1_ip clipboard
    When I run the :rollout_latest client command with:
      | resource | dc/nettest |
    Then the step should succeed
    Given I wait until the status of deployment "nettest" becomes :complete
    Given the pod named "<%= cb.pod1_name %>" status becomes :running
    And I select a random node's host
    When I run commands on the host:
      | curl <%= cb.pod1_ip %>:8080/status -vv|
    Then the step should succeed
    And the expression should be true> @result[:response].include?("200 OK")
