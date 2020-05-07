Feature: create app on web console related
  # @author wsun@redhat.com
  # @case_id OCP-12597
  Scenario: Could edit Routing on create from source page
    Given I have a project
    When I perform the :create_app_without_route_action web console action with:
      | namespace    | openshift |
      | project_name | <%= project.name %> |
      | image_name   | python              |
      | image_tag    | 3.4                 |
      | app_name     | python-sample       |
      | source_url   | https://github.com/sclorg/django-ex.git |
    Then the step should succeed
    When I perform the :check_empty_routes_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-12319
  Scenario: web console:parameter requirement check works correctly
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    When I perform the :create_app_from_template_with_required_field_empty web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
    Then the step should fail
    When I run the :check_error_info_for_required_field web console action
    Then the step should succeed
