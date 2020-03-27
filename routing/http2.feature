Feature: Testing HTTP/2 related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-19707
  @admin
  @destructive
  Scenario: haproxy router with http2 enabled can downgrade to http1.x if client does not support http2
    Given the master version >= "3.11"
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given admin ensures new router pod becomes ready after following env added:
      | ROUTER_ENABLE_HTTP2=true |

    Given I switch to the first user
    And I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/caddy-docker.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=caddy-docker |
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name       | edge-route       |
      | service    | service-unsecure |
    Then the step should succeed

    # force client to use http1.1
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | curl |
      | --http1.1 |
      | -v |
      | -k |
      | https://<%= route("edge-route", service("service-unsecure")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain:
      | ALPN, server accepted to use http/1.1 |
      | HTTP/1.1 200 OK                       |

    # force client to use http1.0
    When I execute on the pod:
      | curl |
      | --http1.0 |
      | -v |
      | -k |
      | https://<%= route("edge-route", service("service-unsecure")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain:
      | HTTP/1.0 200 OK |
