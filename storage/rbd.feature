Feature: Storage of Ceph plugin testing

  # @author wehe@redhat.com
  # @case_id OCP-9933
  @admin
  @destructive
  Scenario: Ceph persistent volume with invalid monitors
    Given I have a project

    #Create a invalid pv with rbd of wrong monitors
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/rbd/rbd-secret.yaml |
    Then the step should succeed
    Given I obtain test data file "storage/rbd/pv-retain.json"
    And I replace content in "pv-retain.json":
      | /\d{3}/ | 000 |
    When admin creates a PV from "pv-retain.json" where:
      | ["metadata"]["name"] | rbd-<%= project.name %> |
    Then the step should succeed

    #Create ceph pvc
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/rbd/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"] | rbdc |
    Then the step should succeed
    And the PV becomes :bound

    Given SCC "privileged" is added to the "default" user
    And SCC "privileged" is added to the "system:serviceaccounts" group

    #Create the pod
    And I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/rbd/pod.json |
    Then the step should succeed
    And I wait up to 500 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pods  |
      | name     | rbdpd |
    Then the output should contain:
      | Connection timed out |
    """

  # @author jhou@redhat.com
  # @case_id OCP-9701
  @admin
  Scenario: Ceph rbd security testing
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project

    Given I have a project

    And I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-rbd-<%= project.name %> |
      | ["spec"]["storageClassName"]                 | cephrbdprovisioner          |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                         |
    Then the step should succeed
    And the "pvc-rbd-<%= project.name %>" PVC becomes :bound within 120 seconds

    # Switch to admin to bypass scc
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/rbd/auto/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | rbd-<%= project.name %>     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-rbd-<%= project.name %> |
    Then the step should succeed
    And the pod named "rbd-<%= project.name %>" becomes ready

    # Verify uid and gid are correct
    When I execute on the "rbd-<%= project.name %>" pod:
      | id | -u |
    Then the output should contain:
      | 101010 |
    When I execute on the "rbd-<%= project.name %>" pod:
      | id | -G |
    Then the output should contain:
      | 123456 |

    # Verify mount directory has supplemental groups set properly
    # Verify SELinux context is set properly
    When I execute on the "rbd-<%= project.name %>" pod:
      | ls | -lZd | /mnt/rbd |
    Then the output should match:
      | 123456                                   |
      | (svirt_sandbox_file_t\|container_file_t) |
      | s0:c2,c13                                |

    # Verify created file belongs to supplemental group
    Given I execute on the "rbd-<%= project.name %>" pod:
      | touch | /mnt/rbd/rbd_testfile |
    When I execute on the "rbd-<%= project.name %>" pod:
      | ls | -l | /mnt/rbd/rbd_testfile |
    Then the output should contain:
      | 123456 |

    # Testing execute permission
    Given I execute on the "rbd-<%= project.name %>" pod:
      | cp | /hello | /mnt/rbd/hello |
    When I execute on the "rbd-<%= project.name %>" pod:
      | /mnt/rbd/hello |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift Storage |

  # @author jhou@redhat.com
  # @case_id OCP-9635
  @admin
  Scenario: Create Ceph rbd pod which reference the rbd server directly from pod template
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project

    Given I have a project

    And I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1               |
      | ["spec"]["storageClassName"]                 | cephrbdprovisioner |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound within 120 seconds

    # Copy secret to user namespace
    Given I run the :get admin command with:
      | resource      | secret         |
      | resource_name | cephrbd-secret |
      | namespace     | default        |
      | o             | yaml           |
    And evaluation of `@result[:parsed]["data"]["key"]` is stored in the :secret_key clipboard
    And I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/user_secret.yaml" replacing paths:
      | ["data"]["key"] | <%= cb.secret_key %> |
    Then the step should succeed

    Given I save volume id from PV named "<%= pvc('pvc1').volume_name %>" in the :image clipboard
    # Switch to admin to bypass scc
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/rbd/pod-inline.json" replacing paths:
      | ["spec"]["volumes"][0]["rbd"]["monitors"][0] | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["spec"]["volumes"][0]["rbd"]["image"]       | <%= cb.image %>                                     |
    Then the step should succeed
    And the pod named "rbd" becomes ready

  # @author lxia@redhat.com
  # @case_id OCP-9693
  @admin
  Scenario: [storage_201] Only one pod with rbd volume can be scheduled when NoDiskConflicts policy is enabled
    Given I have a StorageClass named "cephrbdprovisioner"
    And admin checks that the "cephrbd-secret" secret exists in the "default" project

    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>                   |
      | node_selector | <%= cb.proj_name %>=labelForTC510534  |
      | admin         | <%= user.name %>                      |
    Then the step should succeed

    Given I store the ready and schedulable nodes in the :nodes clipboard
    And label "<%= cb.proj_name %>=labelForTC510534" is added to the "<%= cb.nodes[0].name %>" node

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project

    And I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1               |
      | ["spec"]["storageClassName"]                 | cephrbdprovisioner |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound within 120 seconds

    # Copy secret to user namespace
    Given I run the :get admin command with:
      | resource      | secret         |
      | resource_name | cephrbd-secret |
      | namespace     | default        |
      | o             | yaml           |
    And evaluation of `@result[:parsed]["data"]["key"]` is stored in the :secret_key clipboard
    And I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/user_secret.yaml" replacing paths:
      | ["data"]["key"] | <%= cb.secret_key %> |
    Then the step should succeed

    Given I save volume id from PV named "<%= pvc('pvc1').volume_name %>" in the :image clipboard
    # Switch to admin to bypass scc
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project


    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/rbd/pod-inline.json" replacing paths:
      | ["metadata"]["name"]                         | rbd-pod1-<%= project.name %>                        |
      | ["spec"]["volumes"][0]["rbd"]["monitors"][0] | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["spec"]["volumes"][0]["rbd"]["image"]       | <%= cb.image %>                                     |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-rbd/master/pod-direct.json" replacing paths:
      | ["metadata"]["name"]                         | rbd-pod2-<%= project.name %>                        |
      | ["spec"]["volumes"][0]["rbd"]["monitors"][0] | <%= storage_class("cephrbdprovisioner").monitors %> |
      | ["spec"]["volumes"][0]["rbd"]["image"]       | <%= cb.image %>                                     |
    Then the step should succeed

    When I run the :describe client command with:
      | resource | pod                          |
      | name     | rbd-pod2-<%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | Pending          |
      | FailedScheduling |
      | NoDiskConflict   |

    When I get project events
    Then the step should succeed
    And the output should contain:
      | FailedScheduling |
      | NoDiskConflict   |
