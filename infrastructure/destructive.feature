Feature: relate with destructive features

  # @author chezhang@redhat.com
  # @case_id OCP-9712
  @admin
  @destructive
  Scenario: Creating project with template with quota/limit range
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/create-bootstrap-quota-limit-template.yaml |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    projectConfig:
      projectRequestTemplate: "<%= project.name %>/project-request"
    """
    And the master service is restarted on all master nodes
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
      | Container\\s+memory\\s+-\\s+-\\s+512Mi                           |
      | Container\\s+cpu\\s+-\\s+-\\s+200m                               |
