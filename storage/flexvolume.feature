Feature: Flexvolume plugin testing
  # @author piqin@redhat.com
  # @case_id OCP-19786
  @admin
  Scenario: Install and use flexVolume
    Given I have a project
    And I create the serviceaccount "flex-deployer"
    And SCC "privileged" is added to the "flex-deployer" service account

    Given I obtain test data file "storage/flexvolume/ds.yaml"
    When I run the :create client command with:
      | f | ds.yaml             |
      | n | <%= project.name %> |
    Then the step should succeed
    Given I store the workers in the :workers clipboard
    And <%= cb.workers.count %> pods become ready with labels:
      | app=flex-deploy |

    Given I obtain test data file "storage/flexvolume/deployment.yaml"
    When I run the :create client command with:
      | f | deployment.yaml     |
      | n | <%= project.name %> |
    Then the step should succeed
    And 1 pods become ready with labels:
      | app=hello-storage |
