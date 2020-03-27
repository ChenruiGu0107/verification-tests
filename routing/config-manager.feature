Feature: Testing HAProxy dynamic configuration manager related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-19866
  @admin
  @destructive
  Scenario: update unsecured route with haproxy dynamic changes enabled
    Given the master version >= "3.11"
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given admin ensures new router pod becomes ready after following env added:
      | ROUTER_HAPROXY_CONFIG_MANAGER=true |
    And the last reload log of a router pod is stored in :reload_1 clipboard

    # create unsecure route and add annotation
    Given I switch to the first user
    And I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/caddy-docker.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=caddy-docker |
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/unsecure/service_unsecure.json  |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                    |
      | resourcename | service-unsecure                                         |
      | overwrite    | true                                                     |
      | keyval       | router.openshift.io/haproxy.health.check.interval=1000ms |
    Then the step should succeed
    When I open web server via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"

    # check the router log again and ensure reloaded happened
    Given I switch to cluster admin pseudo user
    And the last reload log of a router pod is stored in :reload_2 clipboard
    And the expression should be true> cb.reload_2 != cb.reload_1

    # remove annoation and ensure no reloaded
    Given I switch to the first user
    When I run the :annotate client command with:
      | resource     | route                                              |
      | resourcename | service-unsecure                                   |
      | overwrite    | true                                               |
      | keyval       | router.openshift.io/haproxy.health.check.interval- |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And the last reload log of a router pod is stored in :reload_3 clipboard
    And the expression should be true> cb.reload_3 == cb.reload_2

