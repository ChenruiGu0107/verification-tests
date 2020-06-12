Feature: volumeMounts should be able to use subPath
  # @author jhou@redhat.com
  # @case_id OCP-14087
  @admin
  Scenario: Subpath should receive right permissions - emptyDir
    Given I have a project
    Given I obtain test data file "storage/emptydir/subpath.yml"
    When I run the :create admin command with:
        | f | subpath.yml |
        | n | <%= project.name %>                                                                                        |
    Then the step should succeed
    Given the pod named "subpath" becomes ready

    When admin executes on the pod:
      | ls | -ld | /mnt/direct |
    Then the output should contain:
      | drwxrwsrwx |
    When admin executes on the pod:
      | ls | -ld | /mnt/subpath |
    Then the output should contain:
      | drwxrwsrwx |

    When admin executes on the pod:
      | touch | /mnt/subpath/testfile |
    Then the step should succeed

  # @author jhou@redhat.com
  # @case_id OCP-18302
  Scenario: Subpath with secret volume
    Given I have a project
    Given I obtain test data file "storage/subpath/secret.yaml"
    When I run the :create client command with:
        | f | secret.yaml |
        | n | <%= project.name %>                                                               |
    Then the step should succeed

    Given I obtain test data file "storage/subpath/secret-subpath.json"
    When I run the :create client command with:
        | f | secret-subpath.json |
        | n | <%= project.name %>                                                                       |
    Then the step should succeed
    And the pod named "subpath" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18303
  Scenario: Subpath with configmap volume
    Given I have a project
    Given I obtain test data file "storage/subpath/configmap.yaml"
    When I run the :create client command with:
        | f | configmap.yaml |
        | n | <%= project.name %>                                                                  |
    Then the step should succeed

    Given I obtain test data file "storage/subpath/configmap-subpath.yaml"
    When I run the :create client command with:
        | f | configmap-subpath.yaml |
        | n | <%= project.name %>                                                                          |
    Then the step should succeed
    And the pod named "configmap" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18304
  Scenario: Subpath with downwardAPI volume
    Given I have a project
    Given I obtain test data file "storage/subpath/downwardApi-subpath.yaml"
    When I run the :create client command with:
        | f | downwardApi-subpath.yaml |
        | n | <%= project.name %>                                                                                                    |
    Then the step should succeed
    And the pod named "pod-dapi-volume" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18305
  Scenario: Subpath with projected volume
    Given I have a project
    Given I obtain test data file "storage/subpath/secret.yaml"
    When I run the :create client command with:
        | f | secret.yaml |
        | n | <%= project.name %>                                                               |
    Then the step should succeed
    Given I obtain test data file "storage/subpath/configmap.yaml"
    When I run the :create client command with:
        | f | configmap.yaml |
        | n | <%= project.name %>                                                                  |
    Then the step should succeed

    Given I obtain test data file "storage/subpath/projected-subpath.yaml"
    When I run the :create client command with:
        | f | projected-subpath.yaml |
        | n | <%= project.name %>                                                                                                  |
    Then the step should succeed
    And the pod named "volume-test" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18407
  @admin
  @destructive
  Scenario: Subpath with NFS volume
    Given I have a project
    And I have a NFS service in the project

    Given I obtain test data file "storage/nfs/auto/pv-template.json"
    Given admin creates a PV from "pv-template.json" where:
      | ["spec"]["nfs"]["server"]                 | <%= service("nfs-service").ip %> |
      | ["spec"]["accessModes"][0]                | ReadWriteMany                    |
      | ["spec"]["capacity"]["storage"]           | 1Gi                              |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                           |
      | ["metadata"]["name"]                      | nfs-<%= project.name %>          |
    Given I obtain test data file "storage/nfs/auto/pvc-template.json"
    When I create a manual pvc from "pvc-template.json" replacing paths:
      | ["metadata"]["name"]                         | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | nfs-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                      |
      | ["spec"]["accessModes"][0]                   | ReadWriteMany            |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    Given I obtain test data file "storage/subpath/nfs-subpath.json"
    When I run oc create over "nfs-subpath.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | nfsc-<%= project.name %>  |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
    Then the step should succeed
    Given the pod named "mypod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | ls | -ld | /mnt/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/test_file |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

  # @author jhou@redhat.com
  # @case_id OCP-18408
  @admin
  @destructive
  Scenario: Subpath with iSCSI volume
    Given I have a iSCSI setup in the environment
    And I have a project

    And admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pv-rwo.json" where:
      | ["metadata"]["name"]               | pv-iscsi-<%= project.name %>  |
      | ["spec"]["iscsi"]["targetPortal"]  | <%= cb.iscsi_ip %>:3260       |
      | ["spec"]["iscsi"]["initiatorName"] | iqn.2016-04.test.com:test.img |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | mypvc                        |
      | ["spec"]["volumeName"] | pv-iscsi-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-iscsi-<%= project.name %>" PV

    # Create tester pod
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    Given I obtain test data file "storage/subpath/iscsi-subpath.json"
    When I run oc create over "iscsi-subpath.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
    Then the step should succeed
    And the pod named "mypod" becomes ready

    When I execute on the pod:
      | id | -u |
    Then the output should contain:
      | 101010 |
    When I execute on the pod:
      | id | -G |
    Then the output should contain:
      | 123456 |

    # Verify mount directory has supplemental groups set properly
    # Verify SELinux context is set properly
    When I execute on the pod:
      | ls | -lZd | /mnt/iscsi |
    Then the output should match:
      | 123456                                   |
      | (svirt_sandbox_file_t\|container_file_t) |
      | s0:c2,c13                                |

    When I execute on the pod:
      | touch | /mnt/iscsi/testfile |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/iscsi/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

  # @author jhou@redhat.com
  @admin
  Scenario Outline: Subpath with cloud volumes
    Given I have a project

    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"]                           | 1Gi                     |
    Then the step should succeed

    Given I obtain test data file "storage/subpath/common-subpath.yaml"
    When I run oc create over "common-subpath.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/iaas               |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the "pod-<%= project.name %>" pod:
      | touch | /mnt/iaas/testfile |
    Then the step should succeed
    When I execute on the "pod-<%= project.name %>" pod:
      | ls | /mnt/iaas/ |
    Then the output should contain:
      | testfile |

    When I execute on the "pod-<%= project.name %>" pod:
      | ls | -ld | /mnt/iaas/ |
    Then the output should contain:
      | drwxr-sr-x |
    When I execute on the "pod-<%= project.name %>" pod:
      | /mnt/iaas/hello |
    Then the output should contain:
      | Hello OpenShift Storage |

    Examples:
      | provisioner    |
      | vsphere-volume | # @case_id OCP-18422
      | gce-pd         | # @case_id OCP-18419
      | aws-ebs        | # @case_id OCP-18418
      | cinder         | # @case_id OCP-18421
      | azure-disk     | # @case_id OCP-18420

  # @author piqin@redhat.com
  # @case_id OCP-18737
  @admin
  Scenario: Subpath with sock file
    Given SCC "privileged" is added to the "default" user
    And I store the schedulable workers in the :nodes clipboard
    And I use the "<%= cb.nodes[0].name %>" node
    And label "subpath=socket" is added to the "<%=node.name%>" node
    When I run commands on the host:
      | rm -rf /run/test.sock    |
      | nc -vklU /run/test.sock& |
    Then the step should succeed

    Given I have a project
    And I run the :patch admin command with:
      | resource      | namespace                                                                      |
      | resource_name | <%=project.name%>                                                              |
      | p             | {"metadata":{"annotations": {"openshift.io/node-selector": "subpath=socket"}}} |
    Then the step should succeed
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/subpath/sock-subpath.json" replacing paths:
      | ["metadata"]["name"]                                      | pod-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"] | /mnt/run/test.sock      |
      | ["spec"]["containers"][0]["volumeMounts"][0]["subPath"]   | run/test.sock           |
    Then the step should succeed

    Given the pod named "pod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | stat | /mnt/run/test.sock |
    Then the step should succeed
    And the output should contain "socket"

  # @author wduan@redhat.com
  # @case_id OCP-18428
  @admin
  Scenario: Subpath with azure-file
    Given I have a project
    And azure file dynamic provisioning is enabled in the project
    Given I obtain test data file "storage/misc/storageClass.yaml"
    When admin creates a StorageClass from "storageClass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %>   |
      | ["provisioner"]      | kubernetes.io/azure-file |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/subpath/common-subpath.yaml"
    When I run oc create over "common-subpath.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc     |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/iaas |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | touch | /mnt/iaas/testfile |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/iaas/ |
    Then the output should contain:
      | testfile |
      | hello    |
    When I execute on the pod:
      | /mnt/iaas/hello |
    Then the output should contain:
      | Hello OpenShift Storage |

