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

  # @author xxing@redhat.com
  # @case_id 479237
  Scenario: Check project annotation info on web console
    When I create a project via web with:
      | display_name | Test |
      | description  ||
    Then the step should succeed
    When I run the :check_project_list web console action
    And I get the "text" attribute of the "a" web element:
      | href | project/<%= project.name %> |
    Then the output should contain "Test"
    When I perform the :check_project_overview web console action with:
      | project_name | <%= project.name %> |
    And I get the "text" attribute of the "element" web element:
      | xpath | //div/ul/li[1]/a[@tabindex="0"] |
    Then the output should contain "Test"
    When I perform the :check_project_without_quota_settings web console action with:
      | project_name | <%= project.name %> |      
    When I get the html of the web page
    Then the output should match:
      | <dd.+Test |
