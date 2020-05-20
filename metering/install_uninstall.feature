Feature: Install and uninstall related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-22073
  @admin
  @destructive
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
