Feature: Egress-ingress related networking scenarios
  # @author yadu@redhat.com
  # @case_id OCP-11263
  Scenario: Invalid QoS parameter could not be set for the pod
    Given I have a project
    Given I obtain test data file "networking/egress-ingress/invalid-iperf.json"
    When I run the :create client command with:
      | f | invalid-iperf.json |
    Then the step should succeed
    Then I wait up to 20 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod   |
      | name     | iperf |
    Then the step should succeed
    And the output should match "resource .*unreasonably"
    """

  # @author yadu@redhat.com
  # @case_id OCP-12083
  @admin
  Scenario: Set the CIDRselector in EgressNetworkPolicy to invalid value
    Given the env is using multitenant or networkpolicy network
    Given I have a project
    Given I switch to cluster admin pseudo user
    Given I obtain test data file "networking/egressnetworkpolicy/invalid_policy.json"
    When I run the :create client command with:
      | f | invalid_policy.json |
      | n | <%= project.name %> |
    Then the step should fail
    And the output should contain "invalid CIDR address"


  # @author yadu@redhat.com
  # @case_id OCP-11625
  @admin
  Scenario: Only the cluster-admins can create EgressNetworkPolicy
    Given the env is using multitenant or networkpolicy network
    Given I have a project
    Given I obtain test data file "networking/egressnetworkpolicy/policy.json"
    When I run the :create client command with:
      | f | policy.json |
      | n | <%= project.name %> |
    Then the step should fail
    And the output should contain "cannot create"
    Given I switch to cluster admin pseudo user
    Given I obtain test data file "networking/egressnetworkpolicy/policy.json"
    When I run the :create client command with:
      | f | policy.json |
      | n | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | egressnetworkpolicy |
      | created             |
    When I run the :get client command with:
      | resource | egressnetworkpolicy |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain "default"
    Given I switch to the first user
    When I run the :get client command with:
      | resource | egressnetworkpolicy |
      | n        | <%= project.name %> |
    Then the step should fail
    And the output should contain "cannot list"
    When I run the :delete client command with:
      | object_type       | egressnetworkpolicy |
      | object_name_or_id | default             |
    Then the step should fail
    And the output should contain "cannot delete"
    Given I switch to cluster admin pseudo user
    When I run the :delete client command with:
      | object_type       | egressnetworkpolicy |
      | object_name_or_id | default             |
      | n                 | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | egressnetworkpolicy |
      | deleted             |

  # @author yadu@redhat.com
  # @case_id OCP-12087
  @admin
  Scenario: EgressNetworkPolicy can be deleted after the project deleted
    Given the env is using multitenant or networkpolicy network
    Given I have a project
    Given I obtain test data file "networking/egressnetworkpolicy/policy.json"
    When I run the :create admin command with:
      | f | policy.json |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | egressnetworkpolicy |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain "default"
    And the project is deleted
    When I run the :get admin command with:
      | resource | egressnetworkpolicy |
      | n        | <%= project.name %> |
    And the output should not contain "default"


  # @author yadu@redhat.com
  # @case_id OCP-10947
  @admin
  @destructive
  Scenario: Dropping all traffic when multiple egressnetworkpolicy in one project
    Given the env is using multitenant or networkpolicy network
    Given I have a project
    Given I obtain test data file "networking/egressnetworkpolicy/policy.json"
    When I run the :create admin command with:
      | f | policy.json |
      | n | <%= project.name %> |
    Given I obtain test data file "networking/egressnetworkpolicy/533253_policy.json"
    When I run the :create admin command with:
      | f | 533253_policy.json |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | egressnetworkpolicy |
      | n        | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | default |
      | policy1 |
    Given I select a random node's host
    And I wait up to 20 seconds for the steps to pass:
    """
    Given I get the networking components logs of the node since "2m" ago
    And the output should contain:
      | multiple EgressNetworkPolicies in same network namespace |
      | dropping all traffic                                     |
    """

  # @author yadu@redhat.com
  # @case_id OCP-10926
  @admin
  @destructive
  Scenario: All the traffics should be dropped when the single egressnetworkpolicy points to multiple projects
    Given the env is using multitenant network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I obtain test data file "networking/egressnetworkpolicy/policy.json"
    When I run the :create admin command with:
      | f | policy.json |
      | n | <%= cb.proj1 %> |
    Then the step should succeed
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I have a pod-for-ping in the project
    When I run the :oadm_pod_network_join_projects admin command with:
      | project | <%= cb.proj1 %> |
      | to      | <%= cb.proj2 %> |
    Then the step should succeed
    Given I select a random node's host
    And I wait up to 20 seconds for the steps to pass:
    """
    Given I get the networking components logs of the node since "120s" ago
    And the output should contain:
      | EgressNetworkPolicy not allowed in shared NetNamespace |
      | <%= cb.proj1 %>                                        |
      | <%= cb.proj2 %>                                        |
      | dropping all traffic                                   |
    """
    When I use the "<%= cb.proj2 %>" project
    When I execute on the pod:
      | curl | --connect-timeout | 5 | --head | www.google.com |
    Then the step should fail

    When I run the :delete admin command with:
      | object_type       | egressnetworkpolicy |
      | object_name_or_id | default             |
      | n                 | <%= cb.proj1 %>     |
    Then the step should succeed
    When I execute on the "hello-pod" pod:
      | curl           |
      | --head         |
      | www.google.com |
    Then the step should succeed
    And the output should contain "HTTP/1.1 200"

    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    Given I have a pod-for-ping in the project
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj4 clipboard
    When I run the :oadm_pod_network_join_projects admin command with:
      | project | <%= cb.proj3 %> |
      | to      | <%= cb.proj4 %> |
    Then the step should succeed
    Given I obtain test data file "networking/egressnetworkpolicy/policy.json"
    When I run the :create admin command with:
      | f | policy.json |
      | n | <%= cb.proj3 %> |
    Then the step should succeed
    Given I select a random node's host
    And I wait up to 20 seconds for the steps to pass:
    """
    Given I get the networking components logs of the node since "120s" ago
    And the output should contain:
      | EgressNetworkPolicy not allowed in shared NetNamespace |
      | <%= cb.proj3 %>                                        |
      | <%= cb.proj4 %>                                        |
      | dropping all traffic                                   |
    """
    When I use the "<%= cb.proj3 %>" project
    When I execute on the pod:
      | curl | --connect-timeout | 5 | --head | www.google.com |
    Then the step should fail

  # @author yadu@redhat.com
  # @case_id OCP-11335
  @admin
  @destructive
  Scenario: egressnetworkpolicy cannot take effect when adding to a globel project
    Given the env is using multitenant network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I have a pod-for-ping in the project
    And the pod named "hello-pod" becomes ready
    Given I obtain test data file "networking/egressnetworkpolicy/limit_policy.json"
    When I run the :create admin command with:
      | f | limit_policy.json |
      | n | <%= cb.proj1 %> |
    Then the step should succeed
    When I execute on the pod:
      | curl | --connect-timeout | 5 | --head | www.google.com |
    Then the step should fail

    When I run the :oadm_pod_network_make_projects_global admin command with:
      | project | <%= cb.proj1 %> |
    Then the step should succeed
    When I use the "<%= cb.proj1 %>" project
    When I execute on the pod:
      | curl           |
      | --head         |
      | www.google.com |
    Then the step should succeed
    And the output should contain "HTTP/1.1 200"
    Given I select a random node's host
    And I wait up to 20 seconds for the steps to pass:
    """
    Given I get the networking components logs of the node since "120s" ago
    And the output should contain:
      | EgressNetworkPolicy in global network namespace is not allowed (<%= cb.proj1 %>:policy1) |
    """
    And the project is deleted
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :oadm_pod_network_make_projects_global admin command with:
      | project | <%= cb.proj2 %> |
    Then the step should succeed
    Given I obtain test data file "networking/egressnetworkpolicy/limit_policy.json"
    When I run the :create admin command with:
      | f | limit_policy.json |
      | n | <%= cb.proj2 %> |
    Given I select a random node's host
    And I wait up to 20 seconds for the steps to pass:
    """
    Given I get the networking components logs of the node since "30s" ago
    And the output should contain:
      | EgressNetworkPolicy in global network namespace is not allowed (<%= cb.proj2 %>:policy1) |
    """
    When I use the "<%= cb.proj2 %>" project
    Given I have a pod-for-ping in the project
    And the pod named "hello-pod" becomes ready
    When I execute on the pod:
      | curl           |
      | --head         |
      | www.google.com |
   Then the step should succeed
   And the output should contain "HTTP/1.1 200"

  # @author bmeng@redhat.com
  # @case_id OCP-11978
  @admin
  @destructive
  Scenario: Set EgressNetworkPolicy to limit the pod connection to specific CIDR ranges in different namespaces
    Given the env is using multitenant or networkpolicy network
    And I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard

    Given I have a pod-for-ping in the project
    And evaluation of `BushSlicer::Common::Net.dns_lookup("github.com")` is stored in the :github_ip clipboard
    When I obtain test data file "networking/egressnetworkpolicy/limit_policy.json"
    And I replace lines in "limit_policy.json":
      | 0.0.0.0/0 | <%= cb.github_ip %>/32 |
    And I run the :create admin command with:
      | f | limit_policy.json |
      | n | <%= cb.proj1 %> |
    Then the step should succeed

    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    And I have a pod-for-ping in the project

    Given I create the "policy2" directory
    When I obtain test data file "networking/egressnetworkpolicy/limit_policy.json" into the "policy2" dir
    And I replace lines in "policy2/limit_policy.json":
      | 0.0.0.0/0 | 8.8.8.8/32 |
    And I run the :create admin command with:
      | f | policy2/limit_policy.json |
      | n | <%= cb.proj2 %> |
    Then the step should succeed

    Given I use the "<%= cb.proj1 %>" project
    Given I obtain test data file "networking/aosqe-pod-for-ping.json"
    When I run oc create over "aosqe-pod-for-ping.json" replacing paths:
      | ["metadata"]["name"] | new-hello-pod |
      | ["metadata"]["labels"]["name"] | new-hello-pod |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-hello-pod |
    When I execute on the "hello-pod" pod:
      | curl |
      | -I |
      | --resolve |
      | github.com:443:<%= cb.github_ip %> |
      | https://github.com/ |
      | --connect-timeout |
      | 5 |
    Then the step should fail
    When I execute on the "hello-pod" pod:
      | ping |
      | -c1 |
      | -W2 |
      | 8.8.8.8 |
    Then the step should succeed
    When I execute on the "new-hello-pod" pod:
      | curl |
      | -I |
      | --resolve |
      | github.com:443:<%= cb.github_ip %> |
      | https://github.com/ |
      | --connect-timeout |
      | 5 |
    Then the step should fail
    When I execute on the "new-hello-pod" pod:
      | curl |
      | -I |
      | http://www.baidu.com/ |
      | --connect-timeout |
      | 5 |
    Then the step should succeed

    Given I use the "<%= cb.proj2 %>" project
    Given I obtain test data file "networking/aosqe-pod-for-ping.json"
    When I run oc create over "aosqe-pod-for-ping.json" replacing paths:
      | ["metadata"]["name"] | new-hello-pod |
      | ["metadata"]["labels"]["name"] | new-hello-pod |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-hello-pod |
    When I execute on the "hello-pod" pod:
      | ping |
      | -c1 |
      | -W2 |
      | 8.8.8.8 |
    Then the step should fail
    When I execute on the "hello-pod" pod:
      | curl |
      | -I |
      | --resolve |
      | github.com:443:<%= cb.github_ip %> |
      | https://github.com/ |
      | --connect-timeout |
      | 5 |
    Then the step should succeed
    When I execute on the "new-hello-pod" pod:
      | ping |
      | -c1 |
      | -W2 |
      | 8.8.8.8 |
    Then the step should fail
    When I execute on the "new-hello-pod" pod:
      | curl |
      | -I |
      | http://www.baidu.com/ |
      | --connect-timeout |
      | 5 |
    Then the step should succeed

  # @author yadu@redhat.com
  # @case_id OCP-13249
  @admin
  @destructive
  Scenario: The openflow rules for the project with egressnetworkpolicy will not be corrupted by the restart node.service
    Given the env is using multitenant or networkpolicy network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard

    Given I obtain test data file "networking/egressnetworkpolicy/533253_policy.json"
    When I run the :create admin command with:
      | f | 533253_policy.json |
      | n | <%= cb.proj1 %> |
    Then the step should succeed
    Given I obtain test data file "networking/egressnetworkpolicy/533253_policy.json"
    When I run the :create admin command with:
      | f | 533253_policy.json |
      | n | <%= cb.proj2 %> |
    Then the step should succeed

    Given I select a random node's host
    When I run the ovs commands on the host:
      | ovs-ofctl dump-flows br0 -O openflow13 \| grep 10.3.0.0 |
    And the output should contain 2 times:
      | actions=drop |
      | reg0=0x      |
    Given the node service is restarted on the host
    Given the node service is verified
    When I run the ovs commands on the host:
      | ovs-ofctl dump-flows br0 -O openflow13 \| grep 10.3.0.0 |
    And the output should contain 2 times:
      | actions=drop |
      | reg0=0x      |

  # @author yadu@redhat.com
  # @case_id OCP-14163
  @admin
  @destructive
  Scenario: Egressnetworkpolicy will take effect as 0.0.0.0/0 when set to 0.0.0.0/32 in cidrSelector
    Given the env is using multitenant or networkpolicy network
    Given I have a project
    Given I have a pod-for-ping in the project
    When I obtain test data file "networking/egressnetworkpolicy/limit_policy.json"
    And I replace lines in "limit_policy.json":
      | 0.0.0.0/0 | 0.0.0.0/32 |
    And I run the :create admin command with:
      | f | limit_policy.json |
      | n | <%= project.name %> |
    Then the step should succeed

    Given I select a random node's host
    Given I get the networking components logs of the node since "30s" ago
    And the output should contain:
      | Correcting CIDRSelector '0.0.0.0/32' to '0.0.0.0/0' |

    When I use the "<%= project.name %>" project
    When I execute on the pod:
      | curl | --connect-timeout | 5 | --head | www.google.com |
    Then the step should fail

  # @author weliang@redhat.com
  # @case_id OCP-13499
  @admin
  Scenario: Change the order of allow and deny rules in egress network policy
    Given the env is using multitenant or networkpolicy network
    Given I have a project
    Given I have a pod-for-ping in the project
    And evaluation of `project.name` is stored in the :proj1 clipboard

    # Create egress policy with allow and deny order
    And evaluation of `BushSlicer::Common::Net.dns_lookup("yahoo.com")` is stored in the :yahoo_ip clipboard
    When I obtain test data file "networking/egress-ingress/dns-egresspolicy1.json"
    And I replace lines in "dns-egresspolicy1.json":
      | 98.138.0.0/16 | <%= cb.yahoo_ip %>/32 |
    And I run the :create admin command with:
      | f | dns-egresspolicy1.json |
      | n | <%= cb.proj1 %> |
    Then the step should succeed

    # Check ping from pod
    When I execute on the pod:
      | ping | -c1 | -W2 | yahoo.com |
    Then the step should succeed
    When I execute on the pod:
      | ping | -c1 | -W2 | <%= cb.yahoo_ip %> |
    Then the step should succeed

    # Check egress policy can be deleted
    When I run the :delete admin command with:
      | object_type       | egressnetworkpolicy |
      | object_name_or_id | policy-test             |
      | n                 |  <%= cb.proj1 %>    |
    Then the step should succeed

    # Create new egress policy with deny and allow order
    When I obtain test data file "networking/egress-ingress/dns-egresspolicy2.json"
    And I replace lines in "dns-egresspolicy2.json":
      | 98.138.0.0/16 | <%= cb.yahoo_ip %>/32 |
    And I run the :create admin command with:
      | f | dns-egresspolicy2.json |
      | n | <%= cb.proj1 %> |
    Then the step should succeed

    # Check ping from pod
    When I execute on the pod:
      | ping | -c1 | -W2 | yahoo.com |
    Then the step should fail
    When I execute on the pod:
      | ping | -c1 | -W2 | <%= cb.yahoo_ip %> |
    Then the step should fail

  # @author weliang@redhat.com
  # @case_id OCP-13501
  @admin
  Scenario: Apply same egress network policy in different projects
    Given the env is using multitenant or networkpolicy network
    Given I have a project
    Given I have a pod-for-ping in the project
    And evaluation of `project.name` is stored in the :proj1 clipboard

    # Create egress policy in project-1
    And evaluation of `BushSlicer::Common::Net.dns_lookup("yahoo.com")` is stored in the :yahoo_ip clipboard
    When I obtain test data file "networking/egress-ingress/dns-egresspolicy1.json"
    And I replace lines in "dns-egresspolicy1.json":
      | 98.138.0.0/16 | <%= cb.yahoo_ip %>/32 |
    And I run the :create admin command with:
      | f | dns-egresspolicy1.json |
      | n | <%= cb.proj1 %> |
    Then the step should succeed

    # Check ping from pod
    When I execute on the pod:
      | ping | -c1 | -W2 | yahoo.com |
    Then the step should succeed
    When I execute on the pod:
      | ping | -c1 | -W2 | <%= cb.yahoo_ip %> |
    Then the step should succeed

    Given I create a new project
    Given I have a pod-for-ping in the project
    And evaluation of `project.name` is stored in the :proj2 clipboard

    # Create same egress policy in project-2
    And evaluation of `BushSlicer::Common::Net.dns_lookup("yahoo.com")` is stored in the :github_ip clipboard
    When I obtain test data file "networking/egress-ingress/dns-egresspolicy1.json"
    And I replace lines in "dns-egresspolicy1.json":
      | 98.138.0.0/16 | <%= cb.yahoo_ip %>/32 |
    And I run the :create admin command with:
      | f | dns-egresspolicy1.json |
      | n | <%= cb.proj2 %> |
    Then the step should succeed

    # Check ping from pod
    When I execute on the pod:
      | ping | -c1 | -W2 | yahoo.com |
    Then the step should succeed
    When I execute on the pod:
      | ping | -c1 | -W2 | <%= cb.yahoo_ip %> |
    Then the step should succeed

    # Check egress policy can be deleted in project1
    When I run the :delete admin command with:
      | object_type       | egressnetworkpolicy |
      | object_name_or_id | policy-test             |
      | n                 |  <%= cb.proj1 %>    |
    Then the step should succeed

    # Check ping from pod after egress policy deleted
    When I execute on the pod:
      | ping | -c1 | -W2 | yahoo.com |
    Then the step should succeed
    When I execute on the pod:
      | ping | -c1 | -W2 | <%= cb.yahoo_ip %> |
    Then the step should succeed

  # @author weliang@redhat.com
  # @case_id OCP-13508
  @admin
  Scenario: Validate cidrSelector and dnsName fields in egress network policy
    Given the env is using multitenant or networkpolicy network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard

    # Create egress policy
    Given I obtain test data file "networking/egress-ingress/dns-invalid-policy1.json"
    When I run the :create admin command with:
      | f | dns-invalid-policy1.json |
      | n | <%= cb.proj1 %> |
    Then the step should fail
    Then the outputs should contain "Invalid value"
    Given I obtain test data file "networking/egress-ingress/dns-invalid-policy2.json"
    When I run the :create admin command with:
      | f | dns-invalid-policy2.json |
      | n | <%= cb.proj1 %> |
    Then the step should fail
    Then the outputs should contain "Invalid value"
    Given I obtain test data file "networking/egress-ingress/dns-invalid-policy3.json"
    When I run the :create admin command with:
      | f | dns-invalid-policy3.json |
      | n | <%= cb.proj1 %> |
    Then the step should fail
    Then the outputs should contain "Invalid value"

  # @author weliang@redhat.com
  # @case_id OCP-15004
  @admin
  Scenario: Service with a DNS name can not by pass Egressnetworkpolicy with IP corresponding that DNS name
    Given the env is using multitenant or networkpolicy network
    Given I have a project
    Given I have a pod-for-ping in the project
    And evaluation of `project.name` is stored in the :proj1 clipboard

    # Create egress policy to deny www.test.com
    And evaluation of `BushSlicer::Common::Net.dns_lookup("test.com")` is stored in the :test_ip clipboard
    When I obtain test data file "networking/egressnetworkpolicy/policy.json"
    And I replace lines in "policy.json":
      | 10.66.140.0/24 | <%= cb.test_ip %>/32 |
    And I run the :create admin command with:
      | f | policy.json |
      | n | <%= cb.proj1 %> |
    Then the step should succeed

    # Create a service with a "externalname"
    Given I obtain test data file "networking/service-externalName.json"
    When I run the :create admin command with:
      | f | service-externalName.json |
      | n | <%= cb.proj1 %> |
    Then the step should succeed

    # Check curl from pod
    When I execute on the pod:
      | curl |-ILs | www.test.com |
    Then the step should fail

    # Delete egress network policy
    When I run the :delete admin command with:
      | object_type       | egressnetworkpolicy |
      | object_name_or_id | default             |
      | n                 | <%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | egressnetworkpolicy |
      | deleted             |

    # Create egress policy to allow www.test.com
    Given I obtain test data file "networking/egressnetworkpolicy/policy.json"
    When I run the :create admin command with:
      | f | policy.json |
      | n | <%= cb.proj1 %> |
    Then the step should succeed

    # Check curl from pod
    When I execute on the pod:
      | curl | -ILs | www.test.com |
    And the output should contain "HTTP/1.1 200"

  # @author huirwang@redhat.com
  # @case_id OCP-12167
  @admin
  Scenario: The endpoints in EgressNetworkPolicy denying cidrSelector will be ignored
    Given I have a project
    And I have a pod-for-ping in the project
    And evaluation of `pod.node_name` is stored in the :node_name clipboard
    When I execute on the "hello-pod" pod:
      | bash | -c | nslookup www.google.com 172.30.0.10 \| grep "Address 1" \| tail -1 \| awk '{print $3}' |
    Then the step should succeed
    And evaluation of `@result[:response].chomp` is stored in the :google_ip clipboard

    # Create service/endpoint, endpoint ip is google_ip
    Given I obtain test data file "networking/egressnetworkpolicy/service_endpoint.json"
    When I run oc create over "service_endpoint.json" replacing paths:
      | ["items"][1]["subsets"][0]["addresses"][0]["ip"] |  <%= cb.google_ip %> |
      | ["items"][1]["subsets"][0]["ports"][0]["port"]   |  80                  |
      | ["items"][0]["spec"]["ports"][0]["targetPort"]   |  80                  |
    Then the step should succeed
    Given I use the "selector-less-service" service
    And evaluation of `service.ip` is stored in the :service_ip clipboard

    #Enter the pod and curl the service should succeed
    When I execute on the "hello-pod" pod:
      | /usr/bin/curl | <%= cb.service_ip %>:10086 |
    Then the step should succeed
    And the output should contain "www.google.com"

    #Create EgressNetworkPolicy with denying to IP
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    Given I obtain test data file "networking/egressnetworkpolicy/533253_policy.json"
    When I run oc create over "533253_policy.json" replacing paths:
      | ["spec"]["egress"][0]["to"]["cidrSelector"] | <%= cb.google_ip %>/32 |
    Then the step should succeed
    And I switch to the first user

    #Enter the pod and curl the service should fail
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.service_ip %>:10086 |
    Then the step should fail
    And the output should contain "Connection timed out"
    # Check sdn logs
    Given I select a random node's host
    And I get the networking components logs of the node since "1m" ago
    Then the output should contain "Service 'selector-less-service' in namespace '<%= project.name %>' has an Endpoint pointing to firewalled destination (<%= cb.google_ip %>)"
    # check iptables on the node
    When I run command on the "<%= cb.node_name%>" node's sdn pod:
      | iptables-save |
    Then the step should succeed
    And the output should not contain:
      | "<%= cb.google_ip %>" |
