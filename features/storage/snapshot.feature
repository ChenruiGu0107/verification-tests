Feature: snapshot specific scenarios
  # @author lxia@redhat.com
  # @case_id OCP-15904
  @admin
  Scenario: Cluster admin create pvc that claims pv based on existing snapshot restore the pv
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc |
    Then the step should succeed
    And the "pvc" PVC becomes :bound
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc |
      | ["metadata"]["name"]                                         | pod |
    Then the step should succeed
    Given the pod named "pod" becomes ready
    When I execute on the pod:
      | touch | /mnt/gce/testfile1 | /mnt/gce/testfile2 |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/snapshot/snapshot.yaml" replacing paths:
      | ["metadata"]["name"]                  | ss-<%= project.name %> |
      | ["metadata"]["namespace"]             | <%= project.name %>    |
      | ["spec"]["persistentVolumeClaimName"] | pvc                    |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/snapshot/storageclass.yaml" where:
      | ["metadata"]["name"] | snapshot-promoter-<%= project.name %> |
    Then the step should succeed
    Given I switch to the default user
    When I execute on the pod:
      | rm | -f | /mnt/gce/testfile2 |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/gce/testfile3 |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | volumesnapshot |
      | all_namespaces | true           |
      | o             | yaml           |
    Then the step should succeed
    And the output should contain "ss-<%= project.name %>"
    When I run the :get admin command with:
      | resource | volumesnapshotdata |
      | o        | yaml               |
    Then the step should succeed
    And the output should contain "ss-<%= project.name %>"
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/snapshot/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                 | snapshot-pvc                          |
      | ["metadata"]["namespace"]                                            | <%= project.name %>                   |
      | ["metadata"]["annotations"]["snapshot.alpha.kubernetes.io/snapshot"] | ss-<%= project.name %>                |
      | ["spec"]["storageClassName"]                                         | snapshot-promoter-<%= project.name %> |
    Then the step should succeed
    And the "snapshot-pvc" PVC becomes :bound
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | snapshot-pvc |
      | ["metadata"]["name"]                                         | mypod        |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | ls | /mnt/gce |
    Then the step should succeed
    And the output should contain:
      | testfile1 |
      | testfile2 |
    And the output should not contain:
      | testfile3 |
