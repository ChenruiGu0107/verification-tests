Feature: logging related scenarios
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
      | kibana_url | https://<%= cb.logging_route %> |
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
       | kibana_url | https://<%= cb.logging_route %> |
       | checktext  | cakephp                         |
       | time_out   | 300                             |
    Then the step should succeed
    When I get the visible text on web html page
    Then the expression should be true> !@result[:response].include? 'java-mainclass'
