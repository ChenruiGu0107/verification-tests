Feature: Check oc status cli
  #@author yapei@redhat.com
  #@case_id 497402
  Scenario: Show RC info and indicate bad secrets reference in 'oc status'
    Given I have a project
    
    # Check project status when project is empty
    When I run the :status client command
    Then the output should contain:
      | You have no services, deployment configs, or build configs |


    # Check standalone RC info is dispalyed in oc status output
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/secret.json |
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/standalone-rc.yaml |
    When I run the :status client command
    Then the output should contain:
      | rc/stdalonerc runs openshift/origin |
      | rc/stdalonerc created |
      | Warnings: |
      | rc/stdalonerc is attempting to mount a secret secret/mysecret disallowed by sa/default |
    
    # Check DC,RC info when has missing/bad secret reference 
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/application-template-stibuild-with-mount-secret.json |
    When I create a new application with:
      | template | ruby-helloworld-sample |
    Then the step should succeed
    When I run the :status client command
    And the output should contain:
      | dc/frontend is attempting to mount a secret secret/my-secret disallowed by sa/default |
      | dc/frontend is attempting to mount a missing secret secret/my-secret |

    # Show RCs for services in oc status 
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cli/replication-controller-match-a-service.yaml |
    Then I run the :describe client command with:
      | resource    | rc |
      | name | rcmatchse |
    And the output should match:
      | Selector:\s+name=database |
    When I run the :status client command
    Then the output should contain:
      | service/database |
      | dc/database deploys |
      | rc/rcmatchse runs |
      | rc/rcmatchse created |
      | service/frontend |
