Feature: only about page related to cluster login page

  # @author xueli@redhat.com
  # @case_id OCP-22042
  Scenario: Check vpcCIDR , podCIDR and serviceCIDR textbox on UI page.
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :switch_to_osd_creation_page web action with:
      | product_id     | osd |
      | cloud_provider | aws |
    Then the step should succeed
    When I run the :select_advanced_radio_button web action
    Then the step should succeed
    # Have to select machine_type due to known issue: SDA-1463
    When I perform the :fill_in_required_items_on_osd_creation_page web action with:
      | cluster_name | sdqe-ui-cidr-temp |
      | machine_type | m5.xlarge         | 
    Then the step should succeed

    Given I saved following keys to list in :cidrs clipboard:
      | aaa               ||
      | abcd.abcd.abcd/12 ||
      | 1222.0.0.0/0      ||
      | 012.0.0.0/10      ||
      | 12.0.0.0/33       ||
      # | 10.0.0.6/16       ||
    When I repeat the following steps for each :cidr_value in cb.cidrs:
    """
    When I perform the :check_machine_cidr_error_message web action with:
      | machine_cidr | #{cb.cidr_value}                   |
      | error_reason | It must follow the RFC-4632 format |
    Then the step should succeed
    When I perform the :check_service_cidr_error_message web action with:
      | service_cidr | #{cb.cidr_value}                   |
      | error_reason | It must follow the RFC-4632 format |
    Then the step should succeed
    When I perform the :check_pod_cidr_error_message web action with:
      | pod_cidr     | #{cb.cidr_value}                   |
      | error_reason | It must follow the RFC-4632 format |
    Then the step should succeed
    """
    Given I saved following keys to list in :actions clipboard:
      | check_machine_cidr_error_message ||
      | check_service_cidr_error_message ||
      | check_pod_cidr_error_message     ||
    When I repeat the following steps for each :action in cb.actions:
    """
    When I perform the :#{cb.action} web action with:
      | machine_cidr | 10.0.0.6/16                                                                           |
      | service_cidr | 10.0.0.6/16                                                                           |
      | pod_cidr     | 10.0.0.6/16                                                                           |
      | error_reason | This is not a subnet address. The subnet prefix is inconsistent with the subnet mask. |
    Then the step should succeed
    """
    When I perform the :check_machine_cidr_error_message web action with:
      | machine_cidr     | 10.0.0.0/26 |
      | error_reason     | /25         |
    Then the step should succeed
    When I perform the :check_machine_cidr_error_message web action with:
      | machine_cidr     | 10.0.0.0/2 |
      | error_reason     | /16        |
    Then the step should succeed
    Given I saved following keys to list in :prefixes clipboard:
      | aaa ||
      | 125 ||
      | -1  ||
    When I repeat the following steps for each :prefix in cb.prefixes:
    """
    When I perform the :check_host_prefix_error_message web action with:
      | host_prefix  | #{cb.prefix}                       |
      | error_reason | It must follow the RFC-4632 format |
    Then the step should succeed
    """
    When I perform the :check_host_prefix_error_message web action with:
      | host_prefix  | 28                                                                                    |
      | error_reason | The subnet mask can't be higher than '/26', which provides up to 62 Pod IP addresses. |
    Then the step should succeed
    When I perform the :check_host_prefix_error_message web action with:
      | host_prefix  | 22                                                                                    |
      | error_reason | The subnet mask can't be lower than '/23', which provides up to 510 Pod IP addresses. |
    Then the step should succeed
    When I perform the :check_cidr_background_validation_error_message web action with:
      | locator_id            | network_machine_cidr                                                  |
      | machine_cidr          | 172.30.0.0/16                                                         |
      | error_reason          | Machine CIDR '172.30.0.0/16' and service CIDR '172.30.0.0/16' overlap |
      | aws                   |                                                                       |
      | max_machinecidr_range | /25                                                                   |
    Then the step should succeed
    When I perform the :check_overlap_subnet_error_message web action with:
      | machine_cidr   | 10.0.0.0/16 |
      | service_cidr   | 10.0.0.0/16 |
      | pod_cidr       | 10.0.0.0/16 |
    Then the step should succeed
    Given I saved following keys to list in :locators clipboard:
      | network_machine_cidr ||
      | network_service_cidr ||
      | network_pod_cidr     ||
    When I repeat the following steps for each :locator in cb.locators:
    """
    When I perform the :clear_input web action with:
      | locator_id   | #{cb.locator} |
    Then the step should succeed
    """
    When I perform the :check_podcidr_hostprefix_invalid_message web action with:
      | pod_cidr     | 10.128.0.0/20 |
      | host_prefix  | /24           |
    Then the step should succeed
    When I run the :select_multi_az web action
    Then the step should succeed
    When I perform the :check_machine_cidr_error_message web action with:
      | machine_cidr          | 10.0.0.0/24 |
      | error_reason          | /24         |
      | max_machinecidr_range | /24         |
    Then the step should succeed
    When I run the :select_basic_radio_button web action
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-cidr-temp|
    Then the step should succeed
    When I perform the :delete_osd_cluster_from_detail_page web action with:
      | cluster_name | sdqe-ui-cidr-temp |
      | input_text   | sdqe-ui-cidr-temp |
    Then the step should succeed
    """
    When I run the :click_create_button web action
    Then the step should succeed
    When I run the :cluster_detail_page_loaded web action
    Then the step should succeed
    

  # @author xueli@redhat.com
  # @case_id OCP-33439
  Scenario: Check vpcCIDR , podCIDR and serviceCIDR textbox on UI page of gcp
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :switch_to_osd_creation_page web action with:
      | product_id     | osd |
      | cloud_provider | gcp |
    Then the step should succeed
    When I run the :select_advanced_radio_button web action
    Then the step should succeed
    When I perform the :fill_in_required_items_on_osd_creation_page web action with:
      | cluster_name | sdqe-ui-33439  |
      | machine_type | custom-4-16384 | 
    Then the step should succeed

    Given I saved following keys to list in :cidrs clipboard:
      | aaa               ||
      | abcd.abcd.abcd/12 ||
      | 1222.0.0.0/0      ||
      | 012.0.0.0/10      ||
      | 12.0.0.0/33       ||
    When I repeat the following steps for each :cidr_value in cb.cidrs:
    """
    When I perform the :check_machine_cidr_error_message web action with:
      | machine_cidr | #{cb.cidr_value}                   |
      | error_reason | It must follow the RFC-4632 format |
    Then the step should succeed
    When I perform the :check_service_cidr_error_message web action with:
      | service_cidr | #{cb.cidr_value}                   |
      | error_reason | It must follow the RFC-4632 format |
    Then the step should succeed
    When I perform the :check_pod_cidr_error_message web action with:
      | pod_cidr     | #{cb.cidr_value}                   |
      | error_reason | It must follow the RFC-4632 format |
    Then the step should succeed
    """
    When I perform the :check_machine_cidr_error_message web action with:
      | machine_cidr | 17.0.0.0/8            |
      | error_reason | Range is not private. |
    Then the step should succeed
    When I perform the :check_service_cidr_error_message web action with:
      | service_cidr | 17.0.0.0/8            |
      | error_reason | Range is not private. |
    Then the step should succeed
    When I perform the :check_pod_cidr_error_message web action with:
      | pod_cidr     | 17.0.0.0/8            |
      | error_reason | Range is not private. |
    Then the step should succeed
    Given I saved following keys to list in :actions clipboard:
      | check_machine_cidr_error_message ||
      | check_service_cidr_error_message ||
      | check_pod_cidr_error_message     ||
    When I repeat the following steps for each :action in cb.actions:
    """
    When I perform the :#{cb.action} web action with:
      | machine_cidr | 10.0.0.6/16                                                                           |
      | service_cidr | 10.0.0.6/16                                                                           |
      | pod_cidr     | 10.0.0.6/16                                                                           |
      | error_reason | This is not a subnet address. The subnet prefix is inconsistent with the subnet mask. |
    Then the step should succeed
    """
    When I perform the :check_machine_cidr_error_message web action with:
      | machine_cidr     | 10.0.0.0/26 |
      | error_reason     | /23         |
    Then the step should succeed
    Given I saved following keys to list in :prefixes clipboard:
      | aaa ||
      | 125 ||
      | -1  ||
    When I repeat the following steps for each :prefix in cb.prefixes:
    """
    When I perform the :check_host_prefix_error_message web action with:
      | host_prefix  | #{cb.prefix} |
      | error_reason | It must follow the RFC-4632 format |
    Then the step should succeed
    """
    When I perform the :check_host_prefix_error_message web action with:
      | host_prefix  | 28                                                                                    |
      | error_reason | The subnet mask can't be higher than '/26', which provides up to 62 Pod IP addresses. |
    Then the step should succeed
    When I perform the :check_host_prefix_error_message web action with:
      | host_prefix  | 22                                                                                    |
      | error_reason | The subnet mask can't be lower than '/23', which provides up to 510 Pod IP addresses. |
    Then the step should succeed
    When I perform the :check_cidr_background_validation_error_message web action with:
      | locator_id            | network_machine_cidr                                                  |
      | machine_cidr          | 172.30.0.0/16                                                         |
      | error_reason          | Machine CIDR '172.30.0.0/16' and service CIDR '172.30.0.0/16' overlap |
      | gcp                   |                                                                       |
      | max_machinecidr_range | /23                                                                   |
    Then the step should succeed
    When I perform the :check_overlap_subnet_error_message web action with:
      | machine_cidr   | 10.0.0.0/16 |
      | service_cidr   | 10.0.0.0/16 |
      | pod_cidr       | 10.0.0.0/16 |
    Then the step should succeed
    Given I saved following keys to list in :locators clipboard:
      | network_machine_cidr ||
      | network_service_cidr ||
      | network_pod_cidr     ||
    When I repeat the following steps for each :locator in cb.locators:
    """
    When I perform the :clear_input web action with:
      | locator_id   | #{cb.locator} |
    Then the step should succeed
    """
    When I perform the :check_podcidr_hostprefix_invalid_message web action with:
      | pod_cidr     | 10.128.0.0/20 |
      | host_prefix  | /24           |
    Then the step should succeed
    When I run the :select_multi_az web action
    Then the step should succeed
    When I perform the :check_machine_cidr_error_message web action with:
      | machine_cidr          | 10.0.0.0/24 |
      | error_reason          | /23         |
      | max_machinecidr_range | /23         |
    Then the step should succeed
    When I run the :select_basic_radio_button web action
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-33439 |
    Then the step should succeed
    When I perform the :delete_osd_cluster_from_detail_page web action with:
      | cluster_name | sdqe-ui-33439 |
      | input_text   | sdqe-ui-33439 |
    Then the step should succeed
    """
    When I run the :click_create_button web action
    Then the step should succeed
    When I run the :cluster_detail_page_loaded web action
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-33439 |
    Then the step should succeed
    When I perform the :delete_osd_cluster_from_detail_page web action with:
      | cluster_name | sdqe-ui-33439 |
      | input_text   | sdqe-ui-33439 |
    Then the step should succeed
    """

  # @author xueli@redhat.com
  # @case_id OCP-25424
  Scenario: Checking hover message for disabled machine types when creating OSD cluster
    Given I open ocm portal as an BYOCMultiZQuotaOnlyUser user
    Then the step should succeed
    When I run the :switch_to_osd_creation_page web action
    Then the step should succeed
    When I run the :close_customer_cloud_subscription_prompt_message web action
    Then the step should succeed
    When I run the :check_disabled_standard_card web action
    Then the step should succeed
    ##### Extra step to make the scroll bar scroll down #######
    When I perform the :select_machine_type web action with:
      | machine_type | m5.2xlarge |
    Then the step should succeed
    ###########################################################
    When I run the :check_disabled_single_zone web action
    Then the step should succeed
    When I perform the :check_no_quota_tooltip web action with:
      | machine_type | m5.2xlarge |
    Then the step should fail
    ##### Extra step to make the scroll bar scroll down #######
    When I perform the :select_machine_type web action with:
      | machine_type | m5.2xlarge |
    Then the step should succeed
    ###########################################################
    When I perform the :check_no_quota_tooltip web action with:
      | machine_type | m5.xlarge  |
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    Given I open ocm portal as an StandSingleZQuotaOnlyUser user
    Then the step should succeed
    When I run the :switch_to_osd_creation_page web action
    Then the step should succeed
    When I run the :check_disabled_multi_zone web action
    Then the step should succeed
    When I run the :check_disabled_byoc_card web action
    Then the step should succeed
    When I perform the :check_no_quota_tooltip web action with:
      | machine_type | m5.xlarge |
    Then the step should fail
    ##### Extra step to make the scroll bar scroll down #######
    When I perform the :select_machine_type web action with:
      | machine_type | m5.xlarge |
    Then the step should succeed
    ###########################################################
    When I perform the :check_no_quota_tooltip web action with:
      | machine_type | m5.2xlarge |
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-26751
  Scenario: There will be validation for AWS credentials for BYOC cluster creation
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :switch_to_osd_creation_page web action with:
      | product_id     | osd |
      | cloud_provider | aws |
    Then the step should succeed
    When I run the :select_byoc_model web action
    Then the step should succeed
    When I run the :byoc_page_loaded web action
    Then the step should succeed
    When I run the :check_no_input_errors_to_required_aws_items web action
    Then the step should succeed
    When I perform the :check_invalid_aws_credential_error_message web action with:
      | account_id     | 111111111111                               |
      | aws_access_key | invalidaccesskey                           |
      | aws_secret     | invalidawssecret                           |
      | error_reason   | The provided AWS credentials are not valid |
      | cluster_name   | aws-test                                   |
      | machine_type   | m5.xlarge                                  |
    Then the step should succeed
    Given I saved following keys to list in :accountids clipboard:
      | aaa                  ||
      | 111                  ||
      | abcd.abcd.abcd       ||
      | 1222000000222aaa     ||
    When I repeat the following steps for each :accountid in cb.accountids:
    """
    When I perform the :check_aws_account_id_error_message web action with:
      | account_id    | #{cb.accountid}                                    |
      | error_message | AWS account ID must be a 12 digits positive number.|
    Then the step should succeed
    """

  # @author xueli@redhat.com
  # @case_id OCP-21801
  Scenario: Can not create multi_AZ cluster on regions which do not support Multizone via UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :switch_to_osd_creation_page web action with:
      | product_id     | osd |
      | cloud_provider | aws |
    Then the step should succeed
    Given I saved following keys to list in :regions clipboard:
      | ap-northeast-2 ||
      | ap-south-1     ||
      | ca-central-1   ||
    When I repeat the following steps for each :region in cb.regions:
    """
    When I perform the :check_non_support_multi_az_region_error_message web action with:
      | no_regions ||
      | region_id  | #{cb.region} |
    Then the step should succeed
    """
  
  # @author xueli@redhat.com
  # @case_id OCP-21675
  Scenario: Verify region drop-down list in create cluster panel
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :switch_to_osd_creation_page web action with:
      | product_id     | osd |
      | cloud_provider | aws |
    Then the step should succeed
    Given I saved following keys to list in :regions clipboard:
      | ap-northeast-1, Asia Pacific, Tokyo     ||
      | ap-northeast-2, Asia Pacific, Seoul     ||
      | ap-south-1, Asia Pacific, Mumbai        ||
      | ap-southeast-1, Asia Pacific, Singapore ||
      | ap-southeast-2, Asia Pacific, Sydney    ||
      | ca-central-1, Canada, Central           ||
      | eu-central-1, EU, Frankfurt             ||
      | eu-north-1, EU, Stockholm               ||
      | eu-west-1, EU, Ireland                  ||
      | eu-west-2, EU, London                   ||
      | eu-west-3, EU, Paris                    ||
      | sa-east-1, South America, São Paulo     ||
      | us-east-1, US East, N. Virginia         ||
      | us-east-2, US East, Ohio                ||
      | us-west-1, US West, N. California       ||
      | us-west-2, US West, Oregon              ||
      # | me-south-1, Middle East, Bahrain        |     |
    When I repeat the following steps for each :region in cb.regions:
    """
    When I perform the :select_region_by_text web action with:
      | region_name | #{cb.region} |
    Then the step should succeed
    """

  # @author xueli@redhat.com
  # @case_id OCP-30503
  Scenario: Check the BYOC creation page
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :switch_to_osd_creation_page web action with:
      | product_id     | osd |
      | cloud_provider | aws |
    Then the step should succeed
    When I run the :select_byoc_model web action
    Then the step should succeed
    When I run the :byoc_page_loaded web action
    Then the step should succeed
    When I run the :check_byoc_creation_page web action
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-21086
  Scenario: Create an default OSD cluster on AWS
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    When I perform the :create_osd_cluster web action with:
      | product_id     | osd             |
      | cloud_provider | aws             |
      | cluster_name   | sdqe-ui-default |
    Then the step should succeed
    Given I close the current browser
    Then the step should succeed
    Given I open ocm portal as an orgAdmin user
    Then the step should succeed
    When I perform the :create_osd_cluster web action with:
      | product_id     | osd                      |
      | cloud_provider | aws                      |
      | cluster_name   | sdqe-orgadmin-ui-default |
    When I perform the :wait_cluster_status_on_detail_page web action with:
      | cluster_status | ready |
    Then the step should succeed
    When I run the :check_install_successfully_message_loaded web action
    Then the step should succeed
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-ui-default |
    Then the step should succeed
    When I run the :go_to_cluster_list_page web action
    Then the step should succeed
    When I perform the :go_to_cluster_detail_page web action with:
      | cluster_name | sdqe-orgadmin-ui-default |
    Then the step should succeed
    When I perform the :wait_cluster_status_on_detail_page web action with:
      | cluster_status | ready |
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-21100
  Scenario: Create an advance OSD cluster on AWS
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :create_osd_cluster web action with:
      | product_id     | osd              |
      | cloud_provider | aws              |
      | cluster_name   | sdqe-ui-advanced |
      | region_id      | eu-central-1     |
      | multi_az       | true             |
      | machine_type   | r5.xlarge        |
      | node_number    | 4                |
      | storage_quota  | 600 GiB          |
      | lb_quota       | 4                |
      | machine_cidr   | 10.0.0.0/23      |
      | service_cidr   | 172.30.0.0/24    |
      | pod_cidr       | 10.128.0.0/18    |
      | host_prefix    | /24              |
      | listening      | internal         |
    Then the step should succeed
    When I perform the :wait_cluster_status_on_detail_page web action with:
      | cluster_status | ready |
    Then the step should succeed
    When I run the :refresh_detail_page web action
    Then the step should succeed
    When I perform the :change_additional_router web action with:
      | trimed_cluster_name      | sdqe-ui-advance |
      | enable_additional_router |                 |
    Then the step should succeed
    When I perform the :install_addon web action with:
      | addon_name  | DBA Operator |
      | wait_status | Installed    |
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-28925
  Scenario: Create an OSD cluster on GCP will succeed
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    When I perform the :create_osd_cluster web action with:
      | product_id     | osd                |
      | cloud_provider | gcp                |
      | cluster_name   | sdqe-ui-gcp        |
      | multi_az       | true               |
      | machine_type   | custom-4-32768-ext |
      | node_number    | 4                  |
      | storage_quota  | 600 GiB            |
      | lb_quota       | 4                  |
      | machine_cidr   | 10.0.0.0/23        |
      | service_cidr   | 172.30.0.0/24      |
      | pod_cidr       | 10.128.0.0/18      |
      | host_prefix    | /24                |
    Then the step should succeed
    When I perform the :wait_cluster_status_on_detail_page web action with:
      | cluster_status | ready |
    Then the step should succeed

  # @author tzhou@redhat.com
  # @case_id OCP-29659
  Scenario: Check the resource elements of AWS and GCP in create cluster page
    Given I open ocm portal as a regularUser user
    Then the step should succeed
    When I perform the :switch_to_osd_creation_page web action with:
      | product_id     | osd |
      | cloud_provider | aws |
    Then the step should succeed
    When I run the :check_aws_compute_node_instances_type web action
    Then the step should succeed
    When I run the :select_multi_az web action
    Then the step should succeed
    When I run the :check_aws_compute_node_instances_type web action
    Then the step should succeed
    When I run the :select_byoc_model web action
    Then the step should succeed
    When I run the :check_aws_compute_node_instances_type web action
    Then the step should succeed
    When I run the :select_multi_az web action
    Then the step should succeed
    When I run the :check_aws_compute_node_instances_type web action
    Then the step should succeed
    When I run the :click_clusters_url web action
    Then the step should succeed
    When I perform the :switch_to_osd_creation_page web action with:
      | product_id     | osd |
      | cloud_provider | gcp |
    Then the step should succeed
    When I run the :check_gcp_compute_node_instances_type web action
    Then the step should succeed
    When I run the :select_multi_az web action
    Then the step should succeed
    When I run the :check_gcp_compute_node_instances_type web action
    Then the step should succeed
