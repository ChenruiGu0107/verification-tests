Feature: snapshot specific scenarios
  # @author lxia@redhat.com
  @admin
  Scenario Outline: admins create pvc that claims pv based on existing snapshot restore the pv
    Given I check volume snapshot is deployed
    And cluster role "<role>" is added to the "second" user

    Given I have a project
    And evaluation of `project.name` is stored in the :proj clipboard
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc |
    Then the step should succeed
    And the "pvc" PVC becomes :bound
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc |
      | ["metadata"]["name"]                                         | pod |
    Then the step should succeed
    Given the pod named "pod" becomes ready
    When I execute on the pod:
      | touch | /mnt/gce/testfile1 | /mnt/gce/testfile2 |
    Then the step should succeed
    Given 30 seconds have passed

    Given I switch to the second user
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/snapshot/snapshot.yaml" replacing paths:
      | ["metadata"]["name"]                  | ss-<%= cb.proj %> |
      | ["metadata"]["namespace"]             | <%= cb.proj %>    |
      | ["spec"]["persistentVolumeClaimName"] | pvc               |
    Then the step should succeed
    And I wait for the "ss-<%= project.name %>" volume_snapshot to become ready up to 180 seconds

    Given I switch to the default user
    When I execute on the pod:
      | rm | -f | /mnt/gce/testfile2 |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/gce/testfile3 |
    Then the step should succeed
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/snapshot/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                 | snapshot-pvc      |
      | ["metadata"]["namespace"]                                            | <%= cb.proj %>    |
      | ["metadata"]["annotations"]["snapshot.alpha.kubernetes.io/snapshot"] | ss-<%= cb.proj %> |
      | ["spec"]["resources"]["requests"]["storage"]                         | 2Gi               |
    Then the step should succeed
    And the "snapshot-pvc" PVC becomes :bound within 120 seconds
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pod.json" replacing paths:
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

    Examples:
      | role                 |
      | cluster-admin        | # @case_id OCP-15904
      | volumesnapshot-admin | # @case_id OCP-15905


  # @author lxia@redhat.com
  # @case_id OCP-15896
  @admin
  Scenario: user create pvc that claims pv based on existing snapshot restore the pv
    Given I check volume snapshot is deployed
    And cluster role "volumesnapshot-admin" is added to the "default" user

    Given I have a project
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc |
    Then the step should succeed
    And the "pvc" PVC becomes :bound
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc |
      | ["metadata"]["name"]                                         | pod |
    Then the step should succeed
    Given the pod named "pod" becomes ready
    When I execute on the pod:
      | touch | /mnt/gce/testfile1 | /mnt/gce/testfile2 |
    Then the step should succeed
    Given 30 seconds have passed

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/snapshot/snapshot.yaml" replacing paths:
      | ["metadata"]["name"]                  | ss-<%= project.name %> |
      | ["metadata"]["namespace"]             | <%= project.name %>    |
      | ["spec"]["persistentVolumeClaimName"] | pvc                    |
    Then the step should succeed
    And I wait for the "ss-<%= project.name %>" volume_snapshot to become ready up to 180 seconds

    When I execute on the pod:
      | rm | -f | /mnt/gce/testfile2 |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/gce/testfile3 |
    Then the step should succeed
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/snapshot/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                 | snapshot-pvc           |
      | ["metadata"]["namespace"]                                            | <%= project.name %>    |
      | ["metadata"]["annotations"]["snapshot.alpha.kubernetes.io/snapshot"] | ss-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"]                         | 2Gi                    |
    Then the step should succeed
    And the "snapshot-pvc" PVC becomes :bound within 120 seconds
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pod.json" replacing paths:
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


  # @author lxia@redhat.com
  # @case_id OCP-15911
  @admin
  Scenario: Restore from non-exist volume snapshot should not restore the pv
    Given I check volume snapshot is deployed
    And cluster role "volumesnapshot-admin" is added to the "default" user

    Given I have a project
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc |
    Then the step should succeed
    And the "pvc" PVC becomes :bound
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc |
      | ["metadata"]["name"]                                         | pod |
    Then the step should succeed
    Given the pod named "pod" becomes ready

    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/snapshot/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                 | snapshot-pvc                  |
      | ["metadata"]["namespace"]                                            | <%= project.name %>           |
      | ["metadata"]["annotations"]["snapshot.alpha.kubernetes.io/snapshot"] | non-exist-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"]                         | 2Gi                           |
    Then the step should succeed
    And the "snapshot-pvc" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc          |
      | name     | snapshot-pvc |
    Then the step should succeed
    And the output should contain:
      | "non-exist-<%= project.name %>" not found |
