Feature: pvc protection specific scenarios
  # @author lxia@redhat.com
  # @case_id OCP-17253
  Scenario: Delete pvc which is not in active use by pod should be deleted immediately
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    And the expression should be true> pvc.finalizers(user: user).include? "kubernetes.io/pvc-protection"
    Given I ensure "pvc-<%= project.name %>" pvc is deleted
