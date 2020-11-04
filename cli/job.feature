Feature: job.feature
  # @author geliu@redhat.com
  # @case_id OCP-17514
  Scenario: The subsequent Cronjob should be suspend when set suppend flag to true
    Given I have a project
    When I run the :create_cronjob client command with:
      | name             | sj1       |
      | image            | busybox   |
      | restart          | Never     |
      | schedule         | * * * * * |
      | oc_opts_end      |           |
      | exec_command     | sleep     |
      | exec_command_arg | 30        |
    Then the step should succeed
    Then status becomes :running of 1 pods labeled:
      | job-name |
    When I run the :patch client command with:
      | resource      | cronjob                   |
      | resource_name | sj1                       |
      | p             | {"spec":{"suspend":true}} |
    Then the step should succeed
    Given 60 seconds have passed
    When I run the :delete client command with:
      | object_type | pod      |
      | l           | job-name |
    Then the step should succeed
    Given 60 seconds have passed
    And I check that there are no pods in the project
    When I run the :patch client command with:
      | resource      | cronjob                    |
      | resource_name | sj1                        |
      | p             | {"spec":{"suspend":false}} |
    Then the step should succeed
    Then status becomes :running of 1 pods labeled:
      | job-name |

  # @author geliu@redhat.com
  # @case_id OCP-17511
  Scenario: Cronjob with spec.startingDeadlineSeconds
    Given I have a project
    Given I obtain test data file "job/cronjob_3.9_with_startingDeadlineSeconds.yaml"
    When I run the :create client command with:
      | f | cronjob_3.9_with_startingDeadlineSeconds.yaml |
    Then the step should succeed
    Then status becomes :running of 1 pods labeled:
      | run=sj3 |
    When I run the :patch client command with:
      | resource      | cronjob                                  |
      | resource_name | sj3                                      |
      | p             | {"spec":{"startingDeadlineSeconds":100}} |
    Then the step should succeed
    Given 70 seconds have passed
    When I run the :delete client command with:
      | object_type | pod     |
      | l           | run=sj3 |
    Then the step should succeed
    Given 70 seconds have passed
    Given status becomes :running of 1 pods labeled:
      | run=sj3 |

  # @author geliu@redhat.com
  # @case_id OCP-17513
  Scenario: User can schedule(Cronjob) a job execution with different concurrencypolicy
    Given I have a project
    When I run the :create_cronjob client command with:
      | name             | sj1       |
      | image            | busybox   |
      | restart          | Never     |
      | schedule         | * * * * * |
      | oc_opts_end      |           |
      | exec_command     | sleep     |
      | exec_command_arg | 180       |
    Then the step should succeed
    Then status becomes :running of 1 pods labeled:
      | job-name |
    Given a pod becomes ready with labels:
      | job-name |
    And evaluation of `pod.name` is stored in the :podname1 clipboard
    When I run the :patch client command with:
      | resource      | cronjob                                  |
      | resource_name | sj1                                      |
      | p             | {"spec":{"concurrencyPolicy":"Replace"}} |
    Then the step should succeed
    Given 90 seconds have passed
    Then status becomes :running of 1 pods labeled:
      | job-name |
    And evaluation of `pod.name` is stored in the :podname2 clipboard
    And the expression should be true> cb.podname1 != cb.podname2
    When I run the :delete client command with:
      | object_type | pod      |
      | l           | job-name |
    Then the step should succeed
    When status becomes :running of 1 pods labeled:
      | job-name |
    And evaluation of `pod.name` is stored in the :podname3 clipboard
    When I run the :patch client command with:
      | resource      | cronjob                                 |
      | resource_name | sj1                                     |
      | p             | {"spec":{"concurrencyPolicy":"Forbid"}} |
    Then the step should succeed
    Given 90 seconds have passed
    Then status becomes :running of 1 pods labeled:
      | job-name |
    And evaluation of `pod.name` is stored in the :podname4 clipboard
    And the expression should be true> cb.podname3 == cb.podname4
    When I run the :patch client command with:
      | resource      | cronjob                                |
      | resource_name | sj1                                    |
      | p             | {"spec":{"concurrencyPolicy":"Allow"}} |
    Then the step should succeed
    Given 90 seconds have passed
    Then status becomes :running of 2 pods labeled:
      | job-name |

  # @author yinzhou@redhat.com
  # @case_id OCP-28003
  Scenario: `oc status` run well when job's spec pointer is nil
    Given I have a project
    Given I obtain test data file "job/job.yaml"
    When I run the :create client command with:
      | f | job.yaml |
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

  # @author yinzhou@redhat.com
  # @case_id OCP-15562
  @admin
  Scenario: Controllers burst via slow start - jobs
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/pod-quota.yaml |
      | n | <%= project.name %>                                                                     |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job_with_long_activeDeadlineSeconds.yaml" replacing paths:
      | ["spec"]["parallelism"] | 15 |
      | ["spec"]["completions"] | 15 |
    Then the step should succeed
    Then status becomes :running of 2 pods labeled:
      | app=pi |
    When I get project events
    Then the output should match:
      | is forbidden: exceeded quota: myquota, requested: pods=1, used: pods=2, limited: pods=2 |

  # @author yinzhou@redhat.com
  # @case_id OCP-29654
  @admin
  Scenario: Create job from exist cronjob
    Given the master version >= "4.5"
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run the :create_cronjob admin command with:
      | name     | cronjob-29654                                                                                                 |
      | image    | quay.io/openshifttest/hello-openshift@sha256:aaea76ff622d2f8bcb32e538e7b3cd0ef6d291953f3e7c9f556c1ba5baf47e2e |
      | schedule | * 5 * * ?                                                                                                     |
    Then the step should succeed
    And I check that the "cronjob-29654" cronjob exists in the project
    When I run the :create_job admin command with:
      | name | hello-job             |
      | from | cronjob/cronjob-29654 |
    Then the step should succeed
    And I check that the "hello-job" job exists in the project

  # @author knarra@redhat.com
  # @case_id OCP-34224
  Scenario: Normal user should be able to create job from existing cronjob
    Given the master version >= "4.4"
    Given I have a project
    When I run the :create_cronjob client command with:
      | name     | cronjob-34224                                                                                                 |
      | image    | quay.io/openshifttest/hello-openshift@sha256:aaea76ff622d2f8bcb32e538e7b3cd0ef6d291953f3e7c9f556c1ba5baf47e2e |
      | schedule | * 5 * * ?                                                                                                     |
    Then the step should succeed
    And I check that the "cronjob-34224" cronjob exists in the project
    When I run the :create_job client command with:
      | name | hello-job             |
      | from | cronjob/cronjob-34224 |
    Then the step should succeed
    And I check that the "hello-job" job exists in the project
