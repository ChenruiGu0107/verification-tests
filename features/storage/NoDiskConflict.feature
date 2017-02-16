Feature: NoDiskConflict
  # @author lxia@redhat.com
  # @case_id OCP-9927
  # @case_id OCP-9929
  @admin
  Scenario Outline: [storage_201] Only one pod with the same persistent volume can be scheduled when NoDiskConflicts policy is enabled
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>                 |
      | node_selector | <%= cb.proj_name %>=NoDiskConflicts |
      | admin         | <%= user.name %>                    |
    Then the step should succeed

    Given I store the schedulable nodes in the :nodes clipboard
    And label "<%= cb.proj_name %>=NoDiskConflicts" is added to the "<%= cb.nodes[0].name %>" node

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project

    Given I have a 1 GB volume and save volume id in the :volumeID clipboard
    When I run oc create over "https://raw.githubusercontent.com/<path_to_file>" replacing paths:
      | ["metadata"]["name"]                                      | pod1-<%= project.name %> |
      | ["spec"]["volumes"][0]["<storage_type>"]["<volume_name>"] | <%= cb.volumeID %>       |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/<path_to_file>" replacing paths:
      | ["metadata"]["name"]                                      | pod2-<%= project.name %> |
      | ["spec"]["volumes"][0]["<storage_type>"]["<volume_name>"] | <%= cb.volumeID %>       |
    Then the step should succeed

    When I run the :describe client command with:
      | resource | pod                      |
      | name     | pod2-<%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | Pending          |
      | FailedScheduling |
      | NoDiskConflict   |
    When I get project events
    Then the step should succeed
    And the output should contain:
      | FailedScheduling |
      | NoDiskConflict   |

    Examples:
      | storage_type         | volume_name | path_to_file |
      | gcePersistentDisk    | pdName      | openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod-NoDiskConflict-1.json              |
      | awsElasticBlockStore | volumeID    | openshift-qe/v3-testfiles/master/persistent-volumes/ebs/security/ebs-selinux-fsgroup-test.json |
