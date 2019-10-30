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
