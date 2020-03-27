Feature: GCE specific scenarios
  # @author lxia@redhat.com
  # @case_id OCP-15528
  @admin
  Scenario: Dynamic provision with storageclass which has zones set to empty string
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"]   | Immediate |
      | ["parameters"]["zones"] | ''        |
    Then the step should succeed
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc                    |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc/pvc |
    Then the step should succeed
    And the output should contain:
      | ProvisioningFailed        |
      | must not contain an empty |

  # @author lxia@redhat.com
  # @case_id OCP-11063
  @admin
  Scenario: Dynamic provision with storageclass which has comma separated list of zones
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"]   | Immediate                   |
      | ["parameters"]["zones"] | us-central1-a,us-central1-b |
    Then the step should succeed
    And I run the steps 10 times:
    """
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc-#{cb.i}            |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-#{cb.i}" PVC becomes :bound
    When I run the :get admin command with:
      | resource | pv/<%= pvc.volume_name %> |
      | o        | json                      |
    Then the output should match:
      | us-central1-[ab] |
    """

  # @author lxia@redhat.com
  # @case_id OCP-12834
  @admin
  Scenario: Dynamic provision with storageclass which has parameter zone set with multiple values should fail
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"]  | Immediate                   |
      | ["parameters"]["zone"] | us-central1-a,us-central1-b |
    Then the step should succeed
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc                    |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc/pvc |
    Then the step should succeed
    And the output should match:
      | ProvisioningFailed                            |
      | does not .*zone "us-central1-a,us-central1-b" |

  # @author lxia@redhat.com
  # @case_id OCP-12833
  @admin
  Scenario: Dynamic provision with storageclass which has both parameter zone and parameter zones set should fail
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"]   | Immediate                   |
      | ["parameters"]["zone"]  | us-central1-a               |
      | ["parameters"]["zones"] | us-central1-a,us-central1-b |
    Then the step should succeed
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc                    |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc/pvc |
    Then the step should succeed
    And the output should contain:
      | ProvisioningFailed                           |
      | parameters must not be used at the same time |

  # @author lxia@redhat.com
  # @case_id OCP-15435
  @admin
  Scenario: Dynamic provision with storageclass which contains invalid parameter should fail
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"]          | Immediate |
      | ["parameters"]["invalidParam"] | test      |
    Then the step should succeed
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc                    |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc/pvc |
    Then the step should succeed
    And the output should contain:
      | ProvisioningFailed            |
      | invalid option "invalidParam" |

  # @author lxia@redhat.com
  # @case_id OCP-15429
  @admin
  Scenario: Dynamic provision with storageclass which has zone set to empty string
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["volumeBindingMode"]  | Immediate |
      | ["parameters"]["zone"] | ''        |
    Then the step should succeed
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc                    |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc/pvc |
    Then the step should succeed
    And the output should match:
      | ProvisioningFailed                                   |
      | (it's an empty string\|does not have a node in zone) |

  # @author lxia@redhat.com
  # @case_id OCP-10219
  @admin
  Scenario: Should be able to create pv with volume in different zone than master on GCE
    Given I have a project
    Given a GCE zone without any cluster masters is stored in the clipboard
    When admin creates a StorageClass from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/storageClass.yaml" where:
      | ["metadata"]["name"]   | sc-<%= project.name %> |
      | ["parameters"]["zone"] | <%= cb.zone %>         |
    Then the step should succeed
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | pvc1                   |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "pvc1" PVC becomes :bound
    And admin ensures "<%= pvc.volume_name %>" pv is deleted after scenario
    Given I save volume id from PV named "<%= pvc.volume_name %>" in the :volumeID clipboard
    When admin creates a PV from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pv-with-failure-domain.json" where:
      | ["metadata"]["name"]                                               | pv-<%= project.name %> |
      | ["metadata"]["labels"]["failure-domain.beta.kubernetes.io/region"] | us-central1            |
      | ["metadata"]["labels"]["failure-domain.beta.kubernetes.io/zone"]   | <%= cb.zone %>         |
      | ["spec"]["gcePersistentDisk"]["pdName"]                            | <%= cb.volumeID %>     |
    Then the step should succeed
    When admin creates a PV from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pv-retain-rwx.json" where:
      | ["metadata"]["name"]                    | pvv-<%= project.name %> |
      | ["spec"]["gcePersistentDisk"]["pdName"] | <%= cb.volumeID %>      |
    Then the step should succeed

  # @author lxia@redhat.com
  # @case_id OCP-11974
  @admin
  Scenario: Rapid repeat pod creation and deletion with GCE PD should not fail
    Given I have a project
    When I create a dynamic pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc |
    Then the step should succeed

    Given I run the steps 30 times:
    """
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
      | ["metadata"]["name"]                                         | mypod |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | mountpoint | -d | /mnt/gce |
    Then the step should succeed
    When I execute on the pod:
      | bash |
      | -c   |
      | date >> /mnt/gce/testfile |
    Then the step should succeed
    Given I ensure "mypod" pod is deleted
    """

  # @author lxia@redhat.com
  # @case_id OCP-12165
  @admin
  @destructive
  Scenario: Two or more pods scheduled to the same node with the same volume with ROX should not fail
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>      |
      | node_selector | <%= cb.proj_name %>=test |
      | admin         | <%= user.name %>         |
    Then the step should succeed

    Given I store the ready and schedulable nodes in the :nodes clipboard
    And label "<%= cb.proj_name %>=test" is added to the "<%= cb.nodes[0].name %>" node

    Given I use the "<%= cb.proj_name %>" project
    And I have a 1 GB volume and save volume id in the :gcepd clipboard

    # Prepare test files in the volume
    When admin creates a PV from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pv-default-rwo.json" where:
      | ["metadata"]["name"]                      | pv-rw-<%= project.name %> |
      | ["spec"]["capacity"]["storage"]           | 1                         |
      | ["spec"]["accessModes"][0]                | ReadWriteMany             |
      | ["spec"]["gcePersistentDisk"]["pdName"]   | <%= cb.gcepd %>           |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                    |
    Then the step should succeed
    When I create a manual pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-rw                    |
      | ["spec"]["volumeName"]                       | pv-rw-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteMany             |
      | ["spec"]["resources"]["requests"]["storage"] | 1                         |
    Then the step should succeed
    And the "pvc-rw" PVC becomes bound to the "pv-rw-<%= project.name %>" PV
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | podname |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-rw  |
    Then the step should succeed
    Given the pod named "podname" becomes ready
    When I execute on the pod:
      | cp | /proc/cpuinfo | /proc/meminfo | /mnt/gce/ |
    Then the step should succeed
    Given I ensure "podname" pod is deleted
    And I ensure "pvc-rw" pvc is deleted

    When admin creates a PV from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pv-default-rwo.json" where:
      | ["metadata"]["name"]                      | pv-<%= project.name %> |
      | ["spec"]["capacity"]["storage"]           | 1                      |
      | ["spec"]["accessModes"][0]                | ReadOnlyMany           |
      | ["spec"]["gcePersistentDisk"]["pdName"]   | <%= cb.gcepd %>        |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                 |
    Then the step should succeed
    When I create a manual pvc from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | pv-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadOnlyMany            |
      | ["spec"]["resources"]["requests"]["storage"] | 1                       |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | pod1-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>  |
    Then the step should succeed
    Given the pod named "pod1-<%= project.name %>" becomes ready
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | pod2-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>  |
    Then the step should succeed
    Given the pod named "pod2-<%= project.name %>" becomes ready
    When I execute on the "<%= pod(-1).name %>" pod:
      | ls | /mnt/gce/cpuinfo |
    Then the step should succeed
    When I execute on the "<%= pod(-2).name %>" pod:
      | ls | /mnt/gce/meminfo |
    Then the step should succeed

  # @author lxia@redhat.com
  # @case_id OCP-11813
  @admin
  Scenario: pods referencing different partitions of the same volume should not fail
    Given I have a project
    And I have a 1 GB volume and save volume id in the :volumeID clipboard

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pod-NoDiskConflict-1.json" replacing paths:
      | ["metadata"]["name"]                                     | pod1-<%= project.name %> |
      | ["spec"]["volumes"][0]["gcePersistentDisk"]["pdName"]    | <%= cb.volumeID %>       |
      | ["spec"]["volumes"][0]["gcePersistentDisk"]["partition"] | 0                        |
    Then the step should succeed
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/gce/pod-NoDiskConflict-1.json" replacing paths:
      | ["metadata"]["name"]                                     | pod2-<%= project.name %> |
      | ["spec"]["volumes"][0]["gcePersistentDisk"]["pdName"]    | <%= cb.volumeID %>       |
      | ["spec"]["volumes"][0]["gcePersistentDisk"]["partition"] | 1                        |
    Then the step should succeed
    Given the pod named "pod1-<%= project.name %>" becomes ready
    Given the pod named "pod2-<%= project.name %>" becomes ready

    When I execute on the "<%= pod(-1).name %>" pod:
      | ls | -al | /mnt/gce/ |
    Then the step should succeed
    When I execute on the "<%= pod(-2).name %>" pod:
      | ls | -al | /mnt/gce/ |
    Then the step should succeed

  # @author lxia@redhat.com
  # @case_id OCP-13672
  @admin
  Scenario: PV with annotation storage-class bind PVC with annotation storage-class
    Given I have a project
    When admin creates a PV from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/hostpath/local-retain.yaml" where:
      | ["metadata"]["name"]                                                   | pv-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | <%= project.name %>    |
    Then the step should succeed
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                                                   | mypvc               |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | <%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

  # @author lxia@redhat.com
  # @case_id OCP-13673
  @admin
  Scenario: PV with attribute storageClassName bind PVC with attribute storageClassName
    Given I have a project
    When admin creates a PV from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/hostpath/local-retain.yaml" where:
      | ["metadata"]["name"]         | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

  # @author lxia@redhat.com
  # @case_id OCP-13674
  @admin
  Scenario: PV with annotation storage-class bind PVC with attribute storageClassName
    Given I have a project
    When admin creates a PV from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/hostpath/local-retain.yaml" where:
      | ["metadata"]["name"]                                                   | pv-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

  # @author lxia@redhat.com
  # @case_id OCP-13675
  @admin
  Scenario: PV with attribute storageClassName bind PVC with annotation storage-class
    Given I have a project
    When admin creates a PV from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/hostpath/local-retain.yaml" where:
      | ["metadata"]["name"]         | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                                                   | mypvc                  |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV
