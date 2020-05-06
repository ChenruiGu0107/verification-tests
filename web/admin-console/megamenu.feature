Feature: mega menu on console

  # @author yanpzhan@redhat.com
  # @case_id OCP-24512
  @admin
  Scenario: Check mega menu on console
    Given the master version >= "4.2"
    And I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :navigate_to_dev_console web action
    Then the step should succeed
    And the expression should be true> browser.url.include? "/topology/"
    When I run the :goto_projects_list_page web action
    Then the step should succeed
    When I run the :check_mega_menu web action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-25761
  @admin
  Scenario: Allow users to Report Bug and Open Support Case from console
    # we don't cover 'Open Support Case' button, this is for the test before release.
    Given the master version >= "4.3"
    And I store master major version in the clipboard
    And evaluation of `cluster_version('version').version` is stored in the :cf_environment_version clipboard
    And evaluation of `cluster_version('version').cluster_id` is stored in the :cluster_id clipboard

    Given the first user is cluster-admin
    And I open admin console in a browser
    When I run the :click_report_bug_link_in_helpmenu web action
    Then the step should succeed
    When I wait up to 60 seconds for the steps to pass:
    """
    When I perform the :check_page_contains web action in ":url=>bugzilla" window with:
      | content | Red Hat Bugzilla |
    Then the step should succeed
    """
    Then the expression should be true> @result[:url].include? "bugzilla.redhat.com/enter_bug"
    And the expression should be true> @result[:url].include? "product=OpenShift%20Container%20Platform"
    And the expression should be true> @result[:url].include? "version=<%= cb.master_version %>"
    And the expression should be true> @result[:url].include? "cf_environment=Version%3A%20<%= cb.cf_environment_version %>"
    And the expression should be true> @result[:url].include? "Cluster%20ID%3A%20<%= cb.cluster_id %>"
