Feature: Persistent Volume reclaim policy tests
  # @author jhou@redhat.com
  # @case_id 488979
  @admin
  @destructive
  Scenario: Recycle reclaim policy for persistent volumes
    # Preparations
    Given I have a project
    And I have a NFS service in the project
    # Creating PV and PVC
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv.json" where:
      | ["metadata"]["name"]                      | pv-nfs-<%= project.name %>       |
      | ["spec"]["nfs"]["server"]                 | <%= service("nfs-service").ip %> |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Recycle                          |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc.json" replacing paths:
      | ["metadata"]["name"]   | pvc-nfs-<%= project.name %> |
      | ["spec"]["volumeName"] | pv-nfs-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-nfs-<%= project.name %>" PVC becomes bound to the "pv-nfs-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-nfs-<%= project.name %>   |
      | ["metadata"]["name"]                                         | pod488979-<%= project.name %> |
    Then the step should succeed
    Given the pod named "pod488979-<%= project.name %>" becomes ready
    Given I ensure "pod488979-<%= project.name %>" pod is deleted
    And I ensure "pvc-nfs-<%= project.name %>" pvc is deleted
    And the PV becomes :available within 300 seconds

  # @author lxia@redhat.com
  # @case_id 508057 484930 530546
  @admin
  @destructive
  Scenario Outline: Persistent disk with RWO access mode and Default policy
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/<path_to_file>" where:
      | ["metadata"]["name"]                        | pv-<%= project.name %> |
      | ["spec"]["capacity"]["storage"]             | 1Gi                    |
      | ["spec"]["accessModes"][0]                  | ReadWriteOnce          |
      | ["spec"]["<storage_type>"]["<volume_name>"] | <%= cb.vid %>          |
      | ["spec"]["persistentVolumeReclaimPolicy"]   | Default                |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | pv-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt                    |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | touch | /mnt/testfile |
    Then the step should succeed

    Given I ensure "pod-<%= project.name %>" pod is deleted
    And I ensure "pvc-<%= project.name %>" pvc is deleted
    And the PV becomes :released

    Examples:
      | storage_type         | volume_name | path_to_file               |
      | gcePersistentDisk    | pdName      | gce/pv-default-rwo.json    |
      | awsElasticBlockStore | volumeID    | ebs/pv-rwo.yaml            |
      | cinder               | volumeID    | cinder/pv-rwx-default.json |

  # @author lxia@redhat.com
  # @case_id 522413 522393 522392
  @admin
  @destructive
  Scenario Outline: Persistent volume with RWO access mode and Delete policy
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard

    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/<path_to_file>" where:
      | ["metadata"]["name"]                        | pv-<%= project.name %> |
      | ["spec"]["capacity"]["storage"]             | 1Gi                    |
      | ["spec"]["accessModes"][0]                  | ReadWriteOnce          |
      | ["spec"]["<storage_type>"]["<volume_name>"] | <%= cb.vid %>          |
      | ["spec"]["persistentVolumeReclaimPolicy"]   | Delete                 |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | pv-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt                    |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | touch | /mnt/testfile |
    Then the step should succeed

    Given I ensure "pod-<%= project.name %>" pod is deleted
    And I ensure "pvc-<%= project.name %>" pvc is deleted
    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pv.name %>" to disappear within 1200 seconds

    Examples:
      | storage_type         | volume_name | path_to_file               |
      | gcePersistentDisk    | pdName      | gce/pv-default-rwo.json    |
      | awsElasticBlockStore | volumeID    | ebs/pv-rwo.yaml            |
      | cinder               | volumeID    | cinder/pv-rwx-default.json |
