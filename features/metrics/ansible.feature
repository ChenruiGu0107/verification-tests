Feature: ansible install related feature
  # @author pruan@redhat.com
  # @case_id OCP-12234
  @admin
  @destructive
  Scenario: Metrics Admin Command - fresh deploy with default values
    Given the master version >= "3.5"
    Given I have a project
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12234/inventory |

  # @author pruan@redhat.com
  # @case_id OCP-12305
  @admin
  @destructive
  Scenario: Metrics Admin Command - clean and install
    Given the master version >= "3.5"
    Given I have a project
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12305/inventory |
    Given I remove metrics service installed in the "openshift-infra" project using ansible
    # reinstall it again
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12305/inventory |

  # @author pruan@redhat.com
  # @case_id OCP-12879
  @admin
  @destructive
  Scenario: Metrics Admin Command - Deploy standalone heapster
    Given the master version >= "3.5"
    Given I have a project
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12879/inventory |
    And I pry