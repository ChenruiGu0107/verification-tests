Feature: local storage operator testing
  # @author piqin@redhat.com
  # @case_id OCP-24498
  @admin
  @smoke
  @flaky
  Scenario: [local-storage-operator] Install operator from the OperatorHub using the CLI
    Given I switch to cluster admin pseudo user
    And local storage operator has been installed successfully
    And local storage provisioner has been installed successfully
    And local storage PVs are created successfully in schedulable workers

  # @author piqin@redhat.com
  # @case_id OCP-24524
  @admin
  @smoke
  @flaky
  Scenario: [local-storage-operator] LocalVolume with Filesystem VolumeMode and type xfs can be used by Pod
    Given I switch to cluster admin pseudo user
    And local storage operator has been installed successfully
    And local storage provisioner has been installed successfully
    And local storage PVs are created successfully in schedulable workers

    Given I switch to the first user
    And I have a project

    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc         |
      | ["spec"]["storageClassName"] | local-storage |
    Then the step should succeed

    Given I obtain test data file "storage/misc/deployment.yaml"
    When I run oc create over "deployment.yaml" replacing paths:
      | ["metadata"]["name"]                                                             | mydep              |
      | ["spec"]["template"]["metadata"]["labels"]["action"]                             | storage            |
      | ["spec"]["template"]["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc              |
      | ["spec"]["template"]["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/local-storage |
    Then the step should succeed
    And a pod becomes ready with labels:
      | action=storage |
    And the "mypvc" PVC becomes :bound

    # check /mnt/local-storage is an xfs filesystem
    When I execute on the pod:
      | df | --type=xfs | /mnt/local-storage |
    Then the step should succeed

    # check the local storage support exec file
    When I execute on the pod:
      | cp | /hello | /mnt/local-storage |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/local-storage/hello |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift Storage |

    # check it is a persistent storage
    Given I run the :scale client command with:
      | resource | deployment |
      | name     | mydep      |
      | replicas | 0          |
    Then the step should succeed
    And all existing pods die with labels:
      | action=storage |

    Given I run the :scale client command with:
      | resource | deployment |
      | name     | mydep      |
      | replicas | 1          |
    Then the step should succeed
    And a pod becomes ready with labels:
      | action=storage |

    When I execute on the pod:
      | ls | /mnt/local-storage/ |
    Then the step should succeed
    And the output should contain "hello"

  # @author piqin@redhat.com
  # @case_id OCP-24520
  @admin
  @smoke
  @flaky
  Scenario: [local-storage-provisioner] PV can be reused
    Given I switch to cluster admin pseudo user
    And local storage operator has been installed successfully
    And local storage provisioner has been installed successfully
    And local storage PVs are created successfully in schedulable workers

    Given I switch to the first user
    And I have a project

    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc         |
      | ["spec"]["storageClassName"] | local-storage |
    Then the step should succeed

    Given I obtain test data file "storage/misc/deployment.yaml"
    When I run oc create over "deployment.yaml" replacing paths:
      | ["metadata"]["name"]                                                             | mydep              |
      | ["spec"]["template"]["metadata"]["labels"]["action"]                             | storage            |
      | ["spec"]["template"]["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc              |
      | ["spec"]["template"]["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/local-storage |
    Then the step should succeed
    And a pod becomes ready with labels:
      | action=storage |
    And the "mypvc" PVC becomes :bound

    Given evaluation of `pvc.volume_name` is stored in the :pv_name clipboard
    When I execute on the pod:
      | touch | /mnt/local-storage/testfile1 |
    Then the step should succeed

    # check the PV is available again
    Given I ensure "mydep" deployment is deleted
    And I ensure "mypvc" pvc is deleted
    And I wait up to 60 seconds for the steps to pass:
    """
    Given the "<%= cb.pv_name %>" PV status is :available
    """

    # check the data on the PV is deleted
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc-2           |
      | ["spec"]["storageClassName"] | local-storage     |
      | ["spec"]["volumeName"]       | <%= cb.pv_name %> |
    Then the step should succeed

    Given I obtain test data file "storage/misc/deployment.yaml"
    When I run oc create over "deployment.yaml" replacing paths:
      | ["metadata"]["name"]                                                             | mydep              |
      | ["spec"]["template"]["metadata"]["labels"]["action"]                             | storage            |
      | ["spec"]["template"]["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc-2            |
      | ["spec"]["template"]["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/local-storage |
    Then the step should succeed
    And a pod becomes ready with labels:
      | action=storage |
    And the "mypvc-2" PVC becomes bound to the "<%= cb.pv_name %>" PV

    When I execute on the pod:
      | ls | /mnt/local-storage/ |
    Then the step should succeed
    And the output should not contain "testfile1"
