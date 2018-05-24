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
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-equal.yaml"
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
  Scenario Outline: Plan add-on can be added under the limit
    Given I open accountant console in a browser
    When I perform the :goto_resource_settings_page web action with:
      | resource | <resource> |
    Then the step should succeed
    When I perform the :set_max_value_by_exceed web action with:
      | resource           | <resource>           |
      | exceed_amount      | <exceed_amount>      |
      | cur_amount         | <current>            |
      | current            | <current> GiB        |
      | resource_page_name | <resource_page_name> |
      | previous           | <previous>           |
      | total              | <total>              |
    Then the step should succeed
    And I register clean-up steps:
    """
    I perform the :goto_resource_settings_page web action with:
      | resource | <resource> |
    the step should succeed
    I perform the :set_resource_amount_by_input_and_update web action with:
      | resource | <resource> |
      | amount   | 0          |
    the step should succeed
    """
    Given I have a project
    Given the "<acrq_name>" applied_cluster_resource_quota is stored in the clipboard
    Then the expression should be true> cb.acrq.hard_quota(cached: false).<type>_raw  == "<total>Gi"

    Examples:
      | resource           | exceed_amount | current | total | acrq_name  | resource_page_name | previous | type             |
      | storage            | 149           | 148     | 150   | noncompute | storage            | 0        | storage_requests | # @case_id OCP-10426
      | memory             | 47            | 46      | 48    | compute    | memory             | 0        | memory_limit     | # @case_id OCP-10427
      | terminating_memory | 19            | 18      | 20    | timebound  | terminating memory | 0        | memory_limit     | # @case_id OCP-13347

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
