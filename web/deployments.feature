Feature: Check deployments function
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
