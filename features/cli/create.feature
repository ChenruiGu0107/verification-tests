Feature: creating 'apps' with CLI

  # @author akostadi@redhat.com
  # @case_id 482262
  Scenario: Create an application with overriding app name
    Given I have a project
    And I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | app_name     | myapp                |
      | namespace    | <%= @project.name %> |
    Then the step should succeed
    When I expose the "myapp" service
    Then the step should succeed
    And a web server should be available via the route

    # TODO: the rest of the steps
