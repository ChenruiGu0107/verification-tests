Feature: HPA relate features

  # @author chezhang@redhat.com
  # @case_id OCP-11205
  Scenario: Creates horizontal pod autoscaler for ReplicationController
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/infrastructure/hpa/rc-hello-hpa.yaml |
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
    When I run the :get client command with:
      | resource | hpa  |
      | o        | yaml |
    Then the step should succeed
    And the output should contain:
      | name: hello-hpa                    |
      | maxReplicas: 10                    |
      | minReplicas: 2                     |
      | targetCPUUtilizationPercentage: 50 |
      | currentCPUUtilizationPercentage: 0 |
      | currentReplicas: 2                 |
    """
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/infrastructure/hpa/hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" status becomes :running within 60 second
    When I run the :exec background client command with:
      | pod              | hello-pod                                         |
      | oc_opts_end      |                                                   |
      | exec_command     | sh                                                |
      | exec_command_arg | -c                                                |
      | exec_command_arg | while true;do curl http://<%= service.url %>;done |
    Then the step should succeed
    Given I wait up to 600 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | hpa       |
      | resource_name | hello-hpa |
      | o             | json      |
    And evaluation of `@result[:parsed]['spec']['targetCPUUtilizationPercentage']` is stored in the :target_cpu clipboard
    And evaluation of `@result[:parsed]['status']['currentCPUUtilizationPercentage']` is stored in the :current_cpu clipboard
    And evaluation of `@result[:parsed]['status']['currentReplicas']` is stored in the :current_replicas clipboard
    Then the expression should be true> cb.target_cpu > cb.current_cpu
    Then the expression should be true> cb.current_replicas > 2
    """
    Given I ensure "hello-pod" pod is deleted
    Given I wait up to 600 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | hpa       |
      | resource_name | hello-hpa |
      | o             | json      |
    And evaluation of `@result[:parsed]['status']['currentCPUUtilizationPercentage']` is stored in the :current_cpu clipboard
    And evaluation of `@result[:parsed]['status']['currentReplicas']` is stored in the :current_replicas clipboard
    Then the expression should be true> cb.current_cpu == 0
    Then the expression should be true> cb.current_replicas == 2
    """

  # @author chezhang@redhat.com
  # @case_id OCP-10730
  Scenario: Creates horizontal pod autoscaler for deploymentConfig
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/infrastructure/hpa/dc-hello-hpa.yaml |
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
    When I run the :get client command with:
      | resource | hpa  |
      | o        | yaml |
    Then the step should succeed
    And the output should contain:
      | name: hello-hpa                    |
      | maxReplicas: 10                    |
      | minReplicas: 2                     |
      | targetCPUUtilizationPercentage: 50 |
      | currentCPUUtilizationPercentage: 0 |
      | currentReplicas: 2                 |
    """
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/infrastructure/hpa/hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" status becomes :running within 60 second
    When I run the :exec background client command with:
      | pod              | hello-pod                                         |
      | oc_opts_end      |                                                   |
      | exec_command     | sh                                                |
      | exec_command_arg | -c                                                |
      | exec_command_arg | while true;do curl http://<%= service.url %>;done |
    Then the step should succeed
    Given I wait up to 600 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | hpa       |
      | resource_name | hello-hpa |
      | o             | json      |
    And evaluation of `@result[:parsed]['spec']['targetCPUUtilizationPercentage']` is stored in the :target_cpu clipboard
    And evaluation of `@result[:parsed]['status']['currentCPUUtilizationPercentage']` is stored in the :current_cpu clipboard
    And evaluation of `@result[:parsed]['status']['currentReplicas']` is stored in the :current_replicas clipboard
    Then the expression should be true> cb.target_cpu > cb.current_cpu
    Then the expression should be true> cb.current_replicas > 2
    """
    Given I ensure "hello-pod" pod is deleted
    Given I wait up to 600 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | hpa       |
      | resource_name | hello-hpa |
      | o             | json      |
    And evaluation of `@result[:parsed]['status']['currentCPUUtilizationPercentage']` is stored in the :current_cpu clipboard
    And evaluation of `@result[:parsed]['status']['currentReplicas']` is stored in the :current_replicas clipboard
    Then the expression should be true> cb.current_cpu == 0
    Then the expression should be true> cb.current_replicas == 2
    """
