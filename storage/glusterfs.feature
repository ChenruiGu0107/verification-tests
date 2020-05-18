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
