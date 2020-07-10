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

