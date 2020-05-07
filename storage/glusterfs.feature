Feature: Storage of GlusterFS plugin testing

  # @author wehe@redhat.com
  # @case_id OCP-9932
  @admin
  @destructive
  Scenario: Gluster storage testing with Invalid gluster endpoint
    Given I have a project

    #Create a invalid endpoint
    And I obtain test data file "storage/gluster/endpoints.json"
    And I replace content in "endpoints.json":
      | /\d{2}/ | 11 |
    And I run the :create client command with:
      | f | endpoints.json |
    Then the step should succeed
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pv-retain-rwo.json" where:
      | ["metadata"]["name"] | gluster-<%= project.name %> |
    Then the step should succeed

    #Create gluster pvc
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/claim-rwo.json" replacing paths:
      | ["metadata"]["name"] | glusterc |
    Then the step should succeed
    And the PV becomes :bound

    #Create the pod
    And I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pod.json |
    Then the step should succeed
    And I wait up to 500 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pods    |
      | name     | gluster |
    Then the output should contain:
      | FailedMount  |
      | mount failed |
    """

  # @author lxia@redhat.com
  # @case_id OCP-12654
  @admin
  @destructive
  Scenario: GlusterFS volume plugin with RWO access mode and Retain policy
    Given I have a project
    And I have a Gluster service in the project
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I execute on the "glusterd" pod:
      | chmod | g+w | /vol |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/endpoints.json" replacing paths:
      | ["metadata"]["name"]                 | glusterfs-cluster             |
      | ["subsets"][0]["addresses"][0]["ip"] | <%= service("glusterd").ip %> |
      | ["subsets"][0]["ports"][0]["port"]   | 24007                         |
    Then the step should succeed
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pv-retain-rwo.json" where:
      | ["metadata"]["name"]                      | pv-gluster-<%= project.name %> |
      | ["spec"]["accessModes"][0]                | ReadWriteOnce                  |
      | ["spec"]["glusterfs"]["endpoints"]        | glusterfs-cluster              |
      | ["spec"]["glusterfs"]["path"]             | testvol                        |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                         |
    Then the step should succeed
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]       | pvc-gluster-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteOnce                   |
      | ["spec"]["volumeName"]     | pv-gluster-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-gluster-<%= project.name %>" PVC becomes bound to the "pv-gluster-<%= project.name %>" PV

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pod.json" replacing paths:
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

  # @author jhou@redhat.com
  # @case_id OCP-12109
  @admin
  Scenario: Using invalid gidMax/gidMin in the StorageClass
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    # Create a StorageCLass for GlusterFS provisioner where gidMin > gidMax
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/storageclass_using_key.yaml" where:
      | ["metadata"]["name"]      | storageclass-<%= project.name %>                                 |
      | ["parameters"]["resturl"] | <%= storage_class("glusterprovisioner").rest_url %> |
      | ["parameters"]["gidMin"]  | 2001                                                             |
      | ["parameters"]["gidMax"]  | 2000                                                             |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %>          |
      | ["spec"]["storageClassName"] | storageclass-<%= project.name %> |
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
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/storageclass_using_key.yaml" where:
      | ["metadata"]["name"]      | storageclass-neg-<%= project.name %>                             |
      | ["parameters"]["resturl"] | <%= storage_class("glusterprovisioner").rest_url %> |
      | ["parameters"]["gidMin"]  | -10000                                                           |
      | ["parameters"]["gidMax"]  | -1000                                                            |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]         | pvc-neg-<%= project.name %>          |
      | ["spec"]["storageClassName"] | storageclass-neg-<%= project.name %> |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc                         |
      | name     | pvc-neg-<%= project.name %> |
    Then the output should match:
      | invalid( (gidMin\|gidMax))? value |
    """
    And the "pvc-neg-<%= project.name %>" PVC status is :pending

  # @author jhou@redhat.com
  # @case_id OCP-12007
  @admin
  Scenario: Using default value for gid
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/storageclass_using_key.yaml" where:
      | ["metadata"]["name"]      | storageclass-<%= project.name %>                                 |
      | ["parameters"]["resturl"] | <%= storage_class("glusterprovisioner").rest_url %> |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]         | pvc1                             |
      | ["spec"]["storageClassName"] | storageclass-<%= project.name %> |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name %>" pv is deleted after scenario

    # Verify PV is annotated with inhitial gidMin 3333
    When I run the :get admin command with:
      | resource      | pv                                 |
      | resource_name | <%= pvc.volume_name %> |
      | o             | yaml                               |
    Then the output should contain:
      | pv.beta.kubernetes.io/gid: "2000" |


  # @author jhou@redhat.com
  # @case_id OCP-12943
  @admin
  Scenario: Setting volume type to create dispersed GlusterFS volumes
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/storageclass_volumetype_disperse.yaml" where:
      | ["metadata"]["name"]          | storageclass-<%= project.name %>                                 |
      | ["parameters"]["resturl"]     | <%= storage_class("glusterprovisioner").rest_url %> |
      | ["parameters"]["restuser"]    | admin                                                            |
      | ["parameters"]["restuserkey"] | test                                                             |
      | ["parameters"]["volumetype"]  | disperse:4:2                                                     |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                         | pvc1                             |
      | ["spec"]["storageClassName"]                 | storageclass-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 16Gi                             |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name %>" pv is deleted after scenario

    Given I save volume id from PV named "<%= pvc('pvc1').volume_name %>" in the :volumeID clipboard
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

    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/storageclass_volumetype_none.yaml" where:
      | ["metadata"]["name"]          | storageclass-<%= project.name %>                                 |
      | ["parameters"]["resturl"]     | <%= storage_class("glusterprovisioner").rest_url %> |
      | ["parameters"]["restuser"]    | admin                                                            |
      | ["parameters"]["restuserkey"] | test                                                             |
      | ["parameters"]["volumetype"]  | none                                                             |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                         | pvc1                             |
      | ["spec"]["storageClassName"]                 | storageclass-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 10Gi                             |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name %>" pv is deleted after scenario

    Given I save volume id from PV named "<%= pvc('pvc1').volume_name %>" in the :volumeID clipboard
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
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/storageclass_volumetype.yaml" where:
      | ["metadata"]["name"]          | storageclass-<%= project.name %>                                 |
      | ["parameters"]["resturl"]     | <%= storage_class("glusterprovisioner").rest_url %> |
      | ["parameters"]["restuser"]    | admin                                                            |
      | ["parameters"]["restuserkey"] | test                                                             |
      | ["parameters"]["volumetype"]  | replicate:2                                                      |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                         | pvc1                             |
      | ["spec"]["storageClassName"]                 | storageclass-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 10Gi                             |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc('pvc1').volume_name %>" pv is deleted after scenario

    Given I save volume id from PV named "<%= pvc('pvc1').volume_name %>" in the :volumeID clipboard
    And I run commands on the StorageClass "glusterprovisioner" backing host:
      | heketi-cli --server http://127.0.0.1:9991 --user admin --secret test volume info <%= cb.volumeID %> |
    Then the output should contain:
      | Durability Type: replicate |
      | Distributed+Replica: 2     |

    # Setting replica to 0
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/storageclass_volumetype.yaml" where:
      | ["metadata"]["name"]          | storageclass1-<%= project.name %>                                |
      | ["parameters"]["resturl"]     | <%= storage_class("glusterprovisioner").rest_url %> |
      | ["parameters"]["restuser"]    | admin                                                            |
      | ["parameters"]["restuserkey"] | test                                                             |
      | ["parameters"]["volumetype"]  | replicate:0                                                      |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                         | pvc2                              |
      | ["spec"]["storageClassName"]                 | storageclass1-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 10Gi                              |
    Then the step should succeed
    And the "pvc2" PVC becomes :bound
    And admin ensures "<%= pvc('pvc2').volume_name %>" pv is deleted after scenario

    Given I save volume id from PV named "<%= pvc('pvc2').volume_name %>" in the :volumeID clipboard
    And I run commands on the StorageClass "glusterprovisioner" backing host:
      | heketi-cli --server http://127.0.0.1:9991 --user admin --secret test volume info <%= cb.volumeID %> |
    Then the output should contain:
      | Durability Type: replicate |
      | Distributed+Replica: 0     |

  # @author lizhou@redhat.com
  # @case_id OCP-13580
  @admin
  Scenario: pods should be able to delete after storage endpoints were down
    Given admin creates a project with a random schedulable node selector
    And I have a Gluster service in the project

    # Create endpoints
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-gluster/master/endpoints.json" replacing paths:
      | ["metadata"]["name"]                 | glusterfs-cluster             |
      | ["subsets"][0]["addresses"][0]["ip"] | <%= service("glusterd").ip %> |
      | ["subsets"][0]["ports"][0]["port"]   | 24007                         |
    Then the step should succeed

    # Create gluster pv
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-gluster/master/pv-rwo.json" where:
      | ["metadata"]["name"]                      | pv-gluster-<%= project.name %> |
      | ["spec"]["accessModes"][0]                | ReadWriteOnce                  |
      | ["spec"]["glusterfs"]["endpoints"]        | glusterfs-cluster              |
      | ["spec"]["glusterfs"]["path"]             | testvol                        |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                         |
    Then the step should succeed

    # Create gluster pvc
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-gluster/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]       | pvc-gluster-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteOnce                   |
      | ["spec"]["volumeName"]     | pv-gluster-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-gluster-<%= project.name %>" PVC becomes bound to the "pv-gluster-<%= project.name %>" PV

    # Create pod
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/docker-gluster/master/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | glusterpd-<%= project.name %>   |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-gluster-<%= project.name %> |
    Then the step should succeed
    Given the pod named "glusterpd-<%= project.name %>" becomes ready

    # Check mount point on node
    Given I use the "<%= node.name %>" node
    When I run commands on the host:
      | mount |
    Then the output should contain:
      | testvol |

    # Delete endpoints
    When I run the :delete client command with:
      | object_type       | endpoints         |
      | object_name_or_id | glusterfs-cluster |
    Then the step should succeed

    # Delete pod
    When I run the :delete client command with:
      | object_type       | pods                          |
      | object_name_or_id | glusterpd-<%= project.name %> |
    Then the step should succeed

    # Check mount point on node
    Given I use the "<%= node.name %>" node
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run commands on the host:
      | mount |
    Then the output should not contain:
      | testvol |
    """

  # @author jhou@redhat.com
  # @case_id OCP-13469
  @admin
  Scenario: Setting GlusterFS read only mount option in PV annotation
    Given I have a project
    And I have a Gluster service in the project
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I execute on the "glusterd" pod:
      | chmod | g+w | /vol |
    Then the step should succeed

    # Prepare service for endpoints
    Given I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/service-endpoints.yaml |
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/endpoints.json" replacing paths:
      | ["metadata"]["name"]                 | glusterfs-cluster             |
      | ["subsets"][0]["addresses"][0]["ip"] | <%= service("glusterd").ip %> |
      | ["subsets"][0]["ports"][0]["port"]   | 24007                         |
    Then the step should succeed
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pv-mount-options.json" where:
      | ["metadata"]["name"]                                                   | pv-gluster-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/mount-options"] | ro                             |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce                  |
      | ["spec"]["glusterfs"]["endpoints"]                                     | glusterfs-cluster              |
      | ["spec"]["glusterfs"]["path"]                                          | testvol                        |
      | ["spec"]["persistentVolumeReclaimPolicy"]                              | Retain                         |
    Then the step should succeed
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]       | pvc-gluster-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadWriteOnce                   |
      | ["spec"]["volumeName"]     | pv-gluster-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-gluster-<%= project.name %>" PVC becomes bound to the "pv-gluster-<%= project.name %>" PV

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod-<%= project.name %>        |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-gluster-<%= project.name %>  |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | ls | -ld | /mnt/gluster |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/gluster/OCP-13469 |
    Then the step should fail
    And the output should contain:
      | Read-only file system |

  # @author jhou@redhat.com
  # @case_id OCP-17277
  @admin
  Scenario: Configure 'Retain' reclaim policy for GlusterFS
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/storageclass_retain.yaml" where:
      | ["metadata"]["name"]      | sc-<%= project.name %>                                           |
      | ["parameters"]["resturl"] | <%= storage_class("glusterprovisioner").rest_url %> |
      | ["reclaimPolicy"]         | Retain                                                           |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1                       |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds
    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Retain"

    When I ensure "pvc-<%= project.name %>" pvc is deleted
    Given I run the :get admin command with:
      | resource      | pv             |
      | resource_name | <%= pv.name %> |
    Then the output should contain:
      | Released |
    And admin ensures "<%= pv.name %>" pv is deleted

  # @author jhou@redhat.com
  # @case_id OCP-17262
  @admin
  Scenario: Using mountOptions for GlusterFS StorageClass
    Given I have a StorageClass named "glusterprovisioner"

    And I have a project

    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/dynamic-provisioning/storageclass_mount_options.yaml" where:
      | ["metadata"]["name"]      | sc-<%= project.name %>                              |
      | ["parameters"]["resturl"] | <%= storage_class("glusterprovisioner").rest_url %> |
      | ["mountOptions"][0]       | ro                                                  |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/rbd/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1                       |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | grep | glusterfs | /etc/mtab | /proc/mounts |
    Then the output should contain:
      | ro |
    Given I ensure "pod-<%= project.name %>" pod is deleted
    And I ensure "pvc-<%= project.name %>" pvc is deleted

  # @author jhou@redhat.com
  # @case_id OCP-19194
  @admin
  Scenario: Can not dynamically provision a GlusterFS volume with block volumeMode
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1               |
      | ["spec"]["storageClassName"]                 | glusterprovisioner |
      | ["spec"]["volumeMode"]                       | Block              |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                |
    Then the step should succeed

    When I run the :describe client command with:
      | resource | pvc  |
      | name     | pvc1 |
    Then the output should contain:
      | kubernetes.io/glusterfs                    |
      | does not support block volume provisioning |
