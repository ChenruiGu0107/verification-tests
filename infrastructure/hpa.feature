Feature: HPA relate features

  # @author chezhang@redhat.com
  # @case_id OCP-11205
  Scenario: Creates horizontal pod autoscaler for ReplicationController
    Given I have a project
    Given I obtain test data file "infrastructure/hpa/rc-hello-hpa.yaml"
    When I run the :create client command with:
      | f | rc-hello-hpa.yaml |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | run=hello-hpa |
    When I run the :expose client command with:
      | resource      | rc        |
      | resource name | hello-hpa |
      | port          | 8080      |
    Given I wait for the "hello-hpa" service to become ready
    When I run the :autoscale client command with:
      | name        | rc/hello-hpa |
      | min         | 2            |
      | max         | 10           |
      | cpu-percent | 50           |
    Then the step should succeed
    Given I wait up to 300 seconds for the steps to pass:
    """
    Then expression should be true> hpa('hello-hpa').min_replicas(cached: false, user: user) == 2
    And expression should be true> hpa.max_replicas == 10
    And expression should be true> hpa.current_cpu_utilization_percentage == 0
    And expression should be true> hpa.target_cpu_utilization_percentage == 50
    And expression should be true> hpa.current_replicas == 2
    """
    Given I obtain test data file "infrastructure/hpa/hello-pod.yaml"
    When I run the :create client command with:
      | f | hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" status becomes :running within 60 seconds
    When I run the :exec background client command with:
      | pod              | hello-pod                                                             |
      | oc_opts_end      |                                                                       |
      | exec_command     | sh                                                                    |
      | exec_command_arg | -c                                                                    |
      | exec_command_arg | while true ; do curl -sS http://<%= service.url %> > /dev/null ; done |
    Then the step should succeed
    Given I wait up to 600 seconds for the steps to pass:
    """
    Then expression should be true> hpa('hello-hpa').current_replicas(cached: false, user: user) > 2
    And expression should be true> hpa.current_cpu_utilization_percentage > hpa.target_cpu_utilization_percentage
    """
    Given I ensure "hello-pod" pod is deleted
    Given I wait up to 600 seconds for the steps to pass:
    """
    Then expression should be true> hpa('hello-hpa').current_cpu_utilization_percentage(cached: false, user: user) == 0
    And expression should be true> hpa.current_replicas == 2
    """

  # @author chezhang@redhat.com
  # @case_id OCP-10730
  Scenario: Creates horizontal pod autoscaler for deploymentConfig
    Given I have a project
    Given I obtain test data file "infrastructure/hpa/dc-hello-hpa.yaml"
    When I run the :create client command with:
      | f | dc-hello-hpa.yaml |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | run=hello-hpa |
    When I run the :expose client command with:
      | resource      | rc          |
      | resource name | hello-hpa-1 |
      | port          | 8080        |
    Given I wait for the "hello-hpa-1" service to become ready
    When I run the :autoscale client command with:
      | name        | dc/hello-hpa |
      | min         | 2            |
      | max         | 10           |
      | cpu-percent | 50           |
    Then the step should succeed
    Given I wait up to 300 seconds for the steps to pass:
    """
    Then expression should be true> hpa('hello-hpa').min_replicas(cached: false, user: user) == 2
    And expression should be true> hpa.max_replicas == 10
    And expression should be true> hpa.current_cpu_utilization_percentage == 0
    And expression should be true> hpa.target_cpu_utilization_percentage == 50
    And expression should be true> hpa.current_replicas == 2
    """
    Given I obtain test data file "infrastructure/hpa/hello-pod.yaml"
    When I run the :create client command with:
      | f | hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" status becomes :running within 60 seconds
    When I run the :exec background client command with:
      | pod              | hello-pod                                                             |
      | oc_opts_end      |                                                                       |
      | exec_command     | sh                                                                    |
      | exec_command_arg | -c                                                                    |
      | exec_command_arg | while true ; do curl -sS http://<%= service.url %> > /dev/null ; done |
    Then the step should succeed
    Given I wait up to 600 seconds for the steps to pass:
    """
    Then expression should be true> hpa('hello-hpa').current_replicas(cached: false, user: user) > 2
    And expression should be true> hpa.current_cpu_utilization_percentage > hpa.target_cpu_utilization_percentage
    """
    Given I ensure "hello-pod" pod is deleted
    Given I wait up to 600 seconds for the steps to pass:
    """
    Then expression should be true> hpa('hello-hpa').current_cpu_utilization_percentage(cached: false, user: user) == 0
    And expression should be true> hpa.current_replicas == 2
    """

  # @author weinliu@redhat.com
  # @case_id OCP-17587
  Scenario: HPA v2beta1 support scaling with ResourceMetricSource - cpu
    Given I have a project
    Given I obtain test data file "infrastructure/hpa/hpa-v2beta1-rc.yaml"
    When I run the :create client command with:
      | f | hpa-v2beta1-rc.yaml |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | run=hello-openshift |
    When I run the :expose client command with:
      | resource      | rc              |
      | resource name | hello-openshift |
      | port          | 8080            |
    Given I wait for the "hello-openshift" service to become ready
    Given I obtain test data file "infrastructure/hpa/resource-metrics-cpu.yaml"
    When I run the :create client command with:
      | f | resource-metrics-cpu.yaml |
    Then the step should succeed
    Given I wait up to 300 seconds for the steps to pass:
    """
    Then expression should be true> hpa('resource-cpu').min_replicas(cached: false) == 2
    And expression should be true> hpa.max_replicas == 10
    And expression should be true> hpa.current_cpu_utilization_percentage == 0
    And expression should be true> hpa.target_cpu_utilization_percentage == 20
    And expression should be true> hpa.current_replicas == 2
    """
    Given I obtain test data file "infrastructure/hpa/hello-pod.yaml"
    When I run the :create client command with:
      | f | hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" status becomes :running within 60 seconds
    When I run the :exec background client command with:
      | pod              | hello-pod                                                       |
      | oc_opts_end      |                                                                 |
      | exec_command     | sh                                                              |
      | exec_command_arg | -c                                                              |
      | exec_command_arg | while true;do curl -sS http://<%= service.url %>>/dev/null;done |
    Then the step should succeed
    Given I wait up to 600 seconds for the steps to pass:
    """
    Then expression should be true> hpa('resource-cpu').current_replicas(cached: false) > 2
    And expression should be true> hpa.current_cpu_utilization_percentage > hpa.target_cpu_utilization_percentage
    """
    Given I ensure "hello-pod" pod is deleted
    Given I wait up to 600 seconds for the steps to pass:
    """
    Then expression should be true> hpa('resource-cpu').current_cpu_utilization_percentage(cached: false) == 0
    And expression should be true> hpa.current_replicas == 2
    """

  # @author weinliu@redhat.com
  # @case_id OCP-17594
  Scenario: HPA v2beta1 support scaling with ResourceMetricSource - memory
    Given I have a project
    Given I obtain test data file "infrastructure/hpa/hello-hpa-memory-rc.yaml"
    When I run the :create client command with:
      | f | hello-hpa-memory-rc.yaml |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | run=hello-hpa-memory |
    When I run the :expose client command with:
      | resource      | rc               |
      | resource name | hello-hpa-memory |
      | port          | 8080             |
    Given I wait for the "hello-hpa-memory" service to become ready
    Given I obtain test data file "infrastructure/hpa/resource-metrics-memory.yaml"
    When I run the :create client command with:
      | f | resource-metrics-memory.yaml |
    Then the step should succeed
    Given I wait up to 200 seconds for the steps to pass:
    """
    Then expression should be true> hpa('resource-memory').min_replicas(cached: false) == 1
    And expression should be true> hpa.max_replicas == 10
    And expression should be true> hpa.current_replicas == 2
    """
    Given I obtain test data file "infrastructure/hpa/hello-pod.yaml"
    When I run the :create client command with:
      | f | hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" status becomes :running within 60 seconds
    When I execute on the pod:
      | curl                                 |
      | --data                               |
      | megabytes=1000&durationSec=600       |
      | http://<%= service.url %>/ConsumeMem |
    Then the step should succeed
    Given I wait up to 600 seconds for the steps to pass:
    """
    Then expression should be true> hpa('resource-memory').current_replicas(cached: false) > 2
    """
