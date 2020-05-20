Feature: CRD related

  # @author hasha@redhat.com
  # @case_id OCP-24330
  @admin
  Scenario: Check tab of instances on the CRD details page
    Given the master version >= "4.2"
    Given I have a project
    Given the first user is cluster-admin
    Given I open admin console in a browser
    When I perform the :goto_crd_instances_page web action with:
      | crd_definition | clusterversions.config.openshift.io |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | version |
      | link_url | k8s/cluster/config.openshift.io~v1~ClusterVersion/version |
    Then the step should succeed
    When I perform the :goto_crd_instances_page web action with:
      | crd_definition | catalogsources.operators.coreos.com |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | certified-operators |
      | link_url | k8s/ns/openshift-marketplace/operators.coreos.com~v1alpha1~CatalogSource/certified-operators |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-26734
  @admin
  Scenario: Switch Alert Manager YAML editor to Monaco editor
    Given the master version >= "4.4"
    Given the first user is cluster-admin
    Given I open admin console in a browser
    When I run the :goto_alertmanagerconfig_page web action
    Then the step should succeed
    When I run the :click_yaml_tab web action
    Then the step should succeed
    When I run the :check_editor_is_monaco_editor web action
    Then the step should succeed
    When I perform the :check_button_missing web action with:
      | button_text | Reload |
    Then the step should succeed
    When I perform the :check_button_missing web action with:
      | button_text | View shortcuts |
    Then the step should succeed
    When I perform the :check_button_missing web action with:
      | button_text | View sidebar |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-29209
  @admin
  Scenario: Updated initial receivers and InfoTip for receivers
    Given the master version >= "4.5"
    Given the first user is cluster-admin
    When I use the "openshift-monitoring" project
    And I get project secret named "alertmanager-main" as JSON
    Then I save the output to file> default-secret.json
    And I register clean-up steps:
    """
    When I run the :replace client command with:
      | f     | default-secret.json |
      | force | true                |
    Then the step should succeed
    """

    Given I open admin console in a browser
    When I run the :goto_alertmanagerconfig_page web action
    Then the step should succeed

    # check alert message for multiple receivers on list page
    When I run the :check_message_when_multiple_receivers_not_configured web action
    Then the step should succeed

    # Critical and Default are different, so check message keyword directly in params
    # check Critical alert message before config
    When I perform the :browse_to_receiver_config web action with:
      | receiver | Critical |
    And I perform the :check_alert_message web action with:
      | title       | Critical                        |
      | description | Finish setting up this receiver |
    Then the step should succeed

    # check Critical receiver message on config page
    When I perform the :choose_item_from_dropdown_menu web action with:
      | dropdown_menu_item | PagerDuty | 
    Then the step should succeed
    # check message disappear
    And I perform the :check_alert_message web action with:
      | title       | Critical                        |
      | description | Finish setting up this receiver |
    Then the step should fail

    # submit Critical receiver config
    When I perform the :set_pagerduty_key web action with:
      | input_value | test | 
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed

    # check alert message for single alerts on list page
    When I run the :check_message_when_single_receiver_not_configured web action
    Then the step should succeed

    # check Default alert message before config
    When I perform the :browse_to_receiver_config web action with:
      | receiver | Default |
    And I perform the :check_alert_message web action with:
      | title       | Default                                     |
      | description | default receiver will automatically receive |
    Then the step should succeed

    # check Default receiver message on config page
    When I perform the :choose_item_from_dropdown_menu web action with:
      | dropdown_menu_item | PagerDuty | 
    Then the step should succeed
    # check message exist
    And I perform the :check_alert_message web action with:
      | title       | Default                                     |
      | description | default receiver will automatically receive |
    Then the step should succeed

    # submit Default receiver config
    When I perform the :set_pagerduty_key web action with:
      | input_value | test | 
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed

    # check no alert message on receivers list
    When I run the :check_message_when_single_receiver_not_configured web action
    Then the step should fail
    When I run the :check_message_when_multiple_receivers_not_configured web action
    Then the step should fail

    # check Watchdog alert message before config
    When I perform the :click_one_operation_in_kebab web action with:
      | resource_name | Watchdog      |
      | kebab_item    | Edit Receiver |
    Then the step should succeed
    And I perform the :check_alert_message web action with:
      | title       | Watchdog                                                  |
      | description | confirm that your alerting stack is functioning correctly |
    Then the step should succeed
    
    # check Watchdog receiver messsage on config page
    When I perform the :choose_item_from_dropdown_menu web action with:
      | dropdown_menu_item | PagerDuty | 
    Then the step should succeed
    # check message disappear
    And I perform the :check_alert_message web action with:
      | title       | Watchdog                                                  |
      | description | confirm that your alerting stack is functioning correctly |
    Then the step should fail
