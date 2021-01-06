Feature: ONLY ONLINE subscription plan related scripts in this file

  # @author xiaocwan@redhat.com
  Scenario Outline: Storage add-on can be downgrade after requested storage
    Given I open accountant console in a browser
    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 3       |
    Then the step should succeed
    And I register clean-up steps:
    """
    I run the :delete client command with:
      | object_type | pvc |
      | all         |     |
    the step should succeed
    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 0       |
    the step should succeed
    """
    Given I have a project
    When I obtain test data file "online/dynamic_persistent_volumes/pvc-equal.yaml"
    Then the step should succeed
    And I replace lines in "pvc-equal.yaml":
      | 1Gi | <pvc_request> |
    When I run the :create client command with:
      | f | pvc-equal.yaml |
    Then the step should succeed
    When the "noncompute" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.total_used(cached: false).storage_requests_raw  == "<applied_request>"

    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 2       |
    Then the step should succeed
    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_check_error_message web action with:
      | resource | storage       |
      | amount   | 1             |
      | quota    | <quota_error> |
    Then the step should succeed

    Examples:
      | pvc_request | applied_request | quota_error |
      | 0.003Ti     |  3298534883328m | 3.072 GiB   | # @case_id OCP-16473
      | 4Gi         |  4Gi            | 4.0 GiB     | # @case_id OCP-16502
      | 3100Mi      |  3100Mi         | 3.027 GiB   | # @case_id OCP-16503
      | 3200100Ki   |  3200100Ki      | 3.052 GiB   | # @case_id OCP-16504
      | 0.004T      |  4G             | 3.725 GiB   | # @case_id OCP-16505
      | 3300M       |  3300M          | 3.073 GiB   | # @case_id OCP-16512
      | 3300100k    |  3300100k       | 3.073 GiB   | # @case_id OCP-16513
      | 3300100100  |  3300100100     | 3.073 GiB   | # @case_id OCP-16514

  # @author xiaocwan@redhat.com
  Scenario Outline: clusterresourcequota add-ons can be upgraded and downgraded
    Given I open accountant console in a browser
    ## set addon and check
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource | <resource> |
      | amount   | <addon>    |
    Then the step should succeed
    Given I have a project
    And I register clean-up steps:
    """
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource | <resource> |
      | amount   | 0          |
    Then the step should succeed
    When the "<acrq_name>" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.hard_quota(cached: false).<type>_raw  == "2Gi"
    """
    When the "<acrq_name>" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.hard_quota(cached: false).<type>_raw  == "<adn_total>"

    ## downgrade and check
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource | <resource>  |
      | amount   | <downgrade> |
    Then the step should succeed
    When the "<acrq_name>" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.hard_quota(cached: false).<type>_raw  == "<dng_total>"

    ## upgrade and check
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource | <resource>|
      | amount   | <upgrade> |
    Then the step should succeed
    When I perform the :check_additional_value_for_plan web action with:
      | cur_amount         | <upgrade> |
      | resource_page_name | <page>    |
    When the "<acrq_name>" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.hard_quota(cached: false).<type>_raw  == "<upg_total>"

    Examples:
    | resource           | acrq_name  | addon | adn_total | downgrade | dng_total | upgrade | upg_total | page               | type             |
    | memory             | compute    | 4     | 6Gi       | 2         | 4Gi       | 8       | 10Gi      | memory             | memory_limit     | # @case_id OCP-10431
    | storage            | noncompute | 5     | 7Gi       | 2         | 4Gi       | 10      | 12Gi      | storage            | storage_requests | # @case_id OCP-10432
    | terminating_memory | timebound  | 4     | 6Gi       | 2         | 4Gi       | 8       | 10Gi      | terminating_memory | memory_limit     | # @case_id OCP-14146

  # @author xiaocwan@redhat.com
  # @case_id OCP-10434
  Scenario: Storage add-on cannot be downgraded to the value lower than the occupied storage quota
    Given I open accountant console in a browser
    When accountant console cluster resource quota is set to:
      | resource | storage |
      | amount   | 5       |
    Then the step should succeed
    And I register clean-up steps:
    """
    I run the :delete client command with:
      | object_type | pvc |
      | all         |     |
    the step should succeed
    When accountant console cluster resource quota is set to:
      | resource | storage |
      | amount   | 0       |
    the step should succeed
    When the "noncompute" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.hard_quota(cached: false).storage_requests_raw  == "2Gi"
    """
    Given I have a project
    When I obtain test data file "online/dynamic_persistent_volumes/pvc-equal.yaml"
    Then the step should succeed
    And I replace lines in "pvc-equal.yaml":
      | 1Gi | 5Gi |
    When I run the :create client command with:
      | f | pvc-equal.yaml |
    Then the step should succeed
    When the "noncompute" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.total_used(cached: false).storage_requests_raw  == "5Gi"

    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_check_error_message web action with:
      | resource | storage |
      | amount   | 2       |
      | quota    | 5.0 GiB |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type | pvc |
      | all         |     |
    Then the step should succeed
    When I replace lines in "pvc-equal.yaml":
      | 5Gi | 4Gi |
    When I run the :create client command with:
      | f | pvc-equal.yaml |
    Then the step should succeed
    When accountant console cluster resource quota is set to:
      | resource | storage |
      | amount   | 2       |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_check_error_message web action with:
      | resource | storage |
      | amount   | 0       |
      | quota    | 4.0 GiB |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  Scenario Outline: User can not use the no-positive-integer value to set subscription
    Given I open accountant console in a browser
    When I perform the :goto_resource_settings_page web action with:
      | resource | <resource> |
    Then the step should succeed

    When I perform the :set_resource_amount_by_input web action with:
      | resource | <resource> |
      | amount   | -1         |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web action with:
      | text | -1 |
    Then the step should succeed

    When I perform the :set_resource_amount_by_input web action with:
      | resource | <resource> |
      | amount   | 1.7        |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web action with:
      | text | 1.7 |
    Then the step should succeed

    When I perform the :set_resource_amount_by_input web action with:
      | resource | <resource> |
      | amount   | abc        |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web action with:
      | text | abc |
    Then the step should succeed

    When I perform the :set_resource_amount_by_input web action with:
      | resource | <resource> |
      | amount   | 1 3        |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web action with:
      | text | 1 3 |
    Then the step should succeed

    Examples:
    | resource            |
    | storage             | # @case_id OCP-15842
    | memory              | # @case_id OCP-15843
    | terminating_memory  | # @case_id OCP-15844

  # @author xiaocwan@redhat.com
  # @case_id OCP-17480
  Scenario: Check the error message when there is no add-on update during doing resource change
    Given I open accountant console in a browser
    When I perform the :set_additional_resources_to_same_value_by_url web action with:
      | resource | memory |
      | size     | 0      |
    Then the step should succeed
    When I perform the :set_additional_resources_to_same_value_by_url web action with:
      | resource | storage |
      | size     | 0       |
    Then the step should succeed
    When I perform the :set_additional_resources_to_same_value_by_url web action with:
      | resource | terminating_memory |
      | size     | 0                  |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-16738
  Scenario: User can not use invalid addon type to subscribe resource add-on through the subscription url
    Given I open accountant console in a browser
    When I perform the :set_additional_resources_to_invalid_value_by_url web action with:
      | resource | memory_1 |
      | size     | 1        |
    Then the step should succeed
    When I perform the :set_additional_resources_to_invalid_value_by_url web action with:
      | resource | storage_1 |
      | size     | 1         |
    Then the step should succeed
    When I perform the :set_additional_resources_to_invalid_value_by_url web action with:
      | resource | terminating_memory_1 |
      | size     | 1                    |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-15154
  Scenario: Trying to upgrade addon to same value should be successful
    Given I open accountant console in a browser
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource | memory |
      | amount   | 3      |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource | memory |
      | amount   | 0      |
    Then the step should succeed
    """
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource | memory |
      | amount   | 1      |
    Then the step should succeed
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource | memory |
      | amount   | 3      |
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-14145
  Scenario: Terminating memory add-ons can't be downgraded to the value lower than the occupied memory quota
    Given I open accountant console in a browser
    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 2                  |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 0                  |
    the step should succeed
    """
    Given I have a project
    When the "timebound" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.hard_quota(cached: false).memory_limit_raw == "4Gi"
    When I run the :run client command with:
      | name    | run-once-pod-1   |
      | image   | openshift/origin |
      | command | true             |
      | cmd     | sleep            |
      | cmd     | 60m              |
      | restart | Never            |
      | limits  | cpu=2,memory=2Gi |
    Then the step should succeed
    When I run the :run client command with:
      | name    | run-once-pod-2   |
      | image   | openshift/origin |
      | command | true             |
      | cmd     | sleep            |
      | cmd     | 60m              |
      | restart | Never            |
      | limits  | cpu=2,memory=1Gi |
    Then the step should succeed
    When I run the :run client command with:
      | name    | run-once-pod-3   |
      | image   | openshift/origin |
      | command | true             |
      | cmd     | sleep            |
      | cmd     | 60m              |
      | restart | Never            |
      | limits  | cpu=2,memory=1Gi |
    Then the step should succeed
    When the "timebound" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.total_used(cached: false).memory_limit_raw == "4Gi"
    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory       |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_check_error_message web action with:
      | resource | terminating_memory        |
      | amount   | 1                         |
      | quota    | 4.0 GiB                   |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | pod            |
      | object_name_or_id | run-once-pod-3 |
    Then the step should succeed
    When the "timebound" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.total_used(cached: false).memory_limit_raw == "3Gi"
    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 1                  |
    Then the step should succeed
    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_check_error_message web action with:
      | resource | terminating_memory  |
      | amount   | 0                   |
      | quota    | 3.0 GiB             |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | pod            |
      | object_name_or_id | run-once-pod-2 |
    Then the step should succeed
    Given I ensure "run-once-pod-2" pod is deleted
    When the "timebound" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.total_used(cached: false).memory_limit_raw == "2Gi"

  # @author yuwan@redhat.com
  # @case_id OCP-13077
  Scenario: The user can subscribe resource add-on after resume the cancelled service
    Given I open accountant console in a browser
    When I run the :click_to_change_plan web action
    Then the step should succeed
    When I run the :click_cancel_your_service web action
    Then the step should succeed
    When I perform the :cancel_your_service_correctly web action with:
      | username | <%= user.name %> |
    Then the step should succeed
    And I register clean-up steps:
    """
    Given the expression should be true> cb.subscribed
    """
    When I perform the :click_resume_your_subscription_confirm web action with:
      | last_date | <%= last_second_of_month.strftime("%A, %B %d, %Y") %> |
    Then the step should succeed
    And evaluation of `true` is stored in the :subscribed clipboard
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource | memory |
      | amount   | 2      |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I perform the :goto_crq_and_set_resource_amount web action with:
      | resource | memory |
      | amount   | 0      |
    Then the step should succeed
    """
    And I run the :go_to_account_page web action
    And I perform the :check_resource_account_overview_page web action with:
      | cur_resource | Memory |
      | cur_amount   | 4GiB   |
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-20548
  Scenario: Check the elements on Resume Subscription page
    Given I open accountant console in a browser
    When I run the :click_to_change_plan web action
    Then the step should succeed
    When I run the :click_cancel_your_service web action
    Then the step should succeed
    When I perform the :cancel_your_service_correctly web action with:
      | username | <%= user.name %> |
    Then the step should succeed
    And I register clean-up steps:
    """
    Given I access the "./" url in the web browser
    When I perform the :click_resume_your_subscription_confirm web action with:
      | last_date | <%= last_second_of_month.strftime("%A, %B %d, %Y") %> |
    Then the step should succeed
    """
    When I perform the :click_resume_your_subscription web action with:
      | last_date | <%= last_second_of_month.strftime("%A, %B %d, %Y") %> |
    Then the step should succeed
    When I run the :check_message_and_elements_on_resume_page web action
    Then the step should succeed
    When I run the :check_plan_includes_content web action
    Then the step should succeed

  # @author yuwan@redhat.com
  # @case_id OCP-20549
  Scenario: Check the elements on Resume Subscription page - Fuse
    Given I open accountant console in a browser
    When I run the :click_to_change_plan web action
    Then the step should succeed
    When I run the :click_cancel_your_service web action
    Then the step should succeed
    When I perform the :cancel_your_service_correctly web action with:
      | username | <%= user.name %> |
    Then the step should succeed
    And I register clean-up steps:
    """
    Given I access the "./" url in the web browser
    When I perform the :click_resume_your_subscription_confirm web action with:
      | last_date | <%= last_second_of_month.strftime("%A, %B %d, %Y") %> |
    Then the step should succeed
    """
    When I perform the :click_resume_your_subscription web action with:
      | last_date | <%= last_second_of_month.strftime("%A, %B %d, %Y") %> |
    Then the step should succeed
    When I run the :check_message_and_elements_on_resume_page web action
    Then the step should succeed
    When I perform the :check_fuse_small_plan_includes_content web action with:
      | integration_number | 5       |
      | memory             | 8GiB    |
      | storage            | 5GiB    |
      | cpu_number         | 16 vCPU |
    Then the step should succeed

  # @author yuwei@redhat.com
  # @case_id OCP-14874
  Scenario: Storage and Terminating memory can be upgraded/downgraded if memory add-on is used
    Given I open accountant console in a browser
    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 2      |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 2                  |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 2       |
    Then the step should succeed
    And I register clean-up steps:
    """
    Given I delete all resources from the project
    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 0                  |
    Then the step should succeed
    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 0       |
    Then the step should succeed
    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 0      |
    Then the step should succeed
    """

    Given I have a project
    When the "compute" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.hard_quota(cached: false).memory_limit_raw == "4Gi"
    When I run the :new_app client command with:
      | template | httpd-example     |
      | p        | MEMORY_LIMIT=1Gi  |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=httpd-example-1 |
    Then I run the :scale client command with:
      | resource | dc                 |
      | name     | httpd-example      |
      | replicas | 3                  |
    Then the step should succeed
    Given I wait until number of replicas match "3" for replicationController "httpd-example-1"
    When the "compute" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.total_used(cached: false).memory_limit_raw == "3Gi"

    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 4                  |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 4       |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 2                  |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 2       |
    Then the step should succeed

  # @author yuwei@redhat.com
  # @case_id OCP-20384
  Scenario: Memory and Storage can be upgrade/downgrade if terminating memory add-on is used
    Given I open accountant console in a browser
    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 2      |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 2                  |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 2       |
    Then the step should succeed
    And I register clean-up steps:
    """
    Given I delete all resources from the project
    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 0      |
    Then the step should succeed
    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 0       |
    Then the step should succeed
    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 0                  |
    Then the step should succeed
    """

    Given I have a project
    When the "timebound" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.hard_quota(cached: false).memory_limit_raw == "4Gi"
    When I run the :run client command with:
      | name    | run-once-pod-1   |
      | image   | openshift/origin |
      | command | true             |
      | cmd     | sleep            |
      | cmd     | 60m              |
      | restart | Never            |
      | limits  | cpu=2,memory=2Gi |
    Then the step should succeed
    When I run the :run client command with:
      | name    | run-once-pod-2   |
      | image   | openshift/origin |
      | command | true             |
      | cmd     | sleep            |
      | cmd     | 60m              |
      | restart | Never            |
      | limits  | cpu=2,memory=1Gi |
    Then the step should succeed

    When the "timebound" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.total_used(cached: false).memory_limit_raw == "3Gi"

    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 4       |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 4      |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 2       |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 2      |
    Then the step should succeed

  # @author yuwei@redhat.com
  # @case_id OCP-20385
  Scenario: Memory and Terminating memory can be upgraded/downgraded if storage add-on is used
    Given I open accountant console in a browser
    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 2      |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 2                  |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 2       |
    Then the step should succeed
    And I register clean-up steps:
    """
    Given I delete all resources from the project
    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 0      |
    Then the step should succeed
    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 0                  |
    Then the step should succeed
    When I perform the :goto_resource_settings_page web action with:
      | resource | storage |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | storage |
      | amount   | 0       |
    Then the step should succeed
    """

    Given I have a project
    When the "noncompute" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.hard_quota(cached: false).storage_requests_raw == "4Gi"
    Given I obtain test data file "online/dynamic_persistent_volumes/pvc-mongodb.yaml"
    And I replace lines in "pvc-mongodb.yaml":
      | storage: 1Gi | storage: 3Gi |
    When I run the :create client command with:
      | f | pvc-mongodb.yaml    |
      | n | <%= project.name %> |
    Then the step should succeed
    When the "noncompute" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.total_used(cached: false).storage_requests_raw == "3Gi"

    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 4                  |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 4      |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | terminating_memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | terminating_memory |
      | amount   | 2                  |
    Then the step should succeed

    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 2      |
    Then the step should succeed

  # @author yuwei@redhat.com
  # @case_id OCP-10433
  Scenario: Memory add-ons can't be downgraded to the value lower than the occupied memory quota
    Given I open accountant console in a browser
    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 4      |
    Then the step should succeed
    And I register clean-up steps:
    """
    Given I delete all resources from the project
    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 0      |
    Then the step should succeed
    """
    Given I have a project
    When the "compute" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.hard_quota(cached: false).memory_limit_raw  == "6Gi"
    When I run the :new_app client command with:
      | template | httpd-example     |
      | p        | MEMORY_LIMIT=1Gi  |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=httpd-example-1 |
    Then I run the :scale client command with:
      | resource | dc                 |
      | name     | httpd-example      |
      | replicas | 4                  |
    Then the step should succeed
    Given I wait until number of replicas match "4" for replicationController "httpd-example-1"
    When the "compute" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.total_used(cached: false).memory_limit_raw == "4Gi"
    When I perform the :goto_resource_settings_page web action with:
      | resource | memory        |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_check_error_message web action with:
      | resource | memory        |
      | amount   | 1             |
      | quota    | 4.0 GiB       |
    Then the step should succeed
    Then I run the :scale client command with:
      | resource | dc                 |
      | name     | httpd-example      |
      | replicas | 3                  |
    Then the step should succeed
    Given I wait until number of replicas match "3" for replicationController "httpd-example-1"
    Given 30 seconds have passed
    When I perform the :goto_resource_settings_page web action with:
      | resource | memory |
    Then the step should succeed
    When I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | memory |
      | amount   | 1      |
    Then the step should succeed
    When the "compute" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.total_used(cached: false).memory_limit_raw == "3Gi"
