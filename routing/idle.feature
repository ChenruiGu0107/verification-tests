Feature: idle service related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-10216
  @admin
  Scenario: The iptables rules for the service should be DNAT or REDIRECT to node after being idled
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And I wait until number of replicas match "1" for replicationController "test-rc"
    Given I use the "test-service" service
    And evaluation of `service.ip(user: user)` is stored in the :service_ip clipboard

    Given I have a pod-for-ping in the project
    And evaluation of `pod('hello-pod').node_ip(user: user)` is stored in the :hostip clipboard
    Given I use the "<%= pod.node_name(user: user) %>" node
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
      | iptables -S -t nat \| grep <%= cb.proj_name %>/test-service |
    Then the step should succeed
    And the output should match:
      | KUBE-PORTALS-CONTAINER -d <%= cb.service_ip %>/32 -p tcp .* -m tcp --dport 27017 -j (DNAT --to-destination <%= cb.hostip %>:\d+\|REDIRECT --to-ports \d+) |
      | KUBE-PORTALS-HOST -d <%= cb.service_ip %>/32 -p tcp .* -m tcp --dport 27017 -j DNAT --to-destination <%= cb.hostip %>:\d+ |

    Then I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | --max-time | 60 | <%= cb.service_ip %>:27017 |
    Then the output should contain "Hello OpenShift!"
    """
    Given a pod becomes ready with labels:
      | name=test-pods |
    Then evaluation of `pod.ip` is stored in the :pod_ip clipboard
    When I run the :get client command with:
      | resource | endpoints |
    Then the step should succeed
    And the output should match:
      | test-service\s+<%= cb.pod_ip %>:8080 |
    When I run commands on the host:
      | iptables -S -t nat \| grep <%= cb.proj_name %>/test-service |
    Then the step should succeed
    And the output should not contain "REDIRECT"
    And the output should match:
      | KUBE-SEP-.+ -s <%= cb.pod_ip %>/32 .* -j KUBE-MARK-MASQ                                |
      | KUBE-SEP-.+ -p tcp .* -m tcp -j DNAT --to-destination <%= cb.pod_ip %>:8080            |
      | KUBE-SERVICES -d <%= cb.service_ip %>/32 -p tcp .* -m tcp --dport 27017 -j KUBE-SVC-.+ |
      | KUBE-SVC-.+ .* -j KUBE-SEP-.+                                                          |

  # @author hongli@redhat.com
  # @case_id OCP-10215
  @admin
  @destructive
  Scenario: The idled rc/dc will not be unidled if set the enableUnidling to false
    # modify node-config to disable unidling
    Given I select a random node's host
    And the node network is verified
    Given I restart the network components on the node after scenario
    Given node config is merged with the following hash:
    """
      enableUnidling: false
    """
    Given I restart the network components on the node

    Given I have a project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
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
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/aosqe-pod-for-ping.json" replacing paths:
      | ["spec"]["nodeName"] | <%= node.name %> |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    And I run the steps 10 times:
    """
    When I execute on the pod:
      | curl |
      | <%= cb.service_ip %>:27017 |
    Then the output should not contain "Hello OpenShift!"
    And the output should contain "is unreachable"
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
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/idle/long-readiness-pod.json |
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

  # @author hongli@redhat.com
  # @case_id OCP-20989
  Scenario: haproxy should load other routes even if headless service is idled
    Given I have a project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/dns/headless-services.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given I wait until number of replicas match "1" for replicationController "caddy-rc"
    And a pod becomes ready with labels:
      | name=caddy-pods |
    When I run the :idle client command with:
      | svc_name | service-unsecure |
    Then the step should succeed
    Given I wait until number of replicas match "0" for replicationController "caddy-rc"

    Given I create a new project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/caddy-docker.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-docker |
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I wait up to 30 seconds for a web server to become available via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"
