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
