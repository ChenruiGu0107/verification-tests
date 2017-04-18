Feature: ansible install related feature
  # @author pruan@redhat.com
  # @case_id OCP-11061
  @admin
  @destructive
  Scenario: Deploy logging via Ansible: clean install when OPS cluster is enabled
    Given the master version >= "3.5"
    Given I have a project
    And logging service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11061/inventory |
    Given a pod becomes ready with labels:
      | component=curator-ops            |
      | logging-infra=curator            |
      | provider=openshift               |
    Given a pod becomes ready with labels:
      | component=es-ops            |
      | logging-infra=elasticsearch |
      | provider=openshift          |
    Given a pod becomes ready with labels:
      | component=kibana-ops |
      | logging-infra=kibana |
      | provider=openshift   |

  # @author pruan@redhat.com
  # @case_id OCP-12377
  @admin
  @destructive
  Scenario: Uninstall logging via Ansible
    Given the master version >= "3.5"
    Given I have a project
    # the clean up steps registered with the install step will be using uninstall
    And logging service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12377/inventory |