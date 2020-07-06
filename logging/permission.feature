@clusterlogging
@commonlogging
Feature: logging permission related tests

  # @author pruan@redhat.com
  # @case_id OCP-18199
  @admin
  @destructive
  Scenario: Couldn't access .operations index without permit
    And I wait for the ".operations" index to appear in the ES pod with labels "es-node-master=true"
    Given I switch to the first user
    And evaluation of `user.cached_tokens.first` is stored in the :user_token clipboard
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | .operations.*/_count |
      | op           | GET                  |
      | token        | <%= cb.user_token %> |
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-18201
  @admin
  @destructive
  Scenario: Couldn't View the project mapping index without permit
    Given I switch to the first user
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed
    Given I switch to the second user
    And evaluation of `user.cached_tokens.first` is stored in the :user_token clipboard
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    Given I wait for the "project.<%= cb.proj_name %>" index to appear in the ES pod with labels "es-node-master=true"
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.<%= cb.proj_name %> |
      | op           | GET                         |
      | token        | <%= cb.user_token %>        |
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author qitang@redhat.com
  # @case_id OCP-10809
  @admin
  @destructive
  Scenario: Verify if cluster-admin is able to view logs for deleted projects
    Given I switch to the first user
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name_1 clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed

    Given I switch to the second user
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name_2 clipboard
    Given I obtain test data file "logging/loggen/container_json_log_template.json"
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed
    Given the second user is cluster-admin

    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    And I wait for the "project.<%= cb.proj_name_1 %>" index to appear in the ES pod with labels "es-node-master=true"
    And I wait for the "project.<%= cb.proj_name_2 %>" index to appear in the ES pod with labels "es-node-master=true"
    When I run the :delete client command with:
      | object_type            | project                 |
      | object_name_or_id      | <%= cb.proj_name_1 %>   |
      | object_name_or_id      | <%= cb.proj_name_2 %>   |
    Then the step should succeed
    Given I wait for the resource "project" named "<%= cb.proj_name_1 %>" to disappear within 3600 seconds
    Given I wait for the resource "project" named "<%= cb.proj_name_2 %>" to disappear within 3600 seconds
    Given I switch to the second user
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.<%= cb.proj_name_1 %>*   |
      | op           | GET                              |
      | token        | <%= user.cached_tokens.first %>  |
    Then the step should succeed
    And the output should contain:
      | project.<%= cb.proj_name_1 %>   |
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.<%= cb.proj_name_2 %>*   |
      | op           | GET                              |
      | token        | <%= user.cached_tokens.first %>  |
    Then the step should succeed
    And the output should contain:
      | project.<%= cb.proj_name_2 %>   |

    Given I switch to the first user
    And evaluation of `user.cached_tokens.first` is stored in the :user_token clipboard
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.<%= cb.proj_name_1 %>*   |
      | op           | GET                              |
      | token        | <%= cb.user_token %>             |
    Then the step should succeed
    And the output should contain:
      |  error                                   |
      |  no permissions for [indices:admin/get]  |
      |  403                                     |
    And the output should not contain:
      | project.<%= cb.proj_name_1 %>   |
    And I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | project.<%= cb.proj_name_2 %>* |
      | op           | GET                            |
      | token        | <%= cb.user_token %>           |
    Then the step should succeed
    And the output should contain:
      |  error                                   |
      |  no permissions for [indices:admin/get]  |
      |  403                                     |
    And the output should not contain:
      | project.<%= cb.proj_name_2 %>   |

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
