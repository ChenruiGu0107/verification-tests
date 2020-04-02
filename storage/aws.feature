Feature: AWS specific scenarios
  # @author wehe@redhat.com
  # @case_id OCP-13104
  @admin
  Scenario: Check AWS EFS storage is provisioned successfully in same zone
    Given I have a project
    And I have a efs-provisioner in the project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/class.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | openshift.org/aws-efs  |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/claim.yaml" replacing paths:
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "efs" PVC becomes :bound within 60 seconds
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/test-pod.yaml |
    Then the step should succeed
    Given the pod named "test-pod" status becomes :succeeded
    And I ensure "test-pod" pod is deleted
    And I ensure "efs" pvc is deleted
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 300 seconds

  # @author chaoyang@redhat.com
  # @case_id OCP-13131
  @admin
  Scenario: Check a pod with 2 containers can use one efs storage correctly
    Given I have a project
    And I have a efs-provisioner in the project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/class.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | openshift.org/aws-efs  |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/claim.yaml" replacing paths:
      | ["metadata"]["name"]         | efspvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>     |
    Then the step should succeed
    And the "efspvc-<%= project.name %>" PVC becomes :bound within 60 seconds
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/efs/double_containers.json" replacing paths:
      | ["metadata"]["name"]                                         | doublecontainers-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | efspvc-<%= project.name %>           |
    Then the step should succeed
    And the pod named "doublecontainers-<%= project.name %>" becomes ready

    When I run the :exec client command with:
      | pod              | doublecontainers-<%= project.name %> |
      | container        | hello-openshift                      |
      | oc_opts_end      |                                      |
      | exec_command     | touch                                |
      | exec_command_arg | /tmp/testfilea                       |
    Then the step should succeed

    When I run the :exec client command with:
      | pod              | doublecontainers-<%= project.name %> |
      | container        | hello-openshift                      |
      | oc_opts_end      |                                      |
      | exec_command     | ls                                   |
      | exec_command_arg | -l                                   |
      | exec_command_arg | /tmp/testfilea                       |
    Then the step should succeed
    When I run the :exec client command with:
      | pod              | doublecontainers-<%= project.name %> |
      | container        | hello-openshift                      |
      | oc_opts_end      |                                      |
      | exec_command     | cp                                   |
      | exec_command_arg | /hello                               |
      | exec_command_arg | /tmp/a                               |
    Then the step should succeed
    When I run the :exec client command with:
      | pod          | doublecontainers-<%= project.name %> |
      | container    | hello-openshift                      |
      | oc_opts_end  |                                      |
      | exec_command | /tmp/a                               |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

    When I run the :exec client command with:
      | pod              | doublecontainers-<%= project.name %> |
      | container        | hello-openshift-fedora               |
      | oc_opts_end      |                                      |
      | exec_command     | touch                                |
      | exec_command_arg | /tmp/testfileb                       |
    Then the step should succeed
    When I run the :exec client command with:
      | pod              | doublecontainers-<%= project.name %> |
      | container        | hello-openshift-fedora               |
      | oc_opts_end      |                                      |
      | exec_command     | ls                                   |
      | exec_command_arg | -l                                   |
      | exec_command_arg | /tmp                                 |
    Then the step should succeed
    Then the output should contain:
      | testfilea |
      | testfileb |

    And I ensure "efspvc-<%= project.name %>" pvc is deleted
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 300 seconds

  # @author chaoyang@redhat.com
  # @case_id OCP-13128
  @admin
  Scenario: Check AWS EFS storage is provisioned successfully with storageclass parameter gidMin and gidMax
    Given I have a project
    And I have a efs-provisioner in the project
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/efs/class-gid.yaml" where:
      | ["metadata"]["name"]     | sc-<%= project.name %> |
      | ["parameters"]["gidMin"] | 40000                  |
      | ["parameters"]["gidMax"] | 49999                  |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/claim.yaml" replacing paths:
      | ["metadata"]["name"]         | efspvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>     |
    Then the step should succeed
    And the "efspvc-<%= project.name %>" PVC becomes :bound within 60 seconds

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %>    |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | efspvc-<%= project.name %> |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | id | -G |
    Then the step should succeed
    And the output should match:
      | 4[0-9][0-9][0-9][0-9] |

    When I run the :exec client command with:
      | pod              | pod-<%= project.name %> |
      | oc_opts_end      |                         |
      | exec_command     | touch                   |
      | exec_command_arg | /tmp/testfile           |
    Then the step should succeed
    And I ensure "efspvc-<%= project.name %>" pvc is deleted
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 300 seconds

  # @author chaoyang@redhat.com
  # @case_id OCP-14318
  @admin
  @destructive
  Scenario: Pod is running with EFS storage after restart atomic-openshift-node service
    Given admin creates a project with a random schedulable node selector
    And I have a efs-provisioner in the project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/class.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | openshift.org/aws-efs  |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/claim.yaml" replacing paths:
      | ["metadata"]["name"]         | efspvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>     |
    Then the step should succeed
    And the "efspvc-<%= project.name %>" PVC becomes :bound within 60 seconds
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %>    |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | efspvc-<%= project.name %> |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | touch | /tmp/testfile_before_restart |
    Then the step should succeed

    Given I use the "<%= node.name %>" node
    And the node service is restarted on the host
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the "pod-<%= project.name %>" pod:
      | ls | /tmp/testfile_before_restart |
    Then the step should succeed
    When I execute on the "pod-<%= project.name %>" pod:
      | touch | /tmp/testfile_after_restart |
    Then the step should succeed
    """
    And I ensure "efspvc-<%= project.name %>" pvc is deleted
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 300 seconds

  # @author chaoyang@redhat.com
  # @case_id OCP-15015
  @admin
  @destructive
  Scenario: Pod with ebs volumes is running after restart controller service
    Given I have a project
    And I run the steps 10 times:
    """
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/claim.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc-#{cb.i} |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                 |

    Then the step should succeed
    And the "dynamic-pvc-#{cb.i}" PVC becomes :bound

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc-#{cb.i}   |
      | ["spec"]["containers"][0]["image"]                           | aosqe/hello-openshift |
      | ["metadata"]["name"]                                         | mypod#{cb.i}          |
    Then the step should succeed
    And the pod named "mypod#{cb.i}" becomes ready
    """

    And I run the steps 3 times:
    """
    Given the master service is restarted on all master nodes
    Given 10 pods become ready with labels:
      | name=frontendhttp|
    """

  # @author chaoyang@redhat.com
  # @case_id OCP-12964
  @admin
  @destructive
  Scenario: Volume is detached when restart contoller manager
    Given I have a project
    And I run the steps 2 times:
    """
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/claim.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc-#{cb.i} |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                 |

    Then the step should succeed
    And the "dynamic-pvc-#{cb.i}" PVC becomes :bound

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc-#{cb.i}   |
      | ["spec"]["containers"][0]["image"]                           | aosqe/hello-openshift |
      | ["metadata"]["name"]                                         | mypod#{cb.i}          |
    Then the step should succeed
    And the pod named "mypod#{cb.i}" becomes ready
    """

    Given I save volume id from PV named "<%= pvc('dynamic-pvc-1').volume_name %>" in the :vid clipboard

    Given I run commands on all masters:
      | systemctl stop atomic-openshift-master-controllers |
    Then the step should succeed
    And I ensure "mypod1" pod is deleted
    And I ensure "dynamic-pvc-1" pvc is deleted

    Given I run commands on all masters:
      | systemctl start atomic-openshift-master-controllers |
    Then the step should succeed
    And the pod named "mypod2" becomes ready
    And I verify that the IAAS volume with id "<%= cb.vid %>" has status "available" within 120 seconds

  # @author chaoyang@redhat.com
  # @case_id OCP-17749
  @admin
  Scenario: Using mountOptions for AWS-EFS StorageClass
    Given I have a project
    And I have a efs-provisioner in the project
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-mountOptions.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | openshift.org/aws-efs  |
      | ["mountOptions"][0]  | tcp                    |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And admin ensures "<%= pvc.volume_name %>" pv is deleted after scenario
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | grep | ocp_pv | /proc/self/mountinfo |
    Then the step should succeed
    And the output should contain:
      | tcp |
