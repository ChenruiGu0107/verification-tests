Feature: metrics permission related tests
  # @author pruan@redhat.com
  # @case_id OCP-11821
  @admin
  @destructive
  Scenario: User can insert data to hawkular metrics in their own tenant when USER_WRITE_ACCESS parameter is 'true'
    Given I have a project
    Given metrics service is installed in the system using:
      | inventory       | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-11821/inventory              |
      | deployer_config | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    And I switch to the first user
    Given I have a project
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /metrics/gauges                                                                                   |
      | payload      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/test_data.json |
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /metrics/gauges     |
      | token        | <%= user.cached_tokens.first %> |
    Then the expression should be true> cb.metrics_data[0][:parsed]['minTimestamp'] == 1460111065369
    Then the expression should be true> cb.metrics_data[0][:parsed]['maxTimestamp'] == 1460413065369

  # @author pruan@redhat.com
  # @case_id OCP-11979
  @admin
  @destructive
  Scenario: User can not create metrics in the tenant which owned by other user
    Given I have a project
    Given metrics service is installed in the system using:
      | inventory       | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-11821/inventory              |
      | deployer_config | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    And I switch to the second user
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /metrics/gauges                                                                                   |
      | payload      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/test_data.json |
    # for older oc version, the status code was 401
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

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
      | payload      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/test_data.json |
    # for older oc version, the status code was 401
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-10928
  @admin
  @destructive
  Scenario: User cannot create metrics in _system tenant even if USER_WRITE_ACCESS parameter is 'true'
    Given I have a project
    Given metrics service is installed in the system using:
      | inventory       | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-11821/inventory              |
      | deployer_config | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    And I switch to the first user
    And I perform the POST metrics rest request with:
      | project_name | _system                                                                                           |
      | path         | /metrics/gauges                                                                                   |
      | payload      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/test_data.json |
    Then the expression should be true> @result[:exitstatus] == 403

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
      | payload      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/test_data.json |
    # for older oc version, the status code was 401
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-11336
  @admin
  @destructive
  Scenario: Insert data into Cassandra DB through external Hawkular Metrics API interface without Hawkular-tenant specified
    Given I have a project
    Given metrics service is installed in the system using:
      | inventory       | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-11821/inventory              |
      | deployer_config | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    Then I switch to the first user
    Given I perform the POST metrics rest request with:
      | project_name | :false                                                                                            |
      | path         | /metrics/gauges                                                                                   |
      | payload      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/test_data.json |
    Then the expression should be true> @result[:exitstatus] == 400
