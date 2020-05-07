Feature: web secrets related
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
