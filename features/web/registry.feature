Feature: Testing registry

  # @author etrott@redhat.com
  # @case_id OCP-10224
  @admin
  Scenario: Login and logout of standalone registry console
    Given I have a project
    And I open registry console in a browser

    When I run the :click_images_link_in_iframe web action
    Then the step should succeed
    When I run the :check_no_images_on_images_page_in_iframe web action
    Then the step should succeed

    When I run the :goto_registry_console web action
    Then the step should succeed
    When I run the :click_images_link_in_iframe web action
    Then the step should succeed
    When I run the :check_no_images_on_images_page_in_iframe web action
    Then the step should succeed

    When I run the :logout web action
    Then the step should succeed
    When I run the :click_login_again web action
    Then the step should succeed
    When I perform login to registry console in the browser
    Then the step should succeed
    When I run the :click_images_link_in_iframe web action
    Then the step should succeed
    When I run the :check_no_images_on_images_page_in_iframe web action
    Then the step should succeed

    When I run the :logout web action
    Then the step should succeed
    When I run the :goto_registry_console web action
    Then the step should succeed

    When I perform login to registry console in the browser
    Then the step should succeed
    When I run the :click_images_link_in_iframe web action
    Then the step should succeed
    When I run the :check_no_images_on_images_page_in_iframe web action
    Then the step should succeed


  # @author etrott@redhat.com
  # @case_id OCP-9901
  @admin
  Scenario: Create image stream from Overview page on atomic-registry web console
    Given I have a project
    Given I open registry console in a browser

    When I perform the :check_project_in_iframe_on_overview_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    When I perform the :create_new_image_stream_in_iframe web action with:
      | is_name      | testis              |
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | is/testis |
    Then the step should succeed

    When I perform the :create_new_image_stream_in_iframe web action with:
      | is_name      | testisnew                                    |
      | project_name | <%= project.name %>                          |
      | populate     | Sync all tags from a remote image repository |
      | pull_from    | docker.io/openshift/hello-openshift          |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | is/testisnew |
    Then the step should succeed

    When I perform the :click_to_goto_one_image_page_in_iframe web action with:
      | project_name | <%= project.name %> |
      | image_name   | testisnew           |
    Then the step should succeed
    When I perform the :check_image_info_in_iframe_on_one_image_page web action with:
      | pull_repository | docker.io/openshift/hello-openshift |
    Then the step should succeed
    When I perform the :check_image_tag_in_iframe_on_one_image_page web action with:
      | project_name | <%= project.name %> |
      | image_name   | testisnew           |
      | tag_label    | latest              |
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-9899
  @admin
  Scenario: Create anonymous project
    Given I open registry console in a browser

    When I perform the :create_new_project_in_iframe web action with:
      | project_name | test |
      | description  | test |
      | display_name | test |
      | cancel       | true |
    Then the step should succeed
    When I perform the :check_project_in_iframe_on_overview_page web action with:
      | project_name | test |
    Then the step should fail

    When I perform the :create_new_project_in_iframe web action with:
      | project_name | test |
      | description  | test |
      | display_name | test |
    Then the step should succeed
    When I perform the :check_project_in_iframe_on_overview_page web action with:
      | project_name | test |
    Then the step should succeed

  # @author cryan@redhat.com xxia@redhat.com
  # @case_id OCP-9896
  Scenario: Create ImageStream pull specific tags from remote repository on atomic-registry console
    Given I have a project
    And I open registry console in a browser
    When I perform the :create_new_image_stream_in_iframe web action with:
      | is_name           | testisnew                                        |
      | project_name      | <%= project.name %>                              |
      | populate          | Pull specific tags from another image repository |
      | pull_from         | docker.io/aosqe/ruby-20-centos7                  |
      | tags              | user0,user1001                                   |
    Then the step should succeed
    When I perform the :goto_one_image_page web action with:
      | project_name | <%= project.name %> |
      | image_name   | testisnew           |
    Then the step should succeed
    # Bug 1373332
    When I perform the :check_image_tag_in_iframe_on_one_image_page web action with:
      | project_name | <%= project.name %> |
      | image_name   | testisnew           |
      | tag_label    | latest              |
    Then the step should fail
    When I perform the :check_image_tag_in_iframe_on_one_image_page web action with:
      | project_name | <%= project.name %> |
      | image_name   | testisnew           |
      | tag_label    | user0               |
    Then the step should succeed
    When I perform the :goto_one_image_page web action with:
      | project_name | <%= project.name %> |
      | image_name   | testisnew           |
    Then the step should succeed
    When I perform the :check_image_tag_in_iframe_on_one_image_page web action with:
      | project_name | <%= project.name %> |
      | image_name   | testisnew           |
      | tag_label    | user1001            |
    Then the step should succeed
