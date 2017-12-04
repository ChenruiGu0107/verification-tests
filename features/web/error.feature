Feature: error page on web console
  # @author yapei@redhat.com
  # @case_id OCP-11446
  Scenario: Redirect to error page when got 403 error
    Given I have a project
    When I perform the :delete_project web console action with:
      | project_name | <%= project.name %> |
      | input_str    | <%= project.name %> |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_error_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    """
    # switch to second user,create new project
    Given I switch to the second user
    Given an 8 characters random string of type :dns is stored into the :project2 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed
    Given I switch to the first user
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed
    When I perform the :check_error_page web console action with:
      | project_name | <%= cb.project2 %> |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-15364
  @destructive
  @admin
  Scenario: Check System Alerts on Masthead as online message
    Given the master version >= "3.7"
    Given I use the first master host
    Given the "/etc/origin/master/system-status.js" file is restored on host after scenario
    When I run commands on all masters:
      | curl -o /etc/origin/master/system-status.js https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/extensions/system-status.js                                                                |
      | sed -i 's#https://m0sg3q4t415n.statuspage.io/api/v2/summary.json#https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/extensions/system-status.json#g'  /etc/origin/master/system-status.js |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    assetConfig:
      extensionScripts:
      - /etc/origin/master/system-status.js
      - /etc/origin/master/openshift-ansible-catalog-console.js
    """
    And the master service is restarted on all master nodes

    When I run the :check_system_status_issues_warning web console action
    Then the step should succeed
