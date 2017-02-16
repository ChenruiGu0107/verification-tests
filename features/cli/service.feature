Feature: service related scenarios
  # @author yinzhou@redhat.com
  # @case_id OCP-10969
  @admin
  Scenario: Create clusterip service
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/hello-openshift.json |
    Then the step should succeed
    When I run the :create client command with:
      | help |  |
    Then the step should succeed
    And the output should contain "Create a service"
    When I run the :create_service client command with:
      | createservice_type | |
      | help               | |
    Then the step should succeed
    And the output should contain:
      | Available Commands: |
      | clusterip           |
      | loadbalancer        |
    When I run the :create_service client command with:
      | createservice_type  | clusterip       |
      | name                | hello-openshift |
      | tcp                 | <%= rand(6000..9000) %>:8080       |
    Then the step should succeed
    Given I wait for the "hello-openshift" service to become ready
    And I select a random node's host
    When I run commands on the host:
      | curl <%= service.url %> |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift! |
    When I run the :delete client command with:
      | object_type       | service         |
      | object_name_or_id | hello-openshift |
    Then the step should succeed
    When I run the :create_service client command with:
      | createservice_type  | clusterip       |
      | name                | hello-openshift |
      | clusterip           | 172.30.250.227  |
      | tcp                 | <%= rand(6000..9000) %>:8080       |
    Then the step should succeed
    Given I wait for the "hello-openshift" service to become ready
    And I select a random node's host
    When I run commands on the host:
      | curl <%= service.url %> |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift! |
    When I run the :create_service client command with:
      | createservice_type  | clusterip       |
      | name                | hello-openshift |
    Then the step should fail
    And the output should contain:
      | tcp port |
    When I run the :create_service client command with:
      | createservice_type  | clusterip       |
      | name                | hello-pod       |
      | tcp                 | 5678:8080       |
      | dry_run             | true            |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | svc       |
      | resource_name | hello-pod |
    Then the step should fail

  # @author yinzhou@redhat.com
  # @case_id OCP-11364
  @admin
  Scenario: Create nodeport service
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/hello-openshift.json |
    Then the step should succeed
    And evaluation of `pod('hello-openshift').node_ip(user: user)` is stored in the :hostip clipboard
    And evaluation of `rand(6000..9000)` is stored in the :hostport clipboard
    And evaluation of `rand(6000..9000)` is stored in the :hostport2 clipboard
    And evaluation of `rand(30000..32767)` is stored in the :random_node_port clipboard
    When I run the :create_service client command with:
      | createservice_type | nodeport                |
      | name               | hello-openshift         |
      | tcp                | <%= cb.hostport %>:8080 |
    Then the step should succeed
    And evaluation of `service('hello-openshift').node_port(user: user, port: cb.hostport)` is stored in the :node_port clipboard
    Then the step should succeed
    Given I wait for the "hello-openshift" service to become ready
    And I select a random node's host
    When I run commands on the host:
      | curl <%= cb.hostip %>:<%= cb.node_port %> |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift! |
    When I run the :delete client command with:
      | object_type       | service         |
      | object_name_or_id | hello-openshift |
    Then the step should succeed
    When I run the :create_service client command with:
      | createservice_type | nodeport                   |
      | name               | hello-openshift            |
      | nodeport           | <%= cb.random_node_port %> |
      | tcp                | <%= cb.hostport2 %>:8080   |
    Then the step should succeed
    And I select a random node's host
    When I run commands on the host:
      | curl <%= cb.hostip %>:<%= cb.random_node_port %> |
    Then the step should succeed


  # @author yinzhou@redhat.com
  # @case_id OCP-10970
  @admin
  Scenario: Create service with multiports
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/pod_with_multi_ports.yaml |
    Then the step should succeed
    And evaluation of `pod('hello-openshift').node_ip(user: user)` is stored in the :hostip clipboard
    And evaluation of `rand(6000..9000)` is stored in the :hostport clipboard
    And evaluation of `rand(6000..9000)` is stored in the :hostport2 clipboard
    When I run the :create_service client command with:
      | createservice_type | nodeport                                         |
      | name               | hello-openshift                                  |
      | tcp                | <%= cb.hostport %>:8080,<%= cb.hostport2 %>:8443 |
    Then the step should succeed
    And evaluation of `service('hello-openshift').node_port(user: user, port: cb.hostport)` is stored in the :node_port clipboard
    Then the step should succeed
    And evaluation of `service('hello-openshift').node_port(user: user, port: cb.hostport2)` is stored in the :node_port2 clipboard
    Then the step should succeed
    Given I wait for the "hello-openshift" service to become ready
    And I select a random node's host
    When I run commands on the host:
      | curl <%= cb.hostip %>:<%= cb.node_port %> |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift-1 http-8080 |
    When I run commands on the host:
      | curl -k https://<%= cb.hostip %>:<%= cb.node_port2 %> |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift-1 https-8443 |
    When I run the :delete client command with:
      | object_type       | service         |
      | object_name_or_id | hello-openshift |
    Then the step should succeed
    When I run the :create_service client command with:
      | createservice_type  | clusterip                                        |
      | name                | hello-openshift                                  |
      | tcp                 | <%= cb.hostport %>:8080,<%= cb.hostport2 %>:8443 |
    Then the step should succeed
    Given I wait for the "hello-openshift" service to become ready
    And evaluation of `service('hello-openshift').ip(user: user)` is stored in the :cluster_ip clipboard
    And I select a random node's host
    When I run commands on the host:
      | curl <%= service.url %> |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift-1 http-8080 |
    When I run commands on the host:
      | curl -k https://<%= cb.cluster_ip %>:<%= cb.hostport2 %> |
    Then the step should succeed
    And the output should contain:
      | Hello-OpenShift-1 https-8443 |

  # @author: chezhang@redhat.com
  # @case_id: OCP-12351
  Scenario: ExternalName service type can be created successful
    Given I have a project
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | sh |
      | -c |
      | ping -c 1 www.baidu.com 2>/dev/null \| head -1 \| cut -d \( -f2 \| cut -d \) -f1 |
    Then the step should succeed
    Given evaluation of `@result[:response].strip` is stored in the :address clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/ExternalSvc.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | endpoints |
    Then the output should contain "No resources found"
    When I run the :get client command with:
      | resource | svc |
    Then the step should succeed
    And the output should match "my-svc.*www.baidu.com"
    When I run the :describe client command with:
      | resource | svc    |
      | name     | my-svc |
    Then the output should match:
      | Name:\\s+my-svc                 |
      | Selector:\\s+<none>             |
      | Type:\\s+ExternalName           |
      | External Name:\\s+www.baidu.com |
    When I run the :get client command with:
      | resource | svc  |
      | o        | yaml |
    Then the output by order should match:
      | name: my-svc                |
      | externalName: www.baidu.com |
      | ports: null                 |
      | type: ExternalName          |
    When I execute on the pod:
      | sh |
      | -c |
      | nslookup my-svc.<%= project.name %> \| tail -1 \| cut -d ' ' -f3 |
    Then the step should succeed
    And the output should match "<%= cb.address %>"

  # @author: chezhang@redhat.com
  # @case_id: OCP-12376
  Scenario: Negative test for ExternalName Service type		
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/ExternalSvc-with-IP.yaml |
    Then the step should fail
    And the output should match " spec.clusterIP: Invalid value.*must be empty for ExternalName services"
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/ExternalSvc-with-port.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/ExternalSvc-cannot-resolve.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | endpoints |
    Then the output should contain "No resources found"
    When I run the :get client command with:
      | resource | svc |
    Then the step should succeed
    And the output should match "my-svc-invalid.*abc123.abc123.com.*s"
    When I run the :describe client command with:
      | resource | svc            |
      | name     | my-svc-invalid |
    Then the output should match:
      | Name:\\s+my-svc-invalid         |
      | Selector:\\s+<none>             |
      | Type:\\s+ExternalName           |
      | External Name:\\s+abc123.abc123.com |
    When I run the :get client command with:
      | resource | svc  |
      | o        | yaml |
    Then the output by order should match:
      | name: my-svc-invalid            |
      | externalName: abc123.abc123.com |
      | ports: null                     |
      | type: ExternalName              |
    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | sh |
      | -c |
      | nslookup my-svc-invalid.<%= project.name %> \| tail -1 |
    Then the step should succeed
    And the output should match "nslookup: can't resolve 'my-svc-invalid.<%= project.name %>'"
