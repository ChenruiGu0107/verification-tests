Feature: pvc testing scenarios
  Scenario: fetch pvc detail when got wrong status
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]       | nfsc-<%= project.name %> |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes :bound
