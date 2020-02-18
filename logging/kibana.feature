@clusterlogging
@commonlogging
Feature: kibana web UI related cases for logging
  # @author pruan@redhat.com
  # @case_id OCP-17426
  @admin
  @destructive
  Scenario: The default pattern in kibana for cluster-admin
    Given I switch to the first user
    And the first user is cluster-admin
    Given I login to kibana logging web console
    Given evaluation of `[".operations.*", ".all", ".orphaned", "project.*"]` is stored in the :indices clipboard
    And I run the :kibana_expand_index_patterns web action
    Given I repeat the following steps for each :index_name in cb.indices:
    """
    And I perform the :kibana_find_index_pattern web action with:
      | index_pattern_name | #{cb.index_name} |
    Then the step should succeed
    """

  # @author pruan@redhat.com
  # @case_id OCP-14119
  @admin
  @destructive
  Scenario: Heap size limit should be set for Kibana pods
    Given a pod becomes ready with labels:
      | component=kibana,logging-infra=kibana |
    # check kibana pods settings
    And evaluation of `pod.container(user: user, name: 'kibana').spec.memory_limit` is stored in the :kibana_container_res_limit clipboard
    And evaluation of `pod.container(user: user, name: 'kibana-proxy').spec.memory_limit` is stored in the :kibana_proxy_container_res_limit clipboard
    Then the expression should be true> cb.kibana_container_res_limit > 700
    Then the expression should be true> cb.kibana_proxy_container_res_limit > 100
    # check kibana dc settings
    And evaluation of `deployment('kibana').container_spec(user: user, name: 'kibana').memory_limit` is stored in the :kibana_deploy_res_limit clipboard
    And evaluation of `deployment('kibana').container_spec(user: user, name: 'kibana-proxy').memory_limit` is stored in the :kibana_proxy_deploy_res_limit clipboard
    Then the expression should be true> cb.kibana_container_res_limit == cb.kibana_deploy_res_limit
    Then the expression should be true> cb.kibana_proxy_container_res_limit == cb.kibana_proxy_deploy_res_limit

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
    And I log out kibana logging web console
    Then the step should succeed
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
    And I perform the :logout_kibana web action in ":url=>https://<%= cb.kibana_route %>" window with:
      | kibana_url | https://<%= cb.kibana_route %> |
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
