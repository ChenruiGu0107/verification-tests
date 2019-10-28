@clusterlogging
@commonlogging
Feature: logging permission related tests

  # @author pruan@redhat.com
  # @case_id OCP-18199
  @admin
  @destructive
  Scenario: Couldn't access .operations index without permit
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
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
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    Given I switch to the second user
    And evaluation of `user.cached_tokens.first` is stored in the :user_token clipboard
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
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
    When I run the :new_app client command with:
      | docker_image | docker.io/aosqe/java-mainclass:2.3-SNAPSHOT |
    Then the step should succeed
    Given I wait until the status of deployment "java-mainclass" becomes :complete

    Given I switch to the second user
    Given I create a project with non-leading digit name
    Given evaluation of `project.name` is stored in the :proj_name_2 clipboard
    When I run the :new_app client command with:
      | docker_image | docker.io/aosqe/java-mainclass:2.3-SNAPSHOT |
    Then the step should succeed
    And I wait until the status of deployment "java-mainclass" becomes :complete
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
