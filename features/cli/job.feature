Feature: job.feature

  # @author cryan@redhat.com
  # @case_id 511597
  Scenario: Create job with multiple completions
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc511597/job.yaml |
    Then the step should succeed
    Given 5 pods become ready with labels:
      | app=pi |
    When I get project pods with labels:
      | app=pi |
    Then the step should succeed
    And the output should contain 5 times:
      |  pi- |
    Given 5 pods become ready with labels:
      | app=pi |
    Given evaluation of `@pods[0].name` is stored in the :pilog clipboard
    Given the pod named "<%= cb.pilog %>" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | <%= cb.pilog %> |
    Then the step should succeed
    And the output should contain "3.14159"
    When I run the :delete client command with:
      | object_type | job |
      | object_name_or_id | pi |
    Then the step should succeed
    Given all existing pods die with labels:
      | app=pi |
    When I get project pods with labels:
      | app=pi |
    Then the step should succeed
    And the output should not contain "pi-"
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc511597/job.yaml" replacing paths:
      | ["spec"]["completions"] | -1 |
    Then the step should fail
    And the output should contain "must be greater than or equal to 0"
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc511597/job.yaml" replacing paths:
      | ["spec"]["completions"] | 0.1 |
    Then the step should fail
    And the output should contain "fractional integer"

  # @author chezhang@redhat.com
  # @case_id 511600
  Scenario: Go through the job example
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job.yaml |
    Then the step should succeed
    When I get project pods
    Then the output should contain 5 times:
      | pi-      |
    Given status becomes :succeeded of exactly 5 pods labeled:
      | app=pi   |
    Then the step should succeed
    And I wait until job "pi" completes
    When I get project jobs
    Then the output should match:
      | pi.*5 |
    When I run the :describe client command with:
      | resource | jobs   |
      | name     | pi     |
    Then the output should match:
      | Name:\\s+pi                               |
      | Image\(s\):\\s+openshift/perl-516-centos7 |
      | Selector:\\s+app=pi                       |
      | Parallelism:\\s+5                         |
      | Completions:\\s+<unset>                   |
      | Labels:\\s+app=pi                         |
      | Pods\\s+Statuses:\\s+0\\s+Running.*5\\s+Succeeded.*0\\s+Failed  |
    And the output should contain 5 times:
      | SuccessfulCreate  |
    When I get project pods
    Then the output should contain 5 times:
      | Completed         |
    When I run the :logs client command with:
      | resource_name     | <%= pod(-5).name %>   |
    Then the step should succeed
    And the output should contain:
      |  3.14159265       |

  # @author qwang@redhat.com
  # @case_id 511598
  Scenario: Create job with pod parallelism
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job_with_0_activeDeadlineSeconds.yaml" replacing paths:
      | ["spec"]["parallelism"]           | 3    |
      | ["spec"]["completions"]           | null |
      | ["spec"]["activeDeadlineSeconds"] | null |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | app=pi |
    When I get project pods with labels:
      | app=pi |
    Then the output should contain 3 times:
      |  zero- |
    # Check job-pod log
    Given evaluation of `@pods[0].name` is stored in the :pilog clipboard
    Given the pod named "<%= cb.pilog %>" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | <%= cb.pilog %> |
    Then the step should succeed
    And the output should contain "3.14159"
    # Delete job and check job and pod
    When I run the :delete client command with:
      | object_type       | job  |
      | object_name_or_id | zero |
    Then the step should succeed
    Given all existing pods die with labels:
      | app=pi |
    When I get project pods with labels:
      | app=pi |
    Then the output should not contain "zero-"
    # Create a job with invalid completions valuse
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job_with_0_activeDeadlineSeconds.yaml" replacing paths:
      | ["spec"]["parallelism"]           | -1   |
      | ["spec"]["completions"]           | null |
      | ["spec"]["activeDeadlineSeconds"] | null |
    Then the step should fail
    And the output should contain:
      | spec.parallelism |
      | must be greater than or equal to 0 |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job_with_0_activeDeadlineSeconds.yaml" replacing paths:
      | ["spec"]["parallelism"]           | 0.1  |
      | ["spec"]["completions"]           | null |
      | ["spec"]["activeDeadlineSeconds"] | null |
    Then the step should fail
    And the output should contain "fractional integer"
    # Create a job with both "parallelism" < "completions"
    Given all existing pods die with labels:
      | app=pi |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job_with_0_activeDeadlineSeconds.yaml" replacing paths:
      | ["spec"]["parallelism"]           | 2    |
      | ["spec"]["completions"]           | 3    |
      | ["spec"]["activeDeadlineSeconds"] | null |
    Then the step should succeed
    When I get project pods with labels:
      | app=pi |
    Then the output should contain 2 times:
      |  zero- |
    Given 3 pods become ready with labels:
      | app=pi |
    When I get project pods with labels:
      | app=pi |
    Then the output should contain 3 times:
      |  zero- |
    # Create a job with both "parallelism" > "completions"
    When I run the :delete client command with:
      | object_type       | job  |
      | object_name_or_id | zero |
    Then the step should succeed
    Given all existing pods die with labels:
      | app=pi |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job_with_0_activeDeadlineSeconds.yaml" replacing paths:
      | ["spec"]["parallelism"]           | 3    |
      | ["spec"]["completions"]           | 2    |
      | ["spec"]["activeDeadlineSeconds"] | null |
    Then the step should succeed
    When I get project pods with labels:
      | app=pi |
    Then the output should contain 2 times:
      |  zero- |
    Given 2 pods become ready with labels:
      | app=pi |
    When I get project pods with labels:
      | app=pi |
    Then the output should contain 2 times:
      |  zero- |

  # @author qwang@redhat.com
  # @case_id 522411
  Scenario: Create job with activeDeadlineSeconds
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/mdshuai/testfile-openshift/master/job/job-runonce.yaml |
    Then the step should succeed
    When I get project job
    Then the output should match:
      | pi-runonce\\s+2\\s+0 |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | job        |
      | name     | pi-runonce |
    Then the output should contain "DeadlineExceeded"
    """

  # @author qwang@redhat.com
  # @case_id 525131
  Scenario: Specifying your own pod selector for job
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job-manualselector.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | job |
      | name     | pi  |
    Then the output should contain "controller-uid=64e92bd2-078d-11e6-a269-fa163e15bd57"
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job_with_0_activeDeadlineSeconds.yaml" replacing paths:
      | ["spec"]["manualSelector"] | false |
    Then the step should fail
    And the output should contain:
      | `selector` not auto-generated |

  # @author qwang@redhat.com
  # @case_id 511596
  Scenario: Create job with different pod restartPolicy
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job-restartpolicy.yaml"
    # Create job without restartPolicy
    And I replace lines in "job-restartpolicy.yaml":
      | from: Never | from: null |
    When I process and create:
      | f | job-restartpolicy.yaml |
    Then the step should fail
    And the output should contain:
      | spec.template.spec.restartPolicy: Unsupported value: "Always": supported values: OnFailure, Never |
    # Create job with restartPolicy=Never
    When I process and create:
      | f | job-restartpolicy.yaml |
      | v | RESTART_POLICY=Never   |
    Then the step should succeed
    And I wait until job "pi-restartpolicy" completes
    When I get project pods
    Then the output should match:
      | Completed\\s+0 |
    When I get project job
    Then the output should match:
      | 1\\s+1 |
    # Create job with restartPolicy=OnFailure
    When I run the :delete client command with:
      | object_type       | job              |
      | object_name_or_id | pi-restartpolicy |
    Then the step should succeed
    Given all existing pods die with labels:
      | app=pi |
    When I process and create:
      | f | job-restartpolicy.yaml   |
      | v | RESTART_POLICY=OnFailure |
    Then the step should succeed
    And I wait until job "pi-restartpolicy" completes
    When I get project pods
    Then the output should match:
      | Completed\\s+0 |
    When I get project job
    Then the output should match:
      | 1\\s+1 |
    # Create job with restartPolicy=Never and make sure the pod never restart even there is error
    When I run the :delete client command with:
      | object_type       | job              |
      | object_name_or_id | pi-restartpolicy |
    Then the step should succeed
    Given all existing pods die with labels:
      | app=pi |
    Given I replace lines in "job-restartpolicy.yaml":
      | openshift/perl-516-centos7 | openshift/perl-516-centos |
    When I process and create:
      | f | job-restartpolicy.yaml |
      | v | RESTART_POLICY=Never   |
    Then the step should succeed
    When I wait for the steps to pass:
    """
    When I get project pods
    Then the output should match:
      | (Err)?ImagePull(BackOff)?\\s+0 |
    """
    When I get project job
    Then the output should match:
      | 1\\s+0 |
    # Create job with restartPolicy=OnFailure and make sure the pod is restared when error
    When I run the :delete client command with:
      | object_type       | job              |
      | object_name_or_id | pi-restartpolicy |
    Then the step should succeed
    Given all existing pods die with labels:
      | app=pi |
    Given I replace lines in "job-restartpolicy.yaml":
      | openshift/perl-516-centos | openshift/perl-516-centos7 |
      | - perl                    | - hello                    |
    When I process and create:
      | f | job-restartpolicy.yaml   |
      | v | RESTART_POLICY=OnFailure |
    Then the step should succeed
    When I wait for the steps to pass:
    """
    When I get project pods
    Then the output should match:
      | CrashLoopBackOff\\s+[1-9][0-9]*? |
    """
    When I get project job
    Then the output should match:
      | 1\\s+0 |
    # Create job with restartPolicy=Always
    When I run the :delete client command with:
      | object_type       | job              |
      | object_name_or_id | pi-restartpolicy |
    Then the step should succeed
    Given all existing pods die with labels:
      | app=pi |
    When I process and create:
      | f | job-restartpolicy.yaml |
      | v | RESTART_POLICY=Always  |
    Then the step should fail
    And the output should contain:
      | spec.template.spec.restartPolicy: Unsupported value: "Always": supported values: OnFailure, Never |
