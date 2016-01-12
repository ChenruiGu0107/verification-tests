Feature: create app on web console related

  # @author xxing@redhat.com
  # @case_id 497608
  Scenario: create app from template with custom build on web console
    When I create a project via web with:
      | display_name | :null               |
      | description  ||
    Then the step should succeed
    Given I use the "<%= project.name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json |
    Then the step should succeed
    When I perform the :create_app_from_template web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
      | label_key     | label1 |
      | label_value   | test   |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    When I access the "/console/project/<%= project.name %>/browse/builds/ruby-sample-build" path in the web console
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
    When I create a project via web with:
      | display_name | :null               |
      | description  ||
    Then the step should succeed
    Given I use the "<%= project.name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Given I replace resource "template" named "ruby-helloworld-sample" saving edit to "tempsti.json":
      | Service | Test |
    When I perform the :create_app_from_template web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
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

  # @author xxing@redhat.com
  # @case_id 507527
  Scenario: Create application from image on web console
    Given I login via web console
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-centos7.json |
    Then the step should succeed
    Given I wait for the :create_app_from_image web console action to succeed with:
      | project_name | <%= project.name %> |
      | image_name   | python              |
      | image_tag    | 3.4                 |
      | namespace    | <%= project.name %> |
      | app_name     | python-sample       |
      | source_url   | https://github.com/openshift/django-ex.git |
    Given I wait for the "python-sample" service to become ready
    And I wait for a server to become available via the "python-sample" route
    When I create a new project via web
    Then the step should succeed
    When I perform the :create_app_from_image_with_advanced_git_options web console action with:
      | project_name | <%= project.name %>   |
      | image_name   | python                |
      | image_tag    | 3.4                   |
      | namespace    | <%= @projects[0].name %> |
      | app_name     | python-sample-another |
      | source_url   | https://github.com/openshift/django-ex.git |
      | git_ref      | v1.0.1                |
      | context_dir  | :null                 |
    Then the step should succeed
    Given I wait for the "python-sample-another" service to become ready
    And I wait for a server to become available via the "python-sample-another" route
  
  # @author xxing@redhat.com
  # @case_id 470453
  Scenario: Create application from template with invalid parameters on web console
    When I create a new project via web
    Then the step should succeed
    Given I use the "<%= project.name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    When I perform the :create_app_from_template web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
      | label_key     | label1 |
      | label_value   | /%^&   |
    Then the step should fail
    When I get the html of the web page
    Then the output should contain:
      | Please enter a valid value|

  # @author xxing@redhat.com
  # @case_id 507521
  Scenario: Show help info and suggestions after creating app from web console
    When I create a new project via web
    Then the step should succeed
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>   |
      | image_name   | nodejs                |
      | image_tag    | 0.10                  |
      | namespace    | openshift             |
      | app_name     | nodejs-sample         |
      | source_url   | https://github.com/openshift/nodejs-ex |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | Command line tools  |
      | Making code changes |

  # @author wsun@redhat.com
  # @case_id 489286
  Scenario: Create the app with invalid name
    Given I login via web console
    Given I have a project
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | 0.10                                       |
      | namespace    | openshift                                  |
      | app_name     | nodejs-sample                              |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should succeed
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | 0.10                                       |
      | namespace    | openshift                                  |
      | app_name     | AA                                         |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should fail
    When I get the html of the web page
    Then the output should contain:
      | Please enter a valid name. |
      | A valid name is applied to all generated resources. It is an alphanumeric (a-z, and 0-9) string with a maximum length of 24 characters, where the first character is a letter (a-z), and the '-' character is allowed anywhere except the first or last character. |
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | 0.10                                       |
      | namespace    | openshift                                  |
      | app_name     | -test                                      |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should fail
    When I get the html of the web page
    Then the output should contain:
      | Please enter a valid name. |
      | A valid name is applied to all generated resources. It is an alphanumeric (a-z, and 0-9) string with a maximum length of 24 characters, where the first character is a letter (a-z), and the '-' character is allowed anywhere except the first or last character. |
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | 0.10                                       |
      | namespace    | openshift                                  |
      | app_name     | test-                                      |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should fail
    When I get the html of the web page
    Then the output should contain:
      | Please enter a valid name. |
      | A valid name is applied to all generated resources. It is an alphanumeric (a-z, and 0-9) string with a maximum length of 24 characters, where the first character is a letter (a-z), and the '-' character is allowed anywhere except the first or last character. |
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | 0.10                                       |
      | namespace    | openshift                                  |
      | app_name     | 123456789                                  |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should fail
    When I get the html of the web page
    Then the output should contain:
      | Please enter a valid name. |
      | A valid name is applied to all generated resources. It is an alphanumeric (a-z, and 0-9) string with a maximum length of 24 characters, where the first character is a letter (a-z), and the '-' character is allowed anywhere except the first or last character. |
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | 0.10                                       |
      | namespace    | openshift                                  |
      | app_name     | nodejs-sample                              |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should fail
    When I get the html of the web page
    Then the output should contain:
      | This name is already in use within the project. Please choose a different name. |


  # @author yanpzhan@redhat.com
  # @case_id 498145
  Scenario: Create app from template leaving empty parameters to be generated
    When I create a new project via web
    Then the step should succeed
    Given I use the "<%= project.name %>" project

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed

    When I perform the :create_app_from_template web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
      | label_key     | :null  |
      | label_value   | :null  |
    Then the step should succeed

    When I run the :env client command with:
      | resource | dc/frontend |
      | list     | true        |
    Then the step should succeed
    And the output should contain:
      |ADMIN_USERNAME=|
      |ADMIN_PASSWORD=|
      |MYSQL_USER=    |
      |MYSQL_PASSWORD=|
