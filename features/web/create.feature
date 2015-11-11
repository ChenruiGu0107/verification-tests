Feature: create app on web console related

  # @author xxing@redhat.com
  # @case_id 497608
  Scenario: create app from template with custom build on web console
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I perform the :new_project web console action with:
      | project_name | <%= cb.proj_name %> |
      | display_name | :null               |
      | description  ||
    Then the step should succeed
    Given I use the "<%= cb.proj_name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json |
    Then the step should succeed
    When I perform the :create_app_from_template web console action with:
      | project_name  | <%= cb.proj_name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= cb.proj_name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
      | label_key     | label1 |
      | label_value   | test   |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    When I access the "/console/project/<%= cb.proj_name %>/browse/builds/ruby-sample-build" path in the web console
    Then the step should succeed
    And I get the html of the web page
    Then the output should contain "ruby-sample-build"
    Given the "ruby-sample-build-1" build completed
    When I run the :get client command with:
      | resource | all         |
      | l        | label1=test |
    Then the output should contain:
      | NAME              |
      | ruby-sample-build |
      | frontend          |
      | database          |   
    When I run the :delete client command with:
      | object_type | all  |
      | l           | label1=test |
    Then the output should match:
      | build.+deleted            |
      | imagestream.+deleted      |
      | deploymentconfig.+deleted |
      | route.+deleted            |
      | service.+deleted          |

  # @author xxing@redhat.com
  # @case_id 497529
  Scenario: Create app from template containing invalid type on web console
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I perform the :new_project web console action with:
      | project_name | <%= cb.proj_name %> |
      | display_name | :null               |
      | description  ||
    Then the step should succeed
    Given I use the "<%= cb.proj_name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Given I replace resource "template" named "ruby-helloworld-sample" saving edit to "tempsti.json":
      | Service | Test |
    When I perform the :create_app_from_template web console action with:
      | project_name  | <%= cb.proj_name %>    |
      | template_name | ruby-helloworld-sample |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
      | label_key     | label1 |
      | label_value   | test   |
    Then the step should fail
    When I get the html of the web page
    Then the output should contain 2 times:
      | Cannot create object   |
      | Unrecognized kind Test |
