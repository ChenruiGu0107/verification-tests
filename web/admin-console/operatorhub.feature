Feature: operatorhub feature related

  # @author hasha@redhat.com
  # @case_id OCP-24340
  @admin
  Scenario: Add "custom form" vs "YAML editor" on "Create Custom Resource" page	
    Given the master version >= "4.3"
    Given I have a project
    Given the first user is cluster-admin
    And I open admin console in a browser
    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | etcd                   |
      | catalog_name     | community-operators    |
      | target_namespace | <%= project.name %>    |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text  | Subscribe |
    Then the step should succeed

    """
    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :create_custom_resource web action with:
      | api      | etcd Cluster |
    Then the step should succeed
    """
    When I perform the :click_button web action with:
      | button_text  | Edit Form |
    Then the step should succeed
    When I perform the :clear_input_value web action with:
     | clear_field_id | metadata.name |
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should match:
      | Error.*Required value: name or generateName is required |
    """
    When I perform the :set_input_value web action with:
      | input_field_id | metadata.name |
      | input_value    | example       |
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | etcdclusters |
    Then the step should succeed
    And the output should contain "example"
