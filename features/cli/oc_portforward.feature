Feature: oc_portforward.feature

  # @author cryan@redhat.com
  # @case_id 472860
  Scenario: Forwarding a pod that isn't running
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod-bad.json |
    When I run the :get client command with:
      | resource | pod |
    Then the output should contain "Pending"
    When I run the :port_forward client command with:
      | pod | hello-openshift |
      | local_port | :8080 |
    Then the step should fail
    And the output should contain "Unable to execute command because pod is not running. Current status=Pending"
