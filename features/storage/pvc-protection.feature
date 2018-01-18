Feature: pvc protection specific scenarios
  # @author lxia@redhat.com
  # @case_id OCP-17253
  Scenario: Delete pvc which is not in active use by pod should be deleted immediately
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    And the expression should be true> pvc.finalizers(user: user)&.include? "kubernetes.io/pvc-protection"
    Given I ensure "pvc-<%= project.name %>" pvc is deleted

  # @author lxia@redhat.com
  # @case_id OCP-17254
  Scenario: Delete pvc which is in active use by pod should postpone deletion
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod                   |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    When I run the :delete client command with:
      | object_type       | pvc                     |
      | object_name_or_id | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes terminating
    When I execute on the pod:
      | touch | /mnt/ocp_pv/testfile |
    Then the step should succeed
    When I get project pvc named "pvc-<%= project.name %>"
    Then the step should succeed
    And the output should contain "Terminating"
    When I run the :describe client command with:
      | resource | pvc                     |
      | name     | pvc-<%= project.name %> |
    Then the step should succeed
    And the output should match "Terminating\s+\(since"
    Given I ensure "mypod" pod is deleted
    And I wait for the resource "pvc" named "pvc-<%= project.name %>" to disappear within 30 seconds

  # @author lxia@redhat.com
  # @case_id OCP-17288
  Scenario: Recreate pvc when pvc is in pvc-protection state should fail
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod                   |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    When I run the :delete client command with:
      | object_type       | pvc                     |
      | object_name_or_id | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes terminating
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should fail

  # @author lxia@redhat.com
  # @case_id OCP-17568
  Scenario: Scheduling of a pod that uses a PVC that is being deleted should fail
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod                   |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    When I run the :delete client command with:
      | object_type       | pvc                     |
      | object_name_or_id | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes terminating
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | newpod                  |
    Then the step should succeed
    And the pod named "newpod" status becomes :pending
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod    |
      | name     | newpod |
    Then the step should succeed
    And the output should contain "pvc-<%= project.name %> is being deleted"
    """
