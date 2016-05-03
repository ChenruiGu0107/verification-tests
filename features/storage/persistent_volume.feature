Feature: Persistent Volume Claim binding policies

  # @author jhou@redhat.com
  # @case_id 510615
  @admin @destructive
  Scenario: PVC with accessMode RWO could bound PV with accessMode RWO
    # Preparations
    Given I have a project

    # Create 2 PVs
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template-all-access-modes.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %> |
    And admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template-rox-rwx.json" where:
      | ["metadata"]["name"]      | nfs1-<%= project.name %> |

    # Create 1 PVC
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json |

    # First PV can bound because it has RWO
    When I run the :get admin command with:
      | resource | pv/nfs-<%= project.name %> |
    Then the output should contain:
      | Bound |
      | nfsc  | # The PVC name it bounds to

    # Second PV can not bound because it does not have RWO
    When I run the :get admin command with:
      | resource | pv/nfs1-<%= project.name %> |
    Then the output should contain:
      | Available |

  # @author jhou@redhat.com
  # @case_id 510616
  @admin @destructive
  Scenario: PVC with accessMode RWX could bound PV with accessMode RWX
    # Preparations
    Given I have a project

    # Create 2 PVs
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template-all-access-modes.json" where:
      | ["metadata"]["name"]      | nfs-<%= project.name %> |
    And admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template-rwo-rox.json" where:
      | ["metadata"]["name"]      | nfs1-<%= project.name %> |

    # Create 1 PVC
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwx.json |

    # First PV can bound because it has RWO
    When I run the :get admin command with:
      | resource | pv/nfs-<%= project.name %> |
    Then the output should contain:
      | Bound |
      | nfsc  | # The PVC name it bounds to

    # Second PV can not bound because it does not have RWO
    When I run the :get admin command with:
      | resource | pv/nfs1-<%= project.name %> |
    Then the output should contain:
      | Available |


  # @author yinzhou@redhat.com
  # @case_id 510610
  @admin @destructive
  Scenario: deployment hook volume inheritance -- with persistentvolumeclaim Volume
    Given I have a project
    And I have a NFS service in the project
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv.json" where:
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc.json |
    When I run the :get client command with:
      | resource | pvc |
    Then the output should contain:
      | Bound   |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/510610/hooks-with-nfsvolume.json |
    Then the step should succeed
  ## mount should be correct to the pod, no-matter if the pod is completed or not, check the case checkpoint
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource  | pod  |
      | resource_name | hooks-1-hook-pre |
      |  o        | yaml |
    Then the output by order should match:
      | - mountPath: /opt1     |
      | name: v1               |
      | persistentVolumeClaim: |
      | claimName: nfsc        |
    """
