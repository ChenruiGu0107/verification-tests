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

    # wait until etcd operator is successfully installed
    Given I use the "<%= project.name %>" project
    Given a pod becomes ready with labels:
      | name=etcd-operator-alm-owned |

    # create etcd Cluster via Edit Form
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :create_custom_resource web action with:
      | api      | etcd Cluster |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text  | Edit Form |
    Then the step should succeed
    When I run the :clear_custom_resource_name_in_form web action
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    When I run the :check_error_message_for_missing_required_name web action
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


  # @author hasha@redhat.com
  # @case_id OCP-25931
  @admin
  @destructive
  Scenario: check Custom serviceCatalog on console
    Given the master version >= "4.3"
    Given I have a project
    Given the first user is cluster-admin
    Given I open admin console in a browser
    Given admin ensures "custom-logging" catalog_source is deleted from the "openshift-marketplace" project after scenario
    And admin ensures "custom-logging-ns" catalog_source is deleted from the "default" project after scenario
    When I perform the :create_catalog_source web action with:
      | catalog_source_name | custom-logging        |
      | display_name        | custom-logging        |
      | publisher_name      | custom-logging        |
      | image               | docker.io/aosqe/logging:latest |
    Then the step should succeed
    And I wait up to 420 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | cluster-logging     |
      | catalog_name     | custom-logging      |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text  | Subscribe |
    Then the step should succeed
    """
    Then I wait for the "cluster-logging" subscription to appear in the "<%= project.name %>" project up to 30 seconds
    When I run the :goto_catalog_source_page web action
    Then the step should succeed
    When I run the :wait_box_loaded web action
    Then the step should succeed
    When I perform the :click_one_operation_in_kebab web action with:
      | resource_name | custom-logging       |
      | button_text   | Delete CatalogSource |
    Then the step should succeed
    When I perform the :confirm_deletion web action with:
      | resource_name | custom-logging |
    Then the step should succeed
    And I wait for the resource "catalogsource" named "cluster-logging" to disappear within 30 seconds
    When I perform the :goto_one_project_subscription_page web action with:
      | project_name      | <%= project.name %> |
      | subscription_name | cluster-logging     |
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | Catalog Source Removed |
    Then the step should succeed
    Then I wait up to 60 seconds for the steps to pass:
    """
    When I perform the :create_catalog_source web action with:
      | catalog_source_name | custom-logging-ns |
      | display_name        | custom-logging-ns |
      | publisher_name      | custom-logging-ns |
      | item                | default           |
      | image               | docker.io/aosqe/logging:latest |
    Then the step should succeed
    """
    Then I wait for the "cluster-logging" packagemanifests to appear in the "default" project up to 30 seconds
    And the packagemanifests named "cluster-logging" does not exist in the "openshift-console" project
