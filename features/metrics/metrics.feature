Feature: metrics related scenarios
  # @author: pruan@redhat.com
  # @case_id: OCP-11821
  Scenario: User can insert data to hawkular metrics in their own tanent when USER_WRITE_ACCESS parameter is 'true'
    Given I have a project
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | type         | gauges                                                                                            |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | type         | gauges              |
    Then the expression should be true> YAML.load(@result[:response])[0]['minTimestamp'] == 1460111065369
    And the expression should be true> YAML.load(@result[:response])[0]['maxTimestamp'] == 1460413065369

  # @author: pruan@redhat.com
  # @case_id: OCP-11979
  Scenario: User can not create metrics in the tenant which owned by other user
    Given I have a project
    And I store default router subdomain in the :metrics clipboard
    And I switch to the second user
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | type         | gauges                                                                                            |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    Then the expression should be true> @result[:exitstatus] == 403


