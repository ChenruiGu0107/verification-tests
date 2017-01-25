Feature: Independent link related scenarios
  # @author xiaocwan@redhat.com
  # @case_id OCP-11863
  @admin
  Scenario: Create app by template and existed project from external page
    Given the master version >= "3.5"
    # create a template under project openshift
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | n | openshift |
    Then the step should succeed
    And I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | template               |
      | object_name_or_id | ruby-helloworld-sample |
      | n                 | openshift              |
    the step should succeed
    """
    Given I have a project
    # create app by template from external page
    When I perform the :goto_create_from_template_external_page web console action with:
      | template_name  | ruby-helloworld-sample         |
      | paramsmap      | {"ADMIN_USERNAME":"adminuser"} |
    Then the step should succeed
    When I run the :check_template_page_with_project web console action
    Then the step should succeed
    When I perform the :choose_one_project web console action with:
      | project_name   | <%= project.name %>            |
    Then the step should succeed  
    And I wait for the steps to pass:
    """
    Given the expression should be true> browser.url =~ /fromtemplate.template=ruby-helloworld-sample.namespace=openshift.templateParamsMap.*ADMIN_USERNAME.*adminuser/
    """
    When I run the :fromtemplate_submit_and_confirm web console action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-11677
  Scenario: Create app by existed imagestream on new-created project from external page
    Given the master version >= "3.5"
    # create app by template from external page
    When I perform the :goto_create_from_image_external_page web console action with:
      | params  | name=nodejs-ex&imageStream=nodejs&imageTag=4 |
    Then the step should succeed
    When I run the :check_create_project_page_without_project web console action
    Then the step should succeed
    When I perform the :new_project_form web console action with:
      | project_name | my-new-project  |
      | display_name | my display name |
      | description  | my description  |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Given the expression should be true> browser.url =~ /fromimage.*imageStream=nodejs.imageTag=4.namespace=openshift.displayName=Node.js.*name=nodejs-ex/
    """
    When I run the :create_app_from_image_try_sample_repo web console action
    Then the step should succeed
    When I run the :create_app_from_image_submit web console action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-11037
  Scenario: Create app with nonexistent resource template on external page
    Given the master version >= "3.5"
    Given I have a project
    # create app by template from external page
    When I perform the :goto_create_from_template_external_page web console action with:
      | template_name  | ruby-helloworld-sample         |
      | paramsmap      | {"ADMIN_USERNAME":"adminuser"} |
    Then the step should succeed
    When I perform the :check_template_not_existed_with_error_message web console action with:
      | template_name  | ruby-helloworld-sample         |
    Then the step should succeed
