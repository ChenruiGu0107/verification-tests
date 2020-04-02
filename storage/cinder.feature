Feature: Cinder Persistent Volume

  # @author wehe@redhat.com
  # @case_id OCP-10052
  @admin
  Scenario: Cinder volume should be detached after delete pod
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard

    #create test pod
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/cinder/cinder-pod.yaml" replacing paths:
      | ['spec']['volumes'][0]['cinder']['volumeID'] | <%= cb.vid %> |
    Then the step should succeed
    And the pod named "cinder" becomes ready

    #create test file
    Given I execute on the "cinder" pod:
      | touch | /mnt/cinderfile |
    Then the step should succeed
    When I execute on the "cinder" pod:
      | ls | -l | /mnt/cinderfile |
    Then the step should succeed

    #Delete pod and pvc, check volume is delete on openstack
    Given I ensure "cinder" pod is deleted
    And I ensure "<%= pvc.name %>" pvc is deleted
    And I verify that the IAAS volume with id "<%= cb.vid %>" was deleted

  # @author piqin@redhat.com
  # @case_id OCP-9828
  @admin
  Scenario Outline: Cinder volume racing condition
    Given I have a project
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/cinder/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod1                                 |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc                                  |
      | ["spec"]["securityContext"]["fsGroup"]                       | <%= project.supplemental_groups.min %> |
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"]       | <%= project.mcs %>                     |
    Then the step should succeed
    Given the pod named "mypod1" becomes ready

    When I execute on the pod:
      | sh                            |
      | -c                            |
      | date > /mnt/cinder/<testfile> |
    Then the step should succeed
    Then I run the :delete client command with:
      | object_type       | pod    |
      | object_name_or_id | mypod1 |

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/cinder/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod2                                 |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc                                  |
      | ["spec"]["securityContext"]["fsGroup"]                       | <%= project.supplemental_groups.min %> |
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"]       | <%= project.mcs %>                     |
    Then the step should succeed
    Given the pod named "mypod2" becomes ready

    Given I run the steps 6 times:
    """
    When I execute on the pod:
      | sh                         |
      | -c                         |
      | cat /mnt/cinder/<testfile> |
    Then the step should succeed
    Given 10 seconds have passed
    """

    Examples:
    | testfile  |
    | testfile1 |
    | testfile2 |
    | testfile3 |
