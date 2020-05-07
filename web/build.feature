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
