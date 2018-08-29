Feature: metrics diagnostics tests
  # @author pruan@redhat.com
  # @case_id OCP-9982
  @admin
  @destructive
  Scenario: Heapster should use node name instead of external ID to indentify metrics
    Given I create a project with non-leading digit name
    And metrics service is installed in the system
    Given I select a random node's host
    And evaluation of `node.external_id` is stored in the :external_id clipboard
    Given cluster role "cluster-admin" is added to the "first" user
    And I switch to first user
    # it usually take a little while for the query to comeback with contents
    And I wait for the steps to pass:
    """
    And I perform the GET metrics rest request with:
      | project_name | _system              |
      | path         | /metrics/metrics     |
    And the expression should be true> @result[:exitstatus] == 200
    """
    # extract all of the result id and parse it into an array which should NOT contain external ID
    And evaluation of `YAML.load(@result[:response]).map { |r| r['id'] }` is stored in the :result_ids clipboard
    Then the expression should be true> cb.result_ids.select {|id| id.include? cb.external_id}.count == 0

  # @author pruan@redhat.com
  # @case_id OCP-13082
  @admin
  @destructive
  Scenario: Make sure no password exposed in process command line
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And metrics service is installed in the system
    And I select a random node's host
    And I run commands on the host:
      | ps -aux \| grep hawkular |
    Then the output should not contain:
      | password= |
