Feature: oc run related scenarios
  # @author xxia@redhat.com
  Scenario Outline: Create container with oc run command
    Given I have a project
    When I run the :run client command with:
      | _tool        | <tool>                |
      | name         | mysql                 |
      | image        | mysql                 |
      | dry_run      | true                  |
    Then the step should succeed
    When I run the :get client command with:
      | _tool         | <tool>             |
      | resource      | dc                 |
      | resource_name | mysql              |
    Then the step should fail
    When I run the :run client command with:
      | _tool        | <tool>                |
      | name         | webapp                |
      | image        | training/webapp       |
      | -l           | test=one              |
      | limits       | memory=256Mi          |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | test=one |

    When I run the :run client command with:
      | _tool        | <tool>                |
      | name         | webapp2               |
      | image        | training/webapp       |
      | replicas     | 2                     |
      | -l           | label=webapp2         |
      | limits       | memory=256Mi          |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | label=webapp2 |

    When I run the :run client command with:
      | name         | webapp3               |
      | image        | training/webapp       |
      | overrides    | {"spec":{"replicas":2}} |
      | limits       | memory=256Mi          |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc                 |
      | resource_name | webapp3            |
      | output        | yaml               |
    Then the step should succeed
    And the output should contain:
      | replicas: 2   |
    When I run the :run client command with:
      | name      | webapp4             |
      | image     | training/webapp     |
      | attach    | true                |
      | _timeout  | 60                  |
    Then the output should match:
      | command prompt.*pressing enter |
    And a pod becomes ready with labels:
      | run=webapp4 |
    When I run the :run client command with:
      | name      | debug               |
      | image     | centos:7            |
      | -i        | true                |
      | tty       | true                |
      | _timeout  | 90                  |
    Then the output should match:
      | command prompt.*pressing enter |
    And a pod becomes ready with labels:
      | run=debug |
    When I run the :run client command with:
      | name      | debug1              |
      | image     | centos:7            |
      | -i        | true                |
      | _timeout  | 60                  |
    Then the output should match:
      | command prompt.*pressing enter |
    And a pod becomes ready with labels:
      | run=debug1 |

    Examples:
      | tool     |
      | oc       | # @case_id OCP-10673
      | kubectl  | # @case_id OCP-21037

  # @author pruan@redhat.com
  # @case_id OCP-11199
  Scenario: oc run can create dc, standalone rc, standalone pod
    Given I have a project
    When I run the :run client command with:
      | name         | myrun                 |
      | image        | aosqe/hello-openshift |
      | limits       | memory=256Mi          |
    Then the step should succeed
    Given I wait until the status of deployment "myrun" becomes :running
    When I run the :get client command with:
      | resource | dc |
    Then the step should succeed
    And the output should contain:
      | myrun |
    When I run the :get client command with:
      | resource | rc |
    Then the step should succeed
    And the output should contain:
      | myrun-1 |
    When I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    And the output should contain:
      | myrun-1- |
    # Create a standalone rc
    When I run the :run client command with:
      | name         | myrun-rc              |
      | image        | aosqe/hello-openshift |
      | generator    | run-controller/v1     |
      | limits       | memory=256Mi          |
    Then the step should succeed
    Given I wait until replicationController "myrun-rc" is ready
    When I run the :get client command with:
      | resource | dc |
    Then the step should succeed
    And the output should not contain:
      | myrun-rc |
    When I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    And the output should contain:
      | myrun-rc-|
    # Create a standalone pod
    When I run the :run client command with:
      | name         | myrun-pod             |
      | image        | aosqe/hello-openshift |
      | generator    | run-pod/v1            |
      | limits       | memory=256Mi          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | dc |
    Then the step should succeed
    And the output should not contain:
      | myrun-pod |
    When I run the :get client command with:
      | resource | rc |
    Then the step should succeed
    And the output should not contain:
      | myrun-pod |
    When I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    And the output should contain:
      | myrun-pod |

  # @author yadu@redhat.com
  # @case_id OCP-11930
  Scenario: oc run has different default creation types when using different 'restart' option
    Given I have a project
    When I run the :run client command with:
      | name  | test-a                |
      | image | aosqe/hello-openshift |
    Then the step should succeed
    When I run the :get client command with:
      | resource | dc/test-a |
    Then the step should succeed
    When I run the :run client command with:
      | name    | test-b                |
      | image   | aosqe/hello-openshift |
      | restart | OnFailure             |
    Then the step should succeed
    # Track bug 1577770
    When I run the :get client command with:
      | resource | job/test-b |
    Then the step should succeed
    Given I ensure "test-b" job is deleted
    # dc test-a may still be deploying and job test-b's pod may still be terminating.
    # In OSO Starter this will reach quota compute-resources-timebound, making below fail for test-c
    And all existing pods die with labels:
      | run=test-b |
    When I run the :run client command with:
      | name    | test-c                |
      | image   | aosqe/hello-openshift |
      | restart | Never                 |
    Then the step should succeed
    When I run the :get client command with:
      | resource | pod/test-c |
    Then the step should succeed
    Given I ensure "test-c" pod is deleted
    # Negative test
    When I run the :run client command with:
      | name    | test-f                |
      | image   | aosqe/hello-openshift |
      | restart | Invalid               |
    Then the step should fail
    And the output should contain:
      | invalid restart policy |
    When I run the :run client command with:
      | name     | test-n                |
      | image    | aosqe/hello-openshift |
      | restart  | Never                 |
      | replicas | 2                     |
    Then the step should fail
    And the output should contain:
      | error |
    When I run the :run client command with:
      | name     | test-m                |
      | image    | aosqe/hello-openshift |
      | restart  | Never                 |
      | replicas | 1                     |
    Then the step should succeed
    When I run the :get client command with:
      | resource | pod/test-m |
    Then the step should succeed

  # @author yadu@redhat.com
  Scenario Outline: oc run can set various fields in the pod container
    Given I have a project
    When I run the :run client command with:
      | _tool     | <tool>                |
      | name      | myrun-pod             |
      | image     | aosqe/hello-openshift |
      | generator | run-pod/v1            |
      | env       | MYENV1=v1             |
      | env       | MYENV2=v2             |
    Then the step should succeed
    When I run the :get client command with:
      | _tool         | <tool>    |
      | resource      | pod       |
      | resource_name | myrun-pod |
      | o             | json      |
    Then the step should succeed
    And the output should contain:
      | "name": "MYENV1" |
      | "value": "v1     |
      | "name": "MYENV2" |
      | "value": "v2"    |
    # Clear out memory and cpu usage to fit into online quota limits
    Given I ensure "myrun-pod" pod is deleted
    When I run the :run client command with:
      | _tool     | <tool>                |
      | name      | myrun-pod-2           |
      | image     | aosqe/hello-openshift |
      | generator | run-pod/v1            |
      | limits    | cpu=200m,memory=512Mi |
      | requests  | cpu=100m,memory=256Mi |
    Then the step should succeed
    When I run the :get client command with:
      | _tool         | <tool>       |
      | resource      | pod          |
      | resource_name | myrun-pod-2  |
      | o             | json         |
    Then the step should succeed
    And the output should contain:
      |  "limits":          |
      |  "memory": "512Mi"  |
    # Clear out memory and cpu usage to fit into online quota limits
    Given I ensure "myrun-pod-2" pod is deleted
    When I run the :run client command with:
      | _tool     | <tool>                |
      | name      | myrun-pod-3           |
      | image     | aosqe/hello-openshift |
      | generator | run-pod/v1            |
      | restart   | OnFailure             |
    Then the step should succeed
    When I run the :get client command with:
      | _tool         | <tool>       |
      | resource      | pod          |
      | resource_name | myrun-pod-3  |
      | o             | json         |
    Then the step should succeed
    And the output should contain:
      |  "restartPolicy": "OnFailure" |
    # Clear out memory and cpu usage to fit into online quota limits
    Given I ensure "myrun-pod-3" pod is deleted
    When I run the :run client command with:
      | _tool     | <tool>                |
      | name      | myrun-pod-4           |
      | image     | aosqe/hello-openshift |
      | generator | run-pod/v1            |
      | port      | 8888                  |
    Then the step should succeed
    When I run the :get client command with:
      | _tool         | <tool>      |
      | resource      | pod         |
      | resource_name | myrun-pod-4 |
      | o             | json        |
    And the output should contain:
      |  "containerPort": 8888  |
    When I run the :run client command with:
      | _tool     | <tool>                  |
      | name      | test                    |
      | image     | aosqe/hello-openshift   |
      | replicas  | 2                       |
      | overrides | {"spec":{"replicas":3}} |
    Then the step should succeed
    When I run the :get client command with:
      | _tool         | <tool>     |
      | resource      | <resource> |
      | resource_name | test       |
      | o             | json       |
    Then the step should succeed
    And the output should contain:
      | "replicas": 3 |
    When I run the :run client command with:
      | _tool           | <tool>                  |
      | name            | test2                   |
      | image           | aosqe/hello-openshift   |
      | serviceaccount  | fakedeployer            |
    Then the step should succeed
    When I run the :get client command with:
      | _tool         | <tool>     |
      | resource      | <resource> |
      | resource_name | test2      |
      | o             | yaml       |
    Then the step should succeed
    And the output should contain:
      | serviceAccount: fakedeployer |

    Examples:
      | tool     | resource    |
      | oc       | dc          | # @case_id OCP-11759
      | kubectl  | deploy      | # @case_id OCP-21091


  # @author cryan@redhat.com
  # @case_id OCP-11174
  Scenario: Run container via cli with invalid format specifying cpu/memory request/limit
    Given I have a project
    When I run the :run client command with:
      | name | nginx |
      | image | nginx |
      | replicas | 1 |
      | requests | cpu100m,memory=512Mi |
    Then the step should fail
    And the output should contain "Invalid argument syntax"
    When I run the :run client command with:
      | name | nginx |
      | image | nginx |
      | replicas | 2 |
      | limits | cpu100m\&memory=512Mi |
    Then the step should fail
    And the output should contain "Invalid value"
    When I run the :run client command with:
      | name | nginx |
      | image | nginx |
      | replicas | 3 |
      | requests | cpu= |
    Then the step should fail
    And the output should contain "quantities must match the regular expression"
    When I run the :run client command with:
      | name | nginx |
      | image | nginx |
    Then the step should succeed

  # @author yinzhou@redhat.com
  # @case_id OCP-21088
  Scenario: kubectl run can create deploy, standalone rc, standalone pod, and job
    Given I have a project
    When I run the :run client command with:
      | _tool        | kubectl               |
      | name         | myrun                 |
      | image        | aosqe/hello-openshift |
      | limits       | memory=256Mi          |
    Then the step should succeed
    When I run the :get client command with:
      | _tool    | kubectl |
      | resource | deploy  |
    Then the step should succeed
    And the output should contain:
      | myrun |
    When I run the :get client command with:
      | _tool    | kubectl |
      | resource | rs      |
    Then the step should succeed
    And the output should contain:
      | myrun- |
    When I run the :get client command with:
      | _tool    | kubectl |
      | resource | pod     |
    Then the step should succeed
    And the output should contain:
      | myrun- |
    # Create a standalone rc
    When I run the :run client command with:
      | _tool        | kubectl               |
      | name         | myrun-rc              |
      | image        | aosqe/hello-openshift |
      | generator    | run/v1                |
      | limits       | memory=256Mi          |
    Then the step should succeed
    Given I wait until replicationController "myrun-rc" is ready
    When I run the :get client command with:
      | _tool    | kubectl |
      | resource | deploy  |
    Then the step should succeed
    And the output should not contain:
      | myrun-rc |
    When I run the :get client command with:
      | _tool    | kubectl |
      | resource | pod     |
    Then the step should succeed
    And the output should contain:
      | myrun-rc-|
    # Create a standalone pod
    When I run the :run client command with:
      | _tool        | kubectl               |
      | name         | myrun-pod             |
      | image        | aosqe/hello-openshift |
      | generator    | run-pod/v1            |
      | limits       | memory=256Mi          |
    Then the step should succeed
    When I run the :get client command with:
      | _tool    | kubectl |
      | resource | deploy  |
    Then the step should succeed
    And the output should not contain:
      | myrun-pod |
    When I run the :get client command with:
      | _tool    | kubectl |
      | resource | rs      |
    Then the step should succeed
    And the output should not contain:
      | myrun-pod |
    When I run the :get client command with:
      | _tool    | kubectl |
      | resource | pod     |
    Then the step should succeed
    And the output should contain:
      | myrun-pod |
    When I run the :run client command with:
      | _tool        | kubectl               |
      | name         | my-job                |
      | image        | aosqe/hello-openshift |
      | generator    | job/v1                |
      | restart      | OnFailure             |
    Then the step should succeed
    When I run the :get client command with:
      | _tool    | kubectl |
      | resource | job     |
    Then the step should succeed
    And the output should contain:
      | my-job |
    When I run the :run client command with:
      | _tool        | kubectl               |
      | name         | mycron-job            |
      | image        | aosqe/hello-openshift |
      | generator    | cronjob/v1beta1       |
      | restart      | Never                 |
      | schedule     | 5 * * * *             |
    Then the step should succeed
    When I run the :get client command with:
      | _tool    | kubectl |
      | resource | cronjob |
    Then the step should succeed
    And the output should contain:
      | mycron-job |
