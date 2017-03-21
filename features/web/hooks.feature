Feature: dc hooks related

  # @author xxing@redhat.com
  # @case_id OCP-11652
  Scenario: pre/mid/post deployment hooks handling for DC on web console
    Given the master version >= "3.4"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/Recreate-dc-with-prehook.json |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/simple-is.json             |
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
