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
    And I have a NFS service in the project
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv.json" where:
      | ["spec"]["nfs"]["server"]  | <%= service("nfs-service").ip %> |
      | ["spec"]["accessModes"][0] | ReadWriteOnce                    |

    # The output should contain 1 Pending PVC and 1 Bound PVC
    When I run the :get client command with:
      | resource | pvc |
    Then the output should contain:
      | Pending |
      | Bound   |

    # TODO: test if after removing Bound pvc, the other one will get Bound
    # When I run the :delete client command with:
    #  | object_type       | pvc  |
    #  | object_name_or_id | nfsc |

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

