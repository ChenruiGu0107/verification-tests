@clusterlogging
@commonlogging
Feature: kibana web UI related cases for logging

  # @author qitang@redhat.com
  # @case_id OCP-20172
  @admin
  @destructive
  Scenario: Logout kibana web console
    Given I switch to the first user
    And the first user is cluster-admin
    Given evaluation of `route('kibana', service('kibana',project('openshift-logging', switch: false))).dns(by: admin)` is stored in the :kibana_route clipboard
    Given I login to kibana logging web console
    Then the step should succeed
    When I run the :logout_kibana web action
    Then the step should succeed
    And I close the current browser
    Given I open admin console in a browser
    When I perform the :click_kibana_link_in_console web action with:
      | kibana_route   | https://<%= cb.kibana_route %> |
    Then the step should succeed
    And I perform the :kibana_login web action in ":url=>https://<%= cb.kibana_route %>" window with:
      | username   | <%= user.name %>               |
      | password   | <%= user.password %>           |
      | kibana_url | https://<%= cb.kibana_route %> |
      | idp        | <%= env.idp %>                 |
    Then the step should succeed

  # @author qitang@redhat.com
  # @case_id OCP-21485
  @admin
  @destructive
  Scenario: A share configmap are deployed by cluster-logging operator
    Given I switch to the first user
    And the first user is cluster-admin
    Given I use the "openshift-logging" project
    Given evaluation of `route('kibana', service('kibana',project('openshift-logging', switch: false))).dns(by: admin)` is stored in the :kibana_route clipboard
    And the expression should be true> config_map('sharing-config').exists?
    And the expression should be true> config_map('sharing-config').data['kibanaAppURL'].include? cb.kibana_route
    And the expression should be true> config_map('sharing-config').data['kibanaInfraURL'].include? cb.kibana_route
    Given I open admin console in a browser
    When I perform the :click_kibana_link_in_console web action with:
      | kibana_route   | https://<%= cb.kibana_route %> |
    Then the step should succeed
    And I perform the :kibana_login web action in ":url=>https://<%= cb.kibana_route %>" window with:
      | username   | <%= user.name %>               |
      | password   | <%= user.password %>           |
      | kibana_url | https://<%= cb.kibana_route %> |
      | idp        | <%= env.idp %>                 |
    Then the step should succeed
