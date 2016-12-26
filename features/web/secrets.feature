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
      | secret_type  | gitSecret           |
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
      | secret_type       | pullSecret |
      | secret_name       | dockerhub1 |
    Then the step should succeed
    When I perform the :add_another_pull_secret_with_image_registry_credentials web console action with:
      | secret_type       | pullSecret            |
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

  # @author xxing@redhat.com
  # @case_id 536666
  Scenario: Add secrets to source strategy BC for source repo and image repo
    Given I have a project
    When I run the :oc_secrets_new_dockercfg client command with:
      | secret_name     | dockerhub1            |
      | docker_server   | private1.registry.com |
      | docker_username | anyuser1              |
      | docker_password | 12345678              |
      | docker_email    | any1@example.com      |
    Then the step should succeed
    Given a "secretfile1" file is created with the following lines:
      | first test |
    Given a "secretfile2" file is created with the following lines:
      | second test |
    When I run the :new_secret client command with:
      | secret_name     | mysecret-1  |
      | credential_file | secretfile1 |
    Then the step should succeed
    When I run the :new_secret client command with:
      | secret_name     | mysecret-2  |
      | credential_file | secretfile2 |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    When I perform the :check_buildconfig_edit_page_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-sample-build   |
    Then the step should succeed
    When I run the :click_to_show_advanced_options web console action
    Then the step should succeed
    # Add Source Secret
    When I perform the :add_new_source_secret_with_basic_authentication web console action with:
      | secret_type     | gitSecret |
      | new_secret_name | gitsecret |
      | username        | gituser   |
      | password_token  | 12345678  |
    Then the step should succeed
    # Add Pull Secret
    When I perform the :select_one_secret_from_box web console action with:
      | secret_type | pullSecret |
      | secret_name | dockerhub1 |
    Then the step should succeed
    # Add Push Secret
    When I perform the :add_new_push_secret_with_image_registry_credentials web console action with:
      | secret_type       | pushSecret            |
      | new_secret_name   | dockerhub2            |
      | new_docker_server | private2.registry.com |
      | new_docker_user   | anyuser2              |
      | new_docker_passwd | 12345678              |
      | new_docker_email  | any2@example.com      |
    Then the step should succeed
    # Add Build Secret
    When I perform the :select_one_build_secret_from_box web console action with:
      | secret_name | mysecret-1 |
    Then the step should succeed
    When I perform the :set_build_secret_destinationdir web console action with:
      | destinationdir | /tmp/abc |
    Then the step should succeed
    When I run the :click_add_another_build_secret_link web console action
    Then the step should succeed
    When I perform the :select_one_build_secret_from_box web console action with:
      | secret_name | mysecret-2 |
    Then the step should succeed

    When I run the :click_save_button web console action
    Then the step should succeed

    When I run the :get client command with:
      | resource      | buildConfig       |
      | resource_name | ruby-sample-build |
      | o             | yaml              |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["spec"]["output"]["pushSecret"]["name"] == "dockerhub2"
    And the expression should be true> @result[:parsed]["spec"]["source"]["sourceSecret"]["name"] == "gitsecret"
    And the expression should be true> @result[:parsed]["spec"]["strategy"]["sourceStrategy"]["pullSecret"]["name"] == "dockerhub1"
    And the expression should be true> @result[:parsed]["spec"]["source"]["secrets"].include?({"destinationDir"=>"/tmp/abc", "secret"=>{"name"=>"mysecret-1"}})
    And the expression should be true> @result[:parsed]["spec"]["source"]["secrets"].include?({"secret"=>{"name"=>"mysecret-2"}})
    When I run the :get client command with:
      | resource      | sa      |
      | resource_name | builder |
      | o             | yaml    |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["secrets"].include?({"name"=>"gitsecret"})
    And the expression should be true> @result[:parsed]["imagePullSecrets"].include?({"name"=>"dockerhub2"})
    When I perform the :check_buildconfig_edit_page_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-sample-build   |
    Then the step should succeed
    When I run the :click_to_show_advanced_options web console action
    Then the step should succeed
    # Remove all added secrets
    When I perform the :click_remove_secret web console action with:
      | secret_type | gitSecret |
    Then the step should succeed
    When I perform the :click_remove_secret web console action with:
      | secret_type | pullSecret |
    Then the step should succeed
    When I perform the :click_remove_secret web console action with:
      | secret_type | pushSecret |
    Then the step should succeed
    Given I run the steps 2 times:
    """
    When I run the :click_remove_build_secret web console action
    Then the step should succeed
    """
    When I run the :click_save_button web console action
    Then the step should succeed

    When I run the :get client command with:
      | resource      | buildConfig       |
      | resource_name | ruby-sample-build |
      | o             | yaml              |
    Then the step should succeed
    And the output should not contain:
      | gitsecrect |
      | dockerhub1 |
      | dockerhub2 |
      | mysecret-1 |
      | mysecret-2 | 
