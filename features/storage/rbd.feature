Feature: Storage of Ceph plugin testing

  # @author wehe@redhat.com
  # @case_id OCP-9933
  @admin
  @destructive
  Scenario: Ceph persistent volume with invalid monitors
    Given I have a project

    #Create a invalid pv with rbd of wrong monitors
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/rbd/rbd-secret.yaml |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/rbd/pv-retain.json"
    And I replace content in "pv-retain.json":
      | /\d{3}/ | 000 |
    When admin creates a PV from "pv-retain.json" where:
      | ["metadata"]["name"] | rbd-<%= project.name %> |
    Then the step should succeed

    #Create ceph pvc
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/rbd/pvc-rwo.json |
    Then the step should succeed
    And the PV becomes :bound

    Given SCC "privileged" is added to the "default" user
    And SCC "privileged" is added to the "system:serviceaccounts" group

    #Create the pod
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/rbd/pod.json |
    Then the step should succeed
    And I wait up to 500 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pods  |
      | name     | rbdpd |
    Then the output should contain:
      | FailedMount     |
      | rbd: map failed |
    """

  # @author jhou@redhat.com
  # @case_id OCP-9701
  @admin
  @destructive
  Scenario: Ceph rbd security testing
    # Prepare Ceph rbd server
    Given I have a project
    And I have a Ceph pod in the project

    # Prepare PV/PVC
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-rbd/master/pv-rwo.json" where:
      | ["metadata"]["name"]           | pv-rbd-server-<%= project.name %>            |
      | ["spec"]["rbd"]["monitors"][0] | <%= pod("rbd-server").ip(user: user) %>:6789 |
    And I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-rbd/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | pvc-rbd-<%= project.name %>       |
      | ["spec"]["volumeName"] | pv-rbd-server-<%= project.name %> |
    Then the step should succeed
    And the "pvc-rbd-<%= project.name %>" PVC becomes bound to the "pv-rbd-server-<%= project.name %>" PV

    # Create tester pod
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/rbd/auto/pod.json" replacing paths:
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
    Then the output should contain:
      | 123456               |
      | svirt_sandbox_file_t |
      | s0:c2,c13            |

    # Verify created file belongs to supplemental group
    Given I execute on the "rbd-<%= project.name %>" pod:
      | touch | /mnt/rbd/rbd_testfile |
    When I execute on the "rbd-<%= project.name %>" pod:
      | ls | -l | /mnt/rbd/rbd_testfile |
    Then the output should contain:
      | 123456 |

  # @author jhou@redhat.com
  # @case_id OCP-9635
  @admin
  @destructive
  Scenario: Create Ceph rbd pod which reference the rbd server directly from pod template
    Given I have a project
    And I have a Ceph pod in the project

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-rbd/master/pod-direct.json" replacing paths:
      | ["spec"]["volumes"][0]["rbd"]["monitors"][0] | <%= pod("rbd-server").ip(user: user) %>:6789 |
    Then the step should succeed
    And the pod named "rbd" becomes ready

  # @author lxia@redhat.com
  # @case_id OCP-9693
  @admin
  @destructive
  Scenario: [storage_201] Only one pod with rbd volume can be scheduled when NoDiskConflicts policy is enabled
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>                   |
      | node_selector | <%= cb.proj_name %>=labelForTC510534  |
      | admin         | <%= user.name %>                      |
    Then the step should succeed

    Given I store the schedulable nodes in the :nodes clipboard
    And label "<%= cb.proj_name %>=labelForTC510534" is added to the "<%= cb.nodes[0].name %>" node

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project
    And I have a Ceph pod in the project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-rbd/master/pod-direct.json" replacing paths:
      | ["metadata"]["name"]                         | rbd-pod1-<%= project.name %>                 |
      | ["spec"]["volumes"][0]["rbd"]["monitors"][0] | <%= pod("rbd-server").ip(user: user) %>:6789 |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-rbd/master/pod-direct.json" replacing paths:
      | ["metadata"]["name"]                         | rbd-pod2-<%= project.name %>                 |
      | ["spec"]["volumes"][0]["rbd"]["monitors"][0] | <%= pod("rbd-server").ip(user: user) %>:6789 |
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

  # @author jhou@redhat.com
  # @case_id OCP-10485
  @admin
  Scenario: Dynamically provision Ceph RBD volumes
    Given I have a StorageClass named "cephrbdprovisioner"
    # The "cephrbd-secret" is "default" namespace is used for volume provision
    And I run the :get admin command with:
      | resource      | secret         |
      | resource_name | cephrbd-secret |
      | namespace     | default        |
      | o             | yaml           |
    # The user secret is retrieved from "cephrbd-secret" for pod mounts
    And evaluation of `@result[:parsed]["data"]["key"]` is stored in the :secret_key clipboard

    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/rbd/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | cephrbdprovisioner      |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

    # Switch to admin so as to create pod with desired FSGroup and SElinux levels
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    And I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/rbd/dynamic-provisioning/user_secret.yaml" replacing paths:
      | ["data"]["key"] | <%= cb.secret_key %> |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/rbd/dynamic-provisioning/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the pod named "rbdpd" becomes ready

    # Test creating files
    When I execute on the pod:
      | ls | -lZd | /mnt/rbd/ |
    Then the output should contain:
      | 123456               |
      | svirt_sandbox_file_t |

    When I execute on the pod:
      | touch | /mnt/rbd/rbd_testfile |
    Then the step should succeed

    When I execute on the pod:
      | ls | -l | /mnt/rbd/rbd_testfile |
    Then the output should contain:
      | 123456 |

  # @author jhou@redhat.com
  # @case_id OCP-10268
  @admin
  Scenario: Dynamically provisioned rbd volumes should have correct capacity
    Given I have a StorageClass named "cephrbdprovisioner"
    # CephRBD provisioner needs secret, verify secret and StorageClass both exists
    Given I have a "secret" named "cephrbd-secret" in the "default" namespace
    And I have a project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/rbd/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | cephrbdprovisioner      |
      | ["spec"]["resources"]["requests"]["storage"]                           | 9Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

    And the expression should be true> pvc.capacity(user: user) == "9Gi"


  # @author jhou@redhat.com
  # @case_id OCP-10269
  @admin
  Scenario: Reclaim a dynamically provisioned Ceph RBD volumes
    Given I have a StorageClass named "cephrbdprovisioner"
    # CephRBD provisioner needs secret, verify secret and StorageClass both exists
    Given I have a "secret" named "cephrbd-secret" in the "default" namespace
    And I have a project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/rbd/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | cephrbdprovisioner      |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

    And the expression should be true> pv(pvc.volume_name(user: user)).reclaim_policy(user: admin) == "Delete"

    # Test auto deleting PV
    Given I run the :delete client command with:
      | object_type       | pvc                     |
      | object_name_or_id | pvc-<%= project.name %> |
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: user) %>" to disappear within 60 seconds
