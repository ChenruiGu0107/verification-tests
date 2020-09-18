Feature: pods related feature

  # @author yanpzhan@redhat.com
  # @case_id OCP-26868
  Scenario: Show metrics, ready count, and restarts in pod list table
    Given the master version >= "4.4"
    Given I have a project
    Given I obtain test data file "deployment/hello-deployment-1.yaml"
    When I run the :create client command with:
      | f | hello-deployment-1.yaml |
      | n | <%= project.name %>     |
    Then the step should succeed
    Given 10 pods become ready with labels:
      | app=hello-openshift |
    Given I open admin console in a browser
    When I perform the :goto_project_pods_list_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    When I run the :check_column_header_items_on_pods_list_page web action
    Then the step should succeed

    When I perform the :check_ready_count_items_on_pods_list_page web action with:
      | ready_count | 1/1 |
    Then the step should succeed

    When I run the :check_memory_descending_sorted_on_pods_list_page web action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-32152
  @admin
  Scenario: Project selector set back to all projects when navigating back to list view
    Given the master version >= "4.6"
    And the first user is cluster-admin
    Given I open admin console in a browser

    # Check resource list set back to "all project" for current resource list
    When I run the :goto_all_projects_pods_list web action
    Then the step should succeed
    When I run the :check_project_dropdown_selected_all_projects web action
    Then the step should succeed
    When I run the :click_first_item_in_grid_cell_list web action
    Then the step should succeed
    When I run the :check_project_dropdown_not_selected_all_projects web action
    Then the step should succeed
    # need manually switch to all project from project-dropdown at very 1st time
    # Won't fix a minor issue: https://bugzilla.redhat.com/show_bug.cgi?id=1853187
    When I perform the :switch_to_project web action with:
      | project_name | all projects |
    Then the step should succeed
    When I run the :goto_all_projects_pods_list web action
    Then the step should succeed
    When I run the :click_first_item_in_grid_cell_list web action
    Then the step should succeed   
    When I perform the :check_link_in_breadcrumb web action with:
      | layer_number | 1                   |
      | link         | all-namespaces/pods |
      | text         | Pods                |
    Then the step should succeed
    When I perform the :check_secondary_menu_link web action with:
      | secondary_menu | Deployments                |
      | text           | Deployments                |
      | link_url       | all-namespaces/deployments |
    Then the step should succeed
    When I perform the :check_secondary_menu_link web action with:
      | secondary_menu | Secrets                |
      | text           | Secrets                |
      | link_url       | all-namespaces/secrets |
    Then the step should succeed
    When I perform the :check_secondary_menu_link web action with:
      | secondary_menu | Jobs                |
      | text           | Jobs                |
      | link_url       | all-namespaces/jobs |
    Then the step should succeed

    # Check resource list set back to "all project" 
    # from cluster resource detail page to anothor resource list
    When I run the :goto_all_installed_operators_page web action
    Then the step should succeed
    When I run the :click_first_item_in_grid_cell_list web action
    Then the step should succeed 
    When I perform the :check_link_and_text web action with:
      | text         | Installed Operators                 |
      | link_url     | all-namespaces/operators.coreos.com |
    Then the step should succeed
    When I perform the :click_primary_menu web action with:
      | primary_menu | Workloads |
    Then the step should succeed
    When I perform the :check_secondary_menu_link web action with:
      | secondary_menu | Deployment Configs               |
      | text           | Deployment Configs               |
      | link_url       | all-namespaces/deploymentconfigs |
    Then the step should succeed
    When I perform the :check_secondary_menu_link web action with:
      | secondary_menu | Replica Sets               |
      | text           | Replica Sets               |
      | link_url       | all-namespaces/replicasets |
    Then the step should succeed
    When I perform the :check_secondary_menu_link web action with:
      | secondary_menu | Replication Controllers               |
      | text           | Replication Controllers               |
      | link_url       | all-namespaces/replicationcontrollers |
    Then the step should succeed

    # Check resource list should not set back to "all project" after change project-selector
    When I run the :goto_all_projects_pods_list web action
    Then the step should succeed
    When I perform the :switch_to_project web action with:
      | project_name | openshift-console |
    Then the step should succeed
    When I run the :click_first_item_in_grid_cell_list web action
    Then the step should succeed 
    When I perform the :check_link_in_breadcrumb web action with:
      | layer_number | 1                      |
      | link         | openshift-console/pods |
      | text         | Pods                   |
    Then the step should succeed
    When I perform the :check_secondary_menu_link web action with:
      | secondary_menu | Deployments                   |
      | text           | Deployments                   |
      | link_url       | openshift-console/deployments |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-33568
  @admin
  Scenario: column management for resource tables
    Given the master version >= "4.6"
    Given I have a project
    When I run the :new_app client command with:
      | template | httpd-example |
    Then the step should succeed
    Given a pod is present with labels:
      | name=httpd-example |

    # column management on one Project Pods list page
    Given I open admin console in a browser
    When I run the :navigate_to_admin_console web action
    Then the step should succeed
    When I perform the :check_default_columns_in_one_project_pods_list_table web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :change_one_project_pods_list_columns web action
    Then the step should succeed
    When I run the :check_changed_one_project_pods_list_columns web action
    Then the step should succeed

    # column management on Projects list page - normal user
    When I run the :check_default_columns_in_projects_list_table web action
    Then the step should succeed
    When I run the :change_projects_list_columns web action
    Then the step should succeed
    When I run the :check_changed_projects_list_columns web action
    Then the step should succeed

    # column management on Namespaces list page
    Given the first user is cluster-admin
    When I run the :check_default_columns_in_namespaces_list_table web action
    Then the step should succeed
    When I run the :change_namespaces_list_columns web action
    Then the step should succeed
    When I run the :check_changed_namespaces_list_columns web action
    Then the step should succeed

    # column management on Nodes list page
    When I run the :check_default_columns_in_nodes_list_table web action
    Then the step should succeed
    When I run the :change_nodes_list_columns web action
    Then the step should succeed
    When I run the :check_changed_nodes_list_columns web action
    Then the step should succeed

    # column management on All Projects Pods list page
    When I run the :check_updated_columns_in_all_projects_pods_list_table web action
    Then the step should succeed
    When I run the :change_all_projects_pods_list_columns_but_reset web action
    Then the step should succeed
    When I run the :check_default_columns_in_all_projects_pods_list_table web action
    Then the step should succeed

    # column management on All Projects list page - cluster-admin
    When I run the :check_changed_columns_in_all_projects_list_table web action
    Then the step should succeed   
