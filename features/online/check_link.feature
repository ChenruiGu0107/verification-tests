Feature: Check links in Openshift

  # @author etrott@redhat.com
  # @case_id OCP-10251
  Scenario: Check the doc links on web page
    # check documentation link in getting started instructions
    When I run the :check_default_documentation_link_in_get_started_online web console action
    Then the step should succeed

    # check Documentation link on /console help
    When I run the :check_default_documentation_link_in_console_help_online web console action
    Then the step should succeed

    # check docs link in about page
    When I run the :check_default_documentation_link_in_about_page_online web console action
    Then the step should succeed

    # check docs link on command line page
    When I run the :check_get_started_with_cli_doc_link_in_cli_page_online web console action
    Then the step should succeed
    When I run the :check_cli_reference_doc_link_in_cli_page_online web console action
    Then the step should succeed
    When I run the :check_basic_cli_reference_doc_link_in_cli_page_online web console action
    Then the step should succeed

    # check doc link on next step page
    When I create a new project via web
    Then the step should succeed
    When I perform the :check_documentation_link_in_next_step_page_online web console action with:
      | project_name | <%= project.name %>   |
      | image_name   | nodejs                |
      | image_tag    | 0.10                  |
      | namespace    | openshift             |
      | app_name     | nodejs-sample         |
      | source_url   | https://github.com/openshift/nodejs-ex |
    Then the step should succeed

    # check docs link about build
    When I perform the :check_webhook_trigger_doc_link_in_bc_page_online web console action with:
      | project_name | <%= project.name %>   |
      | bc_name      | nodejs-sample         |
    Then the step should succeed
    When I perform the :check_start_build_doc_link_in_bc_page_online web console action with:
      | project_name | <%= project.name %>   |
      | bc_name      | nodejs-sample         |
    Then the step should succeed

    # check doc link about deployment
    When I perform the :check_documentation_link_in_dc_page_online web console action with:
      | project_name | <%= project.name %>  |
      | dc_name      | nodejs-sample        |
    Then the step should succeed

    # check doc links on create route page
    When I perform the :check_route_type_doc_link_on_create_route_page_online web console action with:
      | project_name | <%= project.name %>  |
    Then the step should succeed

    # check doc links about pv
    When I perform the :check_pv_doc_link_on_attach_page_online web console action with:
      | project_name | <%= project.name %>  |
      | dc_name      | nodejs-sample        |
    Then the step should succeed

    # check doc link about compute resource
    When I perform the :check_compute_resource_doc_link_on_set_limit_page_online web console action with:
      | project_name | <%= project.name %>  |
      | dc_name      | nodejs-sample        |
    Then the step should succeed

    # check doc link about health check
    When I perform the :check_health_check_doc_link_on_edit_health_check_page_online web console action with:
      | project_name | <%= project.name %>  |
      | dc_name      | nodejs-sample        |
    Then the step should succeed

    # check doc link about autoscaler
    When I perform the :check_autoscaler_doc_link_on_add_autoscaler_page_online web console action with:
      | project_name | <%= project.name %>  |
      | dc_name      | nodejs-sample        |
    Then the step should succeed

  # @author yasun@redhat.com
  # @case_id OCP-9873
  Scenario: Check the CLI download links on web page
    When I run the :version client command
    Then the step should succeed
    And evaluation of `@result[:props][:openshift_server_version]` is stored in the :server_version clipboard

    # check the download links on command line page
    When I perform the :check_download_cli_doc_link_in_cli_page_online web console action with:
      | platform     | Linux (64 bits)                           |
      | download_url | <%= cb.server_version %>/linux/oc.tar.gz  |
    Then the step should succeed
    When I perform the :check_download_cli_doc_link_in_cli_page_online web console action with:
      | platform     | Mac OS X                                  |
      | download_url | <%= cb.server_version %>/macosx/oc.tar.gz |
    Then the step should succeed
    When I perform the :check_download_cli_doc_link_in_cli_page_online web console action with:
      | platform     | Windows                                   |
      | download_url | <%= cb.server_version %>/windows/oc.zip   |
    Then the step should succeed

    # check the effectiveness of the download links
    # store the link in clipboard
    When I get the "href" attribute of the "a" web element:
      | text  | Linux (64 bits) |
    And evaluation of `@result[:response]` is stored in the :linux clipboard
    When I get the "href" attribute of the "a" web element:
      | text  | Mac OS X        |
    And evaluation of `@result[:response]` is stored in the :macosx clipboard
    When I get the "href" attribute of the "a" web element:
      | text  | Windows         |
    And evaluation of `@result[:response]` is stored in the :windows clipboard

    Given I have a project
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl | -I | <%= cb.linux %>   |
    Then the output should match "HTTP/.* 200 OK"
    When I execute on the pod:
      | curl | -I | <%= cb.macosx %>  |
    Then the output should match "HTTP/.* 200 OK"
    When I execute on the pod:
      | curl | -I | <%= cb.windows %> |
    Then the output should match "HTTP/.* 200 OK"
