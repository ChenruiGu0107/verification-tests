Feature: genericbuild.feature
  # @author wewang@redhat.com
  # @case_id OCP-14373
  Scenario: Support valueFrom with filedRef syntax for pod field
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc14373/test-valuefrom.json"
    And I run the :create client command with:
      | f | test-valuefrom.json | 
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    When I run the :env client command with:
      | resource | pods/hello-openshift |
      | list     | true                 |
    And the output should contain:
      |  podname from field path metadata.name |
    And I replace lines in "test-valuefrom.json":
      | "fieldPath":"metadata.name" | "fieldPath":"" | 
    Then the step should succeed
    And I run the :create client command with:
      | f | test-valuefrom.json |
    Then the step should fail
    And the output should contain "valueFrom.fieldRef.fieldPath: Required value"

  # @author wewang@redhat.com
  # @case_id OCP-14381
  Scenario: Support valueFrom with configMapKeyRef syntax for pod field
    Given I have a project
    When I run the :create_configmap client command with:
      | name         | special-config     |
      | from_literal | special.how=very   |
      | from_literal | special.type=charm |
    Then the step should succeed
    When I run the :get client command with:
      | resource  | configmap |
      | o         | yaml      |
    Then the output should match:
      | special.how: very |
      | special.type: charm |
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc14381/test-valuefrommap.json"
    And I run the :create client command with:
      | f | test-valuefrommap.json |
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :running
    When I run the :env client command with:
      | resource | pods/hello-openshift |
      | list     | true                 |
    Then the step should succeed
    And the output should contain:
      | SPECIAL_LEVEL_KEY from configmap special-config, key special.how |
      | SPECIAL_TYPE_KEY from configmap special-config, key special.type |
    And I replace lines in "test-valuefrommap.json":
      | "key":"special.how" | "key":"" |
    Then the step should succeed
    And I run the :create client command with:
      | f | test-valuefrommap.json |
    Then the step should fail
    And the output should contain "configMapKeyRef.key: Required value"
