Feature: storage (storageclass, pv, pvc) related

  # @author xiaocwan@redhat.com
  # @case_id OCP-19663
  @admin
  @destructive
  Scenario: Storage Classes
    Given I open admin console in a browser
    Given the first user is cluster-admin
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
      | storageclass_name | example |
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
  @destructive
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
    # Create DC to consume PVC then it can become Bound
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/simpledc.json |
    Then the step should succeed
    When I run the :set_volume client command with:
      | resource      | dc                      |
      | resource_name | hooks                   |
      | add           | true                    |
      | type          | pvc                     |
      | claim-name    | pvc-<%= project.name %> |
      | mount-path    | /tmp/data               |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    When I perform the :goto_one_pvc_page web action with:
      | project_name | <%= project.name %>     |
      | pvc_name     | pvc-<%= project.name %> |
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

    # check spec.resources.requests.storage is 2Gi
    When I run the :get client command with:
      | resource | pvc/pvc-<%= project.name %>  |
      | o        | yaml                         |
    Then the step should succeed
    Given the expression should be true> @result[:parsed]['spec']['resources']['requests']['storage'] == "2Gi"


  # @author yapei@redhat.com
  # @case_id OCP-23682
  @admin
  @destructive
  Scenario: Expand PVC when there is limitrange and quota set
    Given the master version >= "4.2"
    
    # admin could create ResourceQuata and LimitRange
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/simpledc.json |
    Then the step should succeed

    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/quota-pvc-storage.yaml" replacing paths:
      | ["spec"]["hard"]["persistentvolumeclaims"] | 4   |
      | ["spec"]["hard"]["requests.storage"]       | 2Gi |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/limits.yaml |
      | n | <%= project.name %>                                                                   |
    Then the step should succeed

    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed

    # Add PVC to workloads so it can be Bound
    When I run the :set_volume client command with:
      | resource      | dc                      |   
      | resource_name | hooks                   |   
      | add           | true                    |   
      | type          | pvc                     |   
      | claim-name    | pvc-<%= project.name %> |      
      | mount-path    | /tmp/data               |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    Given I switch to the first user
    Given I open admin console in a browser
    When I perform the :goto_one_pvc_page web action with:
      | project_name | <%= project.name %>     |
      | pvc_name     | pvc-<%= project.name %> |
    Then the step should succeed

    # resize to larger value but not exceed the quota
    When I perform the :click_one_dropdown_action web action with:
      | item | Expand PVC |
    Then the step should succeed
    When I perform the :expand_pvc_size web action with:
      | pvc_request_size | 1.5 |
      | pvc_size_unit    | Gi  |
    Then the step should succeed
    When I perform the :check_page_not_match web action with:
      | content | error |
    Then the step should succeed

    # resize to a larger value beyonds quota
    When I perform the :click_one_dropdown_action web action with:
      | item | Expand PVC |
    Then the step should succeed
    When I perform the :expand_pvc_size web action with:
      | pvc_request_size | 3   |
      | pvc_size_unit    | Gi  |
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | exceeded quota |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-21034
  @admin
  Scenario: storage class creation negative testing	
    Given the master version >= "4.1"
    Given I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :goto_storageclass_page web action
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Create Storage Class |
    Then the step should succeed
    When I run the :wait_form_loaded web action
    Then the step should succeed
    When I perform the :check_button_disabled web action with:
      | button_text | Create |
    Then the step should succeed

    #negative test: invalid name
    When I perform the :set_input_value web action with:
      | input_field_id | storage-class-name |
      | input_value    | invalidname@@      |
    Then the step should succeed
    When I perform the :choose_dropdown_item web action with:
      | dropdown_field | Provisioner |
      | dropdown_item  | local       |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Create |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | Invalid value |
    Then the step should succeed

    #negative test: invalid iops value
    When I perform the :set_input_value web action with:
      | input_field_id | storage-class-name |
      | input_value    | testsc             |
    Then the step should succeed
    When I perform the :choose_dropdown_item web action with:
      | dropdown_field | Provisioner |
      | dropdown_item  | aws         |
    Then the step should succeed
    When I perform the :choose_dropdown_item web action with:
      | dropdown_field | Type     |
      | dropdown_item  | io1      |
    Then the step should succeed
    When I perform the :set_input_value web action with:
      | input_field_id | provisioner-settings-iopsPerGB |
      | input_value    | invalidtest |
    Then the step should succeed
    When I perform the :check_button_disabled web action with:
      | button_text | Create |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-24415
  Scenario: Select container when attach/remove volume
    Given the master version >= "4.2"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-two-containers.yaml |
    Then the step should succeed
    Given I open admin console in a browser
    When I perform the :create_persistent_volume_claims web action with:
      | project_name     | <%= project.name %> |
      | pvc_name         | pvc1                |
      | pvc_request_size | 1                   |
    Then the step should succeed
    When I perform the :create_persistent_volume_claims web action with:
      | project_name     | <%= project.name %> |
      | pvc_name         | pvc2                |
      | pvc_request_size | 1                   |
    Then the step should succeed

    When I perform the :attach_storage_to_container web action with:
      | project_name       | <%= project.name %> |
      | dc_name            | dctest              |
      | pvc_name           | pvc1                |
      | mount_path         | /test               |
      | use_none_container | true                |
    Then the step should succeed
    When I perform the :select_one_container web action with:
      | container_name | dctest-1 |
    Then the step should succeed
    When I run the :submit_changes web action
    Then the step should succeed
    When I perform the :check_volume_missing_on_workload_page web action with:
      | volume_name    | pvc1     |
      | mount_path     | /test    |
      | pvc_name       | pvc1     |
      | container_name | dctest-2 |
    Then the step should succeed

    When I perform the :attach_storage_to_container web action with:
      | project_name       | <%= project.name %> |
      | dc_name            | dctest              |
      | pvc_name           | pvc2                |
      | mount_path         | /test2              |
      | use_all_containers | true                |
    Then the step should succeed
    When I perform the :check_volume_on_workload_page web action with:
      | volume_name    | pvc2     |
      | mount_path     | /test2   |
      | pvc_name       | pvc2     |
      | container_name | dctest-1 |
    Then the step should succeed
    When I perform the :check_volume_on_workload_page web action with:
      | volume_name    | pvc2     |
      | mount_path     | /test2   |
      | pvc_name       | pvc2     |
      | container_name | dctest-2 |
    Then the step should succeed

    When I perform the :remove_volume_from_container web action with:
      | volume_name    | pvc1          |
      | container_name | dctest-1      |
      | button_text    | Cancel        |
    Then the step should succeed
    When I perform the :remove_volume_from_container web action with:
      | volume_name    | pvc2          |
      | container_name | dctest-2      |
      | button_text    | Remove Volume |
    Then the step should succeed
    When I perform the :check_volume_missing_on_workload_page web action with:
      | volume_name    | pvc2     |
      | mount_path     | /test2   |
      | pvc_name       | pvc2     |
      | container_name | dctest-2 |
    Then the step should succeed
    When I perform the :check_volume_on_workload_page web action with:
      | volume_name    | pvc2     |
      | mount_path     | /test2   |
      | pvc_name       | pvc2     |
      | container_name | dctest-1 |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-20964
  @admin
  Scenario: admin create storage class from Form
    Given the master version >= "4.1"
    Given I open admin console in a browser
    Given the first user is cluster-admin
    Given admin ensures "testsc-20964" storageclass is deleted after scenario
    When I perform the :create_storageclass_from_form web action with:
      | sc_name     | testsc-20964 |
      | provisioner | local        |
    Then the step should succeed
    Given the expression should be true> storage_class('testsc-20964').provisioner == "kubernetes.io/no-provisioner"
    Given the expression should be true> storage_class('testsc-20964').reclaim_policy == "Delete"
