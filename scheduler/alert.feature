Feature: Scheduler alert related features
  # @author yinzhou@redhat.com
  # @case_id OCP-26247
  @admin
  Scenario: Alert when pod has a PodDisruptionBudget(minAvailable=1 disruptionsAllowed 0)
    Given I have a project
    When I run the :new_app client command with:
      | template | httpd-example |
    Then the step should succeed
    When I run the :create_poddisruptionbudget client command with:
      | name          | test              |
      | min_available | 1                 |
      | selector      |name=httpd-example |
    Then the step should succeed
    Given status becomes :running of 1 pods labeled:
      | name=httpd-example |
    When I run the :serviceaccounts_get_token admin command with:
      | serviceaccount_name | prometheus-k8s       |
      | n                   | openshift-monitoring |
    Then the step should succeed
    And evaluation of `@result[:stdout]` is stored in the :sa_token clipboard
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring       |
      | pod              | prometheus-k8s-0           |
      | c                | prometheus                 |
      | oc_opts_end      |                            |
      | exec_command     | sh                         |
      | exec_command_arg | -c                         |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" 'https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/query?query=ALERTS%7Balertname%3D%22PodDisruptionBudgetAtLimit%22%7D'|
    Then the step should succeed
    And the output should match 1 times:
      | warning |
    """
    When I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | httpd-example    |
      | replicas | 0                |
    Then the step should succeed
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :exec admin command with:
      | n                | openshift-monitoring       |
      | pod              | prometheus-k8s-0           |
      | c                | prometheus                 |
      | oc_opts_end      |                            |
      | exec_command     | sh                         |
      | exec_command_arg | -c                         |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" 'https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/query?query=ALERTS%7Balertname%3D%22PodDisruptionBudgetLimit%22%7D'|
    Then the step should succeed
    And the output should match 1 times:
      | critical |
    """
