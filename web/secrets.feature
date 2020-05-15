Feature: web secrets related
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
