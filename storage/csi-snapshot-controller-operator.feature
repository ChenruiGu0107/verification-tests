Feature: CSI snapshot operator related scenarios
  # @author lxia@redhat.com
  # @author wduan@redhat.com
  # @case_id OCP-27564
  @admin
  Scenario: CSI snapshot controller operator is installed by default	
    Given the master version >= "4.4"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-cluster-storage-operator" project
    And a pod becomes ready with labels:
      | app=csi-snapshot-controller-operator |

  # @author lxia@redhat.com
  # @author wduan@redhat.com
  # @case_id OCP-27567
  @admin
  Scenario: CSI snapshot controller operator installs CSI snapshot controller
    Given the master version >= "4.4"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-cluster-storage-operator" project
    And a pod becomes ready with labels:
      | app=csi-snapshot-controller |

  # @author lxia@redhat.com
  # @case_id OCP-27568
  @admin
  Scenario: Cluster operator csi-snapshot-controller is in available status
    Given the master version >= "4.4"
    Given the expression should be true> cluster_operator('csi-snapshot-controller').condition(type: 'Progressing')['status'] == "False"
    Given the expression should be true> cluster_operator('csi-snapshot-controller').condition(type: 'Available')['status'] == "True"
    Given the expression should be true> cluster_operator('csi-snapshot-controller').condition(type: 'Degraded')['status'] == "False"
    Given the expression should be true> cluster_operator('csi-snapshot-controller').condition(type: 'Upgradeable')['status'] == "True"

