Feature: CephFS storage plugin testing

  # @author jhou@redhat.com
  # @case_id OCP-9634
  @admin
  @destructive
  Scenario: Creating cephfs persistent volume with RWO accessmode and default policy
    # Prepare CephFS server
    Given I have a project
    And I have a CephFS pod in the project

    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-ceph/master/pv-rwo.json" where:
      | ["metadata"]["name"]              | pv-cephfs-server-<%= project.name %>            |
      | ["spec"]["cephfs"]["monitors"][0] | <%= pod("cephfs-server").ip(user: user) %>:6789 |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-ceph/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | pvc-cephfs-<%= project.name %>       |
      | ["spec"]["volumeName"] | pv-cephfs-server-<%= project.name %> |
    Then the step should succeed
    And the "pvc-cephfs-<%= project.name %>" PVC becomes bound to the "pv-cephfs-server-<%= project.name %>" PV

    # Create tester pod
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-ceph/master/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | cephfs-<%= project.name %>     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-cephfs-<%= project.name %> |
    Then the step should succeed
    And the pod named "cephfs-<%= project.name %>" becomes ready

    # Test creating files
    Given I execute on the "cephfs-<%= project.name %>" pod:
      | touch | /mnt/cephfs/cephfs_testfile |
    Then the step should succeed
    When I execute on the "cephfs-<%= project.name %>" pod:
      | ls | -l | /mnt/cephfs/cephfs_testfile |
    Then the step should succeed

  # @author jhou@redhat.com
  # @case_id 507222
  @admin
  Scenario: Create CephFS pod which reference the server directly from pod template
    # Prepare CephFS server
    Given I have a project
    And I have a CephFS pod in the project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-ceph/master/pod-direct.json" replacing paths:
      | ["spec"]["volumes"][0]["cephfs"]["monitors"][0] | <%= pod("cephfs-server").ip(user: user) %>:6789 |
    Then the step should succeed
    And the pod named "cephfs" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-17460
  @admin
  Scenario: Namespaced CephFS secrets
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project
    And I have a project

    Given admin creates a PV from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/cephfs/pv-retain.json" where:
      | ["metadata"]["name"]                         | pv-cephfs-server-<%= project.name %>                |
      | ["spec"]["cephfs"]["monitors"][0]            | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["spec"]["cephfs"]["secretRef"]["name"]      | cephrbd-secret                                      |
      | ["spec"]["cephfs"]["secretRef"]["namespace"] | default                                             |
    And I create a manual pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/cephfs/pvc-cephfs.json" replacing paths:
      | ["metadata"]["name"]   | pvc-cephfs-<%= project.name %>       |
      | ["spec"]["volumeName"] | pv-cephfs-server-<%= project.name %> |
    Then the step should succeed
    And the "pvc-cephfs-<%= project.name %>" PVC becomes bound to the "pv-cephfs-server-<%= project.name %>" PV

    # Create tester pod
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/cephfs/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | cephfs-<%= project.name %>     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-cephfs-<%= project.name %> |
    Then the step should succeed
    And the pod named "cephfs-<%= project.name %>" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18673
  @admin
  Scenario: CephFS dynamic provisioner
    Given I have a StorageClass named "cephfs"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project
    And I have a project

    # Verify dynamic provisioner
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/cephfs/dynamic-provisioning/cephfs_claim.yaml" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | cephfs                  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 60 seconds

    # Verify Pod works
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/cephfs/dynamic-provisioning/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | cephfs-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>    |
    Then the step should succeed
    And the pod named "cephfs-<%= project.name %>" becomes ready

    When I execute on the pod:
      | ls | -ld | /mnt/cephfs |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/cephfs/OCP-18673 |
    Then the step should succeed

    Given I ensure "cephfs-<%= project.name %>" pod is deleted
    And I ensure "pvc-<%= project.name %>" pvc is deleted
    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 120 seconds

