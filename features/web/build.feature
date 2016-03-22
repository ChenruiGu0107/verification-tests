Feature: build related feature on web console

  # @author: xxing@redhat.com
  # @case_id: 482266
  Scenario: Check the build information from web console
    When I create a new project via web
    Then the step should succeed
    Given I use the "<%= project.name %>" project
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
    Given the "python-sample-1" build completed
    When I perform the :check_one_build_inside_bc_page web console action with:
      | project_name            | <%= project.name %> |
      | bc_and_build_name       | python-sample/python-sample-1       |
    Then the step should succeed
    When I click the following "button" element:
      | text  | Rebuild |
      | class | btn-default |
    Then the step should succeed
    Given the "python-sample-2" build was created
    When I get the "disabled" attribute of the "button" web element:
      | text  | Rebuild |
      | class | btn-default |
    Then the output should contain "true"
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
    Given I use the "<%= project.name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json |
    Then the step should succeed
    Given I wait for the :create_app_from_image web console action to succeed with:
      | project_name | <%= project.name %> |
      | image_name   | ruby                |
      | image_tag    | 2.2                 |
      | namespace    | <%= project.name %> |
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
      | namespace    | <%= project.name %> |
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
      | build_status  | complete             |
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
