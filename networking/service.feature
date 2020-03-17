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
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service.json" replacing paths:
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

  # @author bmeng@redhat.com
  # @case_id OCP-9644
  Scenario: The packets should be dropped when accessing the service which points to a pod in another project
    ## Create pod in project1 and copy the pod ip
    Given I have a project
    And evaluation of `project.name` is stored in the :project1 clipboard
    Given I have a pod-for-ping in the project
    And evaluation of `pod.ip` is stored in the :pod1_ip clipboard

    ## Create pod in project2
    Given I create a new project
    And evaluation of `project.name` is stored in the :project2 clipboard
    And I use the "<%= cb.project2 %>" project
    Given I have a pod-for-ping in the project

    ## Create selector less service in project2 which point to the pod in project1
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service_to_external_pod.json" replacing paths:
      | ["items"][1]["subsets"][0]["addresses"][0]["ip"] | <%= cb.pod1_ip %> |
    Then the step should succeed
    Given I use the "selector-less-service" service
    And evaluation of `service.ip(user: user)` is stored in the :service2_ip clipboard

    ## Access the above service from the pod in project2
    When I execute on the "hello-pod" pod:
      | /usr/bin/curl | --connect-timeout | 4 | <%= cb.service2_ip %>:10086 |
    Then the step should fail
    And the output should not contain "Hello OpenShift!"

  # @author bmeng@redhat.com
  # @case_id OCP-9645
  Scenario: The packets should be dropped when accessing the service which points to a service in another project
    ## Create pod and service in project1 and copy the service ip
    Given I have a project
    And evaluation of `project.name` is stored in the :project1 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=test-pods |
    Given I use the "test-service" service
    And evaluation of `service.ip(user: user)` is stored in the :service1_ip clipboard

    ## Create pod in project2
    Given I create a new project
    And evaluation of `project.name` is stored in the :project2 clipboard
    And I use the "<%= cb.project2 %>" project
    Given I have a pod-for-ping in the project

    ## Create selector less service in project2 which point to the service in project1
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service_to_external_service.json" replacing paths:
      | ["items"][1]["subsets"][0]["addresses"][0]["ip"] | <%= cb.service1_ip %> |
    Then the step should succeed
    Given I use the "selector-less-service" service
    And evaluation of `service.ip(user: user)` is stored in the :service2_ip clipboard

    ## Access the above service from the pod in project2
    When I execute on the "hello-pod" pod:
      | /usr/bin/curl | --connect-timeout | 4 | <%= cb.service2_ip %>:10086 |
    Then the step should fail
    And the output should not contain "Hello OpenShift!"

  # @author zzhao@redhat.com
  # @case_id OCP-10770
  Scenario: Be able to access the service via the nodeport
    Given I have a project
    And evaluation of `rand(30000..32767)` is stored in the :port clipboard
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/nodeport_service.json"
    And I replace lines in "nodeport_service.json":
      |30000|<%= cb.port %>|
    When I run the :create client command with:
      | f |  nodeport_service.json |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    And evaluation of `pod('hello-pod').node_ip(user: user)` is stored in the :hostip clipboard

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    And evaluation of `pod.ip` is stored in the :pod_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    And evaluation of `service("service-unsecure").ip(user: user)` is stored in the :service_ip clipboard

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service_to_external_pod.json" replacing paths:
      | ["items"][0]["metadata"]["name"] | clustercidr |
      | ["items"][1]["subsets"][0]["addresses"][0]["ip"] | <%= cb.pod_ip %> |
    Then the step should fail
    And the output should match "endpoint address .* is not allowed"
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service_to_external_pod.json" replacing paths:
      | ["items"][0]["metadata"]["name"] | servicecidr |
      | ["items"][1]["subsets"][0]["addresses"][0]["ip"] | <%= cb.service_ip %> |
    Then the step should fail
    And the output should match "endpoint address .* is not allowed"

  # @author bmeng@redhat.com
  # @case_id OCP-10936
  @admin
  Scenario: Be able to create endpoints which point to the cluster network after given the permission by cluster admin
    Given I switch to cluster admin pseudo user
    When I run the :get client command with:
      | resource | clusternetwork |
      | resource_name | default |
      | template | {{.network}} |
    Then the step should succeed
    And evaluation of `@result[:response].split(".")[0]` is stored in the :clusternetwork_1 clipboard
    And evaluation of `@result[:response].split(".")[1]` is stored in the :clusternetwork_2 clipboard
    When I run the :get client command with:
      | resource | clusternetwork |
      | resource_name | default |
      | template | {{.serviceNetwork}} |
    Then the step should succeed
    And evaluation of `@result[:response].split(".")[0]` is stored in the :servicenetwork_1 clipboard
    And evaluation of `@result[:response].split(".")[1]` is stored in the :servicenetwork_2 clipboard

    Given I switch to the first user
    And I have a project
    And cluster role "system:endpoint-controller" is added to the "first" user
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service_to_external_pod.json" replacing paths:
      | ["items"][0]["metadata"]["name"] | clustercidr |
      | ["items"][1]["metadata"]["name"] | clustercidr-endpoint |
      | ["items"][1]["subsets"][0]["addresses"][0]["ip"] | <%= cb.clusternetwork_1 %>.<%= cb.clusternetwork_2 %>.<%= rand(255) %>.<%= rand(1..255) %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service_to_external_pod.json" replacing paths:
      | ["items"][0]["metadata"]["name"] | servicecidr |
      | ["items"][1]["metadata"]["name"] | servicecidr-endpoint |
      | ["items"][1]["subsets"][0]["addresses"][0]["ip"] | <%= cb.servicenetwork_1 %>.<%= cb.servicenetwork_2 %>.<%= rand(255) %>.<%= rand(1..255) %> |
    Then the step should succeed

  # @author yadu@redhat.com
  # @case_id OCP-9978
  @admin
  @destructive
  Scenario: Fail to create svc with a invalid external IP defined
    Given master config is merged with the following hash:
    """
    networkConfig:
      externalIPNetworkCIDRs:
      - 10.5.0.0/24
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/externalip_service2.json |
    Then the step should fail
    And the output should contain:
      | externalIP is not allowed |

  # @author yadu@redhat.com
  # @case_id OCP-9979
  @admin
  @destructive
  Scenario: Create multiple service with different external IP sections defined
    Given master config is merged with the following hash:
    """
    networkConfig:
      externalIPNetworkCIDRs:
      - 10.5.0.0/24
      - 10.6.0.0/24
    """
    And the master service is restarted on all master nodes
    Given I have a project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    """
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/externalip_service1.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/externalip_service2.json |
    Then the step should succeed

    When I run the :get client command with:
      | resource      | service          |
    Then the step should succeed
    And the output should contain:
      | 10.5.0.1 |
      | 10.6.0.1 |
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | /usr/bin/curl | --connect-timeout | 4 | 10.5.0.1:27017 |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift |
    When I execute on the pod:
      | /usr/bin/curl | --connect-timeout | 4 | 10.6.0.1:27017 |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift |

  # @author bmeng@redhat.com
  # @case_id OCP-16748
  @admin
  Scenario: Should remove the conntrack table immediately when the endpoint of UDP service gets deleted
    # Create pod and svc which is listening on the udp port
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/udp8080-pod.json |
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
      | bash | -c | conntrack -L -d <%= cb.service_ip %> \|\| runc exec atomic-openshift-node conntrack -L -d <%= cb.service_ip %> \|\| docker exec atomic-openshift-node conntrack -L -d <%= cb.service_ip %> |
    Then the step should succeed
    And the output should contain:
      | udp |
      | dst=<%= cb.service_ip %> |

    Given I ensure "udp-pod" pod is deleted
    # Check the conntrack entry is deleted with the svc
    When I run command on the "<%= cb.node %>" node's sdn pod:
      | bash | -c | conntrack -L -d <%= cb.service_ip %> \|\| runc exec atomic-openshift-node conntrack -L -d <%= cb.service_ip %> \|\| docker exec atomic-openshift-node conntrack -L -d <%= cb.service_ip %> |
    Then the step should succeed
    And the output should not contain "dst=<%= cb.service_ip %>"
