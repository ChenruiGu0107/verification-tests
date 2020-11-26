Feature: Compliance Operator related scenarios
  # @author xiyuan@redhat.com
  # @case_id OCP-35892
  @admin
  Scenario: Compliance Operator should get deployed successfully in stage env
    Given I switch to cluster admin pseudo user
    When I use the "openshift-compliance" project
    #check compliance related pods are ready in openshift-compliance projects
    And status becomes :running of exactly 1 pods labeled:
      | name=compliance-operator |
    And status becomes :running of exactly 2 pods labeled:
      | workload=profileparser |
