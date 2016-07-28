Feature: GCE specific scenarios
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
