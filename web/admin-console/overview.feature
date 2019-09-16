Feature: overview cases

  # @author yapei@redhat.com
  # @case_id OCP-20932
  Scenario: Check app resources on overview page
    Given the master version >= "4.1"
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/python:latest                 |
      | code         | https://github.com/sclorg/django-ex.git |
      | name         | python-sample                           |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | svc           | 
      | resource_name | python-sample |
    Then the step should succeed

    Given I open admin console in a browser
    When I perform the :goto_project_resources_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_list_heading_shown web action with:
      | heading | python-sample |
    Then the step should succeed

    # click list item will open sidebar
    When I perform the :click_list_item web action with:
      | resource_kind | DeploymentConfig |
      | resource_name | python-sample    |
    Then the step should succeed
    When I run the :sidebar_is_loaded web action
    Then the step should succeed

    # check basic info on overview view
    When I run the :click_sidebar_overview_tab web action
    Then the step should succeed
    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Name          |
      | value | python-sample |
    Then the step should succeed
    When I perform the :check_key_and_resource_link web action with:
      | key           | Namespace                                   |
      | resource_link | /k8s/cluster/namespaces/<%= project.name %> |
    Then the step should succeed
    When I perform the :check_key_and_action_link web action with:
      | key            | Tolerations   |
      | text_in_action | 0 Tolerations |
    Then the step should succeed
    When I perform the :check_key_and_action_link web action with:
      | key            | Annotations  |
      | text_in_action | 1 Annotation |
    Then the step should succeed
    When I perform the :check_pod_number web action with:
      | pod_number | 1 |
    Then the step should succeed

    # check builds, service, routes info on resources view
    When I run the :click_sidebar_resources_tab web action
    Then the step should succeed
    When I perform the :check_resource_name_and_icon web action with:
      | icon_text     | Service       |
      | resource_name | python-sample |
    Then the step should succeed
    When I perform the :check_resource_name_and_icon web action with:
      | icon_text     | BuildConfig   |
      | resource_name | python-sample |
    Then the step should succeed
    When I perform the :check_resource_name_and_icon web action with:
      | icon_text     | Route         |
      | resource_name | python-sample |
    Then the step should succeed

    # check resource links are correct
    When I perform the :check_resource_link web action with:
      | resource_link | /k8s/ns/<%= project.name %>/buildconfigs/python-sample |
    Then the step should succeed
    When I perform the :check_resource_link web action with:
      | resource_link | /k8s/ns/<%= project.name %>/services/python-sample |
    Then the step should succeed  
    When I perform the :check_resource_link web action with:
      | resource_link | /k8s/ns/<%= project.name %>/routes/python-sample |
    Then the step should succeed
    When I perform the :check_resource_link web action with:
      | resource_link | <%= route("python-sample").dns(by: user) %> |
    Then the step should succeed

    # check action menus available
    When I run the :click_resource_action_button web action
    Then the step should succeed
    When I run the :check_dc_available_action_menus web action
    Then the step should succeed
