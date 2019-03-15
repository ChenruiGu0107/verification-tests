Feature: https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-22715
  # @author lxia@redhat.com
  # @case_id OCP-22715
  @admin
  Scenario: Cluster operator storage should be in available status
    When I run the :get admin command with:
      | resource      | clusteroperator                                                    |
      | resource_name | storage                                                            |
      | o             | jsonpath='{.status.conditions[?(@.type == "Progressing")].status}' |
    Then the step should succeed
    And the output should contain:
      | False |
    When I run the :get admin command with:
      | resource      | clusteroperator                                                  |
      | resource_name | storage                                                          |
      | o             | jsonpath='{.status.conditions[?(@.type == "Available")].status}' |
    Then the step should succeed
    And the output should contain:
      | True |
    When I run the :get admin command with:
      | resource      | clusteroperator                                                |
      | resource_name | storage                                                        |
      | o             | jsonpath='{.status.conditions[?(@.type == "Failing")].status}' |
    Then the step should succeed
    And the output should contain:
      | False |
