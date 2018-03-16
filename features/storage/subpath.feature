Feature: volumeMounts should be able to use subPath
  # @author jhou@redhat.com
  # @case_id OCP-14087
  @admin
  Scenario: Subpath should receive right permissions - emptyDir
    Given I have a project
    When I run the :create admin command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/emptydir/subpath.yml |
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
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/subpath/secret.yaml |
        | n | <%= project.name %>                                                                                       |
    Then the step should succeed

    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/subpath/secret-subpath.json |
        | n | <%= project.name %>                                                                                               |
    Then the step should succeed
    And the pod named "subpath" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18303
  Scenario: Subpath with configmap volume
    Given I have a project
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/subpath/configmap.yaml |
        | n | <%= project.name %>                                                                                          |
    Then the step should succeed

    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/subpath/configmap-subpath.yaml |
        | n | <%= project.name %>                                                                                                  |
    Then the step should succeed
    And the pod named "configmap" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18304
  Scenario: Subpath with downwardAPI volume
    Given I have a project
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/subpath/downwardApi-subpath.yaml |
        | n | <%= project.name %>                                                                                                    |
    Then the step should succeed
    And the pod named "pod-dapi-volume" becomes ready

  # @author jhou@redhat.com
  # @case_id OCP-18305
  Scenario: Subpath with projected volume
    Given I have a project
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/subpath/secret.yaml |
        | n | <%= project.name %>                                                                                       |
    Then the step should succeed
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/subpath/configmap.yaml |
        | n | <%= project.name %>                                                                                          |
    Then the step should succeed

    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/subpath/projected-subpath.yaml |
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

    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv-template.json" where:
      | ["spec"]["nfs"]["server"]                 | <%= service("nfs-service").ip %> |
      | ["spec"]["accessModes"][0]                | ReadWriteMany                    |
      | ["spec"]["capacity"]["storage"]           | 1Gi                              |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Retain                           |
      | ["metadata"]["name"]                      | nfs-<%= project.name %>          |
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc-template.json" replacing paths:
      | ["metadata"]["name"]                         | nfsc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | nfs-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                      |
      | ["spec"]["accessModes"][0]                   | ReadWriteMany            |
    Then the step should succeed
    And the "nfsc-<%= project.name %>" PVC becomes bound to the "nfs-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["containers"][0]["image"]                           | aosqe/hello-openshift     |
      | ["spec"]["containers"][0]["volumeMounts"][0]["subPath"]      | subpath                   |
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
    #And the output should not contain "Permission denied"
    When I execute on the pod:
      | cp | /hello | /mnt |
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
      | ["metadata"]["name"]              | pv-iscsi-<%= project.name %> |
      | ["spec"]["iscsi"]["targetPortal"] | <%= cb.iscsi_ip %>:3260      |
    And I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/docker-iscsi/master/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]   | pvc-iscsi-<%= project.name %> |
      | ["spec"]["volumeName"] | pv-iscsi-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-iscsi-<%= project.name %>" PVC becomes bound to the "pv-iscsi-<%= project.name %>" PV

    # Create tester pod
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/subpath/iscsi-subpath.json" replacing paths:
      | ["metadata"]["name"]                                         | iscsi-<%= project.name %>     |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-iscsi-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["subPath"]      | subpath                       |
    Then the step should succeed
    And the pod named "iscsi-<%= project.name %>" becomes ready

    When I execute on the "iscsi-<%= project.name %>" pod:
      | id | -u |
    Then the output should contain:
      | 101010 |
    When I execute on the "iscsi-<%= project.name %>" pod:
      | id | -G |
    Then the output should contain:
      | 123456 |

    # Verify mount directory has supplemental groups set properly
    # Verify SELinux context is set properly
    When I execute on the "iscsi-<%= project.name %>" pod:
      | ls | -lZd | /mnt/iscsi |
    Then the output should contain:
      | 123456               |
      | svirt_sandbox_file_t |
      | s0:c2,c13            |


