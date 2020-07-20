Feature: search page related

  # @author yanpzhan@redhat.com
  # @case_id OCP-27550
  @admin
  Scenario: Allow users to search for more than one resource type on search page
    Given the master version >= "4.4"
    Given the first user is cluster-admin
    And I open admin console in a browser
    When I run the :goto_search_page web action
    Then the step should succeed
    When I perform the :switch_to_project web action with:
      | project_name | all projects |
    Then the step should succeed

    #search by resource
    When I perform the :search_by_resource web action with:
      | resource_kind | Alertmanager |
    Then the step should succeed
    When I perform the :check_resource_tile web action with:
      | resource_kind  | Alertmanagers            |
      | resource_group | monitoring.coreos.com/v1 |
    Then the step should succeed
    When I perform the :search_by_resource web action with:
      | resource_kind  | Build               |
      | resource_group | config.openshift.io |
    Then the step should succeed
    When I perform the :check_resource_tile web action with:
      | resource_kind  | Builds              |
      | resource_group | config.openshift.io |
    Then the step should succeed

    When I perform the :clear_one_search_item web action with:
      | search_item | Build |
    Then the step should succeed
    When I perform the :check_resource_tile web action with:
      | resource_kind  | Builds              |
      | resource_group | config.openshift.io |
    Then the step should fail

    When I perform the :search_by_resource web action with:
      | resource_kind | Deployment |
    Then the step should succeed
    When I perform the :check_resource_tile web action with:
      | resource_kind  | Deployments |
      | resource_group | apps/v1     |
    Then the step should succeed

    # filter by label
    When I perform the :set_filter_content_on_search_page web action with:
      | filter_content | alertmanager=main |
    Then the step should succeed
    When I perform the :press_input_enter_on_search_page web action with:
      | press_enter | :return |
    Then the step should succeed
    When I perform the :check_item_in_table web action with:
      | item | main |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | No Deployments Found |
    Then the step should succeed
    When I perform the :clear_one_search_item web action with:
      | search_item | alertmanager=main |
    Then the step should succeed

    # filter by name
    When I perform the :choose_filter_type_on_search_page web action with:
      | filter_type | Name |
    Then the step should succeed
    When I perform the :set_filter_content_on_search_page web action with:
      | filter_content | console |
    Then the step should succeed
    When I perform the :press_input_enter_on_search_page web action with:
      | press_enter | :return |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | No Alertmanagers Found |
    Then the step should succeed
    When I perform the :check_item_in_table web action with:
      | item | console-operator |
    Then the step should succeed

    Given I wait up to 30 seconds for the steps to pass:
    """
    When I run the :clear_all_filters web action
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | No resources selected |
    Then the step should succeed
    """
