Feature: Install and uninstall related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-20878
  @admin
  @destructive
  Scenario: install metering with ansible
    Given the master version >= "3.11"
    Given admin ensure "openshift-metering" project is deleted
    Given I create a project with non-leading digit name
    And I store master major version in the clipboard
    And metering service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_install_metering_params |
      | playbook_args | -e openshift_image_tag=v<%= cb.master_version %> -e openshift_release=<%= cb.master_version %>                     |

  # @author pruan@redhat.com
  # @case_id OCP-20947
  @admin
  @destructive
  Scenario: install metering with user specific image using ansible
    Given the master version >= "3.10"
    And evaluation of `"quay.io/coreos/metering-helm-operator:0.8.0-latest"` is stored in the :metering_image clipboard
    Given admin ensure "openshift-metering" project is deleted
    Given I create a project with non-leading digit name
    And I store master major version in the clipboard
    And metering service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_install_metering_params |
      | playbook_args | -e openshift_image_tag=v<%= cb.master_version %> -e openshift_release=<%= cb.master_version %>                     |
    And a pod becomes ready with labels:
      | app=metering-operator |
    Then the expression should be true> pod.container_specs[0].image == cb[:metering_image]

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
