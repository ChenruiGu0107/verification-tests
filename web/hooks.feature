Feature: bc/dc hooks related
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

