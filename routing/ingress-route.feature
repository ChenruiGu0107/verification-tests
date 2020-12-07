Feature: Testing ingress to route object

  # @author zzhao@redhat.com
  # @case_id OCP-18790
  Scenario: Ingress with path can be worked well
    Given the master version >= "3.10"
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard

    Given I obtain test data file "routing/web-server-1.yaml"
    When I run the :create client command with:
      | f | web-server-1.yaml |
    Then the step should succeed
    And the pod named "web-server-1" becomes ready
    Given I obtain test data file "routing/service_unsecure.yaml"
    When I run the :create client command with:
      | f | service_unsecure.yaml |
    Then the step should succeed
    Given I obtain test data file "routing/ingress/path-ingress.json"
    When I run oc create over "path-ingress.json" replacing paths:
      | ["spec"]["rules"][0]["host"] | "<%= cb.proj_name %>.<%= cb.subdomain %>"   |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | ingress      |
      | resource_name | path-ingress |
    Then the step should succeed
    And the output should contain "<%= cb.proj_name %>.<%= cb.subdomain %>"

    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | curl |
      | http://<%= cb.proj_name %>.<%= cb.subdomain %> |
      | -v |
    Then the step should succeed
    And the output should contain "503 Service Unavailable"
    When I execute on the "hello-pod" pod:
      | curl |
      | http://<%= cb.proj_name %>.<%= cb.subdomain %>/test/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-Path-Test"

  # @author zzhao@redhat.com
  # @case_id OCP-18791
  Scenario: haproxy support ingress object with TLS
    Given the master version >= "3.10"
    Given I have a project
    And I store an available router IP in the :router_ip clipboard
    Given I obtain test data file "routing/web-server-1.yaml"
    When I run the :create client command with:
      | f | web-server-1.yaml |
    Then the step should succeed
    And the pod named "web-server-1" becomes ready
    Given I obtain test data file "routing/service_unsecure.yaml"
    When I run the :create client command with:
      | f | service_unsecure.yaml |
    Then the step should succeed

    # create secret and TLS ingress
    Given I obtain test data file "routing/edge/route_edge-www.edge.com.crt"
    Given I obtain test data file "routing/edge/route_edge-www.edge.com.key"
    When I run the :create_secret client command with:
      | secret_type | tls                                                                                      |
      | name        | mysecret                                                                                 |
      | cert        | route_edge-www.edge.com.crt |
      | key         | route_edge-www.edge.com.key |
    Then the step should succeed
    Given I obtain test data file "routing/ingress/tls-ingress.json"
    When I run oc create over "tls-ingress.json" replacing paths:
      | ["spec"]["rules"][0]["host"]  | zhao-ingress.example.com |
      | ["spec"]["tls"][0]["hosts"][0] | zhao-ingress.example.com |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | ingress      |
      | resource_name | tls-ingress |
    Then the step should succeed
    And the output should contain "zhao-ingress.example.com"

    Given I have a pod-for-ping in the project
    And CA trust is added to the pod-for-ping
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | zhao-ingress.example.com:443:<%= cb.router_ip[0] %> |
      | https://zhao-ingress.example.com/ |
      | --cacert |
      | /tmp/ca-test.pem |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

  # @author zzhao@redhat.com
  # @case_id OCP-18792
  Scenario: The path and service can be updated for ingress
    Given the master version >= "3.10"
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard

    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=abtest-websrv1 |
    Given I obtain test data file "routing/ingress/path-ingress.json"
    When I run oc create over "path-ingress.json" replacing paths:
      | ["spec"]["rules"][0]["host"] | "<%= cb.proj_name %>.<%= cb.subdomain %>"   |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | ingress      |
      | resource_name | path-ingress |
    Then the step should succeed
    And the output should contain "<%= cb.proj_name %>.<%= cb.subdomain %>"

    # create another pod and service for updating service later
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=abtest-websrv2 |

    # updating the path
    When I run the :patch client command with:
      | resource      | ingress      |
      | resource_name | path-ingress |
      | p             | {"spec":{"rules":[{"host":"<%= cb.proj_name %>.<%= cb.subdomain %>","http":{"paths":[{"backend":{"serviceName":"service-unsecure","servicePort":27017},"path":"/"}]}}]}} |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | curl |
      | http://<%= cb.proj_name %>.<%= cb.subdomain %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift abtest-websrv1"

    # updating the service
    When I run the :patch client command with:
      | resource      | ingress      |
      | resource_name | path-ingress |
      | p             | {"spec":{"rules":[{"host":"<%= cb.proj_name %>.<%= cb.subdomain %>","http":{"paths":[{"backend":{"serviceName":"service-unsecure-2","servicePort":27017}}]}}]}} |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the "hello-pod" pod:
      | curl |
      | http://<%= cb.proj_name %>.<%= cb.subdomain %>/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift abtest-websrv2"
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-33960
  Scenario: Setting "route.openshift.io/termination" annotation to "Edge" in ingress resource deploys "Edge" terminated route object
    Given the master version >= "4.6"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard

    # Create secret certificate for ingress edge termination in the project 
    Given I obtain test data file "routing/ingress/ingress-secret.yaml"
    When I run the :create client command with:
      | f | ingress-secret.yaml |
    Then the step should succeed
   
    # Create pods and backend service
    Given I obtain test data file "routing/web-server-rc.yaml"
    When I run the :create client command with:
      | f | web-server-rc.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=web-server-rc |

    # create ingress resource with edge termination and check the reachability of the route
    Given I obtain test data file "routing/ingress/ingress-resource.yaml"
    And I run oc create over "ingress-resource.yaml" replacing paths:
      | ["spec"]["rules"][0]["host"]   | ingress-edge-<%= project.name %>.<%= cb.subdomain %> |
      | ["spec"]["tls"][0]["hosts"][0] | ingress-edge-<%= project.name %>.<%= cb.subdomain %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
    Then the output should contain "edge/Redirect"
    And I wait up to 30 seconds for the steps to pass:
    """
    When I open web server via the "https://ingress-edge-<%= project.name %>.<%= cb.subdomain %>" url
    And the output should contain "Hello-OpenShift"
    """

    
  # @author aiyengar@redhat.com
  # @case_id OCP-33962
  Scenario: Setting "route.openshift.io/termination" annotation to "Reencrypt" in ingress resource deploys "reen" terminated route object
    Given the master version >= "4.6"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard

    # Deploy secure service with signed secret annotation
    Given I obtain test data file "routing/ingress/signed-service.json"
    When I run the :create client command with:
      | f | signed-service.json |
    And the step should succeed
    And I wait for the "service-secret" secret to appear up to 30 seconds

    # Create secret certificate for ingress reencypt termination in the project 
    Given I obtain test data file "routing/ingress/ingress-secret.yaml"
    When I run the :create client command with:
      | f | ingress-secret.yaml |
    Then the step should succeed

    # Deploy a pod with secret volume and mountpaths
    Given I obtain test data file "routing/ingress/web-server-secret-rc.yaml"
    When I run the :create client command with:
      | f | web-server-secret-rc.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=web-server-rc |
    And evaluation of `pod.name` is stored in the :websrv_pod clipboard
    When I get project configmaps
    Then the output should match "nginx-config"

    # create ingress resource with reencrypt termination and check the routes
    Given I obtain test data file "routing/ingress/ingress-resource.yaml"
    And I run oc create over "ingress-resource.yaml" replacing paths:
      | ["metadata"]["name"]                                                             | ingress-reencrypt                                         |
      | ["spec"]["rules"][0]["host"]                                                     | ingress-reencrypt-<%= project.name %>.<%= cb.subdomain %> |
      | ["spec"]["tls"][0]["hosts"][0]                                                   | ingress-reencrypt-<%= project.name %>.<%= cb.subdomain %> |
      | ["metadata"]["annotations"]["route.openshift.io/termination"]                    | reencrypt                                                 |
      | ["spec"]["rules"][0]["http"]["paths"][0]["backend"]["service"]["name"]           | service-secure                                            |
      | ["spec"]["rules"][0]["http"]["paths"][0]["backend"]["service"]["port"]["number"] | 27443                                                     |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
    Then the output should contain "reencrypt/Redirect"
    And I wait up to 30 seconds for the steps to pass:
    """
    When I open web server via the "https://ingress-reencrypt-<%= project.name %>.<%= cb.subdomain %>" url
    And the output should contain "Hello-OpenShift <%= cb.websrv_pod %> https-8443 default"
    """

  # @author aiyengar@redhat.com
  # @case_id OCP-33986
  Scenario: Setting values other than "edge/passthrough/reencrypt" for "route.openshift.io/termination" annotation are ignored by ingress object
    Given the master version >= "4.6"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard 

    # Create secret certificate for ingress edge termination in the project 
    Given I obtain test data file "routing/ingress/ingress-secret.yaml"
    When I run the :create client command with:
      | f | ingress-secret.yaml |
    Then the step should succeed

    # Create pods and backend service
    Given I obtain test data file "routing/web-server-rc.yaml"
    When I run the :create client command with:
      | f | web-server-rc.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=web-server-rc |

    # create ingress resource with edge termination and check the routes
    Given I obtain test data file "routing/ingress/ingress-resource.yaml"
    And I run oc create over "ingress-resource.yaml" replacing paths:
      | ["spec"]["rules"][0]["host"]                                  | 33986-<%= project.name %>.example.com |
      | ["spec"]["tls"][0]["hosts"][0]                                | 33986-<%= project.name %>.example.com |
      | ["metadata"]["annotations"]["route.openshift.io/termination"] | abcd                                  |
    Then the step should succeed
    When I run the :get client command with:
      | resource | route |
    Then the output should contain "edge/Redirect"
