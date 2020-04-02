Feature: KUBE API server related features
  # @author kewang@redhat.com
  # @case_id OCP-24698
  @admin
  Scenario: Check the http accessible /readyz for kube-apiserver	
    Given I store the schedulable masters in the :nodes clipboard
    When I run the :project admin command with:
      | project_name | openshift-kube-apiserver |
    Then the output should contain:
      | project "openshift-kube-apiserver" on server |
    And I run the :port_forward background admin command with:
      | pod       | kube-apiserver-<%= cb.nodes[1].name %> |
      | port_spec | 6080                                   |
      | _timeout  | 60                                     |
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I open web server via the "http://127.0.0.1:6080/readyz" url
    Then the step should succeed
    And the output should contain "ok"
    """
