Feature: https://polarion.engineering.redhat.com/polarion/#/project/OSE/workitem?id=OCP-22125
  # @author lxia@redhat.com
  # @case_id OCP-22125
  Scenario: There should be one and only one default storage class
    When I run the :get client command with:
      | resource | storageclass |
    Then the step should succeed
    And the output should contain:
      | default |
    When I run the :get client command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should contain 1 times:
      | storageclass.kubernetes.io/is-default-class: "true" |
    When I run the :describe client command with:
      | resource | storageclass |
    Then the step should succeed
    And the output should contain 1 times:
      | storageclass.kubernetes.io/is-default-class=true |
