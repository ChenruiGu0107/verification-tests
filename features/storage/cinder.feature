Feature: Cinder Persistent Volume
  # @author wehe@redhat.com
  # @case_id OCP-9643
  @admin
  Scenario: Persistent Volume with cinder volume plugin
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard

    #create test pod
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/cinder/cinder-pod.yaml" replacing paths:
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

  # @author wehe@redhat.com
  # @case_id OCP-10052
  @admin
  Scenario: Cinder volume should be detached after delete pod
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard

    #create test pod
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/cinder/cinder-pod.yaml" replacing paths:
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
    Given I have a 1 GB volume and save volume id in the :vid clipboard

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/cinder/pv-rwx-default.json" where:
      | ["metadata"]["name"]                      | pv-<%= project.name %> |
      | ["spec"]["accessModes"][0]                | ReadWriteOnce          |
      | ["spec"]["capacity"]["storage"]           | 5Gi                    |
      | ["spec"]["cinder"]["volumeID"]            | <%= cb.vid %>          |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                 |
    Then the step should succeed

    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/cinder/pvc-rwx.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce            |
      | ["spec"]["resources"]["requests"]["storaeg"] | 5Gi                      |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/cinder/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod-a-<%= project.name %>                                  |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>                                      |
      | ["spec"]["securityContext"]["fsGroup"]                       | <%= project.supplemental_groups.min %>                       |
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"]       | <%= project.mcs %>                                           |
    Then the step should succeed
    Given the pod named "mypod-a-<%= project.name %>" becomes ready

    When I execute on the pod:
      | sh                            |
      | -c                            |
      | date > /mnt/cinder/<testfile> |
    Then the step should succeed
    Then I run the :delete client command with:
      | object_type       | pod                         |
      | object_name_or_id | mypod-a-<%= project.name %> |

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/cinder/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod-b-<%= project.name %>                                  |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>                                      |
      | ["spec"]["securityContext"]["fsGroup"]                       | <%= project.supplemental_groups.min %>                       |
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"]       | <%= project.mcs %>                                           |
    Then the step should succeed
    Given the pod named "mypod-b-<%= project.name %>" becomes ready

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
