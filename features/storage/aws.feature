Feature: AWS specific scenarios

  # @author jhou@redhat.com
  # @case_id OCP-10173
  @admin
  Scenario: PV with invalid volume id should be prevented from creating
    Given admin ensures "ebsinvalid" pv is deleted after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pv-invalid.yaml |
    Then the step should fail
    And the output should contain:
      | The volume 'vol-00000123' does not exist |

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
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "efs" PVC becomes :bound within 60 seconds
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/test-pod.yaml |
    Then the step should succeed
    Given the pod named "test-pod" status becomes :succeeded
    And I ensure "test-pod" pod is deleted
    And I ensure "efs" pvc is deleted
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: user) %>" to disappear within 300 seconds

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
      | ["metadata"]["name"]                                                   | efspvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>     |
    Then the step should succeed
    And the "efspvc-<%= project.name %>" PVC becomes :bound within 60 seconds
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/efs/double_containers.json" replacing paths:
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
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: user) %>" to disappear within 300 seconds

  # @author chaoyang@redhat.com
  # @case_id OCP-13128
  @admin
  Scenario: Check AWS EFS storage is provisioned successfully with storageclass parameter gidMin and gidMax
    Given I have a project
    And I have a efs-provisioner in the project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/efs/class-gid.yaml" where:
      | ["metadata"]["name"]     | sc-<%= project.name %> |
      | ["parameters"]["gidMin"] | 40000                  |
      | ["parameters"]["gidMax"] | 49999                  |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | efspvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>     |
    Then the step should succeed
    And the "efspvc-<%= project.name %>" PVC becomes :bound within 60 seconds

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pod.yaml" replacing paths:
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
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: user) %>" to disappear within 300 seconds

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
      | ["metadata"]["name"]                                                   | efspvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>     |
    Then the step should succeed
    And the "efspvc-<%= project.name %>" PVC becomes :bound within 60 seconds
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pod.yaml" replacing paths:
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
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: user) %>" to disappear within 300 seconds


  # @author chaoyang@redhat.com
  # @case_id OCP-14335
  @admin
  Scenario: Check two pods using one efs pv is working correctly
    Given I have a project
    And I have a efs-provisioner in the project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/class.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | openshift.org/aws-efs  |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/aws/efs/deploy/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | efspvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>     |
    Then the step should succeed
    And the "efspvc-<%= project.name %>" PVC becomes :bound within 60 seconds
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod1-<%= project.name %>   |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | efspvc-<%= project.name %> |
    Then the step should succeed
    And the pod named "pod1-<%= project.name %>" becomes ready
    When I execute on the pod:
      | touch | /tmp/file_pod1 |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod2-<%= project.name %>   |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | efspvc-<%= project.name %> |
    Then the step should succeed
    And the pod named "pod2-<%= project.name %>" becomes ready
    When I execute on the pod:
      | touch | /tmp/file_pod2 |
    Then the step should succeed
    When I execute on the pod:
      | ls | /tmp |
    Then the step should succeed
    Then the output should contain:
      | file_pod1 |
      | file_pod2 |

    And I ensure "efspvc-<%= project.name %>" pvc is deleted
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: user) %>" to disappear within 300 seconds
