Feature: F5 router related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-11998
  @admin
  Scenario: the F5 routes change accordingly when the routes update
    Given F5 router public IP is stored in the :vserver_ip clipboard
    And admin ensures a F5 router pod is ready

    Given I have a project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-pods |

    # create four type of routes
    When I expose the "service-unsecure" service
    Then the step should succeed

    Given I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/edge/route_edge-www.edge.com.crt"
    And I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/edge/route_edge-www.edge.com.key"
    And I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/ca.pem"
    When I run the :create_route_edge client command with:
      | name     | edge-route |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service  | service-unsecure |
      | cert     | route_edge-www.edge.com.crt |
      | key      | route_edge-www.edge.com.key |
      | cacert   | ca.pem |
    Then the step should succeed

    When I run the :create_route_passthrough client command with:
      | name     | route-pass     |
      | service  | service-secure |
      | hostname | <%= rand_str(5, :dns) %>-pass.example.com |
    Then the step should succeed

    Given I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/reencrypt/route_reencrypt-reen.example.com.crt"
    And I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/reencrypt/route_reencrypt-reen.example.com.key"
    And I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/reencrypt/route_reencrypt.ca"
    And I download a file from "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | route-reen |
      | hostname   | <%= rand_str(5, :dns) %>-reen.example.com |
      | service    | service-secure |
      | cert       | route_reencrypt-reen.example.com.crt |
      | key        | route_reencrypt-reen.example.com.key |
      | cacert     | route_reencrypt.ca |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed

    # check all routes if reachable from pod-for-ping
    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -sS  |
      | --resolve |
      | <%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>:80:<%= cb.vserver_ip %> |
      | http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """

    Given I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("edge-route", service("service-unsecure")).dns(by: user) %>:443:<%= cb.vserver_ip %> |
      | https://<%= route("edge-route", service("service-unsecure")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """

    Given I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("route-pass", service("service-secure")).dns(by: user) %>:443:<%= cb.vserver_ip %> |
      | https://<%= route("route-pass", service("service-secure")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """

    Given I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | -sS |
      | --resolve |
      | <%= route("route-reen", service("service-secure")).dns(by: user) %>:443:<%= cb.vserver_ip %> |
      | https://<%= route("route-reen", service("service-secure")).dns(by: user) %>/ |
      | --cacert |
      | /tmp/ca.pem |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    """

  # @author hongli@redhat.com
  # @case_id OCP-12106
  @admin
  Scenario: Should report meaningful error message when trying to create the wildcard domain on f5 router
    Given F5 router public IP is stored in the :vserver_ip clipboard
    And admin ensures a F5 router pod is ready
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/wildcard_route/route_edge.json |
    Then the step should succeed

    Given I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | route |
      | resource_name | wildcard-edge-route |
      | o             | yaml |
    Then the step should succeed
    And the output should contain "RouteNotAdmitted"
    And the output should contain "Wildcard routes are currently not supported by the F5 router"
    """

