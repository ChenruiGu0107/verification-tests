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

  # @author yapei@redhat.com
  # @case_id OCP-23681
  @admin
  Scenario: Expand PVC when no quota or limit is set
    Given the master version >= "4.2"
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled
    Given I open admin console in a browser
    When I perform the :create_persistent_volume_claims web action with:
      | project_name       | <%= project.name %>     |
      | storage_class_name | sc-<%= project.name %>  |
      | pvc_name           | pvc-<%= project.name %> |
      | pvc_request_size   | 300                     |      
      | access_mode        | ReadWriteOnce           |
      | pvc_size_unit      | Mi                      |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 60 seconds
    When I perform the :goto_one_pvc_page web action with:
      | project_name | <%= project.name %> |
      | pvc_name | pvc-<%= project.name %> |
    Then the step should succeed
    When I perform the :click_one_dropdown_action web action with:
      | item | Expand PVC |
    Then the step should succeed

    # to smaller value
    When I perform the :expand_pvc_size web action with:
      | pvc_request_size | 100 |
      | pvc_size_unit    | Mi  |
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | error |
    Then the step should succeed

    # to negative value
    When I perform the :expand_pvc_size web action with:
      | pvc_request_size | -1 |
      | pvc_size_unit    | Mi |
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | error |
    Then the step should succeed  

    # to string
    When I perform the :expand_pvc_size web action with:
      | pvc_request_size | test |
      | pvc_size_unit    | Mi   |
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | error |
    Then the step should succeed

    # to larger value
    When I perform the :expand_pvc_size web action with:
      | pvc_request_size | 2  |
      | pvc_size_unit    | Gi |
    Then the step should succeed
    And I wait up to 300 seconds for the steps to pass:
    """
    Given the expression should be true> pv(pvc("pvc-#{project.name}").volume_name).capacity_raw(cached: false) == "2Gi"
    """


