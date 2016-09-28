Feature: negative tests

  # @author pruan@redhat.com
  # @case_id 505047
  Scenario: Add automatic suggestions when "unknown command" errors happen in the CLI
    When I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | labels |
    Then the step should fail
    And the output should contain:
      | unknown command "labels" for "oc" |
      | Did you mean this                 |
      | label                             |
    When I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | creaet |
    Then the step should fail
    And the output should contain:
      | unknown command "creaet" for "oc" |
      | Did you mean this                 |
      | create                            |
    When I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | teg |
    Then the step should fail
    And the output should contain:
      | unknown command "teg" for "oc" |
      | Did you mean this              |
      | tag                            |
  
  # @author xiaocwan@redhat.com
  # @case_id 533685
  Scenario: Check output for resource idle command and negative commands
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/rc/idle-rc-1.yaml |
    Then the step should succeed
    When I run the :idle client command with:
      | svc_name | svc/hello-idle |
      | dry-run  | true           |
    Then the step should fail
    And the output should match:
      | no valid.*resources.*specify endpoints |
    When I run the :idle client command with:
      | svc_name | rc/hello-idle  |
      | dry-run  | true           |
    Then the step should fail
    And the output should match:     
      | no valid.*resources.*specify endpoints |
    ## idle again
    Given I wait until number of replicas match "2" for replicationController "hello-idle"
    And 2 pods become ready with labels:
      | name=hello-idle |
    When I run the :idle client command with:
      | all | true      |
    Then the step should succeed
    When I run the :idle client command with:
      | all | true      |
    Then the step should fail
    And the output should match:
      | [Ee]rror.*no scalable resources |
