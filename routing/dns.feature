Feature: Testing DNS features

  # @author hongli@redhat.com
  # @case_id OCP-21136
  Scenario: DNS can resolve the ClusterIP services
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given I obtain test data file "routing/web-server-1.yaml"
    When I run the :create client command with:
      | f | web-server-1.yaml |
    Then the step should succeed
    And the pod named "web-server-1" becomes ready
    Given I obtain test data file "routing/service_unsecure.yaml"
    When I run the :create client command with:
      | f | service_unsecure.yaml |
    Then the step should succeed
    Given I use the "service-unsecure" service
    And evaluation of `service.ip(user: user)` is stored in the :service_ip clipboard

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | time | curl | service-unsecure:27017 |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    # the real time should be always less than 1s if Bug #1661928 (5s delay sometimes) fixed
    # for now, just rerun this case if below step failed
    And the output should match:
      | real\s+0m 0.\d\ds |

    When I execute on the pod:
      | curl |
      | service-unsecure.<%= cb.proj_name %>:27017 |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

    When I execute on the pod:
      | nslookup |
      | service-unsecure.<%= cb.proj_name %>.svc.cluster.local |
    Then the step should succeed
    And the output should contain "<%= cb.service_ip %>"

    When I execute on the pod:
      | getent |
      | ahosts |
      | service-unsecure.<%= cb.proj_name %>.svc |
    Then the step should succeed
    And the output should contain "<%= cb.service_ip %>"

  # @author hongli@redhat.com
  # @case_id OCP-21137
  Scenario: DNS can resolve the external domain
    Given I have a project
    And I have a pod-for-ping in the project
    When I execute on the pod:
      | curl | -LI | www.yahoo.com |
    Then the step should succeed
    And the output should contain "HTTP/2 200"

    When I execute on the pod:
      | time | curl | -LI | www.google.com |
    Then the step should succeed
    And the output should contain "200 OK"
    # the real time should be always less than 1s if Bug #1661928 (5s delay sometimes) fixed
    # for now, just rerun this case or ignored the step
    And the output should match:
      | real\s+0m 0.\d\ds |

  # @author hongli@redhat.com
  # @case_id OCP-21138
  Scenario: DNS can resolve the ExternalName services
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given I obtain test data file "routing/web-server-1.yaml"
    When I run the :create client command with:
      | f | web-server-1.yaml |
    Then the step should succeed
    And the pod named "web-server-1" becomes ready
    Given I obtain test data file "routing/service_unsecure.yaml"
    When I run the :create client command with:
      | f | service_unsecure.yaml |
    Then the step should succeed
    Given I use the "service-unsecure" service
    And evaluation of `service.ip(user: user)` is stored in the :service_ip clipboard

    Given I obtain test data file "routing/dns/externalname-service-int.json"
    When I run oc create over "externalname-service-int.json" replacing paths:
      | ["spec"]["externalName"] | service-unsecure.<%= cb.proj_name %>.svc.cluster.local |
    Then the step should succeed
    Given I obtain test data file "routing/dns/externalname-service-ext.json"
    When I run the :create client command with:
      | f | externalname-service-ext.json |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | getent | ahosts | external-internal |
    Then the step should succeed
    And the output should contain "<%= cb.service_ip %>"

    When I execute on the pod:
      | getent | ahosts | external-external |
    Then the step should succeed
    And the output should contain "www.google.com"

  # @author hongli@redhat.com
  # @case_id OCP-21139
  Scenario: DNS can resolve headless service to the IP of selected pods
    Given I have a project
    Given I obtain test data file "routing/dns/headless-services.yaml"
    When I run the :create client command with:
      | f | headless-services.yaml |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=web-server-rc |
    And evaluation of `pod(0).ip` is stored in the :pod0_ip clipboard
    And evaluation of `pod(1).ip` is stored in the :pod1_ip clipboard

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | getent | ahosts | service-unsecure |
    Then the step should succeed
    And the output should contain "<%= cb.pod0_ip %>"
    And the output should contain "<%= cb.pod1_ip %>"

  # @author hongli@redhat.com
  # @case_id OCP-21391
  @admin
  Scenario: the image-registry service IP is added to node's hosts file
    Given the master version >= "4.1"
    And the master version < "4.8"
    And I switch to cluster admin pseudo user
    Given I use the "openshift-image-registry" project
    And I use the "image-registry" service
    And evaluation of `service.ip` is stored in the :image_registry_svc_ip clipboard

    Given I use the "openshift-dns" project
    And all existing pods are ready with labels:
      | dns.operator.openshift.io/daemonset-dns=default |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>   |
      | c                | dns-node-resolver |
      | exec_command     | cat               |
      | exec_command_arg | /etc/hosts        |
    Then the step should succeed
    And the output should contain "<%= cb.image_registry_svc_ip %> image-registry.openshift-image-registry.svc image-registry.openshift-image-registry.svc.cluster.local"

  # @author hongli@redhat.com
  # @case_id OCP-23278
  @admin
  Scenario: Integrate coredns metrics with monitoring component
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-dns" project
    Then the expression should be true> service_monitor('dns-default').exists?
    Then the expression should be true> role_binding('prometheus-k8s').exists?
    Then the expression should be true> namespace('openshift-dns').labels['openshift.io/cluster-monitoring'] == 'true'

  # @author hongli@redhat.com
  # @case_id OCP-26151
  @admin
  Scenario: integrate DNS operator metrics with Prometheus
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-dns-operator" project
    Then the expression should be true> service_monitor('dns-operator').exists?
    Then the expression should be true> role_binding('prometheus-k8s').exists?
    Then the expression should be true> namespace('openshift-dns-operator').labels['openshift.io/cluster-monitoring'] == 'true'

  # @author hongli@redhat.com
  # @case_id OCP-37912
  # @bug_id 1813062
  @admin
  @destructive
  Scenario: DNS operator should show clear error message when DNS service IP already allocated
    Given the master version >= "4.6"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-dns" project
    And I register clean-up steps:
    """
    When I run the :delete admin command with:
      | object_type | pod                    |
      | l           | name=dns-operator      |
      | n           | openshift-dns-operator |
    Then the step should succeed
    And I wait up to 600 seconds for the steps to pass:
      | Then the expression should be true> service('dns-default').exists?                                          |
      | And the expression should be true> cluster_operator("dns").condition(type: 'Degraded')['status'] == "False" |
      | And the expression should be true> cluster_operator("dns").condition(type: 'Available')['status'] == "True" |
    """

    # delete dns operator and dns service and create svc-37912
    Given I obtain test data file "routing/dns/svc-37912.yaml"
    When I run the :delete admin command with:
      | object_type | pod                    |
      | l           | name=dns-operator      |
      | n           | openshift-dns-operator |
      | wait        | false                  |
    Then the step should succeed
    When I run the :delete admin command with:
      | object_type       | service       |
      | object_name_or_id | dns-default   |
      | n                 | openshift-dns |
    Then the step should succeed
    Given admin ensures "svc-37912" service is deleted from the "openshift-dns" project after scenario
    When I run the :create admin command with:
      | f | svc-37912.yaml |
    Then the step should succeed

    # check dns operator if show error message
    Given I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | dnses.operator |
      | resource_name | default        |
      | o             | yaml           |
    Then the step should succeed
    And the output should contain 3 times:
      | No IP assigned to DNS service |
    """

  # @author jechen@redhat.com
  # @case_id OCP-39840
  @admin
  Scenario: CoreDNS has been upgraded to v1.8.z for OCP4.8 or higher
    Given the master version >= "4.8"
    Given I switch to cluster admin pseudo user 
    And I use the "openshift-dns" project
    And a pod becomes ready with labels:
      | dns.operator.openshift.io/daemonset-dns=default |
    When I execute on the pod:
      | bash | -c | coredns -version |
    Then the step should succeed
    And the output should contain "CoreDNS-1.8."

  # @author jechen@redhat.com
  # @case_id OCP-40717
  @admin
  Scenario: Hostname lookup does not delay when master node down
    Given the master version >= "4.5"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-dns" project
    And a pod becomes ready with labels:
      | dns.operator.openshift.io/daemonset-dns=default |
    Then the expression should be true> daemon_set('dns-default').container_spec(name: 'dns').readiness_probe.dig('periodSeconds') == 3
    Then the expression should be true> daemon_set('dns-default').container_spec(name: 'dns').readiness_probe.dig('timeoutSeconds') == 3

  # @author jechen@redhat.com
  # @case_id OCP-40867
  @admin
  Scenario: image-registry service IP is added to node's hosts file
    Given the master version >= "4.8"
    And I switch to cluster admin pseudo user
    Given I use the "openshift-image-registry" project
    And I use the "image-registry" service
    And evaluation of `service.ip` is stored in the :image_registry_svc_ip clipboard

    Given I use the "openshift-dns" project
    And all existing pods are ready with labels:
      | dns.operator.openshift.io/daemonset-node-resolver |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>   |
      | exec_command     | cat               |
      | exec_command_arg | /etc/hosts        |
    Then the step should succeed
    And the output should contain "<%= cb.image_registry_svc_ip %> image-registry.openshift-image-registry.svc image-registry.openshift-image-registry.svc.cluster.local"

  # @author hongli@redhat.com
  # @case_id OCP-40718
  # @bug_id 1933761, 1943578
  @admin
  Scenario: CoreDNS cache should use 900s for positive responses and 30s for negative responses
    Given the master version >= "4.6"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-dns" project
    And all existing pods are ready with labels:
      | dns.operator.openshift.io/daemonset-dns=default |
    When I run the :exec client command with:
      | pod              | <%= pod.name %>       |
      | c                | dns                   |
      | exec_command     | cat                   |
      | exec_command_arg | /etc/coredns/Corefile |
    Then the step should succeed
    And the output should contain:
      | cache 900      |
      | denial 9984 30 |

