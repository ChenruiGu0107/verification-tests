Feature: build related feature on web console

  # @author: xxing@redhat.com
  # @case_id: 482266
  Scenario: Check the build information from web console
    When I create a new project via web
    Then the step should succeed
    Given I use the "<%= project.name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json |
    Then the step should succeed
    Given I wait for the :check_one_image_stream web console action to succeed with:
      | project_name | <%= project.name %> |
      | image_name   | python              |
    When I run the :get client command with:
      | resource | imageStream |
      | resource_name | python |
      | o        | json |
    Then the output should contain "openshift.io/image"
    Given I wait for the :create_app_from_image_change_bc_configchange web console action to succeed with:
      | project_name | <%= project.name %> |
      | image_name   | python              |
      | image_tag    | 3.3                 |
      | namespace    | <%= project.name %> |
      | app_name     | python-sample       |
      | source_url   | https://github.com/openshift/django-ex.git |
    When I perform the :check_one_buildconfig_page_with_build_op web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | python-sample |
    Then the step should succeed
    Given the "python-sample-1" build was created
    Given the "python-sample-1" build completed
    When I perform the :check_one_build_inside_bc_page web console action with:
      | project_name            | <%= project.name %> |
      | bc_and_build_name       | python-sample/python-sample-1       |
    Then the step should succeed
    When I click the following "button" element:
      | text  | Rebuild |
      | class | btn-default |
    Then the step should succeed
    Given the "python-sample-2" build was created
    When I get the "disabled" attribute of the "button" web element:
      | text  | Rebuild |
      | class | btn-default |
    Then the output should contain "true"
    When I perform the :check_one_buildconfig_page web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | python-sample |
    Then the step should succeed
    And I get the html of the web page
    Then the output should contain:
      | #1 |
      | #2 |
