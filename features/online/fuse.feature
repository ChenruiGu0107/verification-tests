Feature: ONLY Fuse Plan related scripts in this file

  # @author yuwei@redhat.com
  # @case_id OCP-19003
  Scenario: Check Fuse plan on 'Select a Plan' page	
    Given I open accountant console in a browser
    When I run the :go_to_register_plan web action
    Then the step should succeed
    When I run the :check_fuse_small_plan_info web action
    Then the step should succeed

  # @author yuwei@redhat.com
  # @case_id OCP-19009
  # @note this Scenario requires a user that already has a fuse plan
  Scenario: Check "Subscription index" page - fuse
  	Given I open accountant console in a browser
  	When I perform the :check_fuse_subscription_index_page web action with:
  	  | console_url 		    | <%= env.web_console_url %> |
      | email       		    | <%= user.name %>           |
      | integration_number  | 5							             |
      | memory				      | 8GiB						           |
      | storage				      | 5GiB						           |
      | cpu_number			    | 16 vCPU					           |
  	Then the step should succeed

  # @author yuwei@redhat.com
  # @case_id OCP-19014
  # @note this Scenario requires a user that already has a fuse plan
  Scenario: Check the account overview page after provisioned on a fuse cluster	
	Given I open accountant console in a browser
	When I run the :go_to_account_page web action
	Then the step should succeed
	When I perform the :check_fuse_account_overview_page web action with:
	  | cpu_number | 16 vCPU |
	  | storage    | 5GiB    |
	  | memory     | 8GiB    |
	Then the step should succeed
