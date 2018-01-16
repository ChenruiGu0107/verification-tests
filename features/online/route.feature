Feature: Route test in online environments 
  # @author zhaliu@redhat.com
  # @case_id OCP-10047
  Scenario: Custom route with passthrough termination is not permitted
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    And I wait for the "service-secure" service to become ready
    When I run the :create_route_passthrough client command with:
      | name | passthrough-route-custom |
      | hostname | <%= rand_str(5, :dns) %>-pass.example.com |
      | service | service-secure |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I run the :create_route_passthrough client command with:
      | name | passthrough-route |
      | service | service-secure |
    Then the step should succeed
    And I wait for a secure web server to become available via the "passthrough-route" route
    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("passthrough-route-custom", service("service-secure")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("passthrough-route-custom", service("service-secure")).dns(by: user) %> |
      | -I |
      | -k |
    Then the output should match "HTTP/.* 503 Service Unavailable"
    
  # @author zhaliu@redhat.com
  # @case_id OCP-10046
  Scenario: Custom route with edge termination is not permitted
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And all pods in the project are ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    And I wait for the "service-unsecure" service to become ready
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.key"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem" 
    When I run the :create_route_edge client command with:
      | name | edge-route-custom |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service | service-unsecure |
      | cert | route_edge-www.edge.com.crt |
      | key | route_edge-www.edge.com.key |
      | cacert | ca.pem |
    Then the step should succeed
 
    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | service | service-unsecure |
    Then the step should succeed
    And I wait for a secure web server to become available via the "edge-route" route

    When I execute on the pod:
      | curl |
      | --resolve |
      | <%= route("edge-route-custom", service("service-unsecure")).dns(by: user) %>:443:<%= cb.router_ip[0] %> |
      | https://<%= route("edge-route-custom", service("service-unsecure")).dns(by: user) %>/ |
      | -I | 
      | -k | 
      | -v | 
    Then the output should match "HTTP/.* 503 Service Unavailable"
    Then the output should not contain "CN=*.example.com"

  # @author zhaliu@redhat.com
  # @case_id OCP-16320
  Scenario: Custom hostname is prohibited for passthrough terminated route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/passthrough/service_secure.json |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name    | passthrough-route-custom |
      | service | service-secure           |
    Then the step should succeed

    When I run the :create_route_passthrough client command with:
      | name     | passthrough-route-custom1 |
      | hostname | <%= rand_str(5, :dns) %>-pass.example.com |
      | service  | service-secure |
    Then the step should fail
    And the output should contain "The Route "passthrough-route-custom1" is invalid: spec.host: Forbidden: you do not have permission to set the host field of the route"

  # @author zhaliu@redhat.com
  # @case_id OCP-16318
  Scenario: Custom hostname is prohibited for unsecure route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run the :expose client command with:
      | name          | route-unsecure   | 
      | resource      | service          |
      | resource_name | service-unsecure |
    Then the step should succeed

    When I run the :expose client command with:
      | name          | route-unsecure1                           |
      | hostname      | <%= rand_str(5, :dns) %>-unse.example.com |
      | resource      | service                                   |
      | resource_name | service-unsecure                          |
    Then the step should fail
    And the output should contain "The Route "route-unsecure1" is invalid: spec.host: Forbidden: you do not have permission to set the host field of the route"

  # @author zhaliu@redhat.com
  # @case_id OCP-16319
  Scenario: Custom hostname and cert are prohibited for edge terminated route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.key"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem" 
    When I run the :create_route_edge client command with:
      | name    | edge-route-custom |
      | service | service-unsecure  |
    Then the step should succeed

    When I run the :create_route_edge client command with:
      | name     | edge-route-custom1                        |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service  | service-unsecure                          |
    Then the step should fail
    And the output should contain "The Route "edge-route-custom1" is invalid: spec.host: Forbidden: you do not have permission to set the host field of the route"

    When I run the :create_route_edge client command with:
      | name    | edge-route-custom2          |
      | service | service-unsecure            |
      | cert    | route_edge-www.edge.com.crt |
      | key     | route_edge-www.edge.com.key |
      | cacert  | ca.pem                      |
    Then the step should fail
    And the output should contain "The Route "edge-route-custom2" is invalid: spec.tls: Forbidden: you do not have permission to set certificate fields on the route"

    When I run the :create_route_edge client command with:
      | name     | edge-route-custom3                        |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service  | service-unsecure                          |
      | cert     | route_edge-www.edge.com.crt               |
      | key      | route_edge-www.edge.com.key               |
      | cacert   | ca.pem                                    |
    Then the step should fail
    And the output should contain "The Route "edge-route-custom3" is invalid: spec.host: Forbidden: you do not have permission to set the host field of the route"

  # @author zhaliu@redhat.com
  # @case_id OCP-16357
  Scenario: There should be no privilege of creating custom routes in admin and edit role
    Given I have a project
    When I run the :get client command with:
      | resource      | clusterrole                             |
      | resource_name | admin                                   |
      | o             | template                                |
      | template      | {{range .rules}} {{.resources}} {{end}} |
    Then the step should succeed
    And the output should not contain "routes/custom-host"

    When I run the :get client command with:
      | resource      | clusterrole                             |
      | resource_name | edit                                    |
      | o             | json                                    |
      | template      | {{range .rules}} {{.resources}} {{end}} |
    Then the step should succeed
    And the output should not contain "routes/custom-host"

  # @author zhaliu@redhat.com
  # @case_id OCP-16321
  Scenario: Custom hostname and cert are prohibited for reencrypt terminated route
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/reencrypt-without-all-cert.yaml |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt-reen.example.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt-reen.example.com.key"

    When I run the :create_route_reencrypt client command with:
      | name     | reen-route-custom1                        |
      | hostname | <%= rand_str(5, :dns) %>-edge.example.com |
      | service  | service-secure                            |
    Then the step should fail
    And the output should contain "The Route "reen-route-custom1" is invalid: spec.host: Forbidden: you do not have permission to set the host field of the route"

    When I run the :create_route_reencrypt client command with:
      | name       | reen-route-custom2      |
      | destcacert | route_reencrypt_dest.ca |
      | service    | service-secure          |
    Then the step should fail
    And the output should contain "The Route "reen-route-custom2" is invalid: spec.tls: Forbidden: you do not have permission to set certificate fields on the route"

    When I run the :create_route_reencrypt client command with:
      | name    | reen-route-custom3                         |
      | service | service-secure                             |
      | cert    | route_reencrypt-reen.example.com.crt       |
      | key     | route_reencrypt-reen.example.com.key       |
      | hostname | <%= rand_str(5, :dns) %>-reen.example.com |
    Then the step should fail
    And the output should contain "The Route "reen-route-custom3" is invalid: spec.host: Forbidden: you do not have permission to set the host field of the route"

