Feature: bc/dc hooks related

  # @author xxing@redhat.com
  # @case_id OCP-11652
  Scenario: pre/mid/post deployment hooks handling for DC on web console
    Given the master version >= "3.4"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/Recreate-dc-with-prehook.json |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/image-streams/simple-is.json             |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
    When I perform the :goto_edit_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks          |
    Then the step should succeed
    When I run the :check_dc_recreate_strategy_default_settings web console action
    Then the step should succeed
    When I run the :click_to_show_dc_advanced_strategy_options web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | hooks            |
      | o             | yaml             |
    Then the step should succeed
    Given evaluation of `@result[:parsed]["spec"]["strategy"]["recreateParams"]["pre"]` is stored in the :pre_setting clipboard
    When I perform the :check_dc_exec_new_pod_hook_setting web console action with:
      | hook_type           | pre                                                  |
      | container_name      | <%= cb.pre_setting["execNewPod"]["containerName"] %> |
      | command             | <%= cb.pre_setting["execNewPod"]["command"][0] %>    |
      | failure_policy      | <%= cb.pre_setting["failurePolicy"] %>               |
    Then the step should succeed
    # Modify pre-hook
    When I perform the :add_dc_hook_command web console action with:
      | hook_type           | pre                |
      | hook_cmd            | /bin/true          |
    Then the step should succeed
    When I perform the :select_dc_hook_failure_policy web console action with:
      | hook_type           | pre                |
      | failure_policy      | Retry              |
    Then the step should succeed
    # Add mid-hook
    When I perform the :click_add_lifecycle_hook web console action with:
      | hook_type | mid |
    Then the step should succeed
    When I perform the :set_lifecycle_newpod_hook_action web console action with:
      | hook_type | mid |
    Then the step should succeed
    When I run the :check_dc_pod_based_lifecycle_hook_doc_link web console action
    Then the step should succeed
    When I perform the :add_dc_hook_command web console action with:
      | hook_type           | mid                |
      | hook_cmd            | /bin/false         |
    Then the step should succeed
    When I perform the :select_dc_hook_failure_policy web console action with:
      | hook_type           | mid                |
      | failure_policy      | Abort              |
    Then the step should succeed
    # Add post-hook
    When I perform the :click_add_lifecycle_hook web console action with:
      | hook_type | post |
    Then the step should succeed
    When I perform the :set_lifecycle_images_hook_action web console action with:
      | hook_type | post |
    Then the step should succeed 
    When I perform the :set_dc_hook_tag_as web console action with:
      | hook_type           | post                |
      | image_stream        | hello-openshift     |
      | istag               | test                |
    Then the step should succeed
    When I perform the :select_dc_hook_failure_policy web console action with:
      | hook_type           | post                |
      | failure_policy      | Ignore              |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
    When I run the :describe client command with:
      | resource | deploymentConfig |
      | name     | hooks            |
    Then the step should succeed
    And the output should match:
      | [Pp]re.+pod\s+type.+Retry     |
      | [Mm]id.+pod\s+type.+Abort     |
      | [Pp]ost.+tag\s+images.+Ignore |
    When I run the :click_to_goto_edit_page web console action
    Then the step should succeed
    When I run the :click_to_show_dc_advanced_strategy_options web console action
    Then the step should succeed
    When I perform the :click_remove_dc_lifecycle_hook web console action with:
      | hook_type | mid |
    Then the step should succeed
    When I perform the :set_dc_hook_command web console action with:
      | hook_type           | pre                |
      | hook_cmd            | /bin/false         |
    Then the step should succeed
    When I run the :click_to_hide_dc_advanced_strategy_options web console action
    Then the step should succeed
    When I run the :click_to_show_dc_advanced_strategy_options web console action
    Then the step should succeed
    When I perform the :set_lifecycle_newpod_hook_action web console action with:
      | hook_type | mid |
    Then the step should fail
    When I perform the :check_dc_hook_newpod_command web console action with:
      | command | /bin/false |
    Then the step should fail
    When I run the :click_save_button web console action
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
    When I run the :describe client command with:
      | resource | deploymentConfig |
      | name     | hooks            |
    Then the step should succeed
    And the output should match:
      | [Pp]re.+pod\s+type.+Retry     |
      | [Pp]ost.+tag\s+images.+Ignore |
    And the output should not match:
      | [Mm]id.+hook |

  # @author yanpzhan@redhat.com
  # @case_id OCP-11412
  Scenario: Show hooks of rolling strategy DC
    Given the master version > "3.4"
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed

    When I perform the :check_dc_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | frontend            |
    Then the step should succeed
    When I perform the :check_dc_hook_common_settings_from_dc_page web console action with:
      | hook_type      | pre             |
      | hook_name      | Pre Hook        |
      | hook_action    | Run a command   |
      | failure_policy | Abort           |
      | container_name | ruby-helloworld |
    Then the step should succeed

    When I perform the :check_dc_hook_common_settings_from_dc_page web console action with:
      | hook_type      | post            |
      | hook_name      | Post Hook       |
      | hook_action    | Run a command   |
      | failure_policy | Ignore          |
      | container_name | ruby-helloworld |
    Then the step should succeed

    When I run the :patch client command with:
      | resource      | dc               |
      | resource_name | frontend         |
      | p             | {"spec":{"strategy":{"rollingParams":{"pre":null}}}} |
    Then the step should succeed
    When I perform the :check_dc_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | frontend            |
    Then the step should succeed
    When I perform the :check_dc_hook_missing_from_dc_page web console action with:
      | hook_type | pre      |
      | hook_name | Pre Hook |
    Then the step should succeed

    When I run the :patch client command with:
      | resource      | dc               |
      | resource_name | frontend         |
      | p             | {"spec":{"strategy":{"rollingParams":{"post":null}}}} |
    Then the step should succeed
    When I perform the :check_dc_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | frontend            |
    Then the step should succeed
    When I run the :check_dc_hook_part_missing_from_dc_page web console action
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id OCP-17489
  @admin
  Scenario: Webhook secret value should not be seen to viewer in web
    Given the master version >= "3.9"
    And I have a project
    When I run the :create_secret client command with:
      | secret_type   | generic                   |
      | name          | mysecret                  |
      | from_literal  | WebHookSecretKey=1234qwer |
    Then the step should succeed
    When I run the :create client command with:
      | f    |  <%= BushSlicer::HOME %>/features/tierN/testdata/build/tc-OCP-17489/bc_webhook_triggers.yaml |
    Then the step should succeed

    # user of role view
    When I run the :policy_add_role_to_user client command with:
      | role       | view                               |
      | user_name  | <%= user(1, switch: false).name %> |
    Then the step should succeed
    Given I switch to the second user
    When I perform the :check_bc_webhook_trigger_in_configuration web console action with:
      | project_name    | <%= project.name %>         |
      | bc_name         | ruby-ex                     |
      | webhook_trigger | webhooks/<secret>/bitbucket |
    Then the step should succeed
    When I perform the :check_bc_webhook_trigger web console action with:
      | webhook_trigger | webhooks/<secret>/generic   |
    Then the step should succeed

    # user of role cluster-reader
    Given I switch to the first user
    When I run the :policy_remove_role_from_user client command with:
      | role       | view                               |
      | user_name  | <%= user(1, switch: false).name %> |
    Then the step should succeed
    Given cluster role "cluster-reader" is added to the "second" user
    And I switch to the second user
    When I perform the :check_bc_webhook_trigger_in_configuration web console action with:
      | project_name    | <%= project.name %>         |
      | bc_name         | ruby-ex                     |
      | webhook_trigger | webhooks/<secret>/github    |
    Then the step should succeed
    When I perform the :check_bc_webhook_trigger web console action with:
      | webhook_trigger | webhooks/<secret>/gitlab    |
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id OCP-17666
  Scenario: Check webhook in web when it can reference secret
    Given the master version >= "3.9"
    And I have a project
    When I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    When I perform the :goto_create_secret_page web console action with:
      | project_name | <%= project.name %>   |
    Then the step should succeed
    When I perform the :create_webhook_secret web console action with:
      | new_secret_name    | webhooksecret1   |
      | webhook_secret_key | 1234qwer         |
    Then the step should succeed
    When I run the :click_create_secret_on_secrets_page web console action
    Then the step should succeed
    When I perform the :create_webhook_secret_generated web console action with:
      | new_secret_name    | webhooksecret2   |
    Then the step should succeed

    Given the "ruby-ex-1" build finished
    When I perform the :add_webhook_on_bc_edit_page web console action with:
      | project_name  | <%= project.name %> |
      | bc_name       | ruby-ex             |
      | webhook_type  | Bitbucket           |
      | secret_name   | webhooksecret1      |
    Then the step should succeed
    When I perform the :add_webhook_by_create_new_secret web console action with:
      | webhook_type       | GitLab              |
      | new_secret_name    | webhooksecret3      |
      | webhook_secret_key | 5678qwer            |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    And the expression should be true> bc("ruby-ex").trigger_by_type(type: "GitLab").secret_name == "webhooksecret3"
    When I perform the :check_bc_webhook_trigger_in_configuration web console action with:
      | project_name    | <%= project.name %>         |
      | bc_name         | ruby-ex                     |
      | webhook_trigger | webhooks/1234qwer/bitbucket |
    Then the step should succeed

