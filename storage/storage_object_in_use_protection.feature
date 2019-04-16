Feature: Storage object in use protection

  # @author lxia@redhat.com
  # @case_id OCP-17288
  Scenario: Recreate pvc when pvc is in pvc-protection state should fail
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod                   |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    And the "pvc-<%= project.name %>" PVC becomes :bound
    When I run the :delete client command with:
      | object_type       | pvc                     |
      | object_name_or_id | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes terminating
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should fail

  # @author lxia@redhat.com
  # @case_id OCP-17568
  Scenario: Scheduling of a pod that uses a PVC that is being deleted should fail
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
      | ["metadata"]["name"]                                         | mypod |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    And the "mypvc" PVC becomes :bound
    When I run the :delete client command with:
      | object_type       | pvc   |
      | object_name_or_id | mypvc |
      | wait              | false |
    Then the step should succeed
    And the "mypvc" PVC becomes terminating
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc  |
      | ["metadata"]["name"]                                         | newpod |
    Then the step should succeed
    And the pod named "newpod" status becomes :pending
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod    |
      | name     | newpod |
    Then the step should succeed
    And the output should contain "being delete"
    """

  # @author lxia@redhat.com
  # @case_id OCP-18548
  @admin
  @destructive
  Scenario: Should be able to delete pvc/pv which is created during PVCProtection is enabled and then disabled
    Given I check feature gate "PVCProtection" with admission "PVCProtection" is enabled
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
      | ["metadata"]["name"]                                         | mypod |
    Then the step should succeed
    And the pod named "mypod" becomes ready

    Given feature gate "PVCProtection" is disabled with admission "PVCProtection" disabled
    Given I ensure "mypod" pod is deleted
    And I ensure "mypvc" pvc is deleted
    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear

