Feature: Regression testing cases

  # @author jhou@redhat.com
  # @case_id OCP-10050
  @admin
  @destructive
  Scenario: Delete PVC while pod is running
    Given I have a project
    And I have a NFS service in the project

    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"]                 | <%= service("nfs-service").ip %> |
      | ["spec"]["accessModes"][0]                | ReadOnlyMany                     |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                           |
      | ["metadata"]["name"]                      | nfs-<%= project.name %>          |
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]       | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]     | nfs-<%= project.name %>  |
      | ["spec"]["accessModes"][0] | ReadOnlyMany             |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    And the pod named "mypod-<%= project.name %>" becomes ready

    # Now delete PVC
    Given I ensure "nfsc-<%= project.name %>" pvc is deleted

    # Test deleting dynamic PVC
    Given I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce                   |
      | ["spec"]["resources"]["requests"]["storage"] | 1                               |
    And the "dynamic-pvc-<%= project.name %>" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | dynamic-<%= project.name %>     |
    Then the step should succeed
    And the pod named "dynamic-<%= project.name %>" becomes ready

    Given I ensure "dynamic-pvc-<%= project.name %>" pvc is deleted

    # New pods should be scheduled and ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    And the pod named "hello-openshift" becomes ready

    # Verify all pods are running
    When I get project pods
    # Counting nfs-server pod, should match 4 times
    Then the output should contain 4 times:
      | Running |

  # @author jhou@redhat.com
  # @case_id OCP-16485
  @admin
  Scenario: RWO volumes are exclusively mounted on different nodes
    Given I have a project

    Given I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | ds            |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi           |
    And the "ds" PVC becomes :bound

    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/damonset.json |
      | n | <%= project.name %>                                                                                      |
    Then the step should succeed

    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod |
    Then the output should contain:
      | already |
    """
