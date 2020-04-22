Feature: Testing registry
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
    When I perform the :check_project_on_overview_page_in_iframe web action with:
      | project_name | test |
    Then the step should fail

    When I perform the :create_new_project_in_iframe web action with:
      | project_name | test |
      | description  | test |
      | display_name | test |
    Then the step should succeed
    When I perform the :check_project_on_overview_page_in_iframe web action with:
      | project_name | test |
    Then the step should succeed

  # @author xxia@redhat.com
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

  # @author yanpzhan@redhat.com
  # @case_id OCP-9895
  Scenario: Create ImageStream which sync all tags from remote repository on atomic-registry console
    Given I have a project
    And I open registry console in a browser
    When I run the :click_images_link_in_iframe web action
    Then the step should succeed
    When I perform the :create_new_image_stream_in_iframe web action with:
      | is_name      | test-busybox-is                              |
      | project_name | <%= project.name %>                          |
      | populate     | Sync all tags from a remote image repository |
      | pull_from    | docker.io/aosqe/busybox-multytags            |
    Then the step should succeed

    Given I wait for the "test-busybox-is" imagestreams to appear
    When I perform the :click_to_goto_one_image_page_in_iframe web action with:
      | project_name | <%= project.name %> |
      | image_name   | test-busybox-is     |
    Then the step should succeed
    When I perform the :check_image_tag_in_iframe_on_one_image_page web action with:
      | tag_label    | latest              |
      | project_name | <%= project.name %> |
      | image_name   | test-busybox-is     |
    Then the step should succeed
    When I perform the :check_image_tag_in_iframe_on_one_image_page web action with:
      | tag_label    | v1.2-5              |
      | project_name | <%= project.name %> |
      | image_name   | test-busybox-is     |
    Then the step should succeed
    When I perform the :check_image_tag_in_iframe_on_one_image_page web action with:
      | tag_label    | v1.3-2              |
      | project_name | <%= project.name %> |
      | image_name   | test-busybox-is     |
    Then the step should succeed
    When I perform the :check_image_tag_in_iframe_on_one_image_page web action with:
      | tag_label    | v1.3-3              |
      | project_name | <%= project.name %> |
      | image_name   | test-busybox-is     |
    Then the step should succeed
    When I perform the :check_image_tag_in_iframe_on_one_image_page web action with:
      | tag_label    | v1.3-4              |
      | project_name | <%= project.name %> |
      | image_name   | test-busybox-is     |
    Then the step should succeed

    When I perform the :check_info_on_one_image_tag_page_in_iframe web action with:
      | project_name | <%= project.name %> |
      | image_name   | test-busybox-is     |
      | tag_label    | latest              |
    Then the step should succeed

    When I perform the :click_a_link_in_iframe web action with:
      | link_text     | Show all images                    |
      | url_ends_with | <%= project.name %>/test-busybox-is|
    Then the step should succeed
    When I perform the :click_a_link_in_iframe web action with:
      | link_text     | Show all image streams     |
      | url_ends_with | images/<%= project.name %> |
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id OCP-9897
  Scenario: Check image info and delete image on registry console
    Given I have a project
    And I open registry console in a browser
    When I perform the :create_new_image_stream_in_iframe web action with:
      | is_name           | testisnew                                     |
      | project_name      | <%= project.name %>                           |
      | populate          | Sync all tags from a remote image repository  |
      | pull_from         | docker.io/openshift/hello-openshift           |
    Then the step should succeed
    Given I wait for the "testisnew:latest" imagestreamtags to appear
    When I perform the :goto_one_image_page web action with:
      | project_name | <%= project.name %> |
      | image_name   | testisnew           |
    Then the step should succeed
    When I perform the :tag_expands_in_iframe web action with:
      | tag_label   | latest  |
    Then the step should succeed
    When I perform the :check_image_tab_under_expanded_tag_in_iframe web action with:
      | project_name  | <%= project.name %> |
      | image_name    | testisnew           |
      | tag_label     | latest              |
    Then the step should succeed
    When I perform the :check_container_tab_under_expanded_tag_in_iframe web action with:
      | command     | /hello-openshift |
      | ports       | 8080/tcp         |
      | extra_ports | 8888/tcp         |
    Then the step should succeed
    When I run the :check_metadata_tab_under_expanded_tag_in_iframe web action
    Then the step should succeed
    When I perform the :tag_collapses_in_iframe web action with:
      | tag_label   | latest  |
    Then the step should succeed

    When I perform the :tag_expands_in_iframe web action with:
      | tag_label   | latest  |
    Then the step should succeed
    When I perform the :delete_tag_on_one_imagestream_page_in_iframe web action with:
      | project_name | <%= project.name %> |
      | image_name   | testisnew           |
      | tag_label    | latest              |
      | cancel       | true                |
    Then the step should succeed
    When I perform the :check_tag_missing_on_one_imagestream_page_in_iframe web action with:
      | project_name | <%= project.name %> |
      | image_name   | testisnew           |
      | tag_label    | latest              |
    Then the step should fail
    When I perform the :delete_tag_on_one_imagestream_page_in_iframe web action with:
      | project_name | <%= project.name %> |
      | image_name   | testisnew           |
      | tag_label    | latest              |
    Then the step should succeed
    When I perform the :check_tag_missing_on_one_imagestream_page_in_iframe web action with:
      | project_name | <%= project.name %> |
      | image_name   | testisnew           |
      | tag_label    | latest              |
    Then the step should succeed

  # @author xxia@redhat.com
  # @case_id OCP-9902
  Scenario: Create project and imagestream with invalid name on registry console
    Given I open registry console in a browser
    When I perform the :create_new_project_in_iframe web action with:
      | project_name  | $###@$%^^&&*&               |
      | prompt_msg    | contains invalid characters |
    Then the step should succeed
    When I perform the :create_new_project_in_iframe web action with:
      | project_name  | 123456789aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbb1234567 |
      | prompt_msg    | no more than 63 characters                                             |
    Then the step should succeed

    Given I have a project
    When I perform the :create_new_image_stream_in_iframe web action with:
      | is_name           | abc-dcna$                                     |
      | project_name      | <%= project.name %>                           |
      | populate          | Sync all tags from a remote image repository  |
      | pull_from         | docker.io/openshift/hello-openshift           |
      | prompt_msg        | contains invalid characters                   |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-9893
  Scenario: Check Projects page on atomic-registry web console
    Given I create 2 new projects
    And I open registry console in a browser
    When I run the :goto_projects_page web action
    Then the step should succeed
    When I perform the :select_project_dropdown_in_iframe web action with:
      | project_name | All Projects |
    Then the step should succeed
    When I run the :check_all_projects_page_in_iframe web action
    Then the step should succeed

    When I perform the :add_group_or_user_on_projects_page_in_iframe web action with:
      | type       | group       |
      | name       | test1       |
      | prompt_msg | User "<%= user.name %>" cannot create groups at the cluster scope |
    Then the step should succeed
    When I perform the :add_group_or_user_on_projects_page_in_iframe web action with:
      | type       | user        |
      | name       | test1       |
      | identity   | test1       |
      | prompt_msg | User "<%= user.name %>" cannot create users at the cluster scope |
    Then the step should succeed

    When I perform the :select_project_dropdown_in_iframe web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :check_project_membership_page_in_iframe web action
    Then the step should succeed

    When I perform the :click_a_link_in_iframe web action with:
      | link_text     | Show all Projects |
      | url_ends_with | projects          |
    Then the step should succeed
    When I run the :check_all_projects_page_in_iframe web action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-9894
  Scenario: Check Overview page on atomic-registry web console
    Given I have a project
    When I run the :tag client command with:
      | source_type  | docker                     |
      | source       | docker.io/library/busybox:latest   |
      | dest         | mystream:latest            |
    Then the step should succeed

    Given I open registry console in a browser
    When I run the :check_overview_page_in_iframe web action
    Then the step should succeed
    When I run the :check_docker_commands_in_iframe web action
    Then the step should succeed
    When I perform the :click_images_by_project_in_iframe web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_images_by_project_in_iframe web action with:
      | project_name | <%= project.name %> |
      | image_name   | mystream            |
    Then the step should succeed
    When I perform the :check_images_pushed_recently_in_iframe web action with:
      | project_name | <%= project.name %> |
      | image_name   | mystream            |
    Then the step should succeed
    When I perform the :check_all_images_overview_link_in_iframe web action with:
      | project_name | <%= project.name %> |
      | image_name   | mystream            |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-10498
  Scenario: Create shared project on registry console
    Given I open registry console in a browser
    When I perform the :create_new_project_in_iframe web action with:
      | project_name  | user1-test-prj                                      |
      | description   | test                                                |
      | display_name  | test                                                |
      | access_policy | Shared: Allow any authenticated user to pull images |
    Then the step should succeed

    # Allow time for the project to fully create and register the security policy before logout
    Given I use the "user1-test-prj" project
    Given I wait up to 60 seconds for the steps to pass:
    """
    Given the expression should be true> role_binding("registry-viewer").group_names(cached: false).include? "system:authenticated"
    """

    When I perform the :check_project_on_overview_page_in_iframe web action with:
      | project_name | user1-test-prj |
    Then the step should succeed
    When I run the :logout web action
    Then the step should succeed
    Given I switch to the second user
    When I run the :click_login_again web action
    Then the step should succeed
    And I perform login to registry console in the browser
    When I perform the :check_project_on_overview_page_in_iframe web action with:
      | project_name | user1-test-prj |
    Then the step should succeed
