Feature: Check deployments function
  # @author yapei@redhat.com
  # @case_id OCP-11631
  Scenario: Idled RC handling on web console
    Given I create a new project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/k8s/rc-and-svc-list.yaml |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=hello-pod |
    When I run the :idle client command with:
      | svc_name | hello-svc |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "hello-pod"
    When I perform the :check_standalone_rc_idle_text web console action with:
      | project_name      | <%= project.name %> |
      | rc_name           | hello-pod           |
      | previous_replicas | 2                   |
    Then the step should succeed
    When I perform the :check_dc_idle_text_on_overview web console action with:
      | project_name      | <%= project.name %>    |
      # parameter dc_name used for v3 only, could be refactored
      | dc_name           | hello-openshift        |
      | resource_type     | replication controller |
      | resource_name     | hello-pod              |
      | previous_replicas | 2                      |
    Then the step should succeed
    # check_idle_donut_text_on_overview almost duplicate check_dc_idle_text_on_overview for all versions > 3
    When I perform the :check_idle_donut_text_on_overview web console action with:
      | project_name  | <%= project.name %> |
      # parameter dc_name used for v3 only, could be refactored
      | dc_name       | hello-openshift     |
      | resource_type | deployment          |
      | resource_name | hello-openshift     |
    Then the step should succeed
    # check replicas after wake up
    When I perform the :click_wake_up_option_on_rc_page web console action with:
      | project_name      | <%= project.name %> |
      | rc_name           | hello-pod           |
      | previous_replicas | 2                   |
    Then the step should succeed
    Given I wait until number of replicas match "2" for replicationController "hello-pod"
    When I perform the :check_standalone_rc_replicas web console action with:
      | project_name      | <%= project.name %> |
      | rc_name           | hello-pod           |
      | rc_replicas       | 2                   |
    Then the step should succeed
    When I perform the :check_donut_text_on_overview web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hello-pod           |
      | donut_text   | 2                   |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-12394
  Scenario: Pause and Resume Deployment Configuration
    Given the master version >= "3.4"
    Given I have a project
    When I run the :run client command with:
      | name         | myrun                 |
      | image        | aosqe/hello-openshift |
    Then the step should succeed
    Given I wait until the status of deployment "myrun" becomes :complete
    When I perform the :check_latest_deployment_version web console action with:
      | project_name              | <%= project.name %> |
      | dc_name                   | myrun               |
      | latest_deployment_version | 1                   |
    Then the step should succeed
    When I perform the :pause_deployment_configuration web console action with:
      | project_name       | <%= project.name %> |
      | dc_name            | myrun               |
    Then the step should succeed
    When I perform the :check_pause_message web console action with:
      | resource_name | myrun      |
      | resource_type | deployment |
    Then the step should succeed
    When I perform the :check_pause_message_on_dc_page web console action with:
      | project_name       | <%= project.name %> |
      | dc_name            | myrun               |
    Then the step should succeed
    When I perform the :check_pause_message_on_overview_page web console action with:
      | project_name  | <%= project.name %> |
      | resource_name | myrun               |
      | resource_type | deployment          |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | dc/myrun  |
      | e        | test=1234 |
    Then the step should succeed
    When I perform the :check_latest_deployment_version web console action with:
      | project_name              | <%= project.name %> |
      | dc_name                   | myrun               |
      | latest_deployment_version | 1                   |
    Then the step should succeed
    When I perform the :click_resume_on_overview_page web console action with:
      | project_name              | <%= project.name %> |
    Then the step should succeed
    Given the pod named "myrun-2-deploy" becomes ready
    And I wait for the pod named "myrun-2-deploy" to die
    And a pod becomes ready with labels:
      | deployment=myrun-2 |
    When I perform the :check_latest_deployment_version web console action with:
      | project_name              | <%= project.name %> |
      | dc_name                   | myrun               |
      | latest_deployment_version | 2                   |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource | dc/myrun  |
      | e        | value=ago |
    Then the step should succeed
    Given the pod named "myrun-3-deploy" becomes ready
    And I wait for the pod named "myrun-3-deploy" to die
    When I perform the :check_latest_deployment_version web console action with:
      | project_name              | <%= project.name %> |
      | dc_name                   | myrun               |
      | latest_deployment_version | 3                   |
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-12004
  Scenario: DC Image Configuration on web console
    Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/dc-with-two-containers.yaml |
    Then the step should succeed
    # create imagestream for below use, ensuring the DC can be complete after edit
    When I run the :tag client command with:
      | source       | aosqe/ruby-ex    |
      | dest         | ruby-ex:latest   |
    Then the step should succeed
    Given I wait until the status of deployment "dctest" becomes :complete
    When I perform the :goto_one_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | dctest              |
    Then the step should succeed
    When I run the :click_to_goto_edit_page web console action
    Then the step should succeed
    When I perform the :update_container_image_name web console action with:
      | container_name | dctest-1              |
      | image_name     | aosqe/hello-openshift |
    Then the step should succeed
    When I perform the :set_autostart_deployment_checkbox web console action with:
      | container_name       | dctest-2 |
      | deployment_autostart | true     |
    Then the step should succeed
    When I perform the :set_image_change_trigger web console action with:
      | container_name | dctest-2            |
      | namespace      | <%= project.name %> |
      | image_stream   | ruby-ex             |
      | tag            | latest              |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_dc_image_stream web console action with:
      | project_name   | <%= project.name %>   |
      | dc_name        | dctest                |
      | container_name | dctest-1              |
      | image_stream   | aosqe/hello-openshift |
    Then the step should succeed
    When I perform the :check_dc_image_stream web console action with:
      | project_name   | <%= project.name %>     |
      | dc_name        | dctest                  |
      | container_name | dctest-2                |
      | image_stream   | aosqe/ruby-ex           |
    Then the step should succeed
    When I perform the :check_dc_image_trigger web console action with:
      | project_name | <%= project.name %>                 |
      | dc_name      | dctest                              |
      | dc_image     | <%= project.name %>/ruby-ex:latest  |
    Then the step should succeed

    # wait for dc being stable to avoid confliction.
    Given I wait until the status of deployment "dctest" becomes :complete
    When I run the :click_to_goto_edit_page web console action
    Then the step should succeed
    When I perform the :set_autostart_deployment_checkbox web console action with:
      | container_name       | dctest-1 |
      | deployment_autostart | true     |
    Then the step should succeed
    When I perform the :set_image_change_trigger web console action with:
      | container_name | dctest-1  |
      | namespace      | openshift |
      | image_stream   | nodejs    |
      | tag            | 0.10      |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_dc_image_trigger web console action with:
      | project_name | <%= project.name %>   |
      | dc_name      | dctest                |
      | dc_image     | openshift/nodejs:0.10 |
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id OCP-11406
  Scenario: Change Deployment Stategy from Rolling to Custom on web console
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/rolling.json |
    Then the step should succeed
    Given I wait until the status of deployment "hooks" becomes :complete
    When I perform the :goto_edit_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | hooks               |
    Then the step should succeed
    When I perform the :select_dc_strategy_type web console action with:
      | strategy_type | Custom |
    Then the step should succeed
    When I run the :check_dc_custom_strategy_settings web console action
    Then the step should succeed
    When I perform the :click_add_lifecycle_hook web console action with:
      | hook_type | pre |
    Then the step should fail
    When I perform the :set_dc_custom_strategy_settings web console action with:
      | image_name    | aosqe/hello-openshift |
      | cmd_line      | echo "hello"          |
      | env_var_key   | env1                  |
      | env_var_value | value1                |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_dc_strategy_on_dc_page web console action with:
      | dc_strategy | Custom |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain "Hooks"
    When I run the :describe client command with:
      | resource | deploymentConfig |
      | name     | hooks            |
    Then the step should succeed
    And the output should match:
      | Strategy:\s+Custom             |
      | Image:\s+aosqe/hello-openshift |
      | Environment:\s+env1=value1     |
      | Command:\s+echo "hello"        |

  # @author hasha@redhat.com
  # @case_id OCP-11381
  Scenario: Change Deployment Stategy from Recreate to Rolling and keep some paramaters on web console
    Given I have a project
    # Since importance of the case is low, no related rules for v3.4/3.5/3.6
    Given the master version >= "3.4"
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/rails-ex/master/openshift/templates/rails-postgresql.json |
    Then the step should succeed
    Given I wait until the status of deployment "rails-postgresql-example" becomes :complete
    When I perform the :goto_edit_dc_page web console action with:
      | project_name | <%= project.name %>      |
      | dc_name      | rails-postgresql-example |
    Then the step should succeed
    When I perform the :select_dc_strategy_type web console action with:
      | strategy_type | Rolling |
    Then the step should succeed
    When I run the :keep_parameters_in_dialog web console action
    Then the step should succeed
    When I run the :check_learn_more_link_for_rolling_strategy web console action
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_resource_succesfully_updated_message web console action with:
      | resource | Deployment config        |
      | name     | rails-postgresql-example |
    Then the step should succeed
    When I perform the :check_detail_on_configuration_tab_for_rolling web console action with:
      | project_name     | <%= project.name %>      |
      | dc_name          | rails-postgresql-example |
      | timeout_v        | 600 sec                  |
      | updateperiod_v   | 1 sec                    |
      | interval_v       | 1 sec                    |
      | maxunavailable_v | 25%                      |
      | maxsurge_v       | 25%                      |
    Then the step should succeed
    When I perform the :check_dc_strategy_on_dc_page web console action with:
      | dc_strategy | Rolling |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | dc                       |
      | name     | rails-postgresql-example |
    Then the output should match:
      | Strategy:\\s+Rolling                       |
      | \\s+Pre-deployment\\s+hook.*               |
      | \\s+Container:\\s+rails-postgresql-example |
      | \\s+Command:\\s+./migrate-database.sh      |


  # @author hasha@redhat.com
  # @case_id OCP-11019
  Scenario: Change Deployment Stategy from Recreate to Rolling but do not keep some paramaters on web console
    Given I have a project
    # Since importance of the case is low, no related rules for v3.4/3.5/3.6
    Given the master version >= "3.4"
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/rails-ex/master/openshift/templates/rails-postgresql.json |
    Then the step should succeed
    Given I wait until the status of deployment "rails-postgresql-example" becomes :complete
    When I perform the :goto_edit_dc_page web console action with:
      | project_name | <%= project.name %>      |
      | dc_name      | rails-postgresql-example |
    Then the step should succeed
    When I perform the :select_dc_strategy_type web console action with:
      | strategy_type | Rolling |
    Then the step should succeed
    When I run the :not_keep_parameters_in_dialog web console action
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_resource_succesfully_updated_message web console action with:
      | resource | Deployment config        |
      | name     | rails-postgresql-example |
    Then the step should succeed
    When I perform the :check_detail_on_configuration_tab_for_rolling web console action with:
      | project_name     | <%= project.name %>      |
      | dc_name          | rails-postgresql-example |
      | timeout_v        | 600 sec                  |
      | updateperiod_v   | 1 sec                    |
      | interval_v       | 1 sec                    |
      | maxunavailable_v | 25%                      |
      | maxsurge_v       | 25%                      |
    Then the step should succeed
    When I perform the :check_dc_strategy_on_dc_page web console action with:
      | dc_strategy | Rolling |
    Then the step should succeed
