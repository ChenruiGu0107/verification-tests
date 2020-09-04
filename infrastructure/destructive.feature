Feature: relate with destructive features

  # @author chezhang@redhat.com
  # @author weinliu@redhat.com
  # @case_id OCP-9712
  @admin
  @destructive
  Scenario: Creating project with template with quota/limit range
    Given admin ensures "project-request" templates is deleted from the "openshift-config" project after scenario
    Given I register clean-up steps:
    """
    Given as admin I successfully merge patch resource "project.config.openshift.io/cluster" with:
      | { "spec": { "projectRequestTemplate": {"name": null}}} |
    """
    #Using merge patch to update cluster setting
    Given as admin I successfully merge patch resource "project.config.openshift.io/cluster" with:
      | { "spec": { "projectRequestTemplate": {"name": "project-request" }}} |
    And I obtain test data file "templates/create-bootstrap-quota-limit-template.yaml"
    When I run the :create admin command with:
      | f | create-bootstrap-quota-limit-template.yaml |
      | n | openshift-config                           |
    Then the step should succeed
    # After cluster updated, it requires around 2min to take effect
    Given 120 seconds have passed
    When I run the :new_project client command with:
      | project_name | demo                                             |
      | description  | This is the first demo project with OpenShift v3 |
      | display_name | OpenShift 3 Demo                                 |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | project |
      | name     | demo    |
    Then the output should match:
      | Name:\\s+demo                                                    |
      | Display Name:\\s+OpenShift 3 Demo                                |
      | Description:\\s+This is the first demo project with OpenShift v3 |
      | Status:\\s+Active                                                |
      | cpu.*20                                                          |
      | memory.*1Gi                                                      |
      | persistentvolumeclaims.*10                                       |
      | pods.*10                                                         |
      | replicationcontrollers.*20                                       |
      | resourcequotas.*1                                                |
      | secrets.*10                                                      |
      | services.*5                                                      |
      | Container\\s+memory\\s+-\\s+-\\s+256Mi\\s+512Mi                  |
      | Container\\s+cpu\\s+-\\s+-\\s+100m\\s+200m                       |
