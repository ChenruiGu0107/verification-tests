Feature: deployment related features

  #@author: xxing@redhat.com
  #@case_id: 483193
  Scenario: Restart a failed deployment by oc deploy
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
    And I run the :deploy client command with:
      | deployment_config | hooks |
      | cancel            ||
    Then the step should succeed
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should contain "hooks #1 deployment failed"
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | retry             ||
    Then the output should contain "retried #1"
    When I run the :deploy client command with:
      | deployment_config | hooks |
    Then the output should contain "hooks #1 deployment running"

  #@author: xxing@redhat.com
  #@case_id: 457713
  Scenario: CLI rollback dry run
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1.json |
    Then the step should succeed
    When I run the :replace client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/updatev1.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc |
      | resource_name | hooks |
    Then the output should match:
      | NAME\s+TRIGGERS\s+LATEST VERSION |
      | hooks\s+ImageChange\s+2          |
    When I run the :rollback client command with:
      | deployment_name | hooks-1 |
      | dry_run         ||
    Then the output should match:
      | Strategy:\s+Rolling |
    When I run the :rollback client command with:
      | deployment_name         | hooks-1 |
      | dry_run                 ||
      | change_scaling_settings ||
      | change_strategy         ||
      | change_triggers         ||
    Then the output should match:
      | Triggers:\s+Config   |
      | Strategy:\s+Recreate |
      | Replicas:\s+1        |
