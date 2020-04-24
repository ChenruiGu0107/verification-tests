Feature: persist page state
  # @author yanpzhan@redhat.com
  # @case_id OCP-11832
  Scenario: Persist page state when in special tab
    Given the master version >= "3.4"
    Given I have a project
    When I run the :new_app client command with:
      | code         | https://github.com/sclorg/nodejs-ex.git |
      | image_stream | openshift/nodejs:latest                    |
      | name         | nodejs-sample                              |
    Then the step should succeed
    Given the "nodejs-sample-1" build was created

    When I perform the :goto_one_buildconfig_page web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | nodejs-sample       |
    Then the step should succeed

    When I run the :click_on_configuration_tab web console action
    Then the step should succeed
    And the expression should be true> browser.url.end_with? "/nodejs-sample?tab=configuration"

    When I run the :click_on_environment_tab web console action
    Then the step should succeed
    And the expression should be true> browser.url.end_with? "/nodejs-sample?tab=environment"

    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %>   |
      | pod_name     | nodejs-sample-1-build |
    Then the step should succeed
    When I run the :click_on_details_tab web console action
    Then the step should succeed
    And the expression should be true> browser.url.end_with? "/nodejs-sample-1-build?tab=details"

    When I run the :click_on_logs_tab web console action
    Then the step should succeed
    And the expression should be true> browser.url.end_with? "/nodejs-sample-1-build?tab=logs"

    When I run the :click_on_terminal_tab web console action
    Then the step should succeed
    And the expression should be true> browser.url.end_with? "/nodejs-sample-1-build?tab=terminal"

    When I run the :click_on_events_tab web console action
    Then the step should succeed
    And the expression should be true> browser.url.end_with? "/nodejs-sample-1-build?tab=events"


  # @author yanpzhan@redhat.com
  # @case_id OCP-11361
  Scenario: Persist page state when check on Monitoring page
    Given the master version >= "3.4"
    Given I have a project
    When I perform the :set_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | All                 |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Given the expression should be true> browser.url.end_with? "monitoring?hideOlderResources=true&kind=All"
    """

    When I perform the :set_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Pods                |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Given the expression should be true> browser.url.end_with? "/monitoring?hideOlderResources=true&kind=Pods"
    """

    When I perform the :set_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Deployments         |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Given the expression should be true> browser.url.end_with? "/monitoring?hideOlderResources=true&kind=ReplicationControllers"
    """

    When I perform the :set_resource_type_on_monitoring web console action with:
      | project_name  | <%= project.name %> |
      | resource_type | Builds              |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Given the expression should be true> browser.url.end_with? "/monitoring?hideOlderResources=true&kind=Builds"
    """

  # @author yanpzhan@redhat.com
  # @case_id OCP-11642
  Scenario: Persist page state when filter by kind on other resource page
    Given the master version >= "3.4"
    Given I have a project
    When I perform the :goto_other_resources_page web console action with:
      | project_name  | <%= project.name %> |
    Then the step should succeed

    And I wait for the steps to pass:
    """
    When I perform the :choose_resource_type web console action with:
      | resource_type | Daemon Set |
    Then the step should succeed
    Given the expression should be true> browser.url.include? "/other?kind=DaemonSet"
    """

    And I wait for the steps to pass:
    """
    When I perform the :choose_resource_type web console action with:
      | resource_type | Template |
    Then the step should succeed
    Given the expression should be true> browser.url.include? "/other?kind=Template"
    """

    And I wait for the steps to pass:
    """
    When I perform the :choose_resource_type web console action with:
      | resource_type | Endpoints |
    Then the step should succeed
    Given the expression should be true> browser.url.include? "/other?kind=Endpoints"
    """

    And I wait for the steps to pass:
    """
    When I perform the :choose_resource_type web console action with:
      | resource_type | Horizontal Pod Autoscaler |
    Then the step should succeed
    Given the expression should be true> browser.url.include? "/other?kind=HorizontalPodAutoscaler"
    """

    And I wait for the steps to pass:
    """
    When I perform the :choose_resource_type web console action with:
      | resource_type | Job |
    Then the step should succeed
    Given the expression should be true> browser.url.include? "/other?kind=Job"
    """

    And I wait for the steps to pass:
    """
    When I perform the :choose_resource_type web console action with:
      | resource_type | Service Account |
    Then the step should succeed
    Given the expression should be true> browser.url.include? "/other?kind=ServiceAccount"
    """
