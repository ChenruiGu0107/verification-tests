Feature: Regression testing cases

  # @author jhou@redhat.com
  # @case_id OCP-10050
  @admin
  @destructive
  Scenario: Delete PVC while pod is running
    Given I have a project
    And I have a NFS service in the project

    Given I obtain test data file "storage/nfs/auto/pv-template.json"
    Given admin creates a PV from "pv-template.json" where:
      | ["spec"]["nfs"]["server"]                 | <%= service("nfs-service").ip %> |
      | ["spec"]["accessModes"][0]                | ReadOnlyMany                     |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                           |
      | ["metadata"]["name"]                      | nfs-<%= project.name %>          |
    Given I obtain test data file "storage/nfs/auto/pvc-template.json"
    When I create a manual pvc from "pvc-template.json" replacing paths:
      | ["metadata"]["name"]       | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]     | nfs-<%= project.name %>  |
      | ["spec"]["accessModes"][0] | ReadOnlyMany             |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    Given I obtain test data file "storage/nfs/auto/web-pod.json"
    When I run oc create over "web-pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    And the pod named "mypod-<%= project.name %>" becomes ready

    # Now delete PVC
    Given I ensure "nfsc-<%= project.name %>" pvc is deleted

    # Test deleting dynamic PVC
    Given I obtain test data file "storage/misc/pvc.json"
    Given I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce                   |
      | ["spec"]["resources"]["requests"]["storage"] | 1                               |
    And the "dynamic-pvc-<%= project.name %>" PVC becomes :bound

    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | dynamic-<%= project.name %>     |
    Then the step should succeed
    And the pod named "dynamic-<%= project.name %>" becomes ready

    Given I ensure "dynamic-pvc-<%= project.name %>" pvc is deleted

    # New pods should be scheduled and ready
    Given I obtain test data file "pods/hello-pod.json"
    When I run the :create client command with:
      | f | hello-pod.json |
    Then the step should succeed
    And the pod named "hello-openshift" becomes ready

    # Verify all pods are running
    When I get project pods
    # Counting nfs-server pod, should match 4 times
    Then the output should contain 4 times:
      | Running |

