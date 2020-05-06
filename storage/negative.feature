Feature: negative testing
  # @author lxia@redhat.com
  # @case_id OCP-10188
  # @bug_id 1478814
  Scenario: PVC creation negative testing
    # apiVersion
    Given I have a project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/claim-rwo.json" replacing paths:
      | ["apiVersion"] | invalidVersion |
    Then the step should fail
    And the output should match:
      | no (matches for )?kind "PersistentVolumeClaim" (is registered for \|in )version "invalidVersion" |
    And there is no pvc in the project
    And the project is deleted
    # metadata.name
    Given I have a project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"] | abc@#$$#@cba |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid value     |
    And there is no pvc in the project
    And the project is deleted
    # spec.accessModes
    Given I have a project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/claim-rwo.json" replacing paths:
      | ["spec"]["accessModes"][0] | invalidMode |
    Then the step should fail
    And the output should match:
      | [Uu]nsupported value |
    And there is no pvc in the project
    And the project is deleted
    # spec.resources.Size
    Given I have a project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/nfs/claim-rwo.json" replacing paths:
      | ["spec"]["resources"]["requests"]["storage"] | invalidSizw |
    Then the step should fail
    And the output should contain:
      | quantities must match the regular expression |
    And there is no pvc in the project
    And the project is deleted

  # @author wehe@redhat.com
  # @case_id OCP-15414
  @admin
  Scenario: Check EMC scaleio volume plugin with invalid gateway
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/scaleio/secret.yaml |
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/scaleio/pod.yaml |
      | n | <%= project.name %>                                                                                    |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | po/pod |
    Then the output should contain:
      | ScaleIO storage pool not provided |

