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
