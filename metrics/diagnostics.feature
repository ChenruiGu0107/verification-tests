Feature: metrics diagnostics tests
  # @author pruan@redhat.com
  # @case_id OCP-9982
  @admin
  @destructive
  Scenario: Heapster should use node name instead of external ID to indentify metrics
    Given I create a project with non-leading digit name
    Given I select a random node's host
    And evaluation of `@nodes.map {|n| n.name }` is stored in the :node_names clipboard
    And metrics service is installed in the system
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
    # extract all of the result id and save the names portion into an array which should be one of the node_names
    And evaluation of `YAML.load(@result[:response]).select { |r| r['id'] if r['id'].start_with? 'machine' }.map { |e| e["id"].split('machine/')[1].split('/')[0] }` is stored in the :result_names clipboard
    Then the expression should be true> cb.result_names.select {|n| cb.node_names.include? n}.count == cb.result_names.count
