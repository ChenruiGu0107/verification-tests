Feature: samplesoperator

  # @author xiuwang@redhat.com
  # @case_id OCP-22400
  @admin
  @destructive
  Scenario: Samples operator finalizer
    Given Admin updated the operator crd "config.samples" managementstate operand to Removed
    And I register clean-up steps:
    """
    Admin updated the operator crd "config.samples" managementstate operand to Managed
    """
    And I switch to cluster admin pseudo user
    And I use the "openshift" project
    And I wait for the resource "imagestream" named "ruby" to disappear
    And I wait for the resource "template" named "cakephp-mysql-persistent" to disappear
    When admin ensures "cluster" config_samples_operator_openshift_io is deleted
    Then admin waits for the "cluster" config_samples_operator_openshift_io to appear up to 120 seconds
    When I run the :describe admin command with:
      | resource | config.samples.operator.openshift.io |
      | name     | cluster                              |
    Then the step should succeed
    And the output should contain:
      | Management State:  Managed |
    Given I wait for the "ruby" image_stream to appear in the "openshift" project up to 120 seconds
    And I wait for the "cakephp-mysql-persistent" template to appear in the "openshift" project up to 120 seconds
