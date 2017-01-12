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
    When I perform the :add_another_pull_secret_with_image_registry_credential web console action with:
      | secret_type       | pullSecret                |
      | auth_type         | Image Registry Credential |
      | new_secret_name   | dockerhub2                |
      | new_docker_server | private2.registry.com     |
      | new_docker_user   | anyuser2                  |
      | new_docker_passwd | 12345678                  |
      | new_docker_email  | any2@example.com          |
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
      | secret_type     | gitSecret            |
      | new_secret_name | gitsecret            |
      | auth_type       | Basic Authentication |
      | username        | gituser              |
      | password_token  | 12345678             |
    Then the step should succeed
    # Add Pull Secret
    When I perform the :select_one_secret_from_box web console action with:
      | secret_type | pullSecret |
      | secret_name | dockerhub1 |
    Then the step should succeed
    # Add Push Secret
    When I perform the :add_new_push_secret_with_image_registry_credential web console action with:
      | secret_type       | pushSecret                |
      | auth_type         | Image Registry Credential |
      | new_secret_name   | dockerhub2                |
      | new_docker_server | private2.registry.com     |
      | new_docker_user   | anyuser2                  |
      | new_docker_passwd | 12345678                  |
      | new_docker_email  | any2@example.com          |
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

  # @author xxing@redhat.com
  # @case_id 536667
  Scenario: Create secret via create secret page
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/secrets/credential/.gitconfig"
    Given a "ssh_private_key" file is created with the following lines:
      | <%= CucuShift::SSH::Helper.gen_rsa_key.to_pem %> |
    # Create Source Secret of Basic Authentication type
    When I perform the :create_source_secret_upload_gitconfig_with_basic_authentication web console action with:
      | project_name    | <%= project.name %>              |
      | secret_type     | Source Secret                    |
      | auth_type       | Basic Authentication             |
      | new_secret_name | gitsecret                        |
      | username        | gituser                          |
      | password_token  | 12345678                         |
      | checkbox_option | gitconfig                        |
      | is_check        | true                             |
      | file_type       | gitconfig                        |
      | file_path       | <%= expand_path(".gitconfig") %> |
    Then the step should succeed
    When I perform the :set_link_secret_to_sa web console action with:
      | checkbox_option | linkSecret |
      | is_check        | true       |
      | sa_name         | builder    |
    Then the step should succeed
    When I run the :click_create_secret_button web console action
    Then the step should succeed
    
    When I run the :extract client command with:
      | resource | secret/gitsecret |
      | confirm  | true             |
    Then the step should succeed
    Given evaluation of `File.read("username")` is stored in the :gituser clipboard
    Then  the expression should be true> cb.gituser == "gituser"
    Given evaluation of `File.read("password")` is stored in the :gitpasswd clipboard
    Then  the expression should be true> cb.gitpasswd == "12345678"
    When I run the :get client command with:
      | resource      | sa      |
      | resource_name | builder |
      | o             | yaml    |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["secrets"].include?({"name"=>"gitsecret"})
    # Create Source Secret of SSH Authentication type
    When I perform the :create_source_secret_upload_sshkey_with_ssh_authentication web console action with:
      | project_name    | <%= project.name %>                   |
      | secret_type     | Source Secret                         |
      | new_secret_name | sshkey                                |
      | auth_type       | SSH Key                               |
      | file_type       | private-key                           |
      | file_path       | <%= expand_path("ssh_private_key") %> |
    Then the step should succeed
    When I perform the :set_link_secret_to_sa web console action with:
      | checkbox_option | linkSecret |
      | is_check        | true       |
      | sa_name         | default    |
    Then the step should succeed
    When I run the :click_create_secret_button web console action
    Then the step should succeed

    When I run the :get client command with:
      | resource      | sa      |
      | resource_name | default |
      | o             | yaml    |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["secrets"].include?({"name"=>"sshkey"})
    # Create Image Secret of Image Registry Credential Authentication type
    When I run the :click_create_secret_on_secrets_page web console action
    Then the step should succeed
    When I perform the :create_image_secret_with_image_registry_credential web console action with:
      | secret_type       | Image Secret              |
      | auth_type         | Image Registry Credential |
      | new_secret_name   | dockerhub                 |
      | new_docker_server | private.registry.com      |
      | new_docker_user   | anyuser                   |
      | new_docker_passwd | 12345678                  |
      | new_docker_email  | any@example.com           |
    Then the step should succeed
    When I perform the :set_link_secret_to_sa web console action with:
      | checkbox_option | linkSecret |
      | is_check        | true       |
      | sa_name         | builder    |
    Then the step should succeed
    When I run the :click_create_secret_button web console action
    Then the step should succeed

    When I run the :get client command with:
      | resource      | sa      |
      | resource_name | builder |
      | o             | yaml    |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["imagePullSecrets"].include?({"name"=>"dockerhub"})
    # Create Image Secret of Configuration File Authentication Type
    When I perform the :create_image_secret_upload_dockercfg_with_configuration_file_authentication web console action with:
      | project_name    | <%= project.name %>                                                  |
      | secret_type     | Image Secret                                                         |
      | new_secret_name | dockerconfig                                                         |
      | auth_type       | Configuration File                                                   |
      | file_type       | docker-config                                                        |
      | file_path       | <%= expand_private_path(conf[:services, :docker_hub, :dockercfg]) %> |
    Then the step should succeed
    When I perform the :set_link_secret_to_sa web console action with:
      | checkbox_option | linkSecret |
      | is_check        | true       |
      | sa_name         | deployer   |
    Then the step should succeed
    When I run the :click_create_secret_button web console action
    Then the step should succeed

    When I run the :get client command with:
      | resource      | sa       |
      | resource_name | deployer |
      | o             | yaml     |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["imagePullSecrets"].include?({"name"=>"dockerconfig"})

  # @author xxing@redhat.com
  # @case_id 544854
  Scenario: Prompt invalid input when creating secret in web
    Given I have a project
    When I perform the :goto_create_secret_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :set_created_secret_name web console action with:
      | new_secret_name | user_|
    Then the step should succeed
    When I perform the :select_created_secret_type web console action with:
      | secret_type     | Source Secret |
    Then the step should succeed
    When I run the :check_error_prompt_when_input_secret_name web console action
    Then the step should succeed
    When I perform the :create_image_secret_common_action_with_configuration_file_authentication web console action with:
      | project_name    | <%= project.name %> |
      | secret_type     | Image Secret        |
      | auth_type       | Configuration File  |
      | new_secret_name | dockerhub           |
    Then the step should succeed
    When I perform the :set_docker_configuration_file_textarea web console action with:
      | text_content | abcd |
    Then the step should succeed
    When I run the :check_error_prompt_when_set_secret_configuration_file web console action
    Then the step should succeed
    # Fail here unless bug 1404147 is merged
    When I perform the :create_image_secret_with_image_registry_credential web console action with:
      | secret_type       | Image Secret              |
      | new_secret_name   | dockerhub                 |
      | auth_type         | Image Registry Credential |
      | new_docker_server | docker.io                 |
      | new_docker_user   | user1                     |
      | new_docker_passwd | 12345678                  |
      | new_docker_email  | any                       |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should match "must be in the form of user@domain"

  # @author xxing@redhat.com
  # @case_id 536665
  Scenario: Add secrets to docker strategy BC
    Given I have a project
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
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-dockerbuild.json |
    Then the step should succeed
    When I perform the :check_buildconfig_edit_page_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-sample-build   |
    Then the step should succeed
    When I run the :click_to_show_advanced_options web console action
    Then the step should succeed
    When I perform the :select_one_build_secret_from_box web console action with:
      | secret_name | mysecret-1 |
    Then the step should succeed
    When I run the :click_add_another_build_secret_link web console action
    Then the step should succeed
    When I perform the :select_one_build_secret_from_box web console action with:
      | secret_name | mysecret-2 |
    Then the step should succeed
    When I perform the :set_build_secret_destinationdir web console action with:
      | destinationdir | /tmp |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :check_error_prompt_when_set_dockerbuild_secret_destinationdir web console action
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id 536664
  @admin
  Scenario: Add secrets to custom strategy BC
    Given I have a project
    Given a "secretfile1" file is created with the following lines:
      | secret1 test |
    Given a "secretfile2" file is created with the following lines:
      | secret2 test |
    When I run the :new_secret client command with:
      | secret_name     | mysecret1  |
      | credential_file | secretfile1 |
    Then the step should succeed
    When I run the :new_secret client command with:
      | secret_name     | mysecret2  |
      | credential_file | secretfile2 |
    Then the step should succeed
    When I run the :policy_add_role_to_user admin command with:
      | role      | system:build-strategy-custom |
      | user_name | <%= user.name %>             |
      | n         | <%= project.name %>          |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json |
    Then the step should succeed
    When I perform the :check_buildconfig_edit_page_loaded_completely web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-sample-build   |
    Then the step should succeed
    When I run the :click_to_show_advanced_options web console action
    Then the step should succeed
    When I perform the :select_one_build_secret_from_box web console action with:
      | secret_name | mysecret1 |
    Then the step should succeed
    When I perform the :set_custom_build_secet_mountpath web console action with:
      | mountpath | testdir/exam1 |
    Then the step should succeed
    When I run the :click_add_another_build_secret_link web console action
    Then the step should succeed
    When I perform the :select_one_build_secret_from_box web console action with:
      | secret_name | mysecret2 |
    Then the step should succeed
    When I perform the :set_custom_build_secet_mountpath web console action with:
      | mountpath | /tmp/exam2 |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | buildConfig       |
      | resource_name | ruby-sample-build |
      | o             | yaml              |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["spec"]["strategy"]["customStrategy"]["secrets"].include?({"mountPath"=>"testdir/exam1", "secretSource"=>{"name"=>"mysecret1"}})
    And the expression should be true> @result[:parsed]["spec"]["strategy"]["customStrategy"]["secrets"].include?({"mountPath"=>"/tmp/exam2", "secretSource"=>{"name"=>"mysecret2"}})

  # @author xxing@redhat.com
  # @case_id 540247
  Scenario: Add/remove secrets in DC editor page
    Given I have a project
    When I run the :run client command with:
      | name  | mydc                  |
      | image | aosqe/hello-openshift |
    Then the step should succeed
    Given I wait until the status of deployment "mydc" becomes :complete
    When I run the :oc_secrets_new_dockercfg client command with:
      | secret_name     | dockerhub1           |
      | docker_server   | private.registry.com |
      | docker_username | anyuser1             |
      | docker_password | 12345678             |
      | docker_email    | any1@example.com     |
    Then the step should succeed
    When I run the :oc_secrets_new_dockercfg client command with:
      | secret_name     | dockerhub2           |
      | docker_server   | private.registry.com |
      | docker_username | anyuser2             |
      | docker_password | 12345678             |
      | docker_email    | any2@example.com     |
    Then the step should succeed
    When I perform the :goto_edit_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | mydc                |
    Then the step should succeed
    When I run the :click_to_show_dc_advanced_image_options web console action
    Then the step should succeed
    When I perform the :select_one_secret_from_box web console action with:
      | secret_type | pullSecret |
      | secret_name | dockerhub1 |
    Then the step should succeed
    When I perform the :click_add_another_secret_link web console action with:
      | secret_type | pullSecret |
    Then the step should succeed
    When I perform the :select_one_secret_from_box web console action with:
      | secret_type | pullSecret |
      | secret_name | dockerhub2 |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | mydc             |
      | o             | yaml             |
    Then the step should succeed
    And the expression should be true> a=@result[:parsed]["spec"]["template"]["spec"]["imagePullSecrets"].include?({"name"=>"dockerhub1"})
    And the expression should be true> a=@result[:parsed]["spec"]["template"]["spec"]["imagePullSecrets"].include?({"name"=>"dockerhub2"})
    Given I wait until the status of deployment "mydc" becomes :complete
    When I perform the :goto_edit_dc_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | mydc                |
    Then the step should succeed
    When I run the :click_to_show_dc_advanced_image_options web console action
    Then the step should succeed
    Given I run the steps 2 times:
    """
    When I perform the :click_remove_secret web console action with:
      | secret_type | pullSecret |
    Then the step should succeed
    """
    When I run the :click_save_button web console action
    Then the step should succeed 
    When I run the :get client command with:
      | resource      | deploymentConfig |
      | resource_name | mydc             |
      | o             | yaml             |
    Then the step should succeed
    And the output should not contain:
      | dockerhub1 |
      | dockerhub2 |
