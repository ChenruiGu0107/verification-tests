Feature: create app on web console related

  # @author xxing@redhat.com
  # @case_id OCP-9561
  Scenario: Create app from template containing invalid type on web console
    Given I have a project
    Given I use the "<%= project.name %>" project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    Given I replace resource "template" named "ruby-helloworld-sample" saving edit to "tempsti.json":
      | Service | Test |
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
    Then the step should fail
    When I get the html of the web page
    Then the output should match:
      | not (be )?create |

  # @author xxing@redhat.com
  # @case_id OCP-10691
  Scenario: Show help info and suggestions after creating app from web console
    Given I have a project
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>   |
      | image_name   | nodejs                |
      | image_tag    | 0.10                  |
      | namespace    | openshift             |
      | app_name     | nodejs-sample         |
      | source_url   | https://github.com/sclorg/nodejs-ex |
    Then the step should succeed
    When I run the :check_help_and_sug_on_next_step_page web console action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-9593
  Scenario: Create app from template leaving empty parameters to be generated
    Given I have a project
    Given I use the "<%= project.name %>" project

    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed

    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
    Then the step should succeed

    When I run the :set_env client command with:
      | resource | dc/frontend |
      | list     | true        |
    Then the step should succeed
    And the output should contain:
      | MYSQL_USER             |
      | MYSQL_PASSWORD         |
      | MYSQL_DATABASE         |

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
  # @case_id OCP-10737
  Scenario: Setting env vars for buildconfig on web can be available in assemble phase of STI build
    Given I have a project
    When I perform the :create_app_from_image web console action with:
      | namespace    | openshift                          |
      | project_name | <%= project.name %>                |
      | image_name   | nodejs                             |
      | image_tag    | 0.10                               |
      | app_name     | nd                                 |
      | source_url   | https://github.com/yapei/nodejs-ex |
      | bc_env_key   | BCvalue                            |
      | bc_env_value | bcone                              |
      | dc_env_key   | DCvalue                            |
      | dc_env_value | dcone                              |
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
  # @case_id OCP-10756
  Scenario: v1bata3 API version is not supported
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/tc515804/application-template-stibuild.json |
    Then the step should succeed
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
    Then the step should fail
    When I get the html of the web page
    Then the output should match:
      | API version v1beta3.* |

  # @author xiaocwan@redhat.com
  # @case_id OCP-11233
  Scenario: Create resource from template contains fake api group
    Given I have a project
    When I download a file from "<%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json"
    And I run oc create with "application-template-stibuild-without-customize-route.json" replacing paths:
      | ["objects"][0]["apiVersion"] | fake/v1          |
    Then the step should succeed
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
    Then the step should fail
    When I get the html of the web page
    Then the output should match:
      | not.*create.*fake/v1 |

  # @author yanpzhan@redhat.com
  # @case_id OCP-9794
  Scenario: Multiple ports can be shown and chosen on web console
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/image-streams/tc516702.json |
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
      | source_url   | https://github.com/sclorg/nodejs-ex.git |
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
  # @case_id OCP-10775
  Scenario: Create resource from template contains different api groups
    Given I create a new project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/test-api.yaml |
    Then the step should succeed
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | test-api               |
      | namespace     | <%= project.name %>    |
    Then the step should succeed
    # check resources are created
    When I run the :get client command with:
      | resource | dc,hpa,deployment,job |
    Then the step should succeed
    And the output should contain:
      | php-apache      |
      | test-autoscaler |
      | hello-openshift |
      | simplev1        |

  # @author yapei@redhat.com
  # @case_id OCP-11468
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
      | user_name | <%= user.name %> |
    Then the step should succeed
    When I perform the :check_policy_command web console action with:
      | openshift_command | oc policy add-role-to-user <role> <%= user.name %> -n <projectname> |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain:
      | New Project |
    When I perform the :new_project web console action with:
      | project_name | <%= rand_str(5, :dns) %> |
      | description  ||
    Then the step should fail
    When I perform the :check_error_notification_on_page web console action with:
      | error_message | You may not request a new project via this API |

  # @author yapei@redhat.com
  # @case_id OCP-10895
  Scenario: Check template message on next step page
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/application-template-stibuild.json |
    Then the step should succeed
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %>    |
      | template_name | ruby-helloworld-sample |
      | namespace     | <%= project.name %>    |
      | param_one     | adminuser  |
      | param_four    | mysqlpass  |
    Then the step should succeed
    When I run the :check_template_message_on_next_page web console action
    Then the step should succeed
    When I run the :check_generated_parameter_on_next_page web console action
    Then the step should succeed
    When I run the :check_parameter_value web console action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-10879
  @smoke
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
    And I wait until the status of deployment "hello-openshift" becomes :complete
    And I wait for the "hello-openshift" is to appear
    And I wait for the "hello-openshift" dc to appear
    And I wait for the "hello-openshift" svc to appear
    And a pod is present with labels:
      | mylabel=my-hello-openshift |
    When I run the :set_env client command with:
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

  # @author yapei@redhat.com
  # @case_id OCP-11301
  Scenario: Deploy Image from ImageStreamTag on web console
    Given I have a project
    When I perform the :deploy_from_image_stream_tag_with_image_stream_more_than_24_chars web console action with:
      | project_name      | <%= project.name %> |
      | namespace         | openshift           |
      | image_stream_name | jboss-webserver30-tomcat8-openshift |
    Then the step should succeed
    When I perform the :check_deploy_image_name web console action with:
      | image_name | jboss-webserver30-tomcat |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    # check created resource
    And I wait for the "jboss-webserver30-tomcat" service to appear
    And I wait for the "jboss-webserver30-tomcat" dc to appear
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
    And I wait for the "python-dfi" service to appear
    And I wait for the "python-dfi" dc to appear
    And a pod is present with labels:
      | deployment=python-dfi-1 |

  # @author etrott@redhat.com
  # @case_id OCP-11621
  Scenario: Labels management in create app from template process on web console
    Given I have a project
    When I download a file from "<%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json"
    Then the step should succeed
    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                                       |
      | file_path        | <%= localhost.absolutize("application-template-stibuild-without-customize-route.json") %> |
    And I wait for the steps to pass:
    """
    When I run the :click_create_button web console action
    Then the step should succeed
    When I perform the :process_and_save_template web console action with:
      | process_template | false |
      | save_template    | true  |
    Then the step should succeed
    """
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
    When I run the :click_create_button web console action
    Then the step should succeed
    Given I wait until replicationController "frontend-1" is ready
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | all                 |
      | l        | test=1234updated    |
      | n        | <%= project.name %> |
    And the output should match:
      | ruby-sample-build            |
      | ruby-sample-build-1          |
      | origin-ruby-sample           |
      | ruby-22-centos7              |
      | d[^ ]*c[^ ]*/database        |
      | d[^ ]*c[^ ]*/frontend        |
      | route-edge                   |
      | s[^ ]*v[^ ]*c[^ ]*/database  |
      | s[^ ]*v[^ ]*c[^ ]*/frontend  |
    And the output should not match:
      | po[^ ]*/ |
    """

  # @author etrott@redhat.com
  # @case_id OCP-11288
  Scenario: Add resources missing some required fields to project
    Given I have a project
    When I download a file from "<%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json"
    Then the step should succeed
    Given I backup the file "application-template-stibuild-without-customize-route.json"
    And I replace lines in "application-template-stibuild-without-customize-route.json":
      | "name": "ruby-helloworld-sample", | |
    Then the step should succeed
    When I perform the :create_from_template_file_with_error web console action with:
      | project_name     | <%= project.name %>                                                                       |
      | file_path        | <%= localhost.absolutize("application-template-stibuild-without-customize-route.json") %> |
      | error_message    | Resource name is missing in metadata field.                                               |
    Then the step should succeed

    Given I restore the file "application-template-stibuild-without-customize-route.json"
    And I replace lines in "application-template-stibuild-without-customize-route.json":
      | "uri": "https://github.com/openshift/ruby-hello-world.git" | |
    Then the step should succeed
    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                                                       |
      | file_path        | <%= localhost.absolutize("application-template-stibuild-without-customize-route.json") %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :click_create_button web console action
    Then the step should succeed
    When I perform the :process_and_save_template web console action with:
      | process_template | true  |
      | save_template    | false |
    Then the step should succeed
    """
    And I wait for the steps to pass:
    """
    When I run the :click_create_button web console action
    Then the step should succeed
    """
    When I run the :check_complete_with_error_info_on_next_page web console action
    Then the step should succeed
    When I perform the :check_error_alert_message_on_next_page web console action with:
      | message | Cannot create build config "ruby-sample-build" |
    Then the step should succeed
    When I perform the :check_error_alert_message_on_next_page web console action with:
      | message | spec.source.git.uri: Required value |
    Then the step should succeed

    When I download a file from "<%= BushSlicer::HOME %>/features/tierN/testdata/deployment/deployment1.json"
    Then the step should succeed
    Given I backup the file "deployment1.json"
    And I replace lines in "deployment1.json":
      | "name": "hooks", | |
    Then the step should succeed
    When I perform the :create_from_template_file_with_error web console action with:
      | project_name     | <%= project.name %>                                     |
      | file_path        | <%= File.join(localhost.workdir, "deployment1.json") %> |
      | error_message    | Resource name is missing in metadata field.             |
    Then the step should succeed

    Given I restore the file "deployment1.json"
    And I replace lines in "deployment1.json":
      | "apiVersion": "v1", | |
    Then the step should succeed
    When I perform the :create_from_template_file_with_error web console action with:
      | project_name     | <%= project.name %>                                     |
      | file_path        | <%= File.join(localhost.workdir, "deployment1.json") %> |
      | error_message    | Invalid kind (DeploymentConfig) or API version (<none>) |
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

  # @author etrott@redhat.com
  # @case_id OCP-11962
  Scenario: Replace current resource through Import YAML/JSON
    Given the master version >= "3.3"
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-dockerbuild.json"
    Then the step should succeed
    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                                          |
      | file_path        | <%= File.join(localhost.workdir, "application-template-dockerbuild.json") %> |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :click_create_button web console action
    Then the step should succeed
    When I perform the :process_and_save_template web console action with:
      | process_template | false |
      | save_template    | true  |
    Then the step should succeed
    """
    When I perform the :check_resource_succesfully_created_message web console action with:
      | resource | Template               |
      | name     | ruby-helloworld-sample |
    When I run the :get client command with:
      | resource | templates           |
      | n        | <%= project.name %> |
    Then the step should succeed
    Then the output should contain:
      | ruby-helloworld-sample |
    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                                          |
      | file_path        | <%= File.join(localhost.workdir, "application-template-dockerbuild.json") %> |
    Then the step should succeed
    When I perform the :patch_ace_editor_content web console action with:
      | content_type | JSON |
      | patch        | {"op":"replace","path":"/metadata/annotations/description","value":"This AAAAAA example shows how to create a simple ruby application in openshift origin v3"} |
    Then the step should succeed
    When I run the :click_cancel web console action
    Then the step should succeed
    When I perform the :check_resource_succesfully_updated_message_missing web console action with:
      | resource | Template               |
      | name     | ruby-helloworld-sample |
    When I run the :get client command with:
      | resource | templates           |
      | n        | <%= project.name %> |
    Then the step should succeed
    Then the output should not contain:
      | AAAAAA |
    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                                          |
      | file_path        | <%= File.join(localhost.workdir, "application-template-dockerbuild.json") %> |
    Then the step should succeed
    When I perform the :patch_ace_editor_content web console action with:
      | content_type | JSON |
      | patch        | {"op":"replace","path":"/metadata/annotations/description","value":"This AAAAAA example shows how to create a simple ruby application in openshift origin v3"} |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :click_create_button web console action
    Then the step should succeed
    When I perform the :process_and_update_template web console action with:
      | process_template | false |
      | update_template  | true  |
    Then the step should succeed
    """
    When I perform the :check_resource_succesfully_updated_message web console action with:
      | resource | Template               |
      | name     | ruby-helloworld-sample |
    When I run the :get client command with:
      | resource | templates           |
      | n        | <%= project.name %> |
    Then the step should succeed
    Then the output should contain:
      | AAAAAA |


  # @author hasha@redhat.com
  # @case_id OCP-11796
  Scenario: Add resources with unsupported format to project
    Given the master version >= "3.3"
    Given I have a project
    When I download a file from "<%= BushSlicer::HOME %>/features/tierN/testdata/pods/pod-with-probe.yaml"
    Then the step should succeed
    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                        |
      | file_path        | <%= File.join(localhost.workdir, "pod-with-probe.yaml") %> |
    Then the step should succeed
    When I perform the :patch_ace_editor_content web console action with:
      | content_type | YAML |
      | patch        | {"op":"replace","path":"/kind","value":"PodTest"} |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    When I perform the :check_error_message_on_create_fromfile web console action with:
      | error_message | The API version v1 for kind PodTest is not supported by this server |
    Then the step should succeed
    When I download a file from "<%= BushSlicer::HOME %>/features/tierN/testdata/registry/htpasswd"
    Then the step should succeed
    When I perform the :create_from_template_file web console action with:
      | project_name     | <%= project.name %>                                        |
      | file_path        | <%= File.join(localhost.workdir, "htpasswd") %> |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    When I perform the :check_error_message_on_create_fromfile web console action with:
      | error_message | Resource is missing kind field. |
    Then the step should succeed

