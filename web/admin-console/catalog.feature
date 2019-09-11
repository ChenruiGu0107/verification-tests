Feature: tests on catalog page

  # @author yanpzhan@redhat.com
  # @case_id OCP-23610
  Scenario: Create labels when source-to-image/Deploy Image creation
    Given the master version >= "4.2"
    Given I have a project
    And I open admin console in a browser
    When I perform the :create_app_from_imagestream web action with:
      | project_name | <%= project.name %> |
      | is_name      | ruby                |
      | label        | testapp=one         |
    Then the step should succeed
    Given the "ruby-1" build completed
    And a pod is present with labels:
      | testapp=one |

    When I perform the :create_app_from_deploy_image web action with:
      | project_name   | <%= project.name %>   |
      | search_content | aosqe/hello-openshift |
      | label          | testdc=two            |
    Then the step should succeed
    And a pod is present with labels:
      | testdc=two |
