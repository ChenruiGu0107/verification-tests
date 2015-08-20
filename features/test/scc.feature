Feature: some SCC policy related scenarios

  Scenario: NFS server
    Given I have a project
    And I have a NFS service in the project
    # one needs to verify scc is deleted upon scenario end
