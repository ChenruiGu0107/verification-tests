Feature: build related feature on web console

  # @author: xxing@redhat.com
  # @case_id: 498655
  Scenario: Check the build information from web console
    When I create a new project via web
    Then the step should succeed
    Given I use the "<%= project.name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json |
    Then the step should succeed
    Given I wait for the :create_app_from_image_change_bc_configchange web console action to succeed with:
      | project_name | <%= project.name %> |
      | image_name   | python              |
      | image_tag    | 3.3                 |
      | namespace    | <%= project.name %> |
      | app_name     | python-sample       |
      | source_url   | https://github.com/openshift/django-ex.git |
    When I perform the :check_builds_list web console action with:
      | project_name  | <%= project.name %> |
      | build_or_bc_name | python-sample |
    Then the step should succeed
    When I click the following "button" element:
      | text  | Build |
      | class | btn-default |
    Then the step should succeed
    Given the "python-sample-1" build was created
    Given the "python-sample-1" build completed
    When I perform the :check_builds_list web console action with:
      | project_name  | <%= project.name %> |
      | build_or_bc_name | python-sample/python-sample-1 |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | Status:       |
      | Complete      |
      | Started:      |
      | Duration:     |
      | Builder image:|
      | Output image: |
