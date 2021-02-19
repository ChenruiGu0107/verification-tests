Feature: about cluster setting page

  # @author yanpzhan@redhat.com
  # @case_id OCP-33125
  @admin
  Scenario: Check subscription link and channel helper text with links
    Given the master version >= "4.6"
    Given I open admin console in a browser
    Given the first user is cluster-admin
    Given I store master major version in the :master_version clipboard
    When I run the :goto_cluster_settings_details_page web action
    Then the step should succeed
    When I perform the :check_ocm_subscription web action with:
      | cluster_id | <%= cluster_version("version").cluster_id %> |
    Then the step should succeed
    When I perform the :check_help_info_on_channel_popup web action with:
      | product_version | <%= cb.master_version %> |
    Then the step should succeed
    When I perform the :check_help_info_in_update_channel_modal web action with:
      | product_version | <%= cb.master_version %> |
    Then the step should succeed

  # @author schituku@redhat.com
  # @case_id OCP-25832
  @admin
  Scenario: Check the channels in the channel list drop down.
    Given the master version >= "4.4"
    Given I open admin console in a browser
    Given the first user is cluster-admin
    Given I store master major version in the :master_version clipboard
    When I run the :goto_cluster_settings_details_page web action
    And I perform the :check_list_of_channels_in_channel_modal web action with:
      | product_version | <%= cb.master_version %> |
    Then the step should succeed

  # @author yapei@rehdat.com
  # @case_id OCP-33402
  @admin
  Scenario: Check related objects of cluster operator
    Given the master version >= "4.6"
    Given the first user is cluster-admin
    Given I open admin console in a browser
    
    When I perform the :goto_co_relatedobjects_page web action with:
      | clusteroperator_name | openshift-apiserver |
    Then the step should succeed
    Given I check all relatedObjects of clusteroperator "openshift-apiserver" are shown
    
    When I perform the :goto_co_relatedobjects_page web action with:
      | clusteroperator_name | openshift-controller-manager |
    Then the step should succeed
    Given I check all relatedObjects of clusteroperator "openshift-controller-manager" are shown
    
    When I perform the :goto_co_relatedobjects_page web action with:
      | clusteroperator_name | authentication |
    Then the step should succeed
    Given I check all relatedObjects of clusteroperator "authentication" are shown

    When I perform the :goto_co_relatedobjects_page web action with:
      | clusteroperator_name | console |
    Then the step should succeed
    Given I check all relatedObjects of clusteroperator "console" are shown