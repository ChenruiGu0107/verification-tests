Feature: Install and uninstall related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-20878
  @admin
  @destructive
  Scenario: install metering with ansible
    Given the master version >= "3.11"
    Given I create a project with non-leading digit name
    And I store master major version in the clipboard
    And metering service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_install_metering_params |
      | playbook_args | -e openshift_image_tag=v<%= cb.master_version %> -e openshift_release=<%= cb.master_version %>                     |

