Feature: Pod related features on web console
  # @author etrott@redhat.com
  # @case_id OCP-14311
  Scenario: Pod details should show information about init containers.
    Given the master version >= "3.6"
    Given I have a project
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/initContainers/initContainer.yaml  |
    Then the step should succeed

    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | hello-pod           |
    Then the step should succeed
    When I perform the :check_container_status_on_one_pod_page web console action with:
      | name          | wait    |
      | state         | Running |
      | ready         | false   |
      | restart_count | 0       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=hello-pod |
    When I perform the :check_container_status_on_one_pod_page web console action with:
      | name          | hello-pod |
      | state         | Running   |
      | ready         | true      |
      | restart_count | 0         |
    Then the step should succeed
    When I perform the :check_init_container_successfully_completed_message web console action with:
      | name | wait |
    Then the step should succeed

    When I perform the :check_container_template_on_one_pod_page web console action with:
      | name    | wait   |
      | image   | centos |
      | command |        |
      | mount   |        |
    Then the step should succeed

    When I perform the :check_container_template_on_one_pod_page web console action with:
      | name  | hello-pod |
      | ports | 8080/TCP  |
      | mount |           |
    Then the step should succeed
