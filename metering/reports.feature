Feature: reports related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-20900
  @admin
  @destructive
  Scenario: view metering report with supported formats
    Given metering service has been installed successfully
    And I use the "<%= cb.metering_namespace.name %>" project
    Given I get the "node-cpu-capacity" report and store it in the :res_json clipboard using:
      | query_type          | node-cpu-capacity |
    Then the step should succeed
    Given I get the "node-cpu-capacity" report and store it in the :res_csv clipboard using:
      | query_type          | node-cpu-capacity |
      | use_existing_report | true              |
      | format              | csv               |
    Then the step should succeed
    Given I get the "node-cpu-capacity" report and store it in the :res_tabular clipboard using:
      | query_type          | node-cpu-capacity |
      | use_existing_report | true              |
      | format              | tabular           |
    Then the step should succeed
    # save the last element of the timestamp which should appear in all three formats
    And evaluation of `cb.res_json[-1]['period_start']` is stored in the :timestamp clipboard
    And the expression should be true> cb.res_tabular.include? cb.timestamp
    And the expression should be true> cb.res_csv.include? cb.timestamp

  # @author pruan@redhat.com
  # @case_id OCP-20951
  @admin
  @destructive
  Scenario: verify PV ReportGenerationQuery are supported and be able to generate a report
    Given metering service has been installed successfully
    And I use the "<%= cb.metering_namespace.name %>" project
    Given I get the "persistentvolumeclaim-request" report and store it in the :res_json clipboard using:
      | query_type | persistentvolumeclaim-request |
    Then the step should succeed
    And the expression should be true> (report_query('persistentvolumeclaim-request').column_names - cb.res_json.first.keys).empty?


  # @author pruan@redhat.com
  # @case_id OCP-24821
  @admin
  @destructive
  Scenario: Verify 'columns' in results.values have consistent ordering
    Given metering service has been installed successfully
    And I use the "<%= cb.metering_namespace.name %>" project
    Given I select a random node's host
    Given I get the "node-cpu-capacity" report and store it in the :res_json clipboard using:
      | query_type | node-cpu-capacity |
    # save the expected names into an array
    And evaluation of `cb.res_json['results'].first['values'].map { |h| h['name'] }` is stored in the :golden_list clipboard
    # compare element by element between the two arrays and return those that don't match (should be 0)
    Then the expression should be true> cb.res_json['results'].all? { |r| r['values'].map{ |h| h['name'] } == cb.golden_list }
