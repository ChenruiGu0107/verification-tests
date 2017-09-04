Feature: idle service related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-10935
  @smoke
  Scenario: Pod can be changed to un-idle when there is unsecure or edge or passthrough route coming
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given I wait until replicationController "test-rc" is ready
    And I wait until number of replicas match "1" for replicationController "test-rc"
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :idle client command with:
      | svc_name | service-unsecure |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "test-rc"
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | service-secure.*none |
      | service-unsecure.*none |
    Then I wait up to 60 seconds for a web server to become available via the "service-unsecure" route
    Given I wait until number of replicas match "1" for replicationController "test-rc"
    And a pod becomes ready with labels:
      | name=test-pods |
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | service-secure.*<%= cb.pod_ip %>:8443 |
      | service-unsecure.*<%= cb.pod_ip %>:8080 |

    # check edge route
    When I run the :create_route_edge client command with:
      | name | edge-route |
      | service | service-unsecure |
    Then the step should succeed
    When I run the :idle client command with:
      | svc_name | service-unsecure |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "test-rc"
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | service-secure.*none |
      | service-unsecure.*none |
    Given I use the "edge-route" service
    Then I wait up to 60 seconds for a secure web server to become available via the "edge-route" route
    Given I wait until number of replicas match "1" for replicationController "test-rc"
    And a pod becomes ready with labels:
      | name=test-pods |
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | service-secure.*<%= cb.pod_ip %>:8443 |
      | service-unsecure.*<%= cb.pod_ip %>:8080 |

    # check passthrough route
    When I run the :create_route_passthrough client command with:
      | name    | route-pass     |
      | service | service-secure |
    Then the step should succeed
    When I run the :idle client command with:
      | svc_name | service-secure |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "test-rc"
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | service-secure.*none |
      | service-unsecure.*none |
    Given I use the "route-pass" service
    Then I wait up to 60 seconds for a secure web server to become available via the "route-pass" route
    Given I wait until number of replicas match "1" for replicationController "test-rc"
    And a pod becomes ready with labels:
      | name=test-pods |
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | service-secure.*<%= cb.pod_ip %>:8443 |
      | service-unsecure.*<%= cb.pod_ip %>:8080 |

  # @author hongli@redhat.com
  # @case_id OCP-13837
  Scenario: Pod can be changed to un-idle when there is reencrypt route coming
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given I wait until replicationController "test-rc" is ready
    And I wait until number of replicas match "1" for replicationController "test-rc"

    # check reencrypt route
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/reencrypt/route_reencrypt_dest.ca"
    When I run the :create_route_reencrypt client command with:
      | name       | route-reen              |
      | service    | service-secure          |
      | destcacert | route_reencrypt_dest.ca |
    Then the step should succeed
    When I run the :idle client command with:
      | svc_name | service-secure |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "test-rc"
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | service-secure.*none |
      | service-unsecure.*none |
    Given I use the "route-reen" service
    Then I wait up to 60 seconds for a secure web server to become available via the "route-reen" route
    Given I wait until number of replicas match "1" for replicationController "test-rc"
    And a pod becomes ready with labels:
      | name=test-pods |
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | service-secure.*<%= cb.pod_ip %>:8443 |
      | service-unsecure.*<%= cb.pod_ip %>:8080 |

  # @author hongli@redhat.com
  # @case_id OCP-10216
  @admin
  Scenario: The iptables rules for the service should be replaced by the REDIRECT rule after being idled
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given I wait until replicationController "test-rc" is ready
    And I wait until number of replicas match "2" for replicationController "test-rc"
    Given I use the "test-service" service
    And evaluation of `service.ip(user: user)` is stored in the :service_ip clipboard
    Given I select a random node's host
    And the node network is verified
    And the node service is verified
    When I run the :idle client command with:
      | svc_name | test-service |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "test-rc"
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | test-service.*none |
    When I run commands on the host:
      | iptables -nL -t nat \| grep <%= cb.proj_name %>/test-service |
    Then the step should succeed
    And the output should match:
      | REDIRECT   tcp  --  0.0.0.0/0\s+<%= cb.service_ip %>\s+/\* <%= cb.proj_name %>/test-service:http \*/ tcp dpt:27017 redir ports \d+        |
      | DNAT       tcp  --  0.0.0.0/0\s+<%= cb.service_ip %>\s+/\* <%= cb.proj_name %>/test-service:http \*/ tcp dpt:27017 to:\d+.\d+.\d+.\d+:\d+ |
    Given I have a pod-for-ping in the project
    Then I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl |
      | <%= cb.service_ip %>:27017 |
    Then the output should contain "Hello OpenShift!"
    """
    Given I wait until number of replicas match "2" for replicationController "test-rc"
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | test-service.*\d+.\d+.\d+.\d+:8080,\d+.\d+.\d+.\d+:8080 |
    When I run commands on the host:
      | iptables -nL -t nat \| grep <%= cb.proj_name %>/test-service |
    Then the step should succeed
    And the output should not contain "REDIRECT"
    And the output should match:
      | KUBE-MARK-MASQ  all  --  \d+.\d+.\d+.\d+\s+0.0.0.0/0\s+/\* <%= cb.proj_name %>/test-service:http \*/                            |
      | DNAT       tcp  --  0.0.0.0/0\s+0.0.0.0/0\s+/\* <%= cb.proj_name %>/test-service:http \*/ tcp to:\d+.\d+.\d+.\d+:8080           |
      | KUBE-SVC-.+  tcp  --  0.0.0.0/0\s+<%= cb.service_ip %>\s+/\* <%= cb.proj_name %>/test-service:http cluster IP \*/ tcp dpt:27017 |
      | KUBE-SEP-.+  all  --  0.0.0.0/0\s+0.0.0.0/0\s+/\* <%= cb.proj_name %>/test-service:http \*/                                     |

  # @author hongli@redhat.com
  # @case_id OCP-10215
  @admin
  @destructive
  Scenario: The idled rc/dc will not be unidled if set the enableUnidling to false
    # modify node-config to disable unidling
    Given I select a random node's host
    And the node network is verified
    Given the node service is restarted on the host after scenario
    And the "/etc/origin/node/node-config.yaml" file is restored on host after scenario
    When I run commands on the host:
      | sed -i '/enableUnidling/d' /etc/origin/node/node-config.yaml |
    Then the step should succeed
    When I run commands on the host:
      | echo "enableUnidling: false" >> /etc/origin/node/node-config.yaml |
    Then the step should succeed
    Given the node service is restarted on the host

    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given I wait until replicationController "test-rc" is ready
    And I wait until number of replicas match "1" for replicationController "test-rc"
    Given I use the "test-service" service
    And evaluation of `service.ip(user: user)` is stored in the :service_ip clipboard
    When I run the :idle client command with:
      | svc_name | test-service |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "test-rc"
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | test-service.*none |

    # create pod-for-ping on the node which node-config has been modified
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/aosqe-pod-for-ping.json" replacing paths:
      | ["spec"]["nodeName"] | <%= node.name %> |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    And I run the steps 10 times:
    """
    When I execute on the pod:
      | curl |
      | <%= cb.service_ip %>:27017 |
    Then the output should not contain "Hello OpenShift!"
    """
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | test-service.*none |

  # @author hongli@redhat.com
  # @case_id OCP-13218
  Scenario: should not return 503 errors during wakeup a pod which readiness is more than 30s
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/idle/long-readiness-pod.json |
    Then the step should succeed
    Given I wait until replicationController "test-rc" is ready
    And I wait until number of replicas match "1" for replicationController "test-rc"
    Given a pod becomes ready with labels:
      | name=test-pods |
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                   |
      | resourcename | service-unsecure                        |
      | keyval       | haproxy.router.openshift.io/timeout=90s |
    Then the step should succeed

    When I run the :idle client command with:
      | svc_name | service-unsecure |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "test-rc"
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | service-secure.*none |
      | service-unsecure.*none |

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | time |
      | curl |
      | http://<%= route("service-unsecure", service("service-unsecure")).dns(by: user) %>/ |
    Then the output should contain "Hello-OpenShift"
    And the output should not contain "503 Service Unavailable"
    # check if the total spent time in range (40..89) seconds
    And the output should match "real\s+(0m [4-5][0-9].\d+s|1m [0-2][0-9].\d+s)"
