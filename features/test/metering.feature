Feature: test metering related steps
  @admin
  @destructive
  Scenario: test metering install
    Given the master version >= "3.10"
    Given I create a project with non-leading digit name
    And I store master major version in the clipboard
    And evaluation of `env.get_version(user: user)[0]` is stored in the :full_ver clipboard
    And metering service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_install_metering_params |
      | playbook_args | -e openshift_image_tag=v<%= cb.full_ver %> -e openshift_release=<%= cb.full_ver %>                                 |

