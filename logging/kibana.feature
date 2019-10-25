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
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-logging" project
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
