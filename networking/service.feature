Feature: Service related networking scenarios
  # @author bmeng@redhat.com
  # @case_id OCP-12540
  @smoke
  Scenario: Linking external services to OpenShift multitenant
    Given I have a project
    And I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | bash | -c | nslookup www.google.com 172.30.0.10 \| grep "Address 1" \| tail -1 \| awk '{print $3}' |
    Then the step should succeed
    And evaluation of `@result[:response].chomp` is stored in the :google_ip clipboard
    Given I obtain test data file "networking/external_service.json"
    When I run oc create over "external_service.json" replacing paths:
      | ["items"][1]["subsets"][0]["addresses"][0]["ip"] | <%= cb.google_ip %> |
    Then the step should succeed
    Given I use the "external-http" service
    And evaluation of `service.ip(user: user)` is stored in the :service_ip clipboard
    When I run the :get client command with:
      | resource      | endpoints  |
      | resource_name | external-http |
    Then the output should contain:
      | <%= cb.google_ip %>:80 |
    When I execute on the "hello-pod" pod:
      | /usr/bin/curl | <%= cb.service_ip %>:10086 |
    Then the output should contain "www.google.com"

  # @author zzhao@redhat.com
  # @case_id OCP-10770
  Scenario: Be able to access the service via the nodeport
    Given I have a project
    And evaluation of `rand(30000..32767)` is stored in the :port clipboard
    When I obtain test data file "networking/nodeport_service.json"
    And I replace lines in "nodeport_service.json":
      |30000|<%= cb.port %>|
    When I run the :create client command with:
      | f |  nodeport_service.json |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    And evaluation of `pod('hello-pod').node_ip(user: user)` is stored in the :hostip clipboard

    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=test-pods |
    When I execute on the pod:
      | curl | <%= cb.hostip %>:<%= cb.port %> |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift! |
    When I run the :delete client command with:
      | object_type | service |
      | object_name_or_id | hello-pod |
    Then I wait for the resource "service" named "hello-pod" to disappear
    When I execute on the pod:
      | curl | <%= cb.hostip %>:<%= cb.port %> |
    Then the step should fail
    And the output should not contain:
      | Hello OpenShift! |

  # @author bmeng@redhat.com
  # @case_id OCP-11341
  @admin
  Scenario: Do not allow user to create endpoints which point to the clusternetworkCIDR or servicenetworkCIDR
    Given I have a project
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    And evaluation of `pod.ip` is stored in the :pod_ip clipboard
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    And evaluation of `service("service-unsecure").ip(user: user)` is stored in the :service_ip clipboard

    Given I obtain test data file "networking/external_service_to_external_pod.json"
    When I run oc create over "external_service_to_external_pod.json" replacing paths:
      | ["items"][0]["metadata"]["name"] | clustercidr |
      | ["items"][1]["subsets"][0]["addresses"][0]["ip"] | <%= cb.pod_ip %> |
    Then the step should fail
    And the output should match "endpoint address .* is not allowed"
    Given I obtain test data file "networking/external_service_to_external_pod.json"
    When I run oc create over "external_service_to_external_pod.json" replacing paths:
      | ["items"][0]["metadata"]["name"] | servicecidr |
      | ["items"][1]["subsets"][0]["addresses"][0]["ip"] | <%= cb.service_ip %> |
    Then the step should fail
    And the output should match "endpoint address .* is not allowed"

  # @author bmeng@redhat.com
  # @case_id OCP-16748
  @admin
  Scenario: Should remove the conntrack table immediately when the endpoint of UDP service gets deleted
    # Create pod and svc which is listening on the udp port
    Given I have a project
    Given I obtain test data file "networking/udp8080-pod.json"
    When I run the :create client command with:
      | f | udp8080-pod.json |
    Then the step should succeed
    And the pod named "udp-pod" becomes ready
    And evaluation of `pod("udp-pod").node_name` is stored in the :node_name clipboard
    When I run the :expose client command with:
      | resource       | pod          |
      | resource_name  | udp-pod      |
      | port           | 8080         |
      | protocol       | UDP          |
    Then the step should succeed
    Given I use the "udp-pod" service
    And evaluation of `service.ip(user: user)` is stored in the :service_ip clipboard

    Given I have a pod-for-ping in the project
    And evaluation of `pod.node_name(user: user)` is stored in the :node clipboard

    # Access the udp svc to generate the conntrack entry
    When I execute on the pod:
      | bash | -c | (echo test ; sleep 1 ; echo test) \| /usr/bin/ncat -u <%= cb.service_ip %> 8080 |
    Then the step should succeed

    # Check the conntrack entry generated on the node
    When I run command on the "<%= cb.node %>" node's sdn pod:
      | bash | -c | conntrack -L -d <%= cb.service_ip %> |
    Then the step should succeed
    And the output should contain:
      | udp |
      | dst=<%= cb.service_ip %> |

    Given I ensure "udp-pod" pod is deleted
    # Check the conntrack entry is deleted with the svc
    When I run command on the "<%= cb.node %>" node's sdn pod:
      | bash | -c | conntrack -L -d <%= cb.service_ip %> |
    Then the step should succeed
    And the output should not contain "dst=<%= cb.service_ip %>"
