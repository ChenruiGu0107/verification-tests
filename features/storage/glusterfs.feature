Feature: Storage of GlusterFS plugin testing

  # @author wehe@redhat.com
  # @case_id 522140
  @admin
  @destructive
  Scenario: Gluster storage testing with Invalid gluster endpoint
    Given I have a project

    #Create a invalid endpoint
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/endpoints.json"
    And I replace content in "endpoints.json":
      | /\d{2}/ | 11 |
    And I run the :create client command with:
      | f | endpoints.json |
    Then the step should succeed
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/pv-retain-rwo.json" where:
      | ["metadata"]["name"] | gluster-<%= project.name %> |
    Then the step should succeed

    #Create gluster pvc
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/claim-rwo.json |
    Then the step should succeed
    And the PV becomes :bound

    #Create the pod
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/pod.json |
    Then the step should succeed
    And I wait up to 500 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pods    |
      | name     | gluster |
    Then the output should contain:
      | FailedMount             |
      | glusterfs: mount failed |
    """

  # @author lxia@redhat.com
  # @case_id 508054
  @admin
  @destructive
  Scenario: GlusterFS volume plugin with RWO access mode and Retain policy
    Given I have a project
    And I have a Gluster service in the project
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I execute on the pod:
      | chmod | g+w | /vol |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/endpoints.json" replacing paths:
      | ["metadata"]["name"]                 | glusterfs-cluster             |
      | ["subsets"][0]["addresses"][0]["ip"] | <%= service("glusterd").ip %> |
      | ["subsets"][0]["ports"][0]["port"]   | 24007                         |
    Then the step should succeed
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/pv-retain-rwo.json" where:
      | ["metadata"]["name"]                      | pv-gluster-<%= project.name %> |
      | ["spec"]["accessModes"][0]                | ReadWriteOnce                  |
      | ["spec"]["glusterfs"]["endpoints"]        | glusterfs-cluster              |
      | ["spec"]["glusterfs"]["path"]             | testvol                        |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                         |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]       | pvc-gluster-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteOnce                   |
      | ["spec"]["volumeName"]     | pv-gluster-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-gluster-<%= project.name %>" PVC becomes bound to the "pv-gluster-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod-<%= project.name %>        |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-gluster-<%= project.name %>  |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | ls | -ld | /mnt/gluster |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/gluster/tc508054 |
    Then the step should succeed

    Given I ensure "mypod-<%= project.name %>" pod is deleted
    And I ensure "pvc-gluster-<%= project.name %>" pvc is deleted
    And the PV becomes :released
    When I execute on the "glusterd" pod:
      | ls | /vol/tc508054 |
    Then the step should succeed
    And the PV becomes :released

  # @author chaoyang@redhat.com
  # @case_id 510730
  @admin
  @destructive
  Scenario: Glusterfs volume security testing
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    Given I have a Gluster service in the project
    When I execute on the pod:
      | chown | -R | root:123456 | /vol |
    Then the step should succeed
    And I execute on the pod:
      | chmod | -R | 770 | /vol |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/endpoints.json" replacing paths:
      | ["metadata"]["name"]                 | glusterfs-cluster             |
      | ["subsets"][0]["addresses"][0]["ip"] | <%= service("glusterd").ip %> |
      | ["subsets"][0]["ports"][0]["port"]   | 24007                         |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/security/gluster_pod_sg.json" replacing paths:
      | ["metadata"]["name"] | glusterpd-<%= project.name %> |
    Then the step should succeed

    Given the pod named "glusterpd-<%= project.name %>" becomes ready
    And I execute on the "glusterpd-<%= project.name %>" pod:
      | ls | /mnt/glusterfs |
    Then the step should succeed

    And I execute on the "glusterpd-<%= project.name %>" pod:
      | touch | /mnt/glusterfs/gluster_testfile |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/security/gluster_pod_sg.json" replacing paths:
      | ["metadata"]["name"]                              | glusterpd-negative-<%= project.name %> |
      | ["spec"]["securityContext"]["supplementalGroups"] | [123460]                               |
    Then the step should succeed
    Given the pod named "glusterpd-negative-<%= project.name %>" becomes ready
    And I execute on the "glusterpd-negative-<%= project.name %>" pod:
      | ls | /mnt/glusterfs |
    Then the step should fail
    Then the outputs should contain:
      | Permission denied  |

    And I execute on the "glusterpd-negative-<%= project.name %>" pod:
      | touch | /mnt/glusterfs/gluster_testfile |
    Then the step should fail
    Then the outputs should contain:
      | Permission denied  |

  # @author jhou@redhat.com
  # @case_id 484932
  @admin
  @destructive
  Scenario: Pod references GlusterFS volume directly from its template
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    And I have a Gluster service in the project

    # Create endpoint
    And I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-gluster/master/endpoints.json" replacing paths:
      | ["subsets"][0]["addresses"][0]["ip"] | <%= service("glusterd").ip %> |

    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/docker-gluster/master/pod-direct.json |
    Then the step should succeed
    And the pod named "gluster" becomes ready

  # @author jhou@redhat.com
  # @case_id 534847
  @admin
  Scenario: Dynamically provision a GlusterFS volume
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1               |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | glusterprovisioner |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name(user: admin) %>" pv is deleted after scenario

    # Switch to admin so as to create privileged pod
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc1 |
    Then the step should succeed
    And the pod named "gluster" status becomes :running

    # Test creating files
    When I execute on the "gluster" pod:
      | touch | /mnt/gluster/gluster_testfile |
    Then the step should succeed
    When I execute on the "gluster" pod:
      | ls | /mnt/gluster/ |
    Then the output should contain:
      | gluster_testfile |

  # @author jhou@redhat.com
  # @case_id 534844
  @admin
  Scenario: Dynamically provisioned GlusterFS volume should have correct capacity
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1               |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | glusterprovisioner |
      | ["spec"]["resources"]["requests"]["storage"]                           | 15Gi               |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name(user: admin) %>" pv is deleted after scenario

    And the expression should be true> pvc.capacity(user: user) == "15Gi"

  # @author jhou@redhat.com
  # @case_id 534845
  @admin
  Scenario: Reclaim a provisioned GlusterFS volume
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | glusterprovisioner      |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

    And the expression should be true> pv(pvc.volume_name(user: user)).reclaim_policy(user: admin) == "Delete"

    # Test auto deleting PV
    Given I run the :delete client command with:
      | object_type       | pvc                     |
      | object_name_or_id | pvc-<%= project.name %> |
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: admin, cached: true) %>" to disappear within 60 seconds

  # @author jhou@redhat.com
  # @case_id 535784
  @admin
  Scenario: Dynamically provision a GlusterFS volume using heketi secret
    # A StorageClass preconfigured on the test env
    Given I have a StorageClass named "glusterprovisioner1"
    Given I have a "secret" named "heketi-secret" in the "default" namespace
    And I have a project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1                |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | glusterprovisioner1 |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name(user: admin) %>" pv is deleted after scenario

    # Switch to admin so as to create privileged pod
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc1 |
    Then the step should succeed
    And the pod named "gluster" status becomes :running


  # @author jhou@redhat.com
  # @case_id 535055
  @admin
  Scenario: Endpoint and service are created/deleted by dynamic provisioner
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1               |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | glusterprovisioner |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name(user: admin) %>" pv is deleted after scenario

    When I run the :get client command with:
      | resource      | endpoints              |
      | resource_name | glusterfs-dynamic-pvc1 |
    Then the step should succeed

    When I run the :get client command with:
      | resource      | services               |
      | resource_name | glusterfs-dynamic-pvc1 |
    Then the step should succeed

  # @author jhou@redhat.com
  # @case_id 535758
  @admin
  Scenario: Should throw meaningful message when deleting a PVC having StorageClass already deleted
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project
    And I run the :get admin command with:
      | resource      | storageclass       |
      | resource_name | glusterprovisioner |
      | o             | yaml               |
    And evaluation of `@result[:parsed]["parameters"]["resturl"]` is stored in the :heketi_url clipboard

    # Create a tmp storageclass using the url
    Given admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/storageclass_using_key.yaml" where:
      | ["metadata"]["name"]      | storageclass-<%= project.name %> |
      | ["parameters"]["resturl"] | <%= cb.heketi_url %>             |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %>          |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | storageclass-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And admin ensures "<%= pvc.volume_name(user: admin) %>" pv is deleted after scenario

    # Delete StorageClass then delete pvc
    Given I run the :delete admin command with:
      | object_type       | storageclass                     |
      | object_name_or_id | storageclass-<%= project.name %> |
    And I run the :delete client command with:
      | object_type       | pvc                     |
      | object_name_or_id | pvc-<%= project.name %> |
    When I run the :get admin command with:
      | resource      | pv                                  |
      | resource_name | <%= pvc.volume_name(user: admin) %> |
    Then the output should contain:
      | Failed |
    When I run the :describe admin command with:
      | resource | pv                                  |
      | name     | <%= pvc.volume_name(user: admin) %> |
    Then the output should contain:
      | VolumeFailedDelete                          |
      | "storageclass-<%= project.name%>" not found |

  # @author jhou@redhat.com
  # @case_id 544344
  @admin
  Scenario: Using invalid gidMax/gidMin in the StorageClass
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    # Create a StorageCLass for GlusterFS provisioner where gidMin > gidMax
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/storageclass_using_key.yaml" where:
      | ["metadata"]["name"]      | storageclass-<%= project.name %>                                 |
      | ["parameters"]["resturl"] | <%= storage_class("glusterprovisioner").rest_url(user: admin) %> |
      | ["parameters"]["gidMin"]  | 2001                                                             |
      | ["parameters"]["gidMax"]  | 2000                                                             |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %>          |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | storageclass-<%= project.name %> |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc                     |
      | name     | pvc-<%= project.name %> |
    Then the output should contain:
      | Pending                          |
      | Failed to provision              |
      | must have gidMax value >= gidMin |
    """

    # Create a StorageCLass for GlusterFS provisioner where gidMin/gidMax has negative values
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/storageclass_using_key.yaml" where:
      | ["metadata"]["name"]      | storageclass-neg-<%= project.name %>                             |
      | ["parameters"]["resturl"] | <%= storage_class("glusterprovisioner").rest_url(user: admin) %> |
      | ["parameters"]["gidMin"]  | -10000                                                           |
      | ["parameters"]["gidMax"]  | -1000                                                            |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-neg-<%= project.name %>          |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | storageclass-neg-<%= project.name %> |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc                         |
      | name     | pvc-neg-<%= project.name %> |
    Then the output should contain:
      | Pending       |
      | invalid value |
    """

  # @author jhou@redhat.com
  # @case_id 544937
  @admin
  Scenario: Pods should be assigned a valid GID using GlusterFS dynamic provisioner
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/storageclass_using_key.yaml" where:
      | ["metadata"]["name"]      | storageclass-<%= project.name %>                                 |
      | ["parameters"]["resturl"] | <%= storage_class("glusterprovisioner").rest_url(user: admin) %> |
      | ["parameters"]["gidMin"]  | 3333                                                             |
      | ["parameters"]["gidMax"]  | 33333                                                            |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1                             |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | storageclass-<%= project.name %> |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name(user: admin) %>" pv is deleted after scenario

    # Verify PV is annotated with inhitial gidMin 3333
    When I run the :get admin command with:
      | resource      | pv                                 |
      | resource_name | <%= pvc.volume_name(user: user) %> |
      | o             | yaml                               |
    Then the output should contain:
      | pv.beta.kubernetes.io/gid: "3333" |

    # Verify Pod is assigned gid 3333
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/pod_gid.json" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc1                    |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | id | -G |
    Then the output should contain:
      | 3333 |
    When I execute on the pod:
      | ls | -ld | /mnt/gluster |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/gluster/tc508054 |
    Then the step should succeed

    # Pod should work as well having its supplementalGroups set to 3333 explicitly
    Given I ensure "pod-<%= project.name %>" pod is deleted
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/pod_gid.json" replacing paths:
      | ["metadata"]["name"]                                         | pod1-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc1                     |
      | ["spec"]["securityContext"]["supplementalGroups"]            | [3333]                   |
    Then the step should succeed
    Given the pod named "pod1-<%= project.name %>" becomes ready
    When I execute on the pod:
      | id | -G |
    Then the output should contain:
      | 3333 |
    When I execute on the pod:
      | ls | -ld | /mnt/gluster |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/gluster/tc508054 |
    Then the step should succeed

  # @author jhou@redhat.com
  # @case_id OCP-12007
  @admin
  Scenario: Using default value for gid
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/storageclass_using_key.yaml" where:
      | ["metadata"]["name"]      | storageclass-<%= project.name %>                                 |
      | ["parameters"]["resturl"] | <%= storage_class("glusterprovisioner").rest_url(user: admin) %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1                             |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | storageclass-<%= project.name %> |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name(user: admin) %>" pv is deleted after scenario

    # Verify PV is annotated with inhitial gidMin 3333
    When I run the :get admin command with:
      | resource      | pv                                 |
      | resource_name | <%= pvc.volume_name(user: user) %> |
      | o             | yaml                               |
    Then the output should contain:
      | pv.beta.kubernetes.io/gid: "2000" |


  # @author jhou@redhat.com
  # @case_id 544341
  @admin
  Scenario: Dynamic provisioner should not provision PV/volume with duplicate gid
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/storageclass_using_key.yaml" where:
      | ["metadata"]["name"]      | storageclass-<%= project.name %>                                 |
      | ["parameters"]["resturl"] | <%= storage_class("glusterprovisioner").rest_url(user: admin) %> |
      | ["parameters"]["gidMin"]  | 5555                                                             |
      | ["parameters"]["gidMax"]  | 5555                                                             |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1                             |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | storageclass-<%= project.name %> |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name(user: admin) %>" pv is deleted after scenario

    # The 2nd PVC can't provision any because GID range is full
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc2                             |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | storageclass-<%= project.name %> |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc  |
      | name     | pvc2 |
    Then the output should contain:
      | Pending                                      |
      | failed to reserve gid from table: range full |
    """

    # Verify the queued pending PVC could provision when the GID is released
    Given I ensure "pvc1" pvc is deleted
    And I wait up to 60 seconds for the steps to pass:
    """
    And the "pvc2" PVC becomes :bound
    """
    And admin ensures "<%= pvc('pvc2').volume_name(user: admin) %>" pv is deleted after scenario

  # @author jhou@redhat.com
  # @case_id OCP-12943
  @admin
  Scenario: Setting volume type to create dispersed GlusterFS volumes
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/storageclass_volumetype_disperse.yaml" where:
      | ["metadata"]["name"]          | storageclass-<%= project.name %>                                 |
      | ["parameters"]["resturl"]     | <%= storage_class("glusterprovisioner").rest_url(user: admin) %> |
      | ["parameters"]["restuser"]    | admin                                                            |
      | ["parameters"]["restuserkey"] | test                                                             |
      | ["parameters"]["volumetype"]  | disperse:4:2                                                     |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1                             |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | storageclass-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"]                           | 16Gi                             |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name(user: admin) %>" pv is deleted after scenario

    Given I save volume id from PV named "<%= pvc('pvc1').volume_name(user: admin, cached: true) %>" in the :volumeID clipboard
    And I run commands on the StorageClass "glusterprovisioner" backing host:
      | heketi-cli --server http://127.0.0.1:9991 --user admin --secret test volume info <%= cb.volumeID %> |
    Then the output should contain:
      | Durability Type: disperse |
      | Disperse Data: 4          |
      | Disperse Redundancy: 2    |

  # @author jhou@redhat.com
  # @case_id OCP-12942
  @admin
  Scenario: Setting volume type to none in the StorageClass for GlusterFS dynamic provisioner
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/storageclass_volumetype_none.yaml" where:
      | ["metadata"]["name"]          | storageclass-<%= project.name %>                                 |
      | ["parameters"]["resturl"]     | <%= storage_class("glusterprovisioner").rest_url(user: admin) %> |
      | ["parameters"]["restuser"]    | admin                                                            |
      | ["parameters"]["restuserkey"] | test                                                             |
      | ["parameters"]["volumetype"]  | none                                                             |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1                             |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | storageclass-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"]                           | 10Gi                             |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name(user: admin) %>" pv is deleted after scenario

    Given I save volume id from PV named "<%= pvc('pvc1').volume_name(user: admin, cached: true) %>" in the :volumeID clipboard
    And I run commands on the StorageClass "glusterprovisioner" backing host:
      | heketi-cli --server http://127.0.0.1:9991 --user admin --secret test volume info <%= cb.volumeID %> |
    Then the output should contain:
      | Durability Type: none |

  # @author jhou@redhat.com
  # @case_id OCP-12940
  @admin
  Scenario: Setting replica count in the StorageClass for GlusterFS dynamic provisioner
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    # Setting replica to 2
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/storageclass_volumetype.yaml" where:
      | ["metadata"]["name"]          | storageclass-<%= project.name %>                                 |
      | ["parameters"]["resturl"]     | <%= storage_class("glusterprovisioner").rest_url(user: admin) %> |
      | ["parameters"]["restuser"]    | admin                                                            |
      | ["parameters"]["restuserkey"] | test                                                             |
      | ["parameters"]["volumetype"]  | replicate:2                                                      |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1                             |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | storageclass-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"]                           | 10Gi                             |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name(user: admin) %>" pv is deleted after scenario

    Given I save volume id from PV named "<%= pvc('pvc1').volume_name(user: admin, cached: true) %>" in the :volumeID clipboard
    And I run commands on the StorageClass "glusterprovisioner" backing host:
      | heketi-cli --server http://127.0.0.1:9991 --user admin --secret test volume info <%= cb.volumeID %> |
    Then the output should contain:
      | Durability Type: replicate |
      | Distributed+Replica: 2     |

    # Setting replica to 0
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/storageclass_volumetype.yaml" where:
      | ["metadata"]["name"]          | storageclass1-<%= project.name %>                                |
      | ["parameters"]["resturl"]     | <%= storage_class("glusterprovisioner").rest_url(user: admin) %> |
      | ["parameters"]["restuser"]    | admin                                                            |
      | ["parameters"]["restuserkey"] | test                                                             |
      | ["parameters"]["volumetype"]  | replicate:0                                                      |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc2                              |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | storageclass1-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"]                           | 10Gi                              |
    Then the step should succeed
    And the "pvc2" PVC becomes :bound
    And admin ensures "<%= pvc('pvc2').volume_name(user: admin) %>" pv is deleted after scenario

    Given I save volume id from PV named "<%= pvc('pvc2').volume_name(user: admin, cached: true) %>" in the :volumeID clipboard
    And I run commands on the StorageClass "glusterprovisioner" backing host:
      | heketi-cli --server http://127.0.0.1:9991 --user admin --secret test volume info <%= cb.volumeID %> |
    Then the output should contain:
      | Durability Type: replicate |
      | Distributed+Replica: 0     |

  # @author jhou@redhat.com
  # @case_id OCP-10354
  @admin
  Scenario: Provisioned GlusterFS volume should be replicated with 3 replicas
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1               |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | glusterprovisioner |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name(user: admin) %>" pv is deleted after scenario

    # Verify by default it's replicated with 3 replicas
    Given I save volume id from PV named "<%= pvc('pvc1').volume_name(user: admin, cached: true) %>" in the :volumeID clipboard
    And I run commands on the StorageClass "glusterprovisioner" backing host:
      | heketi-cli --server http://127.0.0.1:9991 --user admin --secret test volume info <%= cb.volumeID %> |
    Then the output should contain:
      | Durability Type: replicate |
      | Distributed+Replica: 3     |
