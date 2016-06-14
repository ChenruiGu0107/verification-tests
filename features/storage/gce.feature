Feature: GCE Persistent Volume
  # @author lxia@redhat.com
  # @case_id 522125
  @admin
  Scenario: [storage_201] Only one pod with GCE PD can be scheduled when NoDiskConflicts policy is enabled
    Given I store the schedulable nodes in the :nodes clipboard
    And I register clean-up steps:
      | I run the :label admin command with:   |
      | ! resource ! node                    ! |
      | ! name     ! <%= cb.nodes[0].name %> ! |
      | ! key_val  ! labelForTC522125-       ! |
      | the step should succeed                |
    When I run the :label admin command with:
      | resource  | node                    |
      | name      | <%= cb.nodes[0].name %> |
      | key_val   | labelForTC522125=1      |
      | overwrite | true                    |
    Then the step should succeed

    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %> |
      | node_selector | labelForTC522125=1  |
      | admin         | <%= user.name %>    |
    Then the step should succeed
    And I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod-NoDiskConflict-1.json" replacing paths:
      | ["metadata"]["name"]                                       | gce-pod1-<%= project.name %> |
      | ["spec"]["containers"][0]["securityContext"]["privileged"] | true                      |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod-NoDiskConflict-2.json" replacing paths:
      | ["metadata"]["name"]                                       | gce-pod2-<%= project.name %> |
      | ["spec"]["containers"][0]["securityContext"]["privileged"] | true                      |
    Then the step should succeed

    When I run the :describe client command with:
      | resource | pod                       |
      | name     | gce-pod2-<%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | Pending          |
      | FailedScheduling |
      | NoDiskConflict   |
    When I run the :get client command with:
      | resource | events |
    Then the step should succeed
    And the output should contain:
      | FailedScheduling |
      | NoDiskConflict   |
