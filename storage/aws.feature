Feature: AWS specific scenarios
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
