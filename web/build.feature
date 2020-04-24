Feature: build related feature on web console
  # @author yapei@redhat.com
  # @case_id OCP-12211
  Scenario: Negative test for modify buildconfig
    Given I have a project
    When I process and create "<%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json"
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
    When I run the :set_env client command with:
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/image-streams/image-source.yaml |
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
      | code         | https://github.com/sclorg/ruby-ex.git |
      | name         | ruby-sample                              |
    Then the step should succeed
    When I run the :describe client command with:
      | resource      | bc/ruby-sample |
    Then the step should succeed
    And the output should match:
      | Strategy.*Source  |
      | URL.*https://github.com/sclorg/ruby-ex.git |
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
    When I process and create "<%= BushSlicer::HOME %>/features/tierN/testdata/templates/tc518660/application-template-stibuild.json"
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
      | f    |  <%= BushSlicer::HOME %>/features/tierN/testdata/build/tc528951/bc_configchange.yaml |
    Then the step should succeed

    Given the "ruby-ex-1" build was created
    When I perform the :check_build_trigger web console action with:
      | project_name      | <%= project.name %> |
      | bc_and_build_name | ruby-ex/ruby-ex-1   |
      | trigger_info      | Build configuration change |
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id OCP-12499
  Scenario: Check build trigger info when the trigger is manual start-build on web
    Given I have a project
    When I run the :create client command with:
      | f    |  <%= BushSlicer::HOME %>/features/tierN/testdata/build/tc528955/bc_no_trigger.yaml |
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
  # @case_id OCP-11269
  Scenario: Check settings for Source strategy build with no inputs
    Given I have a project
    When I obtain test data file "templates/tc525738/application-template-stibuild.json"
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

  # @author xxia@redhat.com
  # @case_id OCP-12476, OCP-12486
  Scenario Outline: Check build trigger info about webhook on web
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
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
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/OCP-11417/ruby22rhel7-template-sti-wrong-source.json |
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/OCP-11417/test-buildconfig-wrong-scripts.json |
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
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/OCP-11417/ruby22rhel7-template-docker-wrong-post-commit.json |
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap.json          |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap-example.yaml  |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/secret.yaml               |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/tc519256/testsecret1.json |
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
