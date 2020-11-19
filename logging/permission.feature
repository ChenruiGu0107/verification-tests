@clusterlogging
@commonlogging
Feature: logging permission related tests

  # @author qitang@redhat.com
  # @case_id OCP-26295
  @admin @destructive
  Scenario: [BZ1316216]Logging should restricted to to current owner/group of a namespace
    Given I switch to the first user
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    And evaluation of `project.uid` is stored in the :proj_uid_1 clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    And I wait for the "project.<%= cb.proj_name %>.<%= cb.proj_uid_1 %>" index to appear in the ES pod with labels "es-node-master=true"
    Given I delete the "<%= cb.proj_name %>" project
    Given I wait for the resource "project" named "<%= cb.proj_name %>" to disappear within 3600 seconds

    Given I switch to the second user
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    And I use the "<%= cb.proj_name %>" project
    And evaluation of `project.uid` is stored in the :proj_uid_2 clipboard
    Given I obtain test data file "logging/loggen/container_json_event_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_event_log_template.json |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    And I wait for the "project.<%= cb.proj_name %>.<%= cb.proj_uid_2 %>" index to appear in the ES pod with labels "es-node-master=true"
    Given I switch to the first user
    Given I login to kibana logging web console
    And I run the :kibana_expand_index_patterns web action
    And I perform the :kibana_find_index_pattern web action with:
      | index_pattern_name | project.<%= cb.proj_name %>.<%= cb.proj_uid_1 %> |
    Then the step should fail

    And I perform the :kibana_find_index_pattern web action with:
      | index_pattern_name | project.<%= cb.proj_name %>.<%= cb.proj_uid_2 %> |
    Then the step should fail
    When I run the :logout_kibana web action
    Then the step should succeed
    And I close the current browser

    Given I switch to the second user
    Given I login to kibana logging web console
    And I run the :kibana_expand_index_patterns web action
    And I perform the :kibana_find_index_pattern web action with:
      | index_pattern_name | project.<%= cb.proj_name %>.<%= cb.proj_uid_1 %> |
    Then the step should fail

    And I perform the :kibana_find_index_pattern web action with:
      | index_pattern_name | project.<%= cb.proj_name %>.<%= cb.proj_uid_2 %> |
    Then the step should succeed
