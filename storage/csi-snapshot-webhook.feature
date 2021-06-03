Feature: CSI snapshot webhook related scenarios
  # @author wduan@redhat.com
  # @case_id OCP-37741
  @admin
  Scenario: [csi-snapshot-webhook] Should be installed by default and managed by CSO
    Given the master version >= "4.7"
    When I switch to cluster admin pseudo user
    And I use the "openshift-cluster-storage-operator" project
    Then a pod becomes ready with labels:
      | app=csi-snapshot-webhook |
    And evaluation of `pod.name` is stored in the :pod_name clipboard

    When I run the :delete client command with:
      | object_type       | deployment           |
      | object_name_or_id | csi-snapshot-webhook |
    And the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I wait for the resource "pod" named "<%= cb.pod_name %>" to disappear
    And a pod becomes ready with labels:
      | app=csi-snapshot-webhook |
    """

  # @author wduan@redhat.com
  # @case_id OCP-37742
  @admin
  Scenario: [csi-snapshot-webhook] Should support setting log level by csi-snapshot-controller operator
    Given the master version >= "4.7"
    When I switch to cluster admin pseudo user
    And I use the "openshift-cluster-storage-operator" project
    Then a pod becomes ready with labels:
      | app=csi-snapshot-webhook |
    # Default logLevel should be Normal (--v=2)
    And the expression should be true> deployment("csi-snapshot-webhook").containers_spec(cached: false).first.args.include?("--v=2")

    # Change the default logLevel to Normal in teardown step
    And I register clean-up steps:
    """
    Given I successfully merge patch resource "CSISnapshotController/cluster" with:
     | {"spec": {"logLevel": "Normal"}} |
    """
    
    When I successfully merge patch resource "CSISnapshotController/cluster" with:
      | {"spec": {"logLevel": "Debug"}} |
    And I wait for the steps to pass:
    """
    Then the expression should be true> deployment("csi-snapshot-webhook").containers_spec(cached: false).first.args.include?("--v=4")
    """

    When I successfully merge patch resource "CSISnapshotController/cluster" with:
      | {"spec": {"logLevel": "TraceAll"}} |
    And I wait for the steps to pass:
    """
    Then the expression should be true> deployment("csi-snapshot-webhook").containers_spec(cached: false).first.args.include?("--v=8")
    """
