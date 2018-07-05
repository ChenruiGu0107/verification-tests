Feature: logging permission related tests
  # @author pruan@redhat.com
  # @case_id OCP-10823
  @admin
  Scenario: Logging is restricted to current owner of a project
    Given I have a project
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :new_app client command with:
      | docker_image | docker.io/aosqe/java-mainclass:2.3-SNAPSHOT |
    Then the step should succeed
    Given I wait until the status of deployment "java-mainclass" becomes :complete
    Given I login to kibana logging web console
    When I perform the :kibana_verify_app_text web action with:
      | checktext  | java-mainclass                  |
      | time_out   | 300                             |
    Then the step should succeed
    When I perform the :logout_kibana web action with:
       | kibana_url | https://<%= cb.logging_route %> |
    When I run the :delete client command with:
      | object_type       | project             |
      | object_name_or_id | <%= cb.proj_name %> |
    Then the step should succeed
    Given I switch to the second user
    # there seems to be a lag in project deletion
    And I wait for the steps to pass:
    """
    And I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    """
    And I use the "<%= cb.proj_name %>" project
    When I run the :new_app client command with:
      | app_repo |  https://github.com/openshift/cakephp-ex.git |
    Then the step should succeed
    And I wait until the status of deployment "cakephp-ex" becomes :complete
    When I perform the :kibana_login web action with:
      | username   | <%= user.name %>                |
      | password   | <%= user.password %>            |
      | kibana_url | https://<%= cb.logging_route %> |
    When I perform the :kibana_verify_app_text web action with:
       | checktext  | cakephp                         |
       | time_out   | 300                             |
    Then the step should succeed
    When I get the visible text on web html page
    Then the expression should be true> !@result[:response].include? 'java-mainclass'

  # @author pruan@redhat.com
  # @case_id OCP-17449
  @admin
  @destructive
  Scenario: View the project mapping index as different roles
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :project clipboard
    Given logging service is installed in the system
    And I switch to the first user
    # need to add app so it will generate some data which will trigger the project index be pushed up to the es pod
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.target_proj %>" project
    Given a pod becomes ready with labels:
      | component=es |

    # index takes over 10 minutes to come up initially
    And I wait up to 900 seconds for the steps to pass:
    """
    And I execute on the pod:
      | ls                                                                   |
      | /elasticsearch/persistent/logging-es/data/logging-es/nodes/0/indices |
    And the output should contain:
      | project.<%= cb.project.name %>.<%= cb.project.uid %> |
    """
    # Give user1 admin role
    When I run the :policy_add_role_to_user client command with:
      | role             | admin                              |
      | user_name        | <%= user(1, switch: false).name %> |
      | rolebinding_name | admin                              |
    Then the step should succeed
    # Give user2 edit role
    When I run the :policy_add_role_to_user client command with:
      | role             | edit                               |
      | user_name        | <%= user(2, switch: false).name %> |
      | rolebinding_name | edit                               |
    Then the step should succeed
    # Give user3 view role
    When I run the :policy_add_role_to_user client command with:
      | role             | view                               |
      | user_name        | <%= user(3, switch: false).name %> |
      | rolebinding_name | view                               |
    Then the step should succeed
    Given evaluation of `%w[first second third]` is stored in the :users clipboard
    Given I repeat the following steps for each :user in cb.users:
    """
    And I switch to the #{cb.user} user
    And I perform the HTTP request on the ES pod:
      | relative_url | project.<%= cb.project.name %>.*/_count?format=JSON |
      | op           | GET                                                 |
      | token        | <%= user.cached_tokens.first %>                     |
    Then the step should succeed
    Then the expression should be true> @result[:parsed]['count'] > 0
    """

  # @author pruan@redhat.com
  # @case_id OCP-17447
  @smoke
  @admin
  @destructive
  Scenario: access operations index with different roles
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    ## wait until the es pod index to show up
    Then I wait for the ".operations" index to appear in the ES pod with labels "component=es"
    And cluster role "cluster-admin" is added to the "first" user
    And cluster role "cluster-reader" is added to the "second" user
    Given evaluation of `%w[first second]` is stored in the :users clipboard
    Given I repeat the following steps for each :user in cb.users:
    """
    And I switch to the #{cb.user} user
    And I perform the HTTP request on the ES pod:
      | relative_url | .operations.*/_count?format=JSON |
      | op           | GET                              |
      | token        | <%= user.cached_tokens.first %>  |
    Then the step should succeed
    Then the expression should be true> @result[:parsed]['count'] > 0
    """

  # @author pruan@redhat.com
  # @case_id OCP-18199
  @admin
  @destructive
  Scenario: Couldn't access .operations index without permit
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    Given I switch to the first user
    And I perform the HTTP request on the ES pod:
      | relative_url | .operations.*/_count?format=JSON |
      | op           | GET                              |
      | token        | <%= user.cached_tokens.first %>  |
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-18201
  @admin
  @destructive
  Scenario: Couldn't View the project mapping index without permit
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And I switch to the first user
    Given I create a project with non-leading digit name
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    And I perform the HTTP request on the ES pod:
      | relative_url | project.<%= project.name %>/_count?format=JSON |
      | op           | GET                              |
      | token        | <%= user.cached_tokens.first %>  |
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-18090
  @admin
  @destructive
  Scenario: Cluster-admin view Elasticsearch cluster/monitor endpoints
    Given I create a project with non-leading digit name
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-18090/inventory |
    And I wait until the ES cluster is healthy
    Given I switch to the first user
    And the first user is cluster-admin
    And evaluation of `%w(_cat/indices _cat/aliases _cat/nodes _cluster/health)` is stored in the :urls clipboard
    Given I repeat the following steps for each :url in cb.urls:
    """
    And I perform the HTTP request:
    <%= '"""' %>
      :url: https://<%= route('logging-es').dns %>/#{cb.url}?output=JSON
      :method: get
      :headers:
        :Authorization: Bearer <%= user.cached_tokens.first %>
    <%= '"""' %>
    Then the expression should be true> @result[:exitstatus] == 200
    """
