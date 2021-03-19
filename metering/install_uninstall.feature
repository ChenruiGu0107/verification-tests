Feature: Install and uninstall related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-22073
  @admin
  @destructive
  @flaky
  Scenario: install metering via OLM
    Given the master version >= "4.1"
    Given metering service has been installed successfully using OLM

  # @author pruan@redhat.com
  # @case_id OCP-22105
  @admin
  @destructive
  Scenario: uninstall metering via OLM
    Given the master version >= "4.1"
    Given metering service has been installed successfully using OLM
    Given the "<%= cb.metering_namespace.name %>" metering service is uninstalled using OLM

  # @author pruan@redhat.com
  # @case_id OCP-22527
  @admin
  @destructive
  @flaky
  Scenario: install metering using Openshift webconsole via Operator Hub link
    # must make sure we don't have an existing project.
    Given the "openshift-metering" metering service is uninstalled using OLM
    Given I set operator channel
    And evaluation of `project('openshift-metering')` is stored in the :metering_namespace clipboard
    Given I switch to the first user
    Given the first user is cluster-admin
    Given I run the :create_namespace client command with:
      | name | openshift-metering |
    And I use the "openshift-metering" project
    When I open admin console in a browser
    Then the step should succeed
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | metering-ocp        |
      | catalog_name     | qe-app-registry     |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    And I perform the :set_custom_channel_and_subscribe web action with:
      | update_channel    | <%= cb.channel %> |
      | install_mode      | OwnNamespace      |
      | approval_strategy | Automatic         |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=metering-operator |
    # apply meteringconfig
    And I run oc create over ERB test file: metering/configs/meteringconfig_hdfs.yaml
    Given all metering related pods are running in the project
    Given all reportdatasources are importing from Prometheus

  # @author pruan@redhat.com
  # @case_id OCP-22557
  @admin
  @destructive
  Scenario: uninstall metering using Openshift webconsole via Operator Hub link
    Given the metering service is installed using OLM
    Given the first user is cluster-admin
    And I switch to the first user
    When I open admin console in a browser
    Given I use the "openshift-metering" project
    And I ensure "openshift-metering" project is deleted after scenario
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    Given I wait up to 40 seconds for the steps to pass:
    """
    When I perform the :uninstall_operator_on_console web action with:
      | resource_name | Metering |
    Then the step should succeed
    """
    And I wait for the resource "subscription" named "metering-ocp" to disappear within 30 seconds
