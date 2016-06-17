Feature: Check links in Openshift
  # @author yapei@redhat.com
  # @case_id 515807
  Scenario: check doc links in web
    # check documentation link in getting started instructions
    When I perform the :check_default_documentation_link_in_get_started web console action with:
      | default_documentation_link | https://docs.openshift.com/enterprise/latest/welcome/index.html |
    Then the step should succeed
    
    # check Documentation link on /console help
    When I perform the :check_default_documentation_link_in_console_help web console action with:
      | default_documentation_link | https://docs.openshift.com/enterprise/latest/welcome/index.html |
    Then the step should succeed
    
    # check docs link in about page
    When I perform the :check_default_documentation_link_in_about_page web console action with:
      | default_documentation_link | https://docs.openshift.com/enterprise/latest/welcome/index.html |
    Then the step should succeed
    When I perform the :check_cli_reference_doc_link_in_about_page web console action with:
      | cli_reference_doc_link | https://docs.openshift.com/enterprise/latest/cli_reference/overview.html |
    Then the step should succeed
    When I perform the :check_basic_cli_reference_doc_link_in_about_page web console action with:
      | basic_cli_reference_doc_link | https://docs.openshift.com/enterprise/latest/cli_reference/basic_cli_operations.html |
    Then the step should succeed
    
    # check docs link on command line page
    When I perform the :check_get_started_with_cli_doc_link_in_cli_page web console action with:
      | get_started_cli_doc_link | https://docs.openshift.com/enterprise/latest/cli_reference/get_started_cli.html |
    Then the step should succeed
    When I perform the :check_cli_reference_doc_link_in_cli_page web console action with:
      | cli_reference_doc_link | https://docs.openshift.com/enterprise/latest/cli_reference/overview.html |
    Then the step should succeed
    When I perform the :check_basic_cli_reference_doc_link_in_cli_page web console action with:
      | basic_cli_reference_doc_link | https://docs.openshift.com/enterprise/latest/cli_reference/basic_cli_operations.html |
    Then the step should succeed

    # check doc link on next step page
    When I create a new project via web
    Then the step should succeed
    When I perform the :check_documentation_link_in_next_step_page web console action with:
      | project_name | <%= project.name %>   |
      | image_name   | nodejs                |
      | image_tag    | 0.10                  |
      | namespace    | openshift             |
      | app_name     | nodejs-sample         |
      | source_url   | https://github.com/openshift/nodejs-ex |
      | cli_reference_doc_link | https://docs.openshift.com/enterprise/latest/cli_reference/overview.html |
      | basic_cli_reference_doc_link | https://docs.openshift.com/enterprise/latest/cli_reference/basic_cli_operations.html |
      | webhook_trigger_doc_link | https://docs.openshift.com/enterprise/latest/dev_guide/builds.html#webhook-triggers |
    Then the step should succeed
    
    # check docs link about build
    When I perform the :check_webhook_trigger_doc_link_in_bc_page web console action with:
      | project_name | <%= project.name %>   |
      | bc_name      | nodejs-sample         |
      | webhook_trigger_doc_link | https://docs.openshift.com/enterprise/latest/dev_guide/builds.html#webhook-triggers |
    Then the step should succeed
    When I perform the :check_start_build_doc_link_in_bc_page web console action with:
      | project_name | <%= project.name %>   |
      | bc_name      | nodejs-sample         |
      | start_build_doc_link | https://docs.openshift.com/enterprise/latest/dev_guide/builds.html#starting-a-build |
    Then the step should succeed

    # check doc link about deployment
    When I perform the :check_documentation_link_in_dc_page web console action with:
      | project_name | <%= project.name %>  |
      | dc_name      | nodejs-sample        |
      | deployment_operation_doc_link | https://docs.openshift.com/enterprise/latest/cli_reference/basic_cli_operations.html#build-and-deployment-cli-operations |
    Then the step should succeed

    # check doc links on create route page
    When I perform the :check_route_type_doc_link_on_create_route_page web console action with:
      | project_name | <%= project.name %>  |
      | route_type_doc_link | https://docs.openshift.com/enterprise/latest/architecture/core_concepts/routes.html#route-types |
    Then the step should succeed

    # check doc links about pv
    When I perform the :check_pv_doc_link_on_attach_page web console action with:
      | project_name | <%= project.name %>  |
      | dc_name      | nodejs-sample        |
      | pv_doc_link  | https://docs.openshift.com/enterprise/latest/dev_guide/persistent_volumes.html |
    Then the step should succeed

    # check doc link about compute resource
    When I perform the :check_compute_resource_doc_link_on_set_limit_page web console action with:
      | project_name | <%= project.name %>  |
      | dc_name      | nodejs-sample        |
      | compute_resource_doc_link | https://docs.openshift.com/enterprise/latest/dev_guide/compute_resources.html |
    Then the step should succeed
    #TODO: will add check links for pod autoscaler and health check once merged in 3.3
