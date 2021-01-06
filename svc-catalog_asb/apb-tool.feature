Feature: The apb tool related scenarios
  # @author jfan@redhat.com
  # @case_id OCP-29835
  @admin
  Scenario: [stage] apb-tools image check
    Given I have a project
    Given I store master major version in the :master_version clipboard
    Given I create the serviceaccount "apbtoolsstage"
    Given SCC "privileged" is added to the "system:serviceaccount:<%= project.name %>:apbtoolsstage" service account
    Given I obtain test data file "svc-catalog/apbtools.yaml"
    When I process and create:
      | f | apbtools.yaml |
      | p | IMAGE=registry.stage.redhat.io/openshift4/apb-tools:v<%= cb.master_version %> |
      | p | NAMESPACE=<%= project.name %> |
    Then the step should succeed
    And I wait up to 300 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should contain:
      | CrashLoopBackOff |
    """
    When I run the :logs client command with:
      | resource_name | deployment/apbtools |
      | since         | 60s                 |
    Then the step should succeed
    And the output should contain:
      | Tool for working with Ansible Playbook Bundles |
