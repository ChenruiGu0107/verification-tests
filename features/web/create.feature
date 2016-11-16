Feature: create app on web console related

  # @author xxing@redhat.com
  # @case_id 497608
  Scenario: create app from template with custom build on web console
    When I create a project via web with:
      | display_name | :null               |
      | description  ||
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json |
    Then the step should succeed
    When I perform the :create_app_from_template_with_label web console action with:
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
    When I perform the :check_one_build_inside_bc_page web console action with:
      | project_name      | <%= project.name %>                   |
      | bc_and_build_name | ruby-sample-build/ruby-sample-build-1 |
    Then the step should succeed
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
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
    Then the step should fail
    When I get the html of the web page
    Then the output should contain 3 times:
      | Cannot create |

  # @author xxing@redhat.com
  # @case_id 507527
  Scenario Outline: Create application from image on web console
    Given I have a project
    Given I wait for the :create_app_from_image_with_advanced_git_options web console action to succeed with:
      | project_name | <%= project.name %> |
      | image_name   | python              |
      | image_tag    | 3.4                 |
      | namespace    | openshift           |
      | app_name     | python-sample       |
      | source_url   | https://github.com/openshift/django-ex.git |
      | git_ref      | <git_ref>                |
      | context_dir  | :null                 |
    Given the "python-sample-1" build was created
    Given the "python-sample-1" build completed
    Given I wait for the "python-sample" service to become ready
    And I wait for a web server to become available via the "python-sample" route
    Examples:
      | git_ref |
      | :null   |
      | v1.0.1  |

  # @author xxing@redhat.com
  # @case_id 470453
  Scenario: Create application from template with invalid parameters on web console
    When I create a new project via web
    Then the step should succeed
    Given I use the "<%= project.name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    When I perform the :create_app_from_template_with_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
      | label_key     | /%^&   |
      | label_value   | value1 |
    Then the step should fail
    When I run the :confirm_errors_with_invalid_template_label web console action
    Then the step should succeed

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
    Given I have a project
    Given I use the "<%= project.name %>" project

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed

    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
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

  # @author wsun@redhat.com
  # @case_id 489294
  Scenario: Could edit Routing on create from source page
    When I create a new project via web
    Then the step should succeed
    When I perform the :create_app_without_route_action web console action with:
      | namespace    | openshift |
      | project_name | <%= project.name %> |
      | image_name   | python              |
      | image_tag    | 3.4                 |
      | app_name     | python-sample       |
      | source_url   | https://github.com/openshift/django-ex.git |
    Then the step should succeed
    When I perform the :check_empty_routes_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id 511644
  Scenario: Setting env vars for buildconfig on web can be available in assemble phase of STI build
    When I create a new project via web
    Then the step should succeed
    When I perform the :create_app_from_image_with_env_options web console action with:
      | namespace    | openshift |
      | project_name | <%= project.name %> |
      | image_name   | nodejs    |
      | image_tag    | 0.10      |
      | app_name     | nd        |
      | source_url   | https://github.com/yapei/nodejs-ex |
      | bc_env_key   | BCvalue |
      | bc_env_value | bcone   |
      | dc_env_key   | DCvalue |
      | dc_env_value | dcone   |
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | nd       |
      | build_status | running  |
    Then the step should succeed
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %> |
      | bc_and_build_name | nd/nd-1  |
      | build_status_name | Running  |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | Displaying ENV vars |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | BCvalue=bcone |
    Then the step should succeed
    Given I use the "<%= project.name %>" project
    And I run the :get client command with:
      | resource      | bc   |
      | resource_name | nd   |
      | o             | yaml |
    Then the step succeeded
    And the output by order should contain:
      | env |
      | name: BCvalue |
      | value: bcone  |
    When I run the :get client command with:
      | resource      | dc   |
      | resource_name | nd   |
      | o             | yaml |
    Then the step succeeded
    And the output by order should contain:
      | env |
      | name: DCvalue |
      | value: dcone  |

  # @author yapei@redhat.com
  # @case_id 515804
  Scenario: v1bata3 API version is not supported
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc515804/application-template-stibuild.json |
    Then the step should succeed
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
    Then the step should fail
    When I get the html of the web page
    Then the output should match:
      | API version v1beta3.* is not supported |

  # @author xiaocwan@redhat.com
  # @case_id 518663
  Scenario: Create resource from template contains fake api group
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    And I run oc create with "application-template-stibuild.json" replacing paths:
      | ["objects"][0]["apiVersion"] | fake/v1          |
    Then the step should succeed
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
    Then the step should fail
    When I get the html of the web page
    Then the output should match:
      | [Ff]ailed to create |
      |  annot create.*fake |

  # @author yanpzhan@redhat.com
  # @case_id 516702
  Scenario: Multiple ports can be shown and chosen on web console
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/tc516702.json |
    Then the step should succeed

    Given the "nodejs" image stream becomes ready

    When I perform the :check_port_on_create_page web console action with:
      | project_name | <%= project.name %> |
      | image_name   | nodejs              |
      | image_tag    | 0.10                |
      | namespace    | <%= project.name %> |
      | target_port  | 5858/TCP            |
    Then the step should succeed

    When I perform the :check_port_on_create_page web console action with:
      | project_name | <%= project.name %> |
      | image_name   | nodejs              |
      | image_tag    | 0.10                |
      | namespace    | <%= project.name %> |
      | target_port  | 8080/TCP            |
    Then the step should succeed

    When I perform the :create_app_from_image_with_port web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | 0.10                                       |
      | namespace    | <%= project.name %>                        |
      | app_name     | nodejs-test                                |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
      | target_port  | 8080/TCP                                   |
    Then the step should succeed

    When I perform the :check_target_port_on_routes_page web console action with:
      | project_name | <%= project.name %> |
      | target_port  | 8080-tcp            |
      | route_name   | nodejs-test         |
    Then the step should succeed

    When I perform the :check_target_port_on_services_page web console action with:
      | project_name | <%= project.name %> |
      | target_port  | 8080/TCP            |
      | service_name | nodejs-test         |
    Then the step should succeed

    When I perform the :check_target_port_on_services_page web console action with:
      | project_name | <%= project.name %> |
      | target_port  | 5858/TCP            |
      | service_name | nodejs-test         |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id 518662
  Scenario: Create resource from template contains different api groups
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/test-api.yaml |
    Then the step should succeed
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | test-api               |
      | namespace     | <%= project.name %>    |
      | param_one     | :null  |
      | param_two     | :null  |
      | param_three   | :null  |
      | param_four    | :null  |
      | param_five    | :null  |
    Then the step should succeed
    # check resources are created
    When I run the :get client command with:
      | resource | dc |
    Then the step should succeed
    And the output should contain:
      | php-apache |
    When I run the :get client command with:
      | resource | hpa |
    Then the step should succeed
    And the output should contain:
      | php-apache      |
      | test-autoscaler |
    When I run the :get client command with:
      | resource | job |
    Then the step should succeed
    And the output should contain:
      | simplev1 |

  # @author yapei@redhat.com
  # @case_id 478984
  @admin
  @destructive
  Scenario: Prompt info telling user to create a new project on console
    Given I create a new project
    When I run the :get client command with:
      | resource | project |
    Then the step should succeed
    And the output should contain:
      | <%= project.name %> |
      | Active              |
    Given cluster role "self-provisioner" is removed from the "system:authenticated:oauth" group
    When I perform the :check_help_info_when_user_have_no_permission web console action with:
      | openshift_command | oadm new-project <projectname> --admin=<%= user.name %> |
    Then the step should succeed
    When I perform the :check_policy_command web console action with:
      | openshift_command | oc policy add-role-to-user <role> <%= user.name %> -n <projectname> |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain:
      | New Project |
    When I perform the :new_project web console action with:
      | project_name | <%= rand_str(5, :dns) %> |
      | display_name | :null                    |
      | description  ||
    Then the step should fail
    When I perform the :check_error_notification_on_page web console action with:
      | error_message | You may not request a new project via this API |

  # @author yapei@redhat.com
  # @case_id 532281
  Scenario: Check template message on next step page
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/application-template-stibuild.json |
    Then the step should succeed
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | adminuser  |
      | param_two     | :null      |
      | param_three   | :null      |
      | param_four    | mysqlpass  |
      | param_five    | :null      |
    Then the step should succeed
    When I run the :check_template_message_on_next_page web console action
    Then the step should succeed
    When I run the :check_generated_parameter_on_next_page web console action
    Then the step should succeed
    When I run the :check_parameter_value web console action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id 530510
  Scenario: Deploy from ImageName on web console
    Given I have a project
    When I perform the :deploy_from_image_stream_name_with_nonexist_image web console action with:
      | project_name      | <%= project.name %> |
      | image_deploy_from | yapei/non-exist     |
    Then the step should succeed
    When I perform the :deploy_from_image_stream_name_with_env_label web console action with:
      | project_name          | <%= project.name %> |
      | image_deploy_from     | openshift/hello-openshift |
      | env_var_key           | myenv               |
      | env_var_value         | my-env-value        |
      | label_key             | mylabel             |
      | label_value           | my-hello-openshift  |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all |
    Then the step should succeed
    And the output should contain:
      | is/hello-openshift  |
      | dc/hello-openshift  |
      | svc/hello-openshift |
    When I run the :env client command with:
      | resource | dc/hello-openshift |
      | list     | true               |
    Then the step should succeed
    And the output should contain:
      | myenv=my-env-value |
    When I run the :get client command with:
      | resource   | is/hello-openshift |
      | show_label | true               |
    Then the step should succeed
    And the output should contain:
      | app=hello-openshift |
      | mylabel=my-hello-openshift |
    When I run the :get client command with:
      | resource   | svc/hello-openshift |
      | show_label | true                |
    Then the step should succeed
    And the output should contain:
      | app=hello-openshift |
      | mylabel=my-hello-openshift |

  # @author: yapei@redhat.com
  # @case_id: 530511
  Scenario: Deploy Image from ImageStreamTag on web console
    Given I have a project
    When I perform the :deploy_from_image_stream_tag_with_image_stream_more_than_24_chars web console action with:
      | project_name      | <%= project.name %> |
      | namespace         | openshift           |
      | image_stream_name | jboss-webserver30-tomcat8-openshift |
      | image_stream_tag  | latest              |
    Then the step should succeed
    When I perform the :check_deploy_image_name web console action with:
      | image_name | jboss-webserver30-tomcat |
    Then the step should succeed
    When I run the :submit_to_create web console action
    Then the step should succeed
    # check created resource
    When I run the :get client command with:
      | resource | all |
    Then the step should succeed
    And the output should contain:
      | dc/jboss-webserver30-tomcat  |
      | svc/jboss-webserver30-tomcat |
    When I perform the :deploy_from_image_stream_tag_with_normal_image_stream web console action with:
      | project_name      | <%= project.name %> |
      | namespace         | openshift           |
      | image_stream_name | python              |
      | image_stream_tag  | 3.4                 |
    Then the step should succeed
    When I perform the :check_deploy_image_name web console action with:
      | image_name | python |
    Then the step should succeed
    When I perform the :set_name_with_1_char web console action with:
      | new_deploy_image_name | a |
    Then the step should succeed
    When I perform the :set_name_with_invalid_chars web console action with:
      | new_deploy_image_name | a_b |
    Then the step should succeed
    When I perform the :set_name_to_blank web console action with:
      | new_deploy_image_name | :null |
    Then the step should succeed
    When I perform the :set_name_to_dash_started_string web console action with:
      | new_deploy_image_name | -ba |
    Then the step should succeed
    When I perform the :set_name_to_string_end_with_dash web console action with:
      | new_deploy_image_name | bca- |
    Then the step should succeed
    When I perform the :deploy_from_image_stream_tag_with_normal_is_and_change_name web console action with:
      | project_name          | <%= project.name %> |
      | namespace             | openshift           |
      | image_stream_name     | python              |
      | image_stream_tag      | 3.4                 |
      | new_deploy_image_name | python-dfi          |
      | image_name            | python-dfi          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all |
    Then the step should succeed
    And the output should contain:
      | dc/python-dfi   |
      | svc/python-dfi  |

  # @author etrott@redhat.com
  # @case_id 533201
  Scenario: Labels management in create app from template process on web console
    When I perform the :new_project web console action with:
      | project_name | <%= project.name %> |
      | display_name | test                |
      | description  | test                |
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    Then the step should succeed
    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                                       |
      | file_path        | <%= File.join(localhost.workdir, "application-template-stibuild.json") %> |
      | process_template | false                                                                     |
      | save_template    | true                                                                      |
    Then the step should succeed
    When I run the :get client command with:
      | resource | templates           |
      | n        | <%= project.name %> |
    Then the output should contain:
      | ruby-helloworld-sample |
    When I perform the :create_app_from_template_check_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | label_key     | test                   |
      | label_value   | 1234                   |
    Then the step should succeed
    When I perform the :add_new_label web console action with:
      | label_key   | testname  |
      | label_value | testvalue |
    Then the step should succeed
    When I perform the :edit_env_var_value web console action with:
      | env_variable_name | test        |
      | new_env_value     | 1234updated |
    Then the step should succeed
    When I perform the :delete_env_var web console action with:
      | env_var_key     | testname |
    Then the step should succeed
    When I get the "disabled" attribute of the "button" web element:
      | text | Create |
    Then the output should not contain "true"
    When I click the following "button" element:
      | text | Create |
    Then the step should succeed
    Given I wait until replicationController "frontend-1" is ready
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | all                 |
      | l        | test=1234updated    |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | bc/ruby-sample-build       |
      | builds/ruby-sample-build-1 |
      | is/origin-ruby-sample      |
      | is/ruby-22-centos7         |
      | dc/database                |
      | dc/frontend                |
      | rc/database-1              |
      | rc/frontend-1              |
      | routes/route-edge          |
      | svc/database               |
      | svc/frontend               |
    And the output should not contain:
      | po/ |
    """

  # @author etrott@redhat.com
  # @case_id 533199
  Scenario: Environment variables and label management in create app from image on web console
    When I perform the :new_project web console action with:
      | project_name | <%= project.name %> |
      | display_name | test                |
      | description  | test                |
    Then the step should succeed
    When I perform the :create_app_from_image_check_label web console action with:
      | project_name | <%= project.name %>                         |
      | image_name   | php                                         |
      | image_tag    | 5.5                                         |
      | namespace    | openshift                                   |
      | app_name     | php                                         |
      | source_url   | https://github.com/openshift/cakephp-ex.git |
      | git_ref      | :null                                       |
      | context_dir  | :null                                       |
      | bc_env_key   | BCkey1                                      |
      | bc_env_value | BCvalue1                                    |
      | dc_env_key   | DCkey1                                      |
      | dc_env_value | DCvalue1                                    |
      | label_key    | test1                                       |
      | label_value  | value1                                      |
    Then the step should succeed

    When I perform the :create_app_from_image_add_bc_env_vars web console action with:
      | bc_env_key   | BCkey2   |
      | bc_env_value | BCvalue2 |
    Then the step should succeed
    When I perform the :edit_env_var_value web console action with:
      | env_variable_name | BCkey1         |
      | new_env_value     | BCvalue1update |
    Then the step should succeed
    When I perform the :delete_env_var web console action with:
      | env_var_key | BCkey2 |
    Then the step should succeed

    When I perform the :create_app_from_image_add_dc_env_vars web console action with:
      | dc_env_key   | DCkey2   |
      | dc_env_value | DCvalue2 |
    Then the step should succeed
    When I perform the :create_app_from_image_add_dc_env_vars web console action with:
      | dc_env_key   | test3!#!   |
      | dc_env_value | testvalue3 |
    Then the step should succeed
    When I run the :confirm_errors_with_invalid_env_var web console action
    Then the step should succeed
    When I perform the :delete_env_var web console action with:
      | env_var_key | test3!#! |
    Then the step should succeed
    When I perform the :edit_env_var_value web console action with:
      | env_variable_name | DCkey2         |
      | new_env_value     | DCvalue2update |
    Then the step should succeed


    When I perform the :add_new_label web console action with:
      | label_key   | test2  |
      | label_value | value2 |
    Then the step should succeed
    When I perform the :add_new_label web console action with:
      | label_key   | test3!#! |
      | label_value | value3   |
    Then the step should succeed
    When I run the :confirm_errors_with_invalid_template_label web console action
    Then the step should succeed
    When I get the "disabled" attribute of the "button" web element:
      | text | Create |
    Then the output should contain "true"
    When I perform the :delete_env_var web console action with:
      | env_var_key | test3!#! |
    Then the step should succeed
    When I perform the :edit_env_var_value web console action with:
      | env_variable_name | test2        |
      | new_env_value     | value2update |
    Then the step should succeed

    When I run the :create_app_from_image_submit web console action
    Then the step should succeed

    When I perform the :check_buildconfig_environment web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | php                 |
      | env_var_key   | BCkey1              |
      | env_var_value | BCvalue1update      |
    Then the step should succeed

    When I perform the :check_build_environment web console action with:
      | project_name      | <%= project.name %> |
      | bc_and_build_name | php/php-1           |
      | env_var_key       | BCkey1              |
      | env_var_value     | BCvalue1update      |
    Then the step should succeed

    When I perform the :check_dc_environment web console action with:
      | project_name  | <%= project.name %> |
      | dc_name       | php                 |
      | env_var_key   | DCkey1              |
      | env_var_value | DCvalue1            |
    Then the step should succeed
    When I perform the :check_dc_environment web console action with:
      | project_name  | <%= project.name %> |
      | dc_name       | php                 |
      | env_var_key   | DCkey2              |
      | env_var_value | DCvalue2update      |
    Then the step should succeed

    When I perform the :manually_deploy web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | php                 |
    Then the step should succeed
    When I perform the :check_deployment_environment web console action with:
      | project_name  | <%= project.name %> |
      | dc_name       | php                 |
      | dc_number     | 1                   |
      | env_var_key   | DCkey1              |
      | env_var_value | DCvalue1            |
    Then the step should succeed
    When I perform the :check_deployment_environment web console action with:
      | project_name  | <%= project.name %> |
      | dc_name       | php                 |
      | dc_number     | 1                   |
      | env_var_key   | DCkey2              |
      | env_var_value | DCvalue2update      |
    Then the step should succeed

    Given a pod becomes ready with labels:
      | deploymentconfig=php |
    Then the step should succeed
    When I perform the :check_pod_environment web console action with:
      | project_name  | <%= project.name %> |
      | pod_name      | <%= pod.name %>     |
      | env_var_key   | DCkey1              |
      | env_var_value | DCvalue1            |
    Then the step should succeed
    When I perform the :check_pod_environment web console action with:
      | project_name  | <%= project.name %> |
      | pod_name      | <%= pod.name %>     |
      | env_var_key   | DCkey2              |
      | env_var_value | DCvalue2update      |
    Then the step should succeed

    When I run the :get client command with:
      | resource | all                 |
      | l        | test1=value1        |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | bc/php             |
      | builds/php-1       |
      | is/php             |
      | dc/php             |
      | rc/php-1           |
      | routes/php         |
      | svc/php            |
      | po/<%= pod.name %> |
