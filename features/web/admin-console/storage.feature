Feature: storage (storageclass, pv, pvc) related

  # @author xiaocwan@redhat.com
  # @case_id OCP-19663
  @admin
  @destructive
  Scenario: Storage Classes
    Given the first user is cluster-admin
    Given I open admin console in a browser
    When I run the :goto_storageclass_page web action
    Then the step should succeed
    When I run the :create_resource_by_default_yaml web action
    Then the step should succeed

    Given admin ensures "example" storageclass is deleted after scenario
    Given I wait up to 30 seconds for the steps to pass:
    """
    the expression should be true> browser.url.end_with? "k8s/cluster/storageclasses/example"
    """

    When I perform the :check_resource_name_and_icon web action with:
      | icon_text     | SC      |
      | resource_name | example |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name            | example        |
      | labels          | No labels      |
      | annotations     | 0 Annotations  |
      | provisioner     | my-provisioner |
      | reclaim_policy  | Delete         |
      | default_class   | false          |
    Then the step should succeed
    