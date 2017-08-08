Feature: negative testing
  # @author lxia@redhat.com
  # @case_id OCP-10188
  Scenario: PVC creation negative testing
    Given I have a project
    # apiVersion
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["apiVersion"] | invalidVersion |
    Then the step should fail
    And the output should contain:
      | no kind "PersistentVolumeClaim" is registered for version "invalidVersion" |
    When I run the :describe client command with:
      | resource | project |
    Then the output should not match:
      | persistentvolumeclaims\s1 |
    # metadata.name
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"] | abc@#$$#@cba |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid value     |
    When I run the :describe client command with:
      | resource | project |
    Then the output should not match:
      | persistentvolumeclaims\s1 |
    # spec.accessModes
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["spec"]["accessModes"][0] | invalidMode |
    Then the step should fail
    And the output should match:
      | [Uu]nsupported value |
    When I run the :describe client command with:
      | resource | project |
    Then the output should not match:
      | persistentvolumeclaims\s1 |
    # spec.resources.Size
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["spec"]["resources"]["requests"]["storage"] | invalidSizw |
    Then the step should fail
    And the output should contain:
      | quantities must match the regular expression |
    When I run the :describe client command with:
      | resource | project |
    Then the output should not match:
      | persistentvolumeclaims\s1 |
