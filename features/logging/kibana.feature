Feature: kibana web UI related cases for logging
  # @author pruan@redhat.com
  # @case_id OCP-17426
  @admin
  @destructive
  Scenario: The default pattern in kibana for cluster-admin
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And I switch to the first user
    And the first user is cluster-admin
    Given I login to kibana logging web console
    Then I run the :kibana_verify_default_index_pattern web action

