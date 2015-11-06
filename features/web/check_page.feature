Feature: check page info related

  # @author xxing@redhat.com
  # @case_id 499945
  Scenario: Help info on project page
    Given I login via web console
    When I get the html of the web page
    Then the output should contain:
      | OpenShift helps you quickly develop, host, and scale applications |
      | Create a project for your application                             |
    When I perform the :new_project web console action with:
      | project_name | <%= rand_str(5, :dns) %> |
      | display_name | :null                    |
      | description  ||
    Then the step should succeed
    And I get the html of the web page
    Then the output should contain:
      | Select Image or Template |
      | Choose from web frameworks, databases, and other components |
