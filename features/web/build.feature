Feature: build related feature on web console

  # @author: xxing@redhat.com
  # @case_id: 482266
  Scenario: Check the build information from web console
    When I create a new project via web
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json |
    Then the step should succeed
    Given I wait for the :check_one_image_stream web console action to succeed with:
      | project_name | <%= project.name %> |
      | image_name   | python              |
    When I run the :get client command with:
      | resource | imageStream |
      | resource_name | python |
      | o        | json |
    Then the output should contain "openshift.io/image"
    Given I wait for the :create_app_from_image_change_bc_configchange web console action to succeed with:
      | project_name | <%= project.name %> |
      | image_name   | python              |
      | image_tag    | 3.3                 |
      | namespace    | <%= project.name %> |
      | app_name     | python-sample       |
      | source_url   | https://github.com/openshift/django-ex.git |
    When I perform the :check_one_buildconfig_page_with_build_op web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | python-sample |
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

  # @author: xxing@redhat.com
  # @case_id: 500940
  Scenario: Cancel the New/Pending/Running build on web console
    When I create a new project via web
    Then the step should succeed
    Given I wait for the :create_app_from_image web console action to succeed with:
      | project_name | <%= project.name %> |
      | image_name   | ruby                |
      | image_tag    | 2.2                 |
      | namespace    | openshift           |
      | app_name     | ruby-sample         |
      | source_url   | https://github.com/openshift/ruby-ex.git |
    When I perform the :cancel_build_from_pending_status web console action with:
      | project_name           | <%= project.name %>       |
      | bc_and_build_name      | ruby-sample/ruby-sample-1 |
    Then the step should succeed
    When I perform the :start_build_base_on_buildconfig web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | ruby-sample |
    Then the step should succeed
    # Wait build to become running
    Given the "ruby-sample-2" build becomes :running
    When I perform the :cancel_build_from_running_status web console action with:
      | project_name           | <%= project.name %> |
      | bc_and_build_name      | ruby-sample/ruby-sample-2 |
    Then the step should succeed
    Given I wait for the :check_pod_list_with_no_pod web console action to succeed with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    # Make build failed by design
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %> |
      | image_name   | ruby                |
      | image_tag    | 2.2                 |
      | namespace    | openshift           |
      | app_name     | ruby-sample-another |
      | source_url   | https://github.com/openshift/fakerepo.git |
    Then the step should succeed
    Given the "ruby-sample-another-1" build failed
    When I perform the :check_one_build_inside_bc_page web console action with:
      | project_name           | <%= project.name %> |
      | bc_and_build_name      | ruby-sample-another/ruby-sample-another-1 |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not match:
      | >Cancel Build</button> |
    When I perform the :start_build_base_on_buildconfig web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | ruby-sample |
    Then the step should succeed
    Given the "ruby-sample-3" build completed
    When I perform the :check_one_build_inside_bc_page web console action with:
      | project_name           | <%= project.name %> |
      | bc_and_build_name      | ruby-sample/ruby-sample-3 |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not match:
      | >Cancel Build</button> |
    When I get project builds
    Then the output by order should match:
      | ruby-sample-1.+Cancelled |
      | ruby-sample-2.+Cancelled |
      | ruby-sample-3.+Complete  |
      | ruby-sample-another-1.+Failed |

  # @author yapei@redhat.com
  # @case_id 518661
  Scenario: Negative test for modify buildconfig
    Given I have a project
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name  | <%= project.name %>  |
      | bc_name       | ruby-sample-build    |
      | build_status  | running              |
    Then the step should succeed
    # check source repo on Configuration tab
    When I perform the :check_buildconfig_source_repo web console action with:
      | project_name  | <%= project.name %>  |
      | bc_name       | ruby-sample-build    |
      | source_repo_url | https://github.com/openshift/ruby-hello-world |
    Then the step should succeed
    # change source repo on edit page and save the changes
    When I perform the :change_bc_source_repo_url web console action with:
      | project_name             | <%= project.name %> |
      | bc_name                  | ruby-sample-build   |
      | changing_source_repo_url | https://github.com/yapei/ruby-hello-world |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
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
    When I run the :cancel_buildconfig_changes web console action
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
    When I run the :save_buildconfig_changes web console action
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
    When I run the :save_buildconfig_changes web console action
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
    When I get the "disabled" attribute of the "button" web element:
      | text | Save |
    Then the output should contain "true"
    When I get the "disabled" attribute of the "element" web element:
      | xpath | //fieldset |
    Then the output should contain "true"

  # @author yapei@redhat.com
  # @case_id 518658
  Scenario: Modify buildconfig for bc has ImageSource
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/image-source.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | bc |
      | resource_name | imagedockerbuild |
      | o             | json             |
    Then the step should succeed
    Then the expression should be true> @result[:parsed]['spec']['source']['images'].length == 1
    When I run the :get client command with:
      | resource      | bc |
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
      | project_name     | <%= project.name %>  |
      | bc_name          | imagedockerbuild     |
      | image_source_from | Image Stream Tag    |
      | image_source_namespace | openshift      |
      | image_source_is | ruby |
      | image_source_tag | 2.2 |
      | source_path | /usr/bin/ruby |
      | dest_dir  | user/test |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    # for bc has more than one imagestream source, couldn't add
    When I perform the :check_buildconfig_edit_page_loaded_completely web console action with:
      | project_name | <%= project.name %>  |
      | bc_name      | imagesourcebuild     |
    Then the step should succeed
    When I perform the :choose_image_source_from web console action with:
      | image_source_from | Image Stream Tag |
    Then the step should fail
    And the output should contain "element not found"
    # check image source via CLI
    When I run the :get client command with:
      | resource      | bc |
      | resource_name | imagedockerbuild |
      | o             | json             |
    Then the step should succeed
    Then the expression should be true> @result[:parsed]['spec']['source']['images'][0]['paths'].length == 2

  # @author yapei@redhat.com
  # @case_id 518657
  Scenario: Modify buildconfig settings for Dockerfile source
    Given I have a project
    When I run the :new_build client command with:
      | D     | FROM centos:7\nRUN yum install -y httpd |
      | to    | myappis                                 |
      | name  | myapp                                   |
    Then the step should succeed
    When I perform the :check_build_strategy web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
      | build_strategy      | Docker               |
    Then the step should succeed
    When I perform the :check_buildconfig_dockerfile_config web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
      | docker_file_content | FROM centos:7RUN yum install -y httpd |
    Then the step should succeed
    # edit bc
    When I perform the :add_env_vars_on_buildconfig_edit_page web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
      | env_var_key         | dockertest           |
      | env_var_value       | docker1234           |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I perform the :add_env_vars_on_buildconfig_edit_page web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
      | env_var_key         | testname          |
      | env_var_value       | testvalue         |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I perform the :enable_webhook_build_trigger web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
    Then the step should fail
    # check env vars on web console
    When I perform the :check_buildconfig_environment web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
      | env_var_key         | dockertest           |
      | env_var_value       | docker1234           |
    Then the step should succeed
    When I perform the :check_buildconfig_environment web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
      | env_var_key         | testname          |
      | env_var_value       | testvalue         |
    Then the step should succeed
    # check env vars via CLI
    When I run the :get client command with:
      | resource      | bc    |
      | resource_name | myapp |
      | o             | json  |
    Then the step should succeed
    Then the expression should be true> @result[:parsed]['spec']['strategy']['dockerStrategy']['env'].include?({"name"=>"dockertest", "value"=>"docker1234"})
    Then the expression should be true> @result[:parsed]['spec']['strategy']['dockerStrategy']['env'].include?({"name"=>"testname", "value"=>"testvalue"})
    # remove env vars
    When I perform the :delete_env_vars_on_buildconfig_edit_page web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
      | env_var_key         | dockertest           |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I perform the :check_buildconfig_environment web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
      | env_var_key         | testname             |
      | env_var_value       | testvalue            |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | dockertest |
      | docker1234 |
    When I perform the :delete_env_vars_on_buildconfig_edit_page web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
      | env_var_key         | testname             |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    # check env vars again
    When I perform the :check_empty_buildconfig_environment web console action with:
      | project_name        | <%= project.name %>  |
      | bc_name             | myapp                |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | bc    |
      | resource_name | myapp |
      | o             | json  |
    Then the step should succeed
    And the output should not contain:
      | dockertest |
      | testname   |

  # @author pruan@redhat.com
  # @case_id 515770
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
  # @case_id 518654
  Scenario: Modify buildconfig settings for custom strategy
    Given I create a new project
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json"
    Then the step should succeed
    When I run the :describe client command with:
      | resource      | bc/ruby-sample-build |
    Then the step should succeed
    And the output should match:
      | Strategy.*Custom  |
      | URL.*git://github.com/openshift/ruby-hello-world.git |
      | Image Reference.*ImageStreamTag   |
      | Triggered by.*ImageChange.*Config |
      | Webhook GitHub    |
      | Webhook Generic   |
    # check bc on web console
    When I perform the :check_build_strategy web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
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
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I perform the :set_force_pull_on_buildconfig_edit_page web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I perform the :change_env_vars_on_buildconfig_edit_page web console action with:
      | project_name      | <%= project.name %>               |
      | bc_name           | ruby-sample-build                 |
      | env_variable_name | OPENSHIFT_CUSTOM_BUILD_BASE_IMAGE |
      | new_env_value     | yapei-test-custom                 |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
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
  # @case_id 518655
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
    When I perform the :check_build_strategy web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
      | build_strategy | Docker               |
    Then the step should succeed
    # edit bc
    When I perform the :toggle_bc_config_change web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I perform the :toggle_bc_image_change web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I perform the :toggle_bc_cache web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
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
  # @case_id 518659
  Scenario: Modify buildconfig settings for source strategy
    Given I create a new project
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %> |
      | image_name   | ruby                |
      | image_tag    | 2.2                 |
      | namespace    | openshift           |
      | app_name     | ruby-sample         |
      | source_url   | https://github.com/openshift/ruby-ex.git |
    Then the step should succeed
    When I run the :describe client command with:
      | resource      | bc/ruby-sample |
    Then the step should succeed
    And the output should match:
      | Strategy.*Source  |
      | URL.*https://github.com/openshift/ruby-ex.git |
      | Triggered by.*ImageChange.*Config |
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
    When I perform the :check_build_strategy web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample          |
      | build_strategy | Source               |
    Then the step should succeed
    # edit bc
    When I perform the :change_bc_source_repo_url web console action with:
      | project_name    | <%= project.name %>  |
      | bc_name         | ruby-sample          |
      | changing_source_repo_url | https://github.com/openshift/s2i-ruby.git |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I perform the :edit_bc_source_repo_ref web console action with:
      | project_name    | <%= project.name %>  |
      | bc_name         | ruby-sample          |
      | source_repo_ref | mfojtik-patch-1      |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I perform the :edit_bc_source_context_dir web console action with:
      | project_name       | <%= project.name %>  |
      | bc_name            | ruby-sample          |
      | source_context_dir | 2.2/test             |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I perform the :edit_build_image_to_image_stream_image web console action with:
      | project_name       | <%= project.name %>  |
      | bc_name            | ruby-sample          |
      | image_stream_image | <%= cb.image_stream_image %> |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    # check bc after make changes
    When I perform the :check_buildconfig_source_repo web console action with:
      | project_name       | <%= project.name %>  |
      | bc_name            | ruby-sample          |
      | source_repo_url    | https://github.com/openshift/s2i-ruby |
    Then the step should succeed
    When I perform the :check_bc_source_ref web console action with:
      | project_name       | <%= project.name %>  |
      | bc_name            | ruby-sample          |
      | source_ref         | mfojtik-patch-1      |
    Then the step should succeed
    When I perform the :check_bc_source_context_dir web console action with:
      | project_name       | <%= project.name %>  |
      | bc_name            | ruby-sample          |
      | source_context_dir | 2.2/test             |
    Then the step should succeed
    When I run the :describe client command with:
      | resource      | bc/ruby-sample |
    Then the step should succeed
    And the output should match:
      | From Image.*ImageStreamImage.*<%= cb.image_stream_image %> |

  # @author yapei@redhat.com
  # @case_id 518656
  Scenario: Modify buildconfig settings for Binary source
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
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby                 |
      | bc_binary      | hello-world-ruby.zip |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc/ruby |
    Then the step should succeed
    And the output should match:
      | Binary.*provided as.*hello-world-ruby.zip.*on build |
    # add Env Vars
    When I perform the :add_env_vars_on_buildconfig_edit_page web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby                 |
      | env_var_key    | binarykey            |
      | env_var_value  | binaryvalue          |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I perform the :check_buildconfig_environment web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby                 |
      | env_var_key    | binarykey            |
      | env_var_value  | binaryvalue          |
    Then the step should succeed
    # for Binary build, there should be no webhook triggers
    When I perform the :enable_webhook_build_trigger web console action with:
      | project_name  | <%= project.name %>  |
      | bc_name       | ruby                 |
    Then the step should fail
    And the output should contain "element not found"

  # @author yapei@redhat.com
  # @case_id 518660
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
    When I run the :save_buildconfig_changes web console action
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
    When I run the :save_buildconfig_changes web console action
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
    When I run the :save_buildconfig_changes web console action
    Then the step should succeed
    When I perform the :check_bc_output web console action with:
      | project_name   | <%= project.name %>     |
      | bc_name        | python-sample-build-sti |
      | bc_output      | None                    |
    Then the step should fail
    And the output should contain "element not found"

  # @author yanpzhan@redhat.com
  # @case_id 521466
  Scenario: View build logs when build status are pending/running/complete/failed/cancelled from web console
    When I create a new project via web
    Then the step should succeed
    When I run the :new_build client command with:
      | code           | https://github.com/openshift/ruby-hello-world |
      | image_stream   | openshift/ruby                                |
    Then the step should succeed

# Since pending status is hard to catch, consider to move this check to
# another manual case.
#    When I perform the :check_build_log_tab web console action with:
#      | project_name      | <%= project.name %> |
#      | bc_and_build_name | ruby-hello-world/ruby-hello-world-1 |
#      | build_status_name | Pending             |
#    Then the step should succeed

    Given the "ruby-hello-world-1" build becomes :running
    When I perform the :check_build_log_tab web console action with:
      | project_name   | <%= project.name %> |
      | bc_and_build_name | ruby-hello-world/ruby-hello-world-1 |
      | build_status_name | Running             |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | unning |
    Then the step should succeed

    When I run the :follow_log web console action
    Then the step should succeed
    When I run the :stop_follow_log web console action
    Then the step should succeed
    When I run the :follow_log web console action
    Then the step should succeed
    When I run the :go_to_top_log web console action
    Then the step should succeed

    Given the "ruby-hello-world-1" build becomes :complete
    When I perform the :check_build_log_tab web console action with:
      | project_name   | <%= project.name %> |
      | bc_and_build_name | ruby-hello-world/ruby-hello-world-1 |
      | build_status_name | Complete             |
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
      | project_name   | <%= project.name %> |
      | bc_and_build_name | ruby-hello-world/ruby-hello-world-2 |
      | build_status_name | Cancelled             |
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
      | project_name   | <%= project.name %> |
      | bc_and_build_name | ruby-hello-world/ruby-hello-world-3 |
      | build_status_name | Failed             |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | error: failed to fetch requested repository "https://github.com/openshift/nonexist" |
    Then the step should succeed

  # @author: xxia@redhat.com
  # @case_id: 528951
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

  # @author: xxia@redhat.com
  # @case_id: 528954
  Scenario: Check build trigger info when the trigger is ImageChange on web
    Given I have a project
    When I run the :create client command with:
      | f    | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc528954/bc_imagechange.yaml |
    Then the step should succeed

    Given the "ruby-ex-1" build was created
    When I perform the :check_build_trigger web console action with:
      | project_name      | <%= project.name %> |
      | bc_and_build_name | ruby-ex/ruby-ex-1   |
      | trigger_info      | Image change for ruby-22-centos7:latest |
    Then the step should succeed

  # @author: xxia@redhat.com
  # @case_id: 528955
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

  # @author: yapei@redhat.com
  # @case_id 525737 525738
  Scenario Outline: Check settings for build with no inputs
    Given I have a project
    When I run the :new_app client command with:
      | file | <template_file> |
    Then the step should succeed
    When I perform the :check_build_strategy web console action with:
      | project_name   | <%= project.name %>  |
      | bc_name        | ruby-sample-build    |
      | build_strategy | <build_strategy>     |
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
    Examples:
      | template_file | build_strategy |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc525737/application-template-custombuild.json | Custom |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc525738/application-template-stibuild.json    | Source |
