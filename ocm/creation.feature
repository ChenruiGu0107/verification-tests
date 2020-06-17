Feature: only about page related to cluster login page

  # @author xueli@redhat.com
  # @case_id OCP-22042
  Scenario: Check vpcCIDR , podCIDR and serviceCIDR textbox on UI page.
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :switch_to_osd_creation_page web action
    When I run the :select_advanced_radio_button web action
    Then the step should succeed
    # Have to select machine_type due to known issue: SDA-1463
    When I perform the :fill_in_required_items_on_osd_creation_page web action with:
      | cluster_name | sdqe-cidr-test |
      | machine_type | m5.xlarge |
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
      | cidr_value | #{cb.cidr_value} |
    Then the step should succeed
    When I perform the :check_service_cidr_error_message web action with:
      | cidr_value | #{cb.cidr_value} |
    Then the step should succeed
    When I perform the :check_pod_cidr_error_message web action with:
      | cidr_value | #{cb.cidr_value} |
    Then the step should succeed
    """
    When I perform the :check_cidr_invalid_range_error_message web action with:
      | cidr_value | 10.0.0.0/25 |
    Then the step should succeed
    When I run the :check_host_prefix_error_messages web action
    Then the step should succeed
    # Input invalid value and close advaced options: known issue SDA-1617
    When I perform the :check_cidr_background_validation_error_message web action with:
      | locator_id   | network_machine_cidr                                                  |
      | cidr_value   | 172.30.0.0/16                                                         |
      | error_reason | Machine CIDR '172.30.0.0/16' and service CIDR '172.30.0.0/16' overlap |
    Then the step should succeed
    When I perform the :check_cidr_background_validation_error_message web action with:
      | locator_id   | network_machine_cidr                                               |
      | cidr_value   | 10.0.0.6/16                                                        |
      | error_reason | network address '10.0.0.6' isn't consistent with network prefix 16 |
    Then the step should succeed
    ########## This step is added to debug below steps #####
    #  When I perform the :clear_input web action with:
    #   |locator_id|network_machine_cidr|
    #  Then the step should succeed
    ########################################################
    When I run the :select_basic_radio_button web action
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    When I run the :cluster_detail_page_loaded web action
    Then the step should succeed
    And I register clean-up steps:
      """
        When I perform the :delete_osd_cluster_from_detail_page web action with:
          | cluster_name | xueli-cidr-test |
          | input_text   | xueli-cidr-test |
        Then the step should succeed
      """

  # @author xueli@redhat.com
  # @case_id OCP-25424
  Scenario: Checking hover message for disabled machine types when creating OSD cluster
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :switch_to_osd_creation_page web action
    Then the step should succeed
    When I perform the :check_no_quota_tooltip web action with:
      | machine_type | m5.xlarge |
    Then the step should fail
    ##### Extra step to make the scroll bar scroll down #######
    When I perform the :select_machine_type web action with:
      | machine_type | c5.2xlarge |
    Then the step should succeed
    ###########################################################
    When I perform the :check_no_quota_tooltip web action with:
      | machine_type | c5.4xlarge |
    Then the step should succeed
    When I run the :select_multi_az web action
    Then the step should succeed
    When I perform the :check_no_quota_tooltip web action with:
      | machine_type | c5.2xlarge |
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-26751
  Scenario: There will be validation for AWS credentials for BYOC cluster creation
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :switch_to_osd_creation_page web action 
    Then the step should succeed
    When I run the :select_byoc_model web action 
    Then the step should succeed
    When I run the :check_no_input_errors_to_required_aws_items web action
    Then the step should succeed
    When I run the :check_invalid_aws_credential_error_message web action
    Then the step should succeed

  # @author xueli@redhat.com
  # @case_id OCP-21801
  Scenario: Can not create multi_AZ cluster on regions which do not support Multizone via UI
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I perform the :switch_to_osd_creation_page web action
    Then the step should succeed
    Given I saved following keys to list in :regions clipboard:
      | ap-northeast-2 ||
      | ap-south-1     ||
      | ca-central-1   ||
    When I repeat the following steps for each :region in cb.regions:
    """
    When I perform the :check_non_support_multi_az_region_error_message web action with:
      | region_id | #{cb.region} |
    Then the step should succeed
    """
  # @author xueli@redhat.com
  # @case_id OCP-21675
  Scenario: Verify region drop-down list in create cluster panel
    Given I open ocm portal as an regularUser user
    Then the step should succeed
    When I run the :switch_to_osd_creation_page web action
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
    When I repeat the following steps for each :region in cb.regions:
    """
    When I perform the :select_region_by_text web action with:
      | region_name | #{cb.region} |
    Then the step should succeed
    """