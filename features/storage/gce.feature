Feature: GCE specific scenarios
  # @author lxia@redhat.com
  # @case_id 532744
  @admin
  Scenario: Rapid repeat pod creation and deletion with GCE PD should not fail
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound

    Given I run the steps 30 times:
    """
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod                   |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | mountpoint | -d | /mnt/gce |
    Then the step should succeed
    When I execute on the pod:
      | bash |
      | -c   |
      | date >> /mnt/gce/testfile |
    Then the step should succeed
    Given I ensure "mypod" pod is deleted
    """

  # @author lxia@redhat.com
  # @case_id 532746
  @admin
  @destructive
  Scenario: Two or more pods scheduled to the same node with the same volume with ROX should not fail
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>      |
      | node_selector | <%= cb.proj_name %>=test |
      | admin         | <%= user.name %>         |
    Then the step should succeed

    Given I store the schedulable nodes in the :nodes clipboard
    And label "<%= cb.proj_name %>=test" is added to the "<%= cb.nodes[0].name %>" node

    Given I use the "<%= cb.proj_name %>" project
    And I have a 1 GB volume and save volume id in the :gcepd clipboard
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pv-default-rwo.json" where:
      | ["metadata"]["name"]                      | pv-<%= project.name %> |
      | ["spec"]["capacity"]["storage"]           | 1                      |
      | ["spec"]["accessModes"][0]                | ReadOnlyMany           |
      | ["spec"]["gcePersistentDisk"]["pdName"]   | <%= cb.gcepd %>        |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                 |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | pv-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadOnlyMany            |
      | ["spec"]["resources"]["requests"]["storage"] | 1                       |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | pod1-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>  |
    Then the step should succeed
    Given the pod named "pod1-<%= project.name %>" becomes ready
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | pod2-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>  |
    Then the step should succeed
    Given the pod named "pod2-<%= project.name %>" becomes ready
    When I execute on the "<%= pod(-1).name %>" pod:
      | ls | /mnt/gce/ |
    Then the step should succeed
    When I execute on the "<%= pod(-2).name %>" pod:
      | ls | /mnt/gce/ |
    Then the step should succeed

  # @author lxia@redhat.com
  # @case_id 532743
  @admin
  Scenario: pods referencing different partitions of the same volume should not fail
    Given I have a project
    And I have a 1 GB volume and save volume id in the :volumeID clipboard

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod-NoDiskConflict-1.json" replacing paths:
      | ["metadata"]["name"]                                     | pod1-<%= project.name %> |
      | ["spec"]["volumes"][0]["gcePersistentDisk"]["pdName"]    | <%= cb.volumeID %>       |
      | ["spec"]["volumes"][0]["gcePersistentDisk"]["partition"] | 0                        |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod-NoDiskConflict-1.json" replacing paths:
      | ["metadata"]["name"]                                     | pod2-<%= project.name %> |
      | ["spec"]["volumes"][0]["gcePersistentDisk"]["pdName"]    | <%= cb.volumeID %>       |
      | ["spec"]["volumes"][0]["gcePersistentDisk"]["partition"] | 1                        |
    Then the step should succeed
    Given the pod named "pod1-<%= project.name %>" becomes ready
    Given the pod named "pod2-<%= project.name %>" becomes ready

    When I execute on the "<%= pod(-1).name %>" pod:
      | ls | -al | /mnt/gce/ |
    Then the step should succeed
    When I execute on the "<%= pod(-2).name %>" pod:
      | ls | -al | /mnt/gce/ |
    Then the step should succeed

  # @author lxia@redhat.com
  # @case_id 535238
  @admin
  Scenario: PV with invalid gce volume id should be prevented from creating
    Given admin ensures "gce" pv is deleted after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pv-retain-rwx.json |
    Then the step should fail
    And the output should contain:
      | error querying GCE PD volume |
