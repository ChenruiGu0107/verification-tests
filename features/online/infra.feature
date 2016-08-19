Feature: ONLY ONLINE Infra related scripts in this file

  # @author etrott@redhat.com
  # @case_id 532324
  Scenario: User cannot deploy a pod to an infra node
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc532324/pod_nodeSelector_infra.yaml |
    Then the step should fail
    And the output should contain:
      | pod node label selector conflicts with its project node label selector |
