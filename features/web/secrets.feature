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

  # @author xxing@redhat.com
  # @case_id 536662
  Scenario: Add secrets in Deploy Image page
    Given I have a project
    When I run the :oc_secrets_new_dockercfg client command with:
      | secret_name     | dockerhub1            |
      | docker_server   | private1.registry.com |
      | docker_username | anyuser1              |
      | docker_password | 12345678              |
      | docker_email    | any1@example.com      |
    Then the step should succeed
    When I perform the :deploy_from_image_stream_name_search_image web console action with:
      | project_name      | <%= project.name %>       |
      | image_deploy_from | openshift/hello-openshift |
    Then the step should succeed
    When I perform the :select_one_secret_from_box web console action with:
      | secret_name       | dockerhub1 |
    Then the step should succeed
    When I perform the :add_another_secret_with_image_registry_credentials web console action with:
      | new_secret_name   | dockerhub2            |
      | new_docker_server | private2.registry.com |
      | new_docker_user   | anyuser2              |
      | new_docker_passwd | 12345678              |
      | new_docker_email  | any2@example.com      |
    Then the step should succeed
    When I run the :click_create_button web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | hello-openshift  |
      | o             | yaml             |
    Then the step should succeed
    And the expression should be true> a=@result[:parsed]["spec"]["template"]["spec"]["imagePullSecrets"]; b=[{"name"=>"dockerhub1"},{"name"=>"dockerhub2"}]; a&b=b
    When I run the :get client command with:
      | resource      | sa      |
      | resource_name | default |
      | o             | yaml    |
    Then the step should succeed
    And the expression should be true> ([{"name"=>"dockerhub2"}] - @result[:parsed]["imagePullSecrets"]).empty?
    And the expression should be true> !([{"name"=>"dockerhub1"}] - @result[:parsed]["imagePullSecrets"]).empty?
