Feature: HPA relate features

  # @author chezhang@redhat.com
  # @case_id OCP-11205
  Scenario: Creates horizontal pod autoscaler for ReplicationController
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/infrastructure/hpa/rc-hello-hpa.yaml |
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
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/infrastructure/hpa/hello-pod.yaml |
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
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/infrastructure/hpa/dc-hello-hpa.yaml |
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
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/infrastructure/hpa/hello-pod.yaml |
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
