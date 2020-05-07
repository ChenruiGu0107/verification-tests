Feature: metrics permission related tests
  # @author pruan@redhat.com
  # @case_id OCP-12084
  @admin
  @destructive
  Scenario: User can only read metrics data when USER_WRITE_ACCESS is specified to false
    Given I have a project
    Given metrics service is installed in the system
    Given I switch to the first user
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /metrics/gauges     |
    Then the expression should be true> @result[:exitstatus] == 204
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /metrics/gauges                                                                                   |
      | payload      | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/test_data.json |
    # for older oc version, the status code was 401
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-12168
  @admin
  @destructive
  Scenario: User can only read metrics data when USER_WRITE_ACCESS parameter is not specified
    Given I have a project
    And evaluation of `project` is stored in the :org_project clipboard
    Given metrics service is installed in the system
    Given I switch to the first user

    And I use the "<%= cb.org_project.name %> project
    Given I perform the GET metrics rest request with:
      | project_name | <%= cb.org_project.name %> |
      | path         | /metrics/gauges     |
    Then the expression should be true> @result[:exitstatus] == 204
    Given I perform the POST metrics rest request with:
      | project_name | <%= cb.org_project.name %>                                                                        |
      | path         | /metrics/gauges                                                                                   |
      | payload      | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/test_data.json |
    # for older oc version, the status code was 401
    Then the expression should be true> [401, 403].include? @result[:exitstatus]
