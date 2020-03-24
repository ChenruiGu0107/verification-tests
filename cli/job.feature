Feature: job.feature

  # @author geliu@redhat.com
  # @case_id OCP-11363
  Scenario: The subsequent scheduled job should be suspend when set suppend flag to true
    Given I have a project
    When I run the :run client command with:
      | name    | sj1       |
      | image   | busybox   |
      | restart | Never     |
      | schedule| * * * * * |
      | sleep   | 30        |
    Then the step should succeed
    Then status becomes :running of 1 pods labeled:  
      | run=sj1 | 
    When I run the :patch client command with:
      | resource      | scheduledjob              |
      | resource_name | sj1                       |
      | p             | {"spec":{"suspend":true}} |
    Then the step should succeed
    Given 60 seconds have passed
    When I run the :delete client command with:
      | object_type | pod             |
      | l           | run=sj1         |
    Then the step should succeed
    Given 60 seconds have passed
    When I get project pods as JSON
    And evaluation of `@result[:parsed]['items']` is stored in the :podlist clipboard
    And the expression should be true> cb.podlist.empty? 
    When I run the :patch client command with:
      | resource      | scheduledjob               |
      | resource_name | sj1                        |
      | p             | {"spec":{"suspend":false}} |
    Then the step should succeed
    Then status becomes :running of 1 pods labeled:
      | run=sj1 |
    
  # @author geliu@redhat.com
  # @case_id OCP-17514
  Scenario: The subsequent Cronjob should be suspend when set suppend flag to true
    Given I have a project
    When I run the :run client command with:
      | name     | sj1       |
      | image    | busybox   |
      | restart  | Never     |
      | schedule | * * * * * |
      | sleep    | 30        |
    Then the step should succeed
    Then status becomes :running of 1 pods labeled:  
      | run=sj1 | 
    When I run the :patch client command with:
      | resource      | cronjob                   |
      | resource_name | sj1                       |
      | p             | {"spec":{"suspend":true}} |
    Then the step should succeed
    Given 60 seconds have passed
    When I run the :delete client command with:
      | object_type | pod             |
      | l           | run=sj1         |
    Then the step should succeed
    Given 60 seconds have passed
    And I check that there are no pods in the project
    When I run the :patch client command with:
      | resource      | cronjob                    |
      | resource_name | sj1                        |
      | p             | {"spec":{"suspend":false}} |
    Then the step should succeed
    Then status becomes :running of 1 pods labeled:
      | run=sj1 |

  # @author geliu@redhat.com
  # @case_id OCP-10968
  Scenario: Schedule job with spec.startingDeadlineSeconds
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/job/scheduledjob_with_startingDeadlineSeconds.yaml |
    Then the step should succeed
    Then status becomes :running of 1 pods labeled:
      | run=sj3 |
    When I run the :patch client command with:
      | resource      | scheduledjob                           |
      | resource_name | sj3                                    |
      | p             | {"spec":{"startingDeadlineSeconds":1}} |
    Then the step should succeed
    Given 70 seconds have passed
    When I run the :delete client command with:
      | object_type | pod             |
      | l           | run=sj3         |
    Then the step should succeed
    Given 70 seconds have passed
    When I get project pods as JSON
    And evaluation of `@result[:parsed]['items']` is stored in the :podlist clipboard
    And the expression should be true> cb.podlist.empty? 

  # @author geliu@redhat.com
  # @case_id OCP-17511
  Scenario: Cronjob with spec.startingDeadlineSeconds
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/job/cronjob_3.9_with_startingDeadlineSeconds.yaml |
    Then the step should succeed
    Then status becomes :running of 1 pods labeled:
      | run=sj3 |
    When I run the :patch client command with:
      | resource      | cronjob                           |
      | resource_name | sj3                                    |
      | p             | {"spec":{"startingDeadlineSeconds":1}} |
    Then the step should succeed
    Given 70 seconds have passed
    When I run the :delete client command with:
      | object_type | pod             |
      | l           | run=sj3         |
    Then the step should succeed
    Given 70 seconds have passed
    And I check that there are no pods in the project

  # @author geliu@redhat.com
  # @case_id OCP-11835
  Scenario: User can schedule a job execution with different concurrencypolicy
    Given I have a project
    When I run the :run client command with:
      | name    | sj1       |
      | image   | busybox   |
      | restart | Never     |
      | schedule| * * * * * |
      | sleep   | 180       |
    Then the step should succeed
    Then status becomes :running of 1 pods labeled:
      | run=sj1 |
    Given a pod becomes ready with labels:
      | run=sj1 |
    And evaluation of `pod.name` is stored in the :podname1 clipboard
    When I run the :patch client command with:
      | resource      | scheduledjob                             |
      | resource_name | sj1                                      |
      | p             | {"spec":{"concurrencyPolicy":"Replace"}} |
    Then the step should succeed
    Given 90 seconds have passed
    Then status becomes :running of 1 pods labeled:
      | run=sj1 |
    And evaluation of `pod.name` is stored in the :podname2 clipboard
    And the expression should be true> cb.podname1 != cb.podname2
    When I run the :delete client command with:
      | object_type | pod     |
      | l           | run=sj1 |
    Then the step should succeed
    When status becomes :running of 1 pods labeled:
      | run=sj1 |
    When I run the :patch client command with:
      | resource      | scheduledjob                            |
      | resource_name | sj1                                     |
      | p             | {"spec":{"concurrencyPolicy":"Forbid"}} |
    Then the step should succeed
    Given 90 seconds have passed
    When I get project pods as JSON
    Given I store in the clipboard the pods labeled: 
      | run=sj1 |
    Then the expression should be true> cb.pods.length == 1
    When I run the :patch client command with:
      | resource      | scheduledjob                           |
      | resource_name | sj1                                    |
      | p             | {"spec":{"concurrencyPolicy":"Allow"}} |
    Then the step should succeed
    Given 90 seconds have passed
    When I get project pods as JSON
    Given I store in the clipboard the pods labeled:
      | run=sj1 |
    Then the expression should be true> cb.pods.length > 1

  # @author geliu@redhat.com
  # @case_id OCP-17513
  Scenario: User can schedule(Cronjob) a job execution with different concurrencypolicy
    Given I have a project
    When I run the :run client command with:
      | name     | sj1       |
      | image    | busybox   |
      | restart  | Never     |
      | schedule | * * * * * |
      | sleep    | 180       |
    Then the step should succeed
    Then status becomes :running of 1 pods labeled:
      | run=sj1 |
    Given a pod becomes ready with labels:
      | run=sj1 |
    And evaluation of `pod.name` is stored in the :podname1 clipboard
    When I run the :patch client command with:
      | resource      | cronjob                                  |
      | resource_name | sj1                                      |
      | p             | {"spec":{"concurrencyPolicy":"Replace"}} |
    Then the step should succeed
    Given 90 seconds have passed
    Then status becomes :running of 1 pods labeled:
      | run=sj1 |
    And evaluation of `pod.name` is stored in the :podname2 clipboard
    And the expression should be true> cb.podname1 != cb.podname2
    When I run the :delete client command with:
      | object_type | pod     |
      | l           | run=sj1 |
    Then the step should succeed
    When status becomes :running of 1 pods labeled:
      | run=sj1 |
    And evaluation of `pod.name` is stored in the :podname3 clipboard
    When I run the :patch client command with:
      | resource      | cronjob                                 |
      | resource_name | sj1                                     |
      | p             | {"spec":{"concurrencyPolicy":"Forbid"}} |
    Then the step should succeed
    Given 90 seconds have passed
    Then status becomes :running of 1 pods labeled:
      | run=sj1 |
    And evaluation of `pod.name` is stored in the :podname4 clipboard
    And the expression should be true> cb.podname3 == cb.podname4
    When I run the :patch client command with:
      | resource      | cronjob                                |
      | resource_name | sj1                                    |
      | p             | {"spec":{"concurrencyPolicy":"Allow"}} |
    Then the step should succeed
    Given 90 seconds have passed
    Then status becomes :running of 2 pods labeled:
      | run=sj1 |     
  
  # @author yinzhou@redhat.com
  # @case_id OCP-28003
  Scenario: `oc status` run well when job's spec pointer is nil
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/job/job.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | job                   |
      | resource_name | pi                    |
      | template      | {{.spec.Completions}} |
    Then the step should succeed
    And the output should contain:
      | <no value> |
    When I run the :status client command
    Then the step should succeed
    And the output should match:
      | job/pi manages |
