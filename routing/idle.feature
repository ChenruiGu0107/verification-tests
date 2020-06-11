Feature: idle service related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-10216
  @admin
  Scenario: The iptables rules for the service should be DNAT or REDIRECT to node after being idled
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
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
  # @case_id OCP-20989
  Scenario: haproxy should load other routes even if headless service is idled
    Given I have a project
    Given I obtain test data file "routing/dns/headless-services.json"
    When I run oc create over "headless-services.json" replacing paths:
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
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-docker |
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I wait up to 30 seconds for a web server to become available via the "service-unsecure" route
    Then the output should contain "Hello-OpenShift"
