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

  # @author wewang@redhat.com
  # @case_id OCP-17484
  @admin
  @destructive
  Scenario: Specify default tolerations via the BuildOverrides plugin
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
            tolerations:
            - key: key1
              value: value1
              effect: NoSchedule
              operator: Equal
            - key: key2
              value: value2
              effect: NoSchedule
              operator: Equal
    """
    Then the step should succeed
    And the master service is restarted on all master nodes	
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    When I run the :describe client command with:
      | resource | pod                      |
      | name     | ruby-hello-world-1-build |
    Then the step should succeed
    Then the output should contain:
      | Tolerations:     key1=value1:NoSchedule |
      |                  key2=value2:NoSchedule |
