Feature: build related

  # @author yapei@redhat.com
  # @case_id OCP-19667
  Scenario: Check builds on console
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/python:latest                 |
      | code         | https://github.com/sclorg/django-ex.git |
      | name         | python-sample                           |
    Then the step should succeed
    Given I open admin console in a browser

    # check BC details
    When I perform the :goto_one_buildconfig_page web action with:
      | project_name  | <%= project.name %>  |
      | bc_name       | python-sample        |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name          | python-sample                           |
      | labels        | app=python-sample                       |
      | type          | Source                                  |
      | namespace     | <%= project.name %>                     |
      | git_repo      | https://github.com/sclorg/django-ex.git |
      | builder_image | python:latest                           |
      | output_image  | python-sample:latest                    |
      | run_policy    | Serial                                  |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text      | <%= project.name %>                         |
      | link_url  | /k8s/cluster/namespaces/<%= project.name %> |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text      | python:latest                            |
      | link_url  | /k8s/ns/openshift/imagestreamtags/python |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text      | python-sample:latest                                       |
      | link_url  | /k8s/ns/<%= project.name %>/imagestreamtags/python-sample  |
    Then the step should succeed
    # bug 1664574
    # When I get the html of the web page
    # Then the output should match:
    #  | build.openshift.io/v1/namespaces/<%= project.name %>/buildconfigs/python-sample/webhooks/.*secret.*/generic |
    # When I perform the :check_link web action with:
    #  | link_url | https://172.30.0.1:443/apis/build.openshift.io/v1/namespaces/yapei/buildconfigs/python-sample/webhooks/<secret>/generic |
    # Then the step should succeed

    # check Builds details
    Given the "python-sample-1" build was created 
    When I perform the :goto_one_build_page web action with:
      | project_name  | <%= project.name %>  |
      | build_name    | python-sample-1      |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name         | python-sample-1     |
      | type         | Source              |
      | namespace    | <%= project.name %> |
      | owner        | python-sample       |
      | triggered_by | Image               |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text      | python-sample                                          |
      | link_url  | /k8s/ns/<%= project.name %>/buildconfigs/python-sample |
    Then the step should succeed

    # trigger new build via Start Build action
    When I perform the :goto_one_buildconfig_page web action with:
      | project_name  | <%= project.name %>  |
      | bc_name       | python-sample        |
    Then the step should succeed
    When I run the :start_build_action web action
    Then the step should succeed
    Given the "python-sample-2" build was created
    When I perform the :goto_one_build_page web action with:
      | project_name  | <%= project.name %>  |
      | build_name    | python-sample-2      |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | triggered_by | Manually |
    Then the step should succeed

    # Delete BC and its builds
    When I perform the :goto_one_buildconfig_page web action with:
      | project_name  | <%= project.name %>  |
      | bc_name       | python-sample        |
    Then the step should succeed
    When I run the :delete_buildconfig_action web action
    Then the step should succeed
    When I perform the :delete_resource_panel web action with:
      | cascade | true |
    Then the step should succeed
    Given I wait for the resource "buildconfig" named "python-sample" to disappear within 60 seconds
    Given I wait for the resource "builds" named "python-sample-1" to disappear within 60 seconds

  # @author yapei@redhat.com
  # @case_id OCP-25795
  Scenario: Check deprecation note of pipeline build strategy
    Given I have a project
    Given I obtain test data file "pipeline/samplepipeline.yaml"
    When I run the :new_app client command with:
      | source_spec | samplepipeline.yaml |
    Then the step should succeed
    Given I open admin console in a browser
    When I perform the :goto_one_buildconfig_page web action with:
      | project_name  | <%= project.name %>  |
      | bc_name       | sample-pipeline      |
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | Pipeline build strategy deprecation |
    Then the step should succeed
    When I run the :check_links_in_pipeline_deprecation_note web action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-24232
  Scenario: Support Cancel action for Builds
    Given the master version >= "4.2"
    Given I have a project
    Given I open admin console in a browser
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:2.5                    |
      | code         | https://github.com/sclorg/ruby-ex.git |
      | name         | ruby-sample                           |
    Then the step should succeed

    # cancel running build from one build page
    Given the "ruby-sample-1" build becomes :running
    When I perform the :goto_one_build_page web action with:
      | project_name  | <%= project.name %>  |
      | build_name    | ruby-sample-1        |
    Then the step should succeed
    When I run the :cancel_build_action web action
    Then the step should succeed
    When I perform the :confirm_cancel_action web action with:
      | cancel | true |
    Then the step should succeed

    When I run the :rebuild_action web action
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample |
    Then the step should succeed
    When I run the :cancel_build_action web action
    Then the step should succeed
    When I perform the :confirm_cancel_action web action with:
      | cancel | false |
    Then the step should succeed

    # cancel new build from builds list page
    When I perform the :goto_builds_page web action with:
      | project_name  | <%= project.name %>  |
    Then the step should succeed
    Given the "ruby-sample-3" build becomes :new
    When I perform the :cancel_build_kebab_operation web action with:
      | resource_name  | ruby-sample-3 |
    Then the step should succeed
    When I perform the :confirm_cancel_action web action with:
      | cancel | true |
    Then the step should succeed

    Given I wait up to 10 seconds for the steps to pass:
    """
    When I get project builds
    Then the output should match:
      | ruby-sample-1.+Cancelled  |
      | ruby-sample-3.+Cancelled  |
    """


  # @author hasha@redhat.com
  # @case_id OCP-23967
  Scenario: explore sidebar for YAML editor
    Given the master version >= "4.3"
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/python:latest                 |
      | code         | https://github.com/sclorg/django-ex.git |
      | name         | python-sample                           |
    Then the step should succeed
    Given I open admin console in a browser

    # check BC breadcrumb_sidebar
    When I perform the :goto_one_buildconfig_page web action with:
      | project_name  | <%= project.name %>  |
      | bc_name       | python-sample        |
    Then the step should succeed
    When I run the :click_yaml_tab web action
    Then the step should succeed
    When I run the :open_view_sidebar web action
    Then the step should succeed
    When I run the :view_schema_definition_of_bc_output_name web action
    Then the step should succeed
    When I perform the :click_item_in_breadcrumb web action with:
      | breadcrumb_item | output |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | output describes the container image the Strategy should produce. |
    Then the step should succeed
    When I run the :close_view_sidebar web action
    Then the step should succeed

    #check build breadcrumb_sidebar
    When I perform the :goto_one_build_page web action with:
      | project_name  | <%= project.name %>  |
      | build_name    | python-sample-1      |
    Then the step should succeed
    When I run the :click_yaml_tab web action
    Then the step should succeed
    When I run the :open_view_sidebar web action
    Then the step should succeed
    When I run the :view_schema_definition_of_build_postcommit_command_field web action
    Then the step should succeed
    When I perform the :click_item_in_breadcrumb web action with:
      | breadcrumb_item | spec |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | spec is all the inputs used to execute the build |
    Then the step should succeed

    #check breadcrumb_sidebar when creating resource by yaml editor
    When I perform the :goto_deployment_page web action with:
      | project_name  | <%= project.name %>  |
    Then the step should succeed
    When I run the :click_yaml_create_button web action
    Then the step should succeed
    When I run the :view_schema_definition_of_for_replicas_field web action
    Then the step should succeed
    When I run the :close_view_sidebar web action
    Then the step should succeed

