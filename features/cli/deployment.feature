Feature: deployment related steps

  # @author chezhang@redhat.com
  # @case_id OCP-11421
  Scenario: Add perma-failed - Deplyment succeed after change pod template by edit deployment
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-perme-failed-1.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+False\\s+MinimumReplicasUnavailable |
      | Progressing\\s+True\\s+ReplicaSetUpdated         |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment does not have minimum availability  |
      | MinimumReplicasUnavailable                     |
      | status: "False"                                |
      | type: Available                                |
      | Replica set "hello-openshift.*" is progressing |
      | ReplicaSetUpdated                              |
      | status: "True"                                 |
      | type: Progressing                              |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+False\\s+MinimumReplicasUnavailable |
      | Progressing\\s+False\\s+ProgressDeadlineExceeded |
    When I run the :get client command with:
      | resource  | deployment |
      | o         | yaml       |
    Then the output by order should match:
      | Deployment does not have minimum availability             |
      | MinimumReplicasUnavailable                                |
      | status: "False"                                           |
      | type: Available                                           |
      | Replica set "hello-openshift.*" has timed out progressing |
      | ProgressDeadlineExceeded                                  |
      | status: "False"                                           |
      | type: Progressing                                         |
    """
    When I run the :patch client command with:
      | resource      | deployment                                                                                                     |
      | resource_name | hello-openshift                                                                                                |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hello-openshift","image":"openshift/hello-openshift"}]}}}} |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable |
      | Progressing\\s+True\\s+NewReplicaSetAvailable |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment has minimum availability                         |
      | MinimumReplicasAvailable                                    |
      | status: "True"                                              |
      | type: Available                                             |
      | Replica set "hello-openshift.*" has successfully progressed |
      | NewReplicaSetAvailable                                      |
      | status: "True"                                              |
      | type: Progressing                                           |
    """

  # @author chezhang@redhat.com
  # @case_id OCP-11046
  Scenario: Add perma-failed - Deployment failed after pausing and resuming
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-perme-failed-1.yaml |
    Then the step should succeed
    When I run the :rollout_pause client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+False\\s+MinimumReplicasUnavailable |
      | Progressing\\s+Unknown\\s+DeploymentPaused       |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment does not have minimum availability |
      | MinimumReplicasUnavailable                    |
      | status: "False"                               |
      | type: Available                               |
      | Deployment is paused                          |
      | DeploymentPaused                              |
      | status: Unknown                               |
      | type: Progressing                             |
    Given 60 seconds have passed
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+False\\s+MinimumReplicasUnavailable |
      | Progressing\\s+Unknown\\s+DeploymentPaused       |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment does not have minimum availability |
      | MinimumReplicasUnavailable                    |
      | status: "False"                               |
      | type: Available                               |
      | Deployment is paused                          |
      | DeploymentPaused                              |
      | status: Unknown                               |
      | type: Progressing                             |
    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+False\\s+MinimumReplicasUnavailable |
      | Progressing\\s+Unknown\\s+DeploymentResumed      |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment does not have minimum availability |
      | MinimumReplicasUnavailable                    |
      | status: "False"                               |
      | type: Available                               |
      | Deployment is resumed                         |
      | DeploymentResumed                             |
      | status: Unknown                               |
      | type: Progressing                             |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+False\\s+MinimumReplicasUnavailable |
      | Progressing\\s+False\\s+ProgressDeadlineExceeded |
    When I run the :get client command with:
      | resource  | deployment |
      | o         | yaml       |
    Then the output by order should match:
      | Deployment does not have minimum availability             |
      | MinimumReplicasUnavailable                                |
      | status: "False"                                           |
      | type: Available                                           |
      | Replica set "hello-openshift.*" has timed out progressing |
      | ProgressDeadlineExceeded                                  |
      | status: "False"                                           |
      | type: Progressing                                         |
    """

  # @author chezhang@redhat.com
  # @case_id OCP-11681
  Scenario: Add perma-failed - Failing deployment can be rolled back successful
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-perme-failed-3.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable |
      | Progressing\\s+True\\s+NewReplicaSetAvailable |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment has minimum availability                         |
      | MinimumReplicasAvailable                                    |
      | status: "True"                                              |
      | type: Available                                             |
      | Replica set "hello-openshift.*" has successfully progressed |
      | NewReplicaSetAvailable                                      |
      | status: "True"                                              |
      | type: Progressing                                           |
    """
    When I run the :patch client command with:
      | resource      | deployment                                                                                                     |
      | resource_name | hello-openshift                                                                                                |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hello-openshift","image":"openshift/hello-openshift-noexist"}]}}}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable |
      | Progressing\\s+True\\s+ReplicaSetUpdated      |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment has minimum availability            |
      | MinimumReplicasAvailable                       |
      | status: "True"                                 |
      | type: Available                                |
      | Replica set "hello-openshift.*" is progressing |
      | ReplicaSetUpdated                              |
      | status: "True"                                 |
      | type: Progressing                              |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable    |
      | Progressing\\s+False\\s+ProgressDeadlineExceeded |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment has minimum availability                       |
      | MinimumReplicasAvailable                                  |
      | status: "True"                                            |
      | type: Available                                           |
      | Replica set "hello-openshift.*" has timed out progressing |
      | ProgressDeadlineExceeded                                  |
      | status: "False"                                           |
      | type: Progressing                                         |
    """
    When I run the :rollout_undo client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable |
      | Progressing\\s+True\\s+NewReplicaSetAvailable |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment has minimum availability                         |
      | MinimumReplicasAvailable                                    |
      | status: "True"                                              |
      | type: Available                                             |
      | Replica set "hello-openshift.*" has successfully progressed |
      | NewReplicaSetAvailable                                      |
      | status: "True"                                              |
      | type: Progressing                                           |
    """

  # @author chezhang@redhat.com
  # @case_id OCP-12110
  Scenario: Add perma-failed - Rolling back to a failing deployment revision
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-perme-failed-3.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable |
      | Progressing\\s+True\\s+NewReplicaSetAvailable |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment has minimum availability                         |
      | MinimumReplicasAvailable                                    |
      | status: "True"                                              |
      | type: Available                                             |
      | Replica set "hello-openshift.*" has successfully progressed |
      | NewReplicaSetAvailable                                      |
      | status: "True"                                              |
      | type: Progressing                                           |
    """
    When I run the :patch client command with:
      | resource      | deployment                                                                                                               |
      | resource_name | hello-openshift                                                                                                          |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hello-openshift","image":"openshift/hello-openshift-noexist-1"}]}}}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable |
      | Progressing\\s+True\\s+ReplicaSetUpdated      |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment has minimum availability            |
      | MinimumReplicasAvailable                       |
      | status: "True"                                 |
      | type: Available                                |
      | Replica set "hello-openshift.*" is progressing |
      | ReplicaSetUpdated                              |
      | status: "True"                                 |
      | type: Progressing                              |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable    |
      | Progressing\\s+False\\s+ProgressDeadlineExceeded |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment has minimum availability                       |
      | MinimumReplicasAvailable                                  |
      | status: "True"                                            |
      | type: Available                                           |
      | Replica set "hello-openshift.*" has timed out progressing |
      | ProgressDeadlineExceeded                                  |
      | status: "False"                                           |
      | type: Progressing                                         |
    """
    When I run the :patch client command with:
      | resource      | deployment                                                                                                               |
      | resource_name | hello-openshift                                                                                                          |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hello-openshift","image":"openshift/hello-openshift-noexist-2"}]}}}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable |
      | Progressing\\s+True\\s+ReplicaSetUpdated      |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment has minimum availability            |
      | MinimumReplicasAvailable                       |
      | status: "True"                                 |
      | type: Available                                |
      | Replica set "hello-openshift.*" is progressing |
      | ReplicaSetUpdated                              |
      | status: "True"                                 |
      | type: Progressing                              |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable    |
      | Progressing\\s+False\\s+ProgressDeadlineExceeded |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment has minimum availability                       |
      | MinimumReplicasAvailable                                  |
      | status: "True"                                            |
      | type: Available                                           |
      | Replica set "hello-openshift.*" has timed out progressing |
      | ProgressDeadlineExceeded                                  |
      | status: "False"                                           |
      | type: Progressing                                         |
    """
    When I run the :rollout_undo client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable |
      | Progressing\\s+True\\s+ReplicaSetUpdated      |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment has minimum availability                     |
      | MinimumReplicasAvailable                                |
      | status: "True"                                          |
      | type: Available                                         |
      | Replica set "hello-openshift.*" is progressing |
      | ReplicaSetUpdated                                       |
      | status: "True"                                          |
      | type: Progressing                                       |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable    |
      | Progressing\\s+False\\s+ProgressDeadlineExceeded |
    When I run the :get client command with:
      | resource  | deployment |
      | o         | yaml       |
    Then the output by order should match:
      | Deployment has minimum availability                       |
      | MinimumReplicasAvailable                                  |
      | status: "True"                                            |
      | type: Available                                           |
      | Replica set "hello-openshift.*" has timed out progressing |
      | ProgressDeadlineExceeded                                  |
      | status: "False"                                           |
      | type: Progressing                                         |
    """

  # @author chezhang@redhat.com
  # @case_id OCP-11865
  Scenario: Add perma-failed - Make a change outside pod template for failing deployment	
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-perme-failed-1.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+False\\s+MinimumReplicasUnavailable |
      | Progressing\\s+True\\s+ReplicaSetUpdated         |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment does not have minimum availability  |
      | MinimumReplicasUnavailable                     |
      | status: "False"                                |
      | type: Available                                |
      | Replica set "hello-openshift.*" is progressing |
      | ReplicaSetUpdated                              |
      | status: "True"                                 |
      | type: Progressing                              |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+False\\s+MinimumReplicasUnavailable |
      | Progressing\\s+False\\s+ProgressDeadlineExceeded |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment does not have minimum availability             |
      | MinimumReplicasUnavailable                                |
      | status: "False"                                           |
      | type: Available                                           |
      | Replica set "hello-openshift.*" has timed out progressing |
      | ProgressDeadlineExceeded                                  |
      | status: "False"                                           |
      | type: Progressing                                         |
    """
    When I run the :patch client command with:
      | resource      | deployment                                                                                                     |
      | resource_name | hello-openshift                                                                                                |
      | p             | {"spec":{"replicas":5}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+False\\s+MinimumReplicasUnavailable |
      | Progressing\\s+True\\s+ReplicaSetUpdated         |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment does not have minimum availability  |
      | MinimumReplicasUnavailable                     |
      | status: "False"                                |
      | type: Available                                |
      | Replica set "hello-openshift.*" is progressing |
      | ReplicaSetUpdated                              |
      | status: "True"                                 |
      | type: Progressing                              |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+False\\s+MinimumReplicasUnavailable |
      | Progressing\\s+False\\s+ProgressDeadlineExceeded |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | Deployment does not have minimum availability             |
      | MinimumReplicasUnavailable                                |
      | status: "False"                                           |
      | type: Available                                           |
      | Replica set "hello-openshift.*" has timed out progressing |
      | ProgressDeadlineExceeded                                  |
      | status: "False"                                           |
      | type: Progressing                                         |
    """

  # @author chezhang@redhat.com
  # @case_id OCP-12009
  Scenario: Add perma-failed - Negative value test of progressDeadlineSeconds in failing deployment	
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment-perme-failed-2.yaml"
    When I run the :create client command with:
      | f | deployment-perme-failed-2.yaml |
    Then the step should fail
    And the output should match:
     | spec.progressDeadlineSeconds: Invalid value.*must be greater than minReadySeconds |
    When I replace lines in "deployment-perme-failed-2.yaml":
      | progressDeadlineSeconds: 0 | progressDeadlineSeconds: -1 |
    Then I run the :create client command with:
      | f | deployment-perme-failed-2.yaml |
    And the step should fail
    And the output should match:
      | spec.progressDeadlineSeconds: Invalid value.*must be greater than or equal to 0 |
      | spec.progressDeadlineSeconds: Invalid value.*must be greater than minReadySeconds |
    When I replace lines in "deployment-perme-failed-2.yaml":
      | progressDeadlineSeconds: -1 | progressDeadlineSeconds: ab |
    Then I run the :create client command with:
      | f | deployment-perme-failed-2.yaml |
    And the step should fail
    And the output should match:
      | cannot be handled as a Deployment.*decNum: got first char 'a' |
    When I replace lines in "deployment-perme-failed-2.yaml":
      | progressDeadlineSeconds: ab | progressDeadlineSeconds: 0.5 |
    Then I run the :create client command with:
      | f | deployment-perme-failed-2.yaml |
    And the step should fail
    And the output should match:
      | cannot be handled as a Deployment.*fractional integer |
  
  # @author: geliu@redhat.com
  # @case_id: OCP-11599
  Scenario: Cleanup policy - Cleanup all previous RSs older than the latest N replica sets in pause
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/hello-deployment-1.yaml |
    Then the step should succeed
    Given 10 pods become ready with labels:
      | app=hello-openshift |
    When I run the :describe client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the output should match:
      | Available\\s+True\\s+MinimumReplicasAvailable |
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | message: Deployment has minimum availability |
      | reason: MinimumReplicasAvailable             |
      | status: "True"                               |
      | type: Available                              | 
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | deployment                                                                                                           |
      | resource_name | hello-openshift                                                                                                      |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"docker.io/aosqe/hello-openshift","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output should match:
      | .*[Ii]mage.*docker.io/aosqe/hello-openshift.* |
    Given 10 pods become ready with labels:  
      | app=hello-openshift |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | deployment                                                                                                        |
      | resource_name | hello-openshift                                                                                                   |
      | p             | {"spec":{"template":{"spec":{"containers":[{"image":"openshift/deployment-example","name":"hello-openshift"}]}}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output should match:
      | .*[Ii]mage.*openshift/deployment-example.* |
    Given 10 pods become ready with labels:  
      | app=hello-openshift |
    Then the step should succeed
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 3               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*openshift/deployment-example.* |
    When I run the :rollout_pause client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed     
    Given 10 pods become ready with labels:  
      | app=hello-openshift |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output by order should match:
      | .*[Pp]aused.*:.*true |
    When I run the :patch client command with:
      | resource      | deployment                          |
      | resource_name | hello-openshift                     |
      | p             | {"spec":{"revisionHistoryLimit":1}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource | deployment |
      | o        | yaml       |
    Then the output should match:
      | .*revisionHistoryLimit.*:.*1.*|
    Given 10 pods become ready with labels:   
      | app=hello-openshift |
    Then the step should succeed
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 2               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*docker.io/aosqe/hello-openshift.* |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 3               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*openshift/deployment-example.* |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 1               |
    Then the step should fail
    And the output should match:
      | .*error.*unable to find the specified revision.* |
    When I run the :rollout_resume client command with:
      | resource | deployment      |
      | name     | hello-openshift |
    Then the step should succeed
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 1               |
    Then the step should fail
    And the output should match:
      | .*error.*unable to find the specified revision.* |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 2               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*docker.io/aosqe/hello-openshift.* |
    When I run the :rollout_history client command with:
      | resource      | deployment      |
      | resource_name | hello-openshift |
      | revision      | 3               |
    Then the step should succeed
    And the output should match:
      | .*[iI]mage.*openshift/deployment-example.* |
