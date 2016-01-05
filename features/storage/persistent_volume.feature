Feature: Persistent Volume Claim binding policies

  # @author jhou@redhat.com
  # @case_id 510615
  @admin @destructive
  Scenario: Given there are one PV and multiple PVCs, only one PVC can bound the PV.
    # Preparations
    Given I have a project

    # Create 2 PVCs and 1 PV
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json |
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo-2.json |
    And admin creates a PV from "https://github.com/openshift-qe/v3-testfiles/raw/master/persistent-volumes/nfs/nfs-default.json" where:
      ||

    # The output should contain 1 Pending PVC and 1 Bound PVC
    When I run the :get client command with:
      | resource | pvc |
    Then the output should contain:
      | Pending |
      | Bound   |
