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

  # @author pruan@redhat.com
  # @case_id OCP-15772
  @admin
  @destructive
  Scenario: kibana status is red when the es pod is not running
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And a replicationController becomes ready with labels:
      | component=es |
    And a deploymentConfig becomes ready with labels:
      | component=es |
    # disable es pod by scaling it to 0
    Then I run the :scale client command with:
      | resource | deploymentConfig |
      | name     | <%= dc.name %>   |
      | replicas | 0                |
    And I wait until number of replicas match "0" for replicationController "<%= rc.name %>"
    # get back to normal user mode
    Given I switch to the first user
    And I login to kibana logging web console
    And I get the visible text on web html page
    And the output should contain:
      | Status: Red |

  # @author pruan@redhat.com
  # @case_id OCP-14119
  @admin
  @destructive
  Scenario: Heap size limit should be set for Kibana pods
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    Given a pod becomes ready with labels:
      |  component=kibana,deployment=logging-kibana-1,deploymentconfig=logging-kibana,logging-infra=kibana,provider=openshift |
    # check kibana pods settings
    And evaluation of `pod.container(user: user, name: 'kibana').spec.memory_limit` is stored in the :kibana_container_res_limit clipboard
    And evaluation of `pod.container(user: user, name: 'kibana-proxy').spec.memory_limit` is stored in the :kibana_proxy_container_res_limit clipboard
    Then the expression should be true> cb.kibana_container_res_limit > 700
    Then the expression should be true> cb.kibana_proxy_container_res_limit > 100
    # check kibana dc settings
    And evaluation of `dc('logging-kibana').container_spec(user: user, name: 'kibana').memory_limit` is stored in the :kibana_dc_res_limit clipboard
    And evaluation of `dc('logging-kibana').container_spec(user: user, name: 'kibana-proxy').memory_limit` is stored in the :kibana_proxy_dc_res_limit clipboard
    Then the expression should be true> cb.kibana_container_res_limit == cb.kibana_dc_res_limit
    Then the expression should be true> cb.kibana_proxy_container_res_limit == cb.kibana_proxy_dc_res_limit

  # @author pruan@redhat.com
  # @case_id OCP-16414
  @admin
  @destructive
  Scenario: Logout kibana web console with installation step included
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And I switch to the first user
    Given I login to kibana logging web console
    When I perform the :logout_kibana web action with:
      | kibana_url | <%= cb.logging_console_url %> |
    Then the step should succeed
    And I access the "<%= cb.logging_console_url %>" url in the web browser
    Given I wait for the title of the web browser to match "(Login|Sign\s+in|SSO|Log In)"
