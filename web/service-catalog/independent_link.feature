Feature: Independent link related scenarios
  # @author xiaocwan@redhat.com
  # @case_id OCP-15857
  @admin
  Scenario: Launch service catalog panel if serivceclass param in url
    Given the master version >= "3.7"
    When I run the :get client command with:
      | resource | clusterserviceclass |
      | n        | openshift           |
    Then the step should succeed
    ## @result[:response].split=> ["NAME", "AGE", "0e991006d21029e47abe71acc255e807", "1d",...]
    And evaluation of `@result[:response].split("\n")[1].split()[0]` is stored in the :id clipboard
    When I run the :describe admin command with:
      | resource | clusterserviceclass |
      | name     | <%= cb.id %>        |
    Then the step should succeed
    ## @result[:stdout].split("External Name:")[1].split()[0] => "mariadb-ephemeral"
    And evaluation of `@result[:stdout].split("External Name:")[1].split()[0]` is stored in the :name clipboard

    # Check wizard is opened by external page by url passing clusterserviceclass name
    Then I perform the :goto_serviceclass_panel web console action with:
      | name | <%= cb.name %>  |
    Then the step should succeed
    When I run the :check_wizard_information web console action
    Then the step should succeed

