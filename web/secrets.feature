Feature: web secrets related

  # @author xxing@redhat.com
  # @case_id OCP-10996
  Scenario: Add secrets in Deploy Image page
    Given I have a project
    When I run the :secrets_new_dockercfg client command with:
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
  # @case_id OCP-11997
  Scenario: Add secrets to source strategy BC for source repo and image repo
    Given the master version >= "3.4"
    Given I have a project
    When I run the :secrets_new_dockercfg client command with:
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
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    When I perform the :click_to_goto_edit_bc_page web console action with:
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
    When I perform the :click_to_goto_edit_bc_page web console action with:
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
  # @case_id OCP-12103
  Scenario: Create secret via create secret page
    Given I have a project
    Given I obtain test data file "secrets/credential/.gitconfig"
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
  # @case_id OCP-10540
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
    # docker configuration file
    When I perform the :set_ace_editor_content web console action with:
      | content | abcd |
    Then the step should succeed
    When I run the :check_error_prompt_when_set_secret_configuration_file web console action
    Then the step should succeed
    # bug 1404147 is fixed in 3.5, will not backport to 3.4
    When I perform the :create_image_secret_with_image_registry_credential web console action with:
      | secret_type       | Image Secret              |
      | new_secret_name   | dockerhub                 |
      | auth_type         | Image Registry Credential |
      | new_docker_server | docker.io                 |
      | new_docker_user   | user1                     |
      | new_docker_passwd | 12345678                  |
      | new_docker_email  | any                       |
    Then the step should succeed
    When I run the :check_mail_format_error web console action
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id OCP-11848
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
  # @case_id OCP-11657
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
    When I perform the :set_custom_build_secret_mountpath web console action with:
      | mountpath | testdir/exam1 |
    Then the step should succeed
    When I run the :click_add_another_build_secret_link web console action
    Then the step should succeed
    When I perform the :select_one_build_secret_from_box web console action with:
      | secret_name | mysecret2 |
    Then the step should succeed
    When I perform the :set_custom_build_secret_mountpath web console action with:
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
  # @case_id OCP-10530
  Scenario: Add/remove secrets in DC editor page
    Given I have a project
    When I run the :run client command with:
      | name  | mydc                  |
      | image | aosqe/hello-openshift |
    Then the step should succeed
    Given I wait until the status of deployment "mydc" becomes :complete
    When I run the :secrets_new_dockercfg client command with:
      | secret_name     | dockerhub1           |
      | docker_server   | private.registry.com |
      | docker_username | anyuser1             |
      | docker_password | 12345678             |
      | docker_email    | any1@example.com     |
    Then the step should succeed
    When I run the :secrets_new_dockercfg client command with:
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

  # @author etrott@redhat.com
  # @case_id OCP-11424
  Scenario: Add/Edit env vars from secret
    Given the master version >= "3.6"
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed

    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/hello-deployment-1.yaml   |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/replicaSet/tc536589/replica-set.yaml |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/rc/idle-rc-1.yaml                    |
    Then the step should succeed
    Given a "secret.yaml" file is created with the following lines:
    """
    apiVersion: v1
    kind: Secret
    metadata:
      name: mysecret
    data:
      data-1: dmFsdWUtMQ0K
      data-2: dmFsdWUtMg0KDQo=
    """
    When I run the :create client command with:
      | f | secret.yaml |
    Then the step should succeed

    When I perform the :goto_one_dc_environment_tab web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | database            |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | my_secret      |
      | resource_name | dbsecret       |
      | resource_key  | mysql-password |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_resource_succesfully_updated_message web console action with:
      | resource | deployment config |
      | name     | database          |
    Then the step should succeed

    When I perform the :goto_one_rc_environment_tab web console action with:
      | project_name | <%= project.name %> |
      | rc_name      | hello-idle          |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | my_secret      |
      | resource_name | dbsecret       |
      | resource_key  | mysql-password |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_resource_updated_message web console action with:
      | resource_name | hello-idle |
    Then the step should succeed

    When I perform the :goto_one_k8s_deployment_environment_tab web console action with:
      | project_name        | <%= project.name %> |
      | k8s_deployment_name | hello-openshift     |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | my_secret      |
      | resource_name | dbsecret       |
      | resource_key  | mysql-password |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_resource_updated_message web console action with:
      | resource_name | hello-openshift |
    Then the step should succeed

    When I perform the :goto_one_k8s_replicaset_environment_tab web console action with:
      | project_name        | <%= project.name %> |
      | k8s_replicaset_name | frontend            |
    Then the step should succeed
    When I perform the :add_env_var_using_configmap_or_secret web console action with:
      | env_var_key   | my_secret      |
      | resource_name | dbsecret       |
      | resource_key  | mysql-password |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I perform the :check_resource_updated_message web console action with:
      | resource_name | frontend |
    Then the step should succeed

    # Check env vars
    When I perform the :goto_one_dc_environment_tab web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | database            |
    Then the step should succeed
    When I perform the :check_configmap_or_secret_env_var web console action with:
      | env_var_key   | my_secret      |
      | resource_name | dbsecret       |
      | resource_key  | mysql-password |
    Then the step should succeed

    When I perform the :goto_one_deployment_environment_tab web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | database            |
      | dc_number    | 2                   |
    Then the step should succeed
    When I perform the :check_environment_variable web console action with:
      | env_var_key   | my_secret                                        |
      | env_var_value | Set to the key mysql-password in secret dbsecret |
    Then the step should succeed

    When I perform the :goto_one_rc_environment_tab web console action with:
      | project_name | <%= project.name %> |
      | rc_name      | hello-idle          |
    Then the step should succeed
    When I perform the :check_configmap_or_secret_env_var web console action with:
      | env_var_key   | my_secret      |
      | resource_name | dbsecret       |
      | resource_key  | mysql-password |
    Then the step should succeed

    When I perform the :goto_one_k8s_deployment_environment_tab web console action with:
      | project_name        | <%= project.name %> |
      | k8s_deployment_name | hello-openshift     |
    Then the step should succeed
    When I perform the :check_configmap_or_secret_env_var web console action with:
      | env_var_key   | my_secret      |
      | resource_name | dbsecret       |
      | resource_key  | mysql-password |
    Then the step should succeed

    When I perform the :goto_one_k8s_replicaset_environment_tab web console action with:
      | project_name        | <%= project.name %> |
      | k8s_replicaset_name | frontend            |
    Then the step should succeed
    When I perform the :check_configmap_or_secret_env_var web console action with:
      | env_var_key   | my_secret      |
      | resource_name | dbsecret       |
      | resource_key  | mysql-password |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-18291
  Scenario: Create generic secret by uploading file on web console
    Given the master version >= "3.10"	
    Given I have a project
    
    #Create generic secret, input value directly
    When I perform the :create_generic_secret_from_user_input web console action with:
      | project_name    | <%= project.name %> |
      | secret_type     | Generic Secret      |
      | new_secret_name | secretone           |
      | item_key        | my.key              |
      | item_value      | my.value            |
    Then the step should succeed
    Given I wait for the "secretone" secret to appear
    When I perform the :goto_one_secret_page web console action with:
      | project_name    | <%= project.name %> |
      | secret          | secretone           |
    Then the step should succeed
    When I run the :click_reveal web console action
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | my.value |

    #Create generic secret, uploading file
    When I obtain test data file "routing/ca.pem"
    Then the step should succeed
    When I perform the :create_generic_secret_from_file web console action with:
      | project_name    | <%= project.name %> |
      | secret_type     | Generic Secret      |
      | new_secret_name | secrettwo           |
      | item_key        | my.key2             |
      | file_path       | <%= File.join(localhost.workdir, "ca.pem") %> |
    Then the step should succeed
    Given I wait for the "secrettwo" secret to appear
    When I perform the :goto_one_secret_page web console action with:
      | project_name    | <%= project.name %> |
      | secret          | secrettwo           |
    Then the step should succeed
    When I run the :click_reveal web console action
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | <%= File.read("ca.pem") %> |

    #Uploading file larger than 5MiB
    When I obtain test data file "secrets/testbigfile"
    Then the step should succeed
    When I perform the :create_generic_secret_from_file web console action with:
      | project_name    | <%= project.name %> |
      | secret_type     | Generic Secret      |
      | new_secret_name | secretthree         |
      | item_key        | my.key3             |
      | file_path       | <%= File.join(localhost.workdir, "testbigfile") %> |
    Then the step should succeed
    When I perform the :check_page_contain_text web console action with:
      | text | The file is too large |
    Then the step should succeed
    When I perform the :check_page_contain_text web console action with:
      | text | The web console has a 5 MiB file limit |
    Then the step should succeed
