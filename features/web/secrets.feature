Feature: web secrets related

  # @author xxing@redhat.com
  # @case_id 536663
  Scenario: Add secret on Create From Image page
    Given I have a project
    When I run the :oc_secrets_new_basicauth client command with:
      | secret_name | gitsecret |
      | username    | user      |
      | password    | 12345678  |
    Then the step should succeed
    When I perform the :create_app_from_image_with_secret web console action with:
      | project_name | <%= project.name %> |
      | image_name   | php                 |
      | image_tag    | latest              |
      | namespace    | openshift           |
      | app_name     | phpdemo             |
      | secret_name  | gitsecret           |
    Then the step should succeed
    Given the "phpdemo-1" build was created
    When I run the :get client command with:
      | resource      | buildConfig |
      | resource_name | phpdemo     |
      | o             | yaml        |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["spec"]["source"]["sourceSecret"]["name"] == "gitsecret"
