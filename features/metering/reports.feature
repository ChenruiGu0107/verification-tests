Feature: reports related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-20900
  @admin
  @destructive
  Scenario: view metering report with supported formats
    Given metering service has been installed successfully
    And I use the "openshift-metering" project
    Given I select a random node's host
    Given I get the "node-cpu-capacity" report and store it in the :res_json clipboard using:
      | query_type          | node-cpu-capacity |
      | use_existing_report | true              |
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
    And evaluation of `Time.parse(cb.res_json[-1]['timestamp']).utc.to_s.gsub('UTC', '+0000 UTC')` is stored in the :timestamp clipboard
    And the expression should be true> cb.res_tabular.include? cb.timestamp
    And the expression should be true> cb.res_csv.include? cb.timestamp
