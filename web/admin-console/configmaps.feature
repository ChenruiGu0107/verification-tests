Feature: configmap related

  # @author yanpzhan@redhat.com
  # @case_id OCP-19717
  Scenario: Check configmap on console
    Given the master version >= "3.11"
    Given I have a project
    Given I open admin console in a browser
    When I perform the :goto_configmaps_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :create_resource_by_default_yaml web action
    Then the step should succeed
    When I perform the :check_resource_name_and_icon web action with:
      | configmap_name | example |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name | example |
    Then the step should succeed
    When I get the visible text on web html page
    And the output should contain:
      | hello |
      | world |
      | property.1=value-1 |
      | property.2=value-2 |
      | property.3=value-3 |
    When I perform the :add_label_for_resource web action with:
      | item        | Edit Labels |
      | new_label   | test1=one   |
      | press_enter | :enter      |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | labels | test1=one |
    Then the step should succeed
    When I perform the :add_annotation_for_resource web action with:
      | annotation_key   | annota1          |
      | annotation_value | annotaone        |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | configmap |
      | resource_name | example   |
      | o             | yaml      |
    Then the output should contain:
      | annota1: annotaone |

    When I perform the :click_one_dropdown_action web action with:
      | item | Delete Config Map |
    Then the step should succeed
    When I perform the :delete_resource_panel web action with:
      | cascade | true |
    Then the step should succeed

    When I run the :get client command with:
      | resource | cm |
    Then the step should succeed
    And the output should not contain:
     | example |

  # @author yapei@redhat.com
  # @case_id OCP-24342
  Scenario: Show binary config map data
    Given the master version >= "4.2"
    Given I have a project
    When I run the :create_configmap client command with:
      | name      | twobigconfigmap                                                                 |
      | from_file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/hello        |
      | from_file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/keystore.jks |
    Then the step should succeed
    Given I open admin console in a browser
    When I perform the :goto_configmaps_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :goto_one_configmap_page web action with:
      | project_name   | <%= project.name %> |
      | configmap_name | twobigconfigmap     |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | No Data Found |
    Then the step should succeed
    When I perform the :check_page_not_match web action with:
      | content | No Binary Data Found |
    Then the step should succeed
    When I perform the :check_binary_data_contains web action with:
      | binary_key | hello |
    Then the step should succeed
    When I perform the :check_binary_data_contains web action with:
      | binary_key | keystore.jks |
    Then the step should succeed 
