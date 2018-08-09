Feature: build related feature on web console

  # @author xxing@redhat.com
  # @case_id OCP-10627
  Scenario: Check the build information from web console
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/python:latest                    |
      | code         | https://github.com/openshift/django-ex.git |
      | name         | python-sample                              |
    Then the step should succeed
    When I perform the :check_one_buildconfig_page_with_build_op web console action with:
      | project_name            | <%= project.name %>                        |
      | bc_name                 | python-sample                              |
      | source_repo_url         | https://github.com/openshift/django-ex.git |
      | generic_webhook_trigger | /generic                                   |
      | github_webhook_trigger  | /github                                    |
    Then the step should succeed
    Given the "python-sample-1" build was created
    # wait for build finished is ok, does not nessarily to be completed
    Given the "python-sample-1" build finished
    When I perform the :check_one_build_inside_bc_page web console action with:
      | project_name            | <%= project.name %> |
      | bc_and_build_name       | python-sample/python-sample-1       |
    Then the step should succeed
    When I click the following "button" element:
      | text  | Rebuild |
      | class | btn-default |
    Then the step should succeed
    Given the "python-sample-2" build was created
    When I run the :check_rebuild_button web console action
    Then the step should succeed
    When I perform the :check_one_buildconfig_page web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | python-sample |
    Then the step should succeed
    And I get the html of the web page
    Then the output should contain:
      | #1 |
      | #2 |

  # @author xxing@redhat.com
  # @case_id OCP-10674
  Scenario: Cancel the New/Pending/Running build on web console
    Given I have a project
    # Delay build for robust cancel to avoid too quick image pushing via source code
    When I run the :new_app client command with:
      | app_repo      | ruby:latest~https://github.com/openshift-qe/v3-testfiles.git |
      | context_dir   | cases/OCP-10674/ruby-ex                                      |
      | name          | ruby-sample                                                  |
    Then the step should succeed
    When I perform the :cancel_build_from_pending_status web console action with:
      | project_name           | <%= project.name %>       |
      | bc_and_build_name      | ruby-sample/ruby-sample-1 |
    Then the step should succeed
    When I perform the :start_build_base_on_buildconfig web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | ruby-sample         |
    Then the step should succeed
    # Wait build to become running
    Given the "ruby-sample-2" build becomes :running
    When I perform the :cancel_build_from_running_status web console action with:
      | project_name           | <%= project.name %>       |
      | bc_and_build_name      | ruby-sample/ruby-sample-2 |
    Then the step should succeed
    Given I wait for the resource "pod" named "ruby-sample-2-build" to disappear
    When I perform the :check_pod_list_with_no_pod web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    # Make build failed by design
    When I run the :new_app client command with:
      | app_repo     | openshift/ruby:latest~https://github.com/openshift/fakerepo.git |
      | name         | ruby-sample-another                                             |
    Then the step should succeed
    Given the "ruby-sample-another-1" build failed
    When I perform the :check_one_build_inside_bc_page web console action with:
      | project_name           | <%= project.name %>                       |
      | bc_and_build_name      | ruby-sample-another/ruby-sample-another-1 |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not match:
      | >Cancel Build</button> |
    When I perform the :start_build_base_on_buildconfig web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | ruby-sample         |
    Then the step should succeed
    Given the "ruby-sample-3" build completed
    When I perform the :check_one_build_inside_bc_page web console action with:
      | project_name           | <%= project.name %>       |
      | bc_and_build_name      | ruby-sample/ruby-sample-3 |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not match:
      | >Cancel Build</button> |
    When I get project builds
    Then the output should match:
      | ruby-sample-1.+Cancelled      |
      | ruby-sample-2.+Cancelled      |
      | ruby-sample-3.+Complete       |
      | ruby-sample-another-1.+Failed |

  # @author yapei@redhat.com
  # @case_id OCP-12211
  Scenario: Negative test for modify buildconfig
    Given I have a project
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/ui/application-template-stibuild-without-customize-route.json"
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name  | <%= project.name %>  |
      | bc_name       | ruby-sample-build    |
      | build_status  | running              |
    Then the step should succeed
    # check source repo on Configuration tab
    When I perform the :check_buildconfig_source_repo web console action with:
      | project_name    | <%= project.name %>                           |
      | bc_name         | ruby-sample-build                             |
      | source_repo_url | https://github.com/openshift/ruby-hello-world |
    Then the step should succeed
    # change source repo on edit page and save the changes
    When I perform the :change_bc_source_repo_url web console action with:
      | project_name             | <%= project.name %> |
      | bc_name                  | ruby-sample-build   |
      | changing_source_repo_url | https://github.com/yapei/ruby-hello-world |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc                |
      | name     | ruby-sample-build |
    Then the output should match:
      | URL:\\s+https://github.com/yapei/ruby-hello-world |
    When I perform the :check_buildconfig_source_repo web console action with:
      | project_name    | <%= project.name %> |
      | bc_name         | ruby-sample-build   |
      | source_repo_url | https://github.com/yapei/ruby-hello-world |
    Then the step should succeed
    # change source repo on edit page, but cancel the update
    When I perform the :change_bc_source_repo_url web console action with:
      | project_name             | <%= project.name %> |
      | bc_name                  | ruby-sample-build   |
      | changing_source_repo_url | https://github.com/yapei/test-ruby-hello-world |
    Then the step should succeed
    When I run the :click_cancel web console action
    Then the step should succeed
    When I perform the :check_buildconfig_source_repo web console action with:
      | project_name    | <%= project.name %>  |
      | bc_name         | ruby-sample-build    |
      | source_repo_url | https://github.com/yapei/ruby-hello-world |
    Then the step should succeed
    # change source repo URL to invalid random character
    When I perform the :change_bc_source_repo_url web console action with:
      | project_name             | <%= project.name %>  |
      | bc_name                  | ruby-sample-build    |
      | changing_source_repo_url | iwio%##$7234         |
    Then the step should succeed
    When I run the :click_somewhere_out_of_focus web console action
    Then the step should succeed
    When I run the :check_invalid_url_warn_message web console action
    Then the step should succeed
    # edit bc via CLI before save changes on web console
    When I perform the :add_env_vars_on_buildconfig_edit_page web console action with:
      | project_name  | <%= project.name %>  |
      | bc_name       | ruby-sample-build    |
      | env_var_key   | testkey              |
      | env_var_value | testvalue            |
    Then the step should succeed
    When I run the :env client command with:
      | resource | bc/ruby-sample-build |
      | e        | key1=value1          |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :check_outdated_bc_warn_message web console action
    Then the step should succeed
    # delete bc before save changes on web console
    When I perform the :add_env_vars_on_buildconfig_edit_page web console action with:
      | project_name  | <%= project.name %>  |
      | bc_name       | ruby-sample-build    |
      | env_var_key   | testkey              |
      | env_var_value | testvalue            |
    Then the step should succeed
    When I run the :delete client command with:
      | object_name_or_id | bc/ruby-sample-build |
    Then the step should succeed
    When I run the :check_deleted_bc_warn_message web console action
    Then the step should succeed
    When I run the :check_buildconfig_edit_page_disabled web console action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-11944
  Scenario: Modify buildconfig for bc has ImageSource
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/image-source.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | bc               |
      | resource_name | imagedockerbuild |
      | o             | json             |
    Then the step should succeed
    Then the expression should be true> @result[:parsed]['spec']['source']['images'].length == 1
    When I run the :get client command with:
      | resource      | bc               |
      | resource_name | imagesourcebuild |
      | o             | json             |
    Then the step should succeed
    Then the expression should be true> @result[:parsed]['spec']['source']['images'].length == 2
    # check bc on web console
    When I perform the :count_buildconfig_image_paths web console action with:
      | project_name     | <%= project.name %>  |
      | bc_name          | imagedockerbuild     |
      | image_path_count | 1                    |
    Then the step should succeed
    When I perform the :count_buildconfig_image_paths web console action with:
      | project_name     | <%= project.name %>  |
      | bc_name          | imagesourcebuild     |
      | image_path_count | 2                    |
    Then the step should succeed
    # change bc
    When I perform the :add_bc_source_and_destination_paths web console action with:
      | project_name           | <%= project.name %> |
      | bc_name                | imagedockerbuild    |
      | image_source_from      | Image Stream Tag    |
      | image_source_namespace | openshift           |
      | image_source_is        | ruby                |
      | image_source_tag       | 2.2                 |
      | source_path            | /usr/bin/ruby       |
      | dest_dir               | user/test           |
    Then the step should succeed
    # for bc has more than one imagestream source, couldn't add
    When I perform the :check_buildconfig_edit_page_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | imagesourcebuild    |
    Then the step should succeed
    When I perform the :add_image_source_path web console action with:
      | source_path | /ust/test |
    Then the step should fail
    And the output should contain "element not found"
    # check image source via CLI
    When I run the :get client command with:
      | resource      | bc               |
      | resource_name | imagedockerbuild |
      | o             | json             |
    Then the step should succeed
    Then the expression should be true> @result[:parsed]['spec']['source']['images'][0]['paths'].length == 2

  # @author yapei@redhat.com
  # @case_id OCP-11773
  Scenario: Modify buildconfig settings for Dockerfile source
    Given I have a project
    When I run the :new_build client command with:
      | D     | FROM centos:7\nRUN yum install -y httpd |
      | to    | myappis                                 |
      | name  | myapp                                   |
    Then the step should succeed
    When I perform the :goto_buildconfig_configuration_tab web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
    Then the step should succeed
    When I perform the :check_build_strategy web console action with:
      | build_strategy      | Docker               |
    Then the step should succeed
    When I perform the :check_buildconfig_dockerfile_config web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
      | docker_file_content | FROM centos:7RUN yum install -y httpd |
    Then the step should succeed
    # edit bc webhook, will fail since Docker bc webhook is not configurable
    When I perform the :enable_webhook_build_trigger web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
    Then the step should fail
    # edit bc Dockerfile content
    When I perform the :edit_buildconfig_dockerfile_content web console action with:
      | project_name           | <%= project.name %>  |
      | bc_name                | myapp                |
      | content | FROM centos:7RUN yum update httpd |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_buildconfig_dockerfile_config web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
      | docker_file_content | FROM centos:7RUN yum update httpd |
    Then the step should succeed

  # @author pruan@redhat.com
  # @case_id OCP-10754
  Scenario: Check build trends chart when no buiilds under buildconfig
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sourcebuildconfig.json |
    Then the step should succeed
    When I perform the :check_empty_buildconfig_environment web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | source-build        |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | No builds. |
    And I click the following "button" element:
      | text  | Start Build           |
      | class | btn-default hidden-xs |
    Then the step should succeed
    When I run the :check_build_has_started_message web console action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-10774
  @admin
  Scenario: Modify buildconfig settings for custom strategy
    Given I create a new project
    When I run the :policy_add_role_to_user admin command with:
      | role            | system:build-strategy-custom |
      | user name       |   <%= user.name %>           |
      | n               |   <%= project.name %>        |
    Then the step should succeed
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json"
    Then the step should succeed
    When I run the :describe client command with:
      | resource      | bc/ruby-sample-build |
    Then the step should succeed
    And the output should match:
      | Strategy.*Custom  |
      | URL.*github.com/openshift/ruby-hello-world.git |
      | Image Reference.*ImageStreamTag   |
      | Triggered by.*ImageChange.*Config |
      | Webhook GitHub    |
      | Webhook Generic   |
    # check bc on web console
    When I perform the :goto_buildconfig_configuration_tab web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I perform the :check_build_strategy web console action with:
      | build_strategy | Custom               |
    Then the step should succeed
    When I perform the :check_bc_builder_image_stream web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
      | builder_image_streams | <%= project.name %>/origin-custom-docker-builder |
    Then the step should succeed
    When I perform the :check_buildconfig_source_repo web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
      | source_repo_url | github.com/openshift/ruby-hello-world |
    Then the step should succeed
    When I perform the :check_bc_output web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
      | bc_output      | <%= project.name %>/origin-ruby-sample:latest |
    Then the step should succeed
    When I perform the :check_bc_github_webhook_trigger web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
      | github_webhook_trigger | webhooks/secret101/github |
    Then the step should succeed
    When I perform the :check_bc_generic_webhook_trigger web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
      | generic_webhook_trigger | webhooks/secret101/generic |
    Then the step should succeed
    When I perform the :check_bc_image_change_trigger web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
      | image_change_trigger | <%= project.name %>/origin-custom-docker-builder:latest |
    Then the step should succeed
    When I perform the :check_bc_config_change_trigger web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
      | config_change_trigger | Build config ruby-sample-build |
    Then the step should succeed
    # edit bc
    When I perform the :edit_build_image_to_docker_image web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
      | docker_image_link | yapei-test/origin-ruby-sample:latest |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :set_force_pull_on_buildconfig_edit_page web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :change_env_vars_on_buildconfig_edit_page web console action with:
      | project_name      | <%= project.name %>               |
      | bc_name           | ruby-sample-build                 |
      | env_variable_name | OPENSHIFT_CUSTOM_BUILD_BASE_IMAGE |
      | new_env_value     | yapei-test-custom                 |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # check bc after made changes
    When I perform the :check_buildconfig_environment web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
      | env_var_key    | OPENSHIFT_CUSTOM_BUILD_BASE_IMAGE |
      | env_var_value  | yapei-test-custom    |
    Then the step should succeed
    When I perform the :check_bc_builder_image_stream web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
      | builder_image_streams | yapei-test/origin-ruby-sample:latest |
    When I run the :describe client command with:
      | resource | bc |
      | name     | ruby-sample-build |
    Then the output should match:
      | Force Pull.*yes |
      | Image Reference.*DockerImage\syapei-test/origin-ruby-sample:latest |

  # @author yapei@redhat.com
  # @case_id OCP-11232
  Scenario: Modify buildconfig settings for Docker strategy
    Given I create a new project
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-dockerbuild.json"
    Then the step should succeed
    When I run the :describe client command with:
      | resource      | bc/ruby-sample-build |
    Then the step should succeed
    And the output should match:
      | Strategy.*Docker  |
      | From Image.*ImageStreamTag        |
      | Triggered by.*ImageChange.*Config |
      | Webhook GitHub  |
      | Webhook Generic |
    # check bc on web console
    When I perform the :goto_buildconfig_configuration_tab web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I perform the :check_build_strategy web console action with:
      | build_strategy | Docker               |
    Then the step should succeed
    # edit bc
    When I perform the :toggle_bc_config_change web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :toggle_bc_image_change web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :toggle_bc_cache web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # check bc after make changes
    When I perform the :check_bc_image_change_trigger web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should fail
    When I perform the :check_bc_config_change_trigger_exist web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should fail
    When I run the :describe client command with:
      | resource      | bc/ruby-sample-build |
    Then the step should succeed
    And the output should not match:
      | Triggered by.*ImageChange.*Config |
    And the output should match:
      | No Cache.*true |

  # @author yapei@redhat.com
  # @case_id OCP-12058
  Scenario: Modify buildconfig settings for source strategy
    Given I create a new project
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:latest                    |
      | code         | https://github.com/openshift/ruby-ex.git |
      | name         | ruby-sample                              |
    Then the step should succeed
    When I run the :describe client command with:
      | resource      | bc/ruby-sample |
    Then the step should succeed
    And the output should match:
      | Strategy.*Source  |
      | URL.*https://github.com/openshift/ruby-ex.git |
      | Triggered by.*Config      |
      | Triggered by.*ImageChange |
      | Webhook GitHub  |
      | Webhook Generic |
    When I run the :tag client command with:
      | source_type  | docker |
      | source       | centos/ruby-22-centos7 |
      | dest         | mystream:latest |
    Then the step should succeed
    Given the "mystream" image stream becomes ready
    When I run the :get client command with:
      | resource      | istag |
      | resource_name | mystream:latest |
      | template      | {{.image.dockerImageReference}} |
    Then the step should succeed
    And evaluation of `@result[:response][0,38]` is stored in the :image_stream_image clipboard
    # check bc on web console
    When I perform the :goto_buildconfig_configuration_tab web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample          |
    Then the step should succeed
    When I perform the :check_build_strategy web console action with:
      | build_strategy | Source               |
    Then the step should succeed
    # edit bc
    When I perform the :change_bc_source_repo_url web console action with:
      | project_name             | <%= project.name %>                       |
      | bc_name                  | ruby-sample                               |
      | changing_source_repo_url | https://github.com/openshift/s2i-ruby.git |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :edit_bc_source_repo_ref web console action with:
      | project_name    | <%= project.name %>  |
      | bc_name         | ruby-sample          |
      | source_repo_ref | mfojtik-patch-1      |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :edit_bc_source_context_dir web console action with:
      | project_name       | <%= project.name %>  |
      | bc_name            | ruby-sample          |
      | source_context_dir | 2.2/test             |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :edit_build_image_to_image_stream_image web console action with:
      | project_name       | <%= project.name %>  |
      | bc_name            | ruby-sample          |
      | image_stream_image | <%= cb.image_stream_image %> |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    # check bc after make changes
    When I perform the :check_buildconfig_source_repo web console action with:
      | project_name    | <%= project.name %>                   |
      | bc_name         | ruby-sample                           |
      | source_repo_url | https://github.com/openshift/s2i-ruby |
    Then the step should succeed
    When I perform the :check_bc_source_ref web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-sample         |
      | source_ref   | mfojtik-patch-1     |
    Then the step should succeed
    When I perform the :check_bc_source_context_dir web console action with:
      | project_name       | <%= project.name %> |
      | bc_name            | ruby-sample         |
      | source_context_dir | 2.2/test            |
    Then the step should succeed
    When I run the :describe client command with:
      | resource      | bc/ruby-sample |
    Then the step should succeed
    And the output should match:
      | From Image.*ImageStreamImage.*<%= cb.image_stream_image %> |

  # @author yapei@redhat.com
  # @case_id OCP-11555
  Scenario: Modify buildconfig settings for Binary source
    Given the master version <= "3.3"
    Given I create a new project
    When I run the :new_build client command with:
      | binary | ruby |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc/ruby |
    Then the step should succeed
    And the output should match:
      | Strategy.*Source |
      | Binary.*on build |
    # change Binary Input
    When I perform the :edit_bc_binary_input web console action with:
      | project_name | <%= project.name %>  |
      | bc_name      | ruby                 |
      | bc_binary    | hello-world-ruby.zip |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc/ruby |
    Then the step should succeed
    And the output should match:
      | Binary.*provided as.*hello-world-ruby.zip.*on build |
    # add Env Vars
    When I perform the :add_env_vars_on_buildconfig_edit_page web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | ruby                |
      | env_var_key   | binarykey           |
      | env_var_value | binaryvalue         |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_buildconfig_environment web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | ruby                |
      | env_var_key   | binarykey           |
      | env_var_value | binaryvalue         |
    Then the step should succeed
    # for Binary build, there should be no webhook triggers
    When I perform the :enable_webhook_build_trigger web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby                |
    Then the step should fail
    And the output should contain "element not found"

  # @author yapei@redhat.com
  # @case_id OCP-12152
  Scenario: Modify buildconfig has DockerImage as build output
    Given I create a new project
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc518660/application-template-stibuild.json"
    Then the step should succeed
    When I run the :describe client command with:
      | resource      | bc/python-sample-build-sti |
    Then the step should succeed
    And the output should match:
      | Strategy.*Source  |
      | Output to.*DockerImage.*docker.io/aosqe/python-sample-sti:latest |
      | Push Secret.*sec-push |
    # check bc on web console
    When I perform the :check_bc_output web console action with:
      | project_name   | <%= project.name %>     |
      | bc_name        | python-sample-build-sti |
      | bc_output      | docker.io/aosqe/python-sample-sti:latest |
    Then the step should succeed
    # edit bc output image to another DockerImageLink
    When I perform the :change_bc_output_image_to_docker_image_link web console action with:
      | project_name             | <%= project.name %>     |
      | bc_name                  | python-sample-build-sti |
      | output_docker_image_link | docker.io/yapei/python-sample-test:latest |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_bc_output web console action with:
      | project_name   | <%= project.name %>     |
      | bc_name        | python-sample-build-sti |
      | bc_output      | docker.io/yapei/python-sample-test:latest |
    Then the step should succeed
    # change bc output image to ImageStreamTag
    When I perform the :change_bc_output_image_to_image_stream_tag web console action with:
      | project_name             | <%= project.name %>     |
      | bc_name                  | python-sample-build-sti |
      | output_image_namespace   | <%= project.name %>     |
      | output_image_is          | python-sample-sti       |
      | output_image_tag         | test                    |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_bc_output web console action with:
      | project_name   | <%= project.name %>     |
      | bc_name        | python-sample-build-sti |
      | bc_output      | <%= project.name %>/python-sample-sti:test |
    Then the step should succeed
    # change bc output image to None
    When I perform the :change_bc_output_image_to_none web console action with:
      | project_name      | <%= project.name %>     |
      | bc_name           | python-sample-build-sti |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_bc_output web console action with:
      | project_name   | <%= project.name %>     |
      | bc_name        | python-sample-build-sti |
      | bc_output      | None                    |
    Then the step should fail
    And the output should contain "element not found"

  # @author yanpzhan@redhat.com
  # @case_id OCP-11258
  Scenario: View build logs when build status are pending/running/complete/failed/cancelled from web console
    Given I have a project
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :new_build client command with:
      | code           | https://github.com/openshift/ruby-hello-world |
      | image_stream   | openshift/ruby                                |
    Then the step should succeed

    Given the "ruby-hello-world-1" build becomes :running
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>                 |
      | bc_and_build_name | ruby-hello-world/ruby-hello-world-1 |
      | build_status_name | Running                             |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | unning |
    Then the step should succeed

    #The "follow" click sometimes failed to show the "stop following" on 3.5, so add wait steps here
    And I wait for the steps to pass:
    """
    When I run the :follow_log web console action
    Then the step should succeed
    When I run the :stop_follow_log web console action
    Then the step should succeed
    """
    And I wait for the steps to pass:
    """
    When I run the :follow_log web console action
    Then the step should succeed
    When I run the :go_to_top_log web console action
    Then the step should succeed
    """

    Given the "ruby-hello-world-1" build becomes :complete
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>                 |
      | bc_and_build_name | ruby-hello-world/ruby-hello-world-1 |
      | build_status_name | Complete                            |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | uccessful |
    Then the step should succeed
    When I run the :go_to_end_log web console action
    Then the step should succeed
    When I run the :go_to_top_log web console action
    Then the step should succeed
    When I perform the :open_full_view_log web console action with:
      | log_context | uccessful |
    Then the step should succeed

    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-2 |
    Then the step should succeed
    Given the "ruby-hello-world-2" build becomes :cancelled
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>                 |
      | bc_and_build_name | ruby-hello-world/ruby-hello-world-2 |
      | build_status_name | Cancelled                           |
    Then the step should succeed
    When I perform the :check_no_log_info web console action with:
      | no_log_one | Logs are not available |
      | no_log_two | The logs are no longer available or could not be loaded |
    Then the step should succeed

    When I replace resource "bc" named "ruby-hello-world":
      | https://github.com/openshift/ruby-hello-world | https://github.com/openshift/nonexist |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    Given the "ruby-hello-world-3" build becomes :failed
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>                 |
      | bc_and_build_name | ruby-hello-world/ruby-hello-world-3 |
      | build_status_name | Failed                              |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | error: failed to fetch requested repository "https://github.com/openshift/nonexist |
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id OCP-12436
  Scenario: Check build trigger info when the trigger is ConfigChange on web
    Given I have a project
    When I run the :create client command with:
      | f    |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc528951/bc_configchange.yaml |
    Then the step should succeed

    Given the "ruby-ex-1" build was created
    When I perform the :check_build_trigger web console action with:
      | project_name      | <%= project.name %> |
      | bc_and_build_name | ruby-ex/ruby-ex-1   |
      | trigger_info      | Build configuration change |
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id OCP-12494
  Scenario: Check build trigger info when the trigger is ImageChange on web
    Given I have a project
    When I run the :create client command with:
      | f    | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc528954/bc_imagechange.yaml |
    Then the step should succeed
    Given the "ruby-ex-1" build was created within 120 seconds
    When I perform the :check_build_trigger web console action with:
      | project_name      | <%= project.name %> |
      | bc_and_build_name | ruby-ex/ruby-ex-1   |
      | trigger_info      | Image change for ruby-22-centos7:latest |
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id OCP-12499
  Scenario: Check build trigger info when the trigger is manual start-build on web
    Given I have a project
    When I run the :create client command with:
      | f    |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc528955/bc_no_trigger.yaml |
    Then the step should succeed

    When I perform the :start_build_base_on_buildconfig web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | ruby-ex             |
    Then the step should succeed

    Given the "ruby-ex-1" build was created
    When I perform the :check_build_trigger web console action with:
      | project_name      | <%= project.name %> |
      | bc_and_build_name | ruby-ex/ruby-ex-1   |
      | trigger_info      | Manual build        |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-10830
  @admin
  Scenario: Check settings for Custom strategy build with no inputs
    Given I have a project
    When I run the :policy_add_role_to_user admin command with:
      | role            | system:build-strategy-custom |
      | user name       |   <%= user.name %>           |
      | n               |   <%= project.name %>        |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc525737/application-template-custombuild.json |
    Then the step should succeed
    When I perform the :goto_buildconfig_configuration_tab web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I perform the :check_build_strategy web console action with:
      | build_strategy | Custom               |
    Then the step should succeed
    When I perform the :check_none_buildconfig_source_repo web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I perform the :check_info_for_no_source_on_edit_page web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain:
      | GitHub webhooks  |
      | Generic webhooks |

  # @author yapei@redhat.com
  # @case_id OCP-11269
  Scenario: Check settings for Source strategy build with no inputs
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc525738/application-template-stibuild.json"
    Then the step should succeed
    And I replace lines in "application-template-stibuild.json":
      | "host": "www.tc525738example.com", |      |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | application-template-stibuild.json |
    Then the step should succeed
    When I perform the :goto_buildconfig_configuration_tab web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I perform the :check_build_strategy web console action with:
      | build_strategy | Source               |
    Then the step should succeed
    When I perform the :check_none_buildconfig_source_repo web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I perform the :check_info_for_no_source_on_edit_page web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain:
      | GitHub webhooks  |
      | Generic webhooks |

  # @author etrott@redhat.com
  # @case_id OCP-10253
  Scenario: Check Build,Deployment,Pod logs and Events on Monitoring
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/nodejs:latest                |
      | code         | https://github.com/openshift/nodejs-ex |
      | name         | nodejs-app                             |
    Then the step should succeed
    Given the "nodejs-app-1" build becomes :running
    When I perform the :set_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | All                 |
    Then the step should succeed
    When I perform the :expand_resource_logs web console action with:
      | resource_type | Builds              |
      | resource_name | nodejs-app-1        |
    Then the step should succeed
    When I run the :open_in_new_window web console action
    Then the step should succeed
    Given the "nodejs-app-1" build finished
    Given I wait until the status of deployment "nodejs-app" becomes :complete
    When I run the :start_build client command with:
      | buildconfig | nodejs-app |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=nodejs-app-2 |
    Then the step should succeed
    When I perform the :click_on_hide_older_resources_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_resource_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Builds              |
      | resource_name | nodejs-app-1        |
    Then the step should succeed
    When I perform the :check_resource_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Builds              |
      | resource_name | nodejs-app-2        |
    Then the step should succeed
    When I perform the :check_resource_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Deployments         |
      | resource_name | nodejs-app-1        |
    Then the step should succeed
    When I perform the :check_resource_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Deployments         |
      | resource_name | nodejs-app-2        |
    Then the step should succeed
    When I perform the :check_resource_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Pods                |
      | resource_name | nodejs-app-1-build  |
    Then the step should succeed
    When I perform the :check_resource_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Pods                |
      | resource_name | nodejs-app-2-build  |
    Then the step should succeed
    When I run the :view_details_on_monitoring web console action
    Then the step should succeed
    Given the expression should be true> browser.url.end_with? "/browse/events"

    When I perform the :set_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Builds              |
    Then the step should succeed
    When I perform the :check_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Builds              |
    Then the step should succeed
    When I perform the :check_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Deployments         |
    Then the step should fail
    When I perform the :check_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Pods                |
    Then the step should fail

    When I perform the :set_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Deployments         |
    Then the step should succeed
    When I perform the :check_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Deployments         |
    Then the step should succeed
    When I perform the :check_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Builds              |
    Then the step should fail
    When I perform the :check_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Pods                |
    Then the step should fail

    When I perform the :set_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Pods                |
    Then the step should succeed
    When I perform the :check_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Pods                |
    Then the step should succeed
    When I perform the :check_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Builds              |
    Then the step should fail
    When I perform the :check_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Deployments         |
    Then the step should fail

    When I perform the :filter_by_name_on_monitoring web console action with:
      | project_name | <%= project.name %> |
      | filter_name  | nodejs              |
    Then the step should succeed
    When I perform the :check_resource_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Builds              |
      | resource_name | nodejs-app-2        |
    Then the step should succeed
    When I perform the :check_resource_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Deployments         |
      | resource_name | nodejs-app-2        |
    Then the step should succeed
    When I perform the :check_resource_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Pods                |
      | resource_name | <%= pod.name %>     |
    Then the step should succeed

    When I perform the :filter_by_name_on_monitoring web console action with:
      | project_name | <%= project.name %> |
      | filter_name  | test                |
    Then the step should succeed
    When I perform the :check_resource_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Builds              |
      | resource_name | nodejs-app-2        |
    Then the step should fail
    When I perform the :check_resource_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Deployments         |
      | resource_name | nodejs-app-2        |
    Then the step should fail
    When I perform the :check_resource_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Pods                |
      | resource_name | nodejs-app-2-build  |
    Then the step should fail

  # @author xxia@redhat.com
  # @case_id OCP-12476, OCP-12486
  Scenario Outline: Check build trigger info about webhook on web
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed

    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/<path><file>"
    And I replace lines in "<file>":
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051 | e79d8870be808a7abb4ab304e94c8bee69d909c6 |
      | <url_before>                             | <url_after>                              |
    Then the step should succeed

    # Wait build #1 is created first
    Given the "ruby-sample-build-1" build was created
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-sample-build/webhooks/secret101/<type>
    :method: post
    :headers:
      :content-type: application/json
      :<header1>: <header2>
    :payload: <%= File.read("<file>").to_json %>
    """
    Then the step should succeed

    # Check build #2
    Given the "ruby-sample-build-2" build was created
    When I perform the :check_build_trigger web console action with:
      | project_name      | <%= project.name %>                     |
      | bc_and_build_name | ruby-sample-build/ruby-sample-build-2   |
      | trigger_info      | <trigger_info>                          |
    Then the step should succeed

    When I perform the :check_build_hidden_secret web console action with:
      | project_name      | <%= project.name %>                     |
      | bc_and_build_name | ruby-sample-build/ruby-sample-build-2   |
      | hidden_text       | secr                                    |
    Then the step should succeed

    # Following checkpoint is only from the TC about generic webhook.
    # Because the script uses Examples Table, the TC about github webhook
    # has to also include it.
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-sample-build/webhooks/secret101/generic
    :method: post
    :headers:
      :content-type: application/json
    """
    Then the step should succeed

    # Check build #3
    Given the "ruby-sample-build-3" build was created
    When I perform the :check_build_trigger web console action with:
      | project_name      | <%= project.name %>                      |
      | bc_and_build_name | ruby-sample-build/ruby-sample-build-3    |
      | trigger_info      | Generic webhook: no revision information |
    Then the step should succeed

    Examples:
      # Check build trigger info when the trigger is generic webhook on web
      | type    | path              | file              | header1 | header2 | url_before                   | url_after                                       | trigger_info |
      | generic | generic/testdata/ | push-generic.json |         |         | git://mygitserver/myrepo.git | git://github.com/openshift/ruby-hello-world.git | Generic webhook: Random act of kindness e79d887 authored by Jon Doe |

    Examples:
      # Check build trigger info when the trigger is github webhook on web
      | type    | path              | file           | header1        | header2 | url_before | url_after | trigger_info |
      | github  | github/testdata/  | pushevent.json | X-Github-Event | push    |            |           | GitHub webhook: Added license e79d887 authored by Anonymous User |

  # @author yapei@redhat.com
  # @case_id OCP-10477
  Scenario: Check webhook URL are consistent
    Given I have a project
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/ui/application-template-stibuild-without-customize-route.json"
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc/ruby-sample-build |
    Then the step should succeed
    And evaluation of `URI::parse(@result[:response].scan(/https.*webhooks/)[0]).path + '/secret101/github'` is stored in the :github_webhook clipboard
    And evaluation of `URI::parse(@result[:response].scan(/https.*webhooks/)[0]).path + '/secret101/generic'` is stored in the :generic_webhook clipboard
    When I perform the :check_bc_github_webhook_trigger web console action with:
      | project_name           | <%= project.name %>      |
      | bc_name                | ruby-sample-build        |
      | github_webhook_trigger | <%= cb.github_webhook %> |
    Then the step should succeed
    When I perform the :check_bc_generic_webhook_trigger web console action with:
      | project_name            | <%= project.name %>        |
      | bc_name                 | ruby-sample-build          |
      | generic_webhook_trigger | <%= cb.generic_webhook %>  |
    Then the step should succeed
    When I perform the :check_bc_github_webhook_trigger_on_bc_edit_page web console action with:
      | project_name           | <%= project.name %>      |
      | bc_name                | ruby-sample-build        |
      | github_webhook_trigger | <%= cb.github_webhook %> |
    Then the step should succeed
    When I perform the :check_bc_generic_webhook_trigger_on_bc_edit_page web console action with:
      | project_name            | <%= project.name %>        |
      | bc_name                 | ruby-sample-build          |
      | generic_webhook_trigger | <%= cb.generic_webhook %>  |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-10286,OCP-11584,OCP-11277
  Scenario Outline: Check BC page when runPolicy set to Serial Parallel and SerialLatestOnly
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/build-postcommit.json"
    And I replace lines in "build-postcommit.json":
       | Parallel | <runpolicy> |
    Then the step should succeed
    When I run the :create client command with:
      | f | build-postcommit.json |
    Then the step should succeed
    When I perform the :check_bc_runpolicy web console action with:
      | project_name  | <%= project.name %>     |
      | bc_name       | ruby-ex                 |
      | run_policy    | <display_run_policy>    |
    Then the step should succeed
    When I perform the :goto_one_build_page web console action with:
      | project_name      | <%= project.name %> |
      | bc_and_build_name | ruby-ex             |
    Then the step should succeed

    ## need to trigger 2 new builds VERY VERY quickly!
    ## cli is slower than clicking button because of parsing response, so trigger from console first
    When I run the :click_start_build_button web console action
    And I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed

    # check build #1 and #2 together as soon as builds start up
    When I perform the :check_one_build_status web console action with:
      | number | 1                   |
      | status | <build1_status>     |
    Then the step should succeed
    When I perform the :check_one_build_status web console action with:
      | number | 2                   |
      | status | <build2_status>     |
    Then the step should succeed
    # check button enabled
    When I run the :click_start_build_button web console action
    Then the step should succeed
    When I run the :check_start_build_button_not_disabled web console action
    Then the step should succeed

    Examples:
      | runpolicy         | display_run_policy | build1_status   | build2_status |
      | Serial            | Serial             | Running         | New           |
      | Parallel          | Parallel           | Running         | Running       |
      | SerialLatestOnly  | Serial latest only | Cancelled       | Running       |

  # @author etrott@redhat.com
  # @case_id OCP-10891
  Scenario: Environment variables management for BC and DC
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | https://github.com/openshift/cakephp-ex.git |
      | name         | php                                         |
      | image_stream | openshift/php:latest                        |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | bc/php         |
      | e        | BCone=bcvalue1 |
      | e        | BCtwo=bcvalue2 |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | dc/php           |
      | e        | DCone=dcvalue1   |
      | e        | DCtwo=dcvalue2   |
      | e        | DCthree=dcvalue3 |
    Then the step should succeed

    When I perform the :check_buildconfig_environment web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | php                 |
      | env_var_key   | BCone               |
      | env_var_value | bcvalue1            |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | BCtwo    |
      | env_var_value | bcvalue2 |
    Then the step should succeed
    Given I perform the :add_env_vars_on_buildconfig_edit_page web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | php                 |
      | env_var_key   | BCthree             |
      | env_var_value | bcvalue3            |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | bc                                    |
      | resource_name | php                                   |
      | template      | {{.spec.strategy.sourceStrategy.env}} |
      | o             | json                                  |
    Then the step should succeed
    And expression should be true> @result[:parsed]["spec"]["strategy"]["sourceStrategy"]["env"].include?({"name"=>"BCthree", "value"=>"bcvalue3"})
    """
    When I perform the :check_buildconfig_environment web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | php                 |
      | env_var_key   | BCthree             |
      | env_var_value | bcvalue3            |
    Then the step should succeed
    Given I perform the :change_env_vars_on_buildconfig_edit_page web console action with:
      | project_name      | <%= project.name %> |
      | bc_name           | php                 |
      | env_variable_name | BCtwo               |
      | new_env_value     | bcvalueupdated      |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | bc                                    |
      | resource_name | php                                   |
      | template      | {{.spec.strategy.sourceStrategy.env}} |
      | o             | json                                  |
    Then the step should succeed
    And expression should be true> @result[:parsed]["spec"]["strategy"]["sourceStrategy"]["env"].include?({"name"=>"BCtwo", "value"=>"bcvalueupdated"})
    When I perform the :check_buildconfig_environment web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | php                 |
      | env_var_key   | BCtwo               |
      | env_var_value | bcvalueupdated      |
    Then the step should succeed

    When I perform the :check_dc_environment web console action with:
      | project_name  | <%= project.name %> |
      | dc_name       | php                 |
      | env_var_key   | DCone               |
      | env_var_value | dcvalue1            |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | DCtwo    |
      | env_var_value | dcvalue2 |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | DCthree  |
      | env_var_value | dcvalue3 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | deployment=php-1 |
#    When I perform the :reorder_environment_variable web console action with:
#      | env_variable_name | DCtwo |
#      | direction         | up    |
#      | offset            | 1     |
#    Then the step should succeed
#    When I run the :click_save_button web console action
#    Then the step should succeed
#    When I run the :get client command with:
#      | resource      | dc   |
#      | resource_name | php  |
#      | o             | json |
#    Then the step succeeded
#    And expression should be true> @result[:parsed]['spec']['template']['spec']['containers'][0]['env'].map {|var| var['name']} == ["DCtwo", "DCone", "DCthree"]
#    When I perform the :check_environment_variables_order web console action with:
#      | env_vars_order | DCtwo,DCone,DCthree |
#    Then the step should succeed
#    Given 1 pods become ready with labels:
#      | deployment=php-2 |
    When I perform the :delete_env_var web console action with:
      | env_var_key | DCone |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc   |
      | resource_name | php  |
      | o             | json |
    Then the step succeeded
    And expression should be true> @result[:parsed]['spec']['template']['spec']['containers'][0]['env'].map {|var| var['name']} == ["DCtwo", "DCthree"]
    When I perform the :check_env_var_missing web console action with:
      | env_var_key   | DCone    |
      | env_var_value | dcvalue1 |
    Then the step should succeed

    Given I perform the :add_env_vars_on_buildconfig_edit_page web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | php                 |
      | env_var_key   | BCname1             |
      | env_var_value | BCvalue1            |
    Then the step should succeed
    Given I run the :add_new_env_var web console action
    Then the step should succeed
    # ^$ will match empty string
    When I perform the :check_environment_variables_order web console action with:
      | env_vars_order | BCname1,^$ |
    Then the step should succeed
    Given I run the :add_new_env_var web console action
    Then the step should succeed
    When I perform the :check_environment_variables_order web console action with:
      | env_vars_order | BCname1,^$,^$ |
    Then the step should succeed
    Given I perform the :add_env_vars web console action with:
      | env_var_key   | BCname2  |
      | env_var_value | BCvalue2 |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | bc                                    |
      | resource_name | php                                   |
      | template      | {{.spec.strategy.sourceStrategy.env}} |
      | o             | json                                  |
    Then the step should succeed
    And expression should be true> @result[:parsed]["spec"]["strategy"]["sourceStrategy"]["env"].include?({"name"=>"BCname1", "value"=>"BCvalue1"})
    And expression should be true> @result[:parsed]["spec"]["strategy"]["sourceStrategy"]["env"].include?({"name"=>"BCname2", "value"=>"BCvalue2"})
    Given I perform the :check_bc_environment_variables_order web console action with:
      | project_name   | <%= project.name %>                 |
      | bc_name        | php                                 |
      | env_vars_order | BCone,BCtwo,BCthree,BCname1,BCname2 |
    Then the step should succeed

    When I perform the :goto_one_dc_environment_tab web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | php                 |
    Then the step should succeed
    Given I perform the :edit_env_var_key web console action with:
      | env_var_value | dcvalue2  |
      | new_env_key   | DCtwoname |
    Then the step should succeed
    When I perform the :check_environment_tab web console action with:
      | env_var_key   | DCtwoname |
      | env_var_value | dcvalue2  |
    Then the step should succeed
    Given I perform the :edit_env_var_key web console action with:
      | env_var_value | dcvalue3 |
      | new_env_key   | DCthree# |
    Then the step should succeed
    When I perform the :check_invalid_env_key_warning_message web console action with:
      | message | Please enter a valid key |
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-11029
  Scenario: Edit Pipeline bc on web console
    Given the master version >= "3.5"
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/samplepipeline.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed
    When I perform the :goto_pipeline_configuration_tab web console action with:
      | project_name  | <%= project.name %> |
      | pipeline_name | sample-pipeline     |
    Then the step should succeed
    When I run the :check_jenkinsfile_link web console action
    Then the step should succeed
    When I run the :close_jenkinsfile_modal_window web console action
    Then the step should succeed
    When I run the :click_to_goto_edit_page web console action
    Then the step should succeed
    When I run the :check_jenkinsfile_link web console action
    Then the step should succeed
    When I run the :copy_snippets_to_ace_editor web console action
    Then the step should succeed
    When I run the :hide_jenkinsfile_examples web console action
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :click_on_configuration_tab web console action
    Then the step should succeed
    When I perform the :check_ace_editor_content_has web console action with:
      | content | Promote to production |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-14629
  Scenario: Check Gitlab and Bitbucket webhooks in the BC editor
    Given the master version >= "3.6"
    Given I have a project
    When I run the :new_build client command with:
      | code         | https://github.com/openshift/ruby-hello-world |
      | image        | openshift/ruby:latest                         |
    Then the step should succeed
    Given I wait for the :add_webhook_type_on_bc_edit_page web console action to succeed with:
      | project_name  | <%= project.name %> |
      | bc_name       | ruby-hello-world    |
      | webhook_type  | GitLab              |
    When I run the :describe client command with:
      | resource | bc/ruby-hello-world |
    Then the step should succeed
    And evaluation of `@result[:response].scan(/https.*gitlab$/)` is stored in the :gitlab_webhook clipboard
    Given I wait for the :add_webhook_type_on_bc_edit_page web console action to succeed with:
      | project_name  | <%= project.name %> |
      | bc_name       | ruby-hello-world    |
      | webhook_type  | Bitbucket           |
    When I run the :describe client command with:
      | resource | bc/ruby-hello-world |
    Then the step should succeed
    And evaluation of `@result[:response].scan(/https.*bitbucket$/)` is stored in the :bitbucket_webhook clipboard
    # Check GitLab and Bitbucket webhook on web
    When I perform the :check_bc_webhook_trigger_in_configuration web console action with:
      | project_name    | <%= project.name %>                              |
      | bc_name         | ruby-hello-world                                 |
      | webhook_trigger | <%= cb.bitbucket_webhook[0].scan(/oapi.*/)[0] %> |
    Then the step should succeed
    When I perform the :check_bc_webhook_trigger_in_configuration web console action with:
      | project_name    | <%= project.name %>                            |
      | bc_name         | ruby-hello-world                               |
      | webhook_trigger | <%= cb.gitlab_webhook[0].scan(/oapi.*/)[0] %>  |
    Then the step should succeed
    When I perform the :check_bc_webhook_trigger_on_bc_edit_page web console action with:
      | project_name    | <%= project.name %>                              |
      | bc_name         | ruby-hello-world                                 |
      | webhook_trigger | <%= cb.bitbucket_webhook[0].scan(/oapi.*/)[0] %> |
    Then the step should succeed
    When I perform the :check_bc_webhook_trigger_on_bc_edit_page web console action with:
      | project_name    | <%= project.name %>                            |
      | bc_name         | ruby-hello-world                               |
      | webhook_trigger | <%= cb.gitlab_webhook[0].scan(/oapi.*/)[0] %>  |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-11417
  Scenario: Show build failure reason in build status for s2i build
    Given the master version >= "3.5"
    Given I have a project
    # Check failure reason for wrong source repo
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/OCP-11417/ruby22rhel7-template-sti-wrong-source.json |
    Then the step should succeed
    Given the "ruby22-sample-build-1" build finishes
    When I perform the :check_build_failure_reason_on_bc_page web console action with:
      | project_name         | <%= project.name %> |
      | bc_name              | ruby22-sample-build |
      | build_failure_reason | Fetch source failed |
    Then the step should succeed
    When I perform the :check_build_failure_reason_on_one_build_page web console action with:
      | project_name         | <%= project.name %>                       |
      | bc_and_build_name    | ruby22-sample-build/ruby22-sample-build-1 |
      | build_failure_reason | Failed to fetch the input source          |
    Then the step should succeed

    # Check failure reason for wrong scripts
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/OCP-11417/test-buildconfig-wrong-scripts.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build finishes
    When I perform the :check_build_failure_reason_on_monitoring web console action with:
      | project_name         | <%= project.name %>  |
      | build_failure_reason | Fetch scripts failed |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-11041
  Scenario: Show build failure reason in build status for docker build
    Given the master version >= "3.5"
    Given I have a project
    # Check failure reason for wrong post commit hooks
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/OCP-11417/ruby22rhel7-template-docker-wrong-post-commit.json |
    Then the step should succeed
    Given the "ruby22-sample-build-1" build finishes
    When I perform the :check_build_failure_reason_on_monitoring web console action with:
      | project_name         | <%= project.name %>     |
      | build_failure_reason | Post commit hook failed |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-17073
  Scenario: Support add ConfigMap/Secret as build env on web console
    Given the master version >= "3.9"
    Given I have a project
    # create configmap and secret
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.json          |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap-example.yaml  |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/secret.yaml               |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/tc519256/testsecret1.json |
    Then the step should succeed
    # check configmap/secret support during create app from image
    When I perform the :create_app_from_image_with_advanced_options web console action with:
      | primary_catagory | Languages  |
      | sub_catagory     | PHP        |
      | service_item     | PHP        |
      | app_name         | php-sample |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret_for_build web console action with:
      | env_var_key   | env_from_sec |
      | resource_name | test-secret  |
      | resource_key  | data-1       |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret_for_build web console action with:
      | env_var_key   | env_from_conmap |
      | resource_name | special-config  |
      | resource_key  | special.type    |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    When I perform the :goto_buildconfig_environment_tab web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | php-sample          |
    Then the step should succeed
    When I perform the :check_configmap_or_secret_env_var web console action with:
      | env_var_key   | env_from_sec  |
      | resource_name | test-secret   |
      | resource_key  | data-1        |
    Then the step should succeed
    When I perform the :check_configmap_or_secret_env_var web console action with:
      | env_var_key   | env_from_conmap |
      | resource_name | special-config  |
      | resource_key  | special.type    |
    Then the step should succeed
    # check configmap/secret support on buildconfig Environment tab
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | env_from_sec2 |
      | resource_name | test-secret   |
      | resource_key  | data-2        |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | env_from_conmap2 |
      | resource_name | special-config   |
      | resource_key  | special.type     |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    Given 5 seconds have passed
    # check configmap/secret support on buildconfig edit page
    When I perform the :check_buildconfig_edit_page_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | php-sample          |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | env_from_sec3 |
      | resource_name | testsecret1   |
      | resource_key  | secret1       |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | env_from_conmap3   |
      | resource_name | example-config     |
      | resource_key  | example.property.1 |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :goto_buildconfig_environment_tab web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | php-sample          |
    Then the step should succeed
    When I perform the :check_configmap_or_secret_env_var web console action with:
      | env_var_key   | env_from_sec3 |
      | resource_name | testsecret1   |
      | resource_key  | secret1       |
    Then the step should succeed
    When I perform the :check_configmap_or_secret_env_var web console action with:
      | env_var_key   | env_from_conmap3   |
      | resource_name | example-config     |
      | resource_key  | example.property.1 |
