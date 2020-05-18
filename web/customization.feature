Feature: web console customization related features

  # @author xiaocwan@redhat.com
  # @case_id OCP-15364
  @destructive
  @admin
  Scenario: Check System Alerts on Masthead as online message
    Given the master version >= "3.9"
    And system verification steps are used:
    """
    I switch to cluster admin pseudo user
    I use the "openshift-web-console" project
    I wait up to 360 seconds for the steps to pass:
      | Given a pod becomes ready with labels:                      |
      |  \| webconsole=true \|                                      |
      | When admin executes on the pod:                             |
      |  \| cat \| /var/webconsole-config/webconsole-config.yaml \| |
      | Then the step should succeed                                |
      | And the output should not contain "system-status.js"        |
    """
    ## redeploy pod to make restored configmap work in tear-down
    And the "webconsole-config" configmap is recreated by admin in the "openshift-web-console" project after scenario
    And a pod becomes ready with labels:
      | webconsole=true |
    When value of "webconsole-config.yaml" in configmap "webconsole-config" as YAML is merged with:
    """
    extensions:
      scriptURLs:
      - "https://rawgit.com/openshift-qe/v3-testfiles/master/extensions/system-status.js"
    """
    Then I wait up to 360 seconds for the steps to pass:
    """
    Given a pod becomes ready with labels:
      | webconsole=true |
    When admin executes on the pod:
      | cat | /var/webconsole-config/webconsole-config.yaml |
    Then the step should succeed
    And the output should contain "system-status.js"
    """

    ## check web-console
    Given I switch to the first user
    And I have a project
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :systemstatus_warning web console action with:
      | text | open issues |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-17848
  @destructive
  @admin
  Scenario: Enable ClusterResourceOverrides for web console
    Given the master version >= "3.9"

    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        ClusterResourceOverride:
          configuration:
            apiVersion: v1
            kind: ClusterResourceOverrideConfig
            limitCPUToMemoryPercent: 200
            cpuRequestToLimitPercent: 25
            memoryRequestToLimitPercent: 25
    """
    Given the master service is restarted on all master nodes

    Given I have a project
    Then evaluation of `project.name` is stored in the :project clipboard
    When I run the :run client command with:
      | name      | testdc                |
      | image     | aosqe/hello-openshift |
    Then the step should succeed

    When I perform the :goto_set_resource_limits_for_dc web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | testdc              |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should contain:
      | CPU     |
      | Request |
      | Limit   |
      | Memory  |
    """
    And system verification steps are used:
    """
    I switch to cluster admin pseudo user
    I use the "openshift-web-console" project
    I wait up to 360 seconds for the steps to pass:
      | Given a pod becomes ready with labels:                                    |
      |  \| webconsole=true \|                                                    |
      | When admin executes on the pod:                                           |
      |  \| cat \| /var/webconsole-config/webconsole-config.yaml \|               |
      | Then the step should succeed                                              |
      | And the output should not contain "clusterResourceOverridesEnabled: true" |
    """
    ## redeploy pod to make restored configmap work in tear-down
    And the "webconsole-config" configmap is recreated by admin in the "openshift-web-console" project after scenario
    And a pod becomes ready with labels:
      | webconsole=true |
    Given I use the first master host
    And value of "webconsole-config.yaml" in configmap "webconsole-config" as YAML is merged with:
    """
    features:
      clusterResourceOverridesEnabled: true
    """
    Then I wait up to 360 seconds for the steps to pass:
    """
    Given a pod becomes ready with labels:
      | webconsole=true |
    When admin executes on the pod:
      | cat | /var/webconsole-config/webconsole-config.yaml |
    Then the step should succeed
    And the output should contain "clusterResourceOverridesEnabled: true"
    """

    Given I switch to the first user
    And I use the "<%= cb.project %>" project
    Given I wait for the steps to pass:
    """
    When I perform the :goto_set_resource_limits_for_dc web console action with:
      | project_name | <%= cb.project %> |
      | dc_name      | testdc            |
    Then the step should succeed
    When I perform the :check_page_contain_text web console action with:
      | text | Memory |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web console action with:
      | text | CPU |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web console action with:
      | text | Request |
    Then the step should succeed
    """
    When I perform the :set_resource_limit_single web console action with:
      | resource_type   | memory     |
      | limit_type      |            |
      | amount_unit     | MB         |
      | resource_amount | 100        |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed

    Given a pod is present with labels:
      | deployment=testdc-2 |
    When I perform the :goto_one_dc_page web console action with:
      | project_name | <%= cb.project %> |
      | dc_name      | testdc            |
    Then the step should succeed
    When I run the :click_on_configuration_tab web console action
    Then the step should succeed
    When I perform the :check_memory_in_pod_template web console action with:
      | container_name | testdc       |
      | memory_range   | 100 MB limit |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should not contain "CPU"
    """
    When I perform the :check_limits_on_pod_page web console action with:
      | project_name   | <%= cb.project %>               |
      | pod_name       | <%= pod.name %>                 |
      | container_name | testdc                          |
      | cpu_range      | 46 millicores to 186 millicores |
      | memory_range   | 25 MB to 100 MB                 |
    Then the step should succeed
