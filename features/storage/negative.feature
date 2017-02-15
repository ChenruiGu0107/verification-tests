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
    # metadata.name
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["metadata"]["name"] | abc@#$$#@cba |
    Then the step should fail
    And the output should match:
      | [Ii]nvalid value     |
      | must match the regex |
    # spec.accessModes
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["spec"]["accessModes"][0] | invalidMode |
    Then the step should fail
    And the output should match:
      | [Uu]nsupported value |
    # spec.resources.Size
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json" replacing paths:
      | ["spec"]["resources"]["requests"]["storage"] | invalidSizw |
    Then the step should fail
    And the output should contain:
      | quantities must match the regular expression |
