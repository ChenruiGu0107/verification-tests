Feature: CephFS storage plugin testing

  # @author jhou@redhat.com
  # @case_id 507218
  @admin
  @destructive
  Scenario: Creating cephfs persistant volume with RWO accessmode and default policy
    # Prepare CephFS server
    Given I have a project
    And I have a CephFS pod in the project

    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-ceph/master/pv-rwo.json" where:
      | ["metadata"]["name"]              | pv-cephfs-server-<%= project.name %>            |
      | ["spec"]["cephfs"]["monitors"][0] | <%= pod("cephfs-server").ip(user: user) %>:6789 |
    And I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-ceph/master/pvc-rwo.json" replacing paths:
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
