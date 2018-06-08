Feature: Testing ingress to route object

  # @author zzhao@redhat.com
  # @case_id OCP-18789
  Scenario: Ingress generic support 
    Given the master version >= "3.10"
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/test-ingress.json" replacing paths:
      | ["spec"]["rules"][0]["http"]["paths"][0]["backend"]["servicePort"] | 27017 |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | ingress      |
      | resource_name | test-ingress |
    Then the step should succeed
    And the output should contain "foo.bar.com"

    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | foo.bar.com:80:<%= cb.router_ip[0] %> |
      | http://foo.bar.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1"
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | foo.bar.com:80:<%= cb.router_ip[0] %> |
      | http://foo.bar.com/test/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-Path-Test"

  # @author zzhao@redhat.com
  # @case_id OCP-18790
  Scenario: Ingress with path
    Given the master version >= "3.10"
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/path-ingress.json" replacing paths:
      | ["spec"]["rules"][0]["http"]["paths"][0]["backend"]["servicePort"] | 27017 |    
    Then the step should succeed
    When I run the :get client command with:
      | resource      | ingress      |
      | resource_name | path-ingress |
    Then the step should succeed
    And the output should contain "foo.bar.com"

    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | foo.bar.com:80:<%= cb.router_ip[0] %> |
      | http://foo.bar.com/ |
      | -v |
    Then the step should succeed
    And the output should contain "503 Service Unavailable"
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | foo.bar.com:80:<%= cb.router_ip[0] %> |
      | http://foo.bar.com/test/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-Path-Test"
    
  # @author zzhao@redhat.com
  # @case_id OCP-18791
  Scenario: Ingress with TLS
    Given the master version >= "3.10"
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    # create secret and TLS ingress
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.crt"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.key"
    When I run the :create_secret client command with:
      | secret_type    | tls                                           |
      | name           | mysecret                                      |
      | cert           | route_edge-www.edge.com.crt                   |
      | key            | route_edge-www.edge.com.key                   |     
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/tls-ingress.json" replacing paths:
      | ["spec"]["rules"][0]["http"]["paths"][0]["backend"]["servicePort"] | 27017 |
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
      | /tmp/ca.pem |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1"

  # @author zzhao@redhat.com
  # @case_id OCP-18792
  Scenario: The path and service can be updated for ingress
    Given the master version >= "3.10"
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/path-ingress.json" replacing paths:
      | ["spec"]["rules"][0]["http"]["paths"][0]["backend"]["servicePort"] | 27017 |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | ingress      |
      | resource_name | path-ingress |
    Then the step should succeed
    And the output should contain "foo.bar.com"
    
    # create another pod and service for updating service later 
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/caddy-docker-2.json |
    Then the step should succeed
    And the pod named "caddy-docker-2" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/abrouting/unseucre/service_unsecure-2.json |
    Then the step should succeed
    
    # updating the path
    When I run the :patch client command with:
      | resource      | ingress      |
      | resource_name | path-ingress |
      | p             | {"spec":{"rules":[{"host":"foo.bar.com","http":{"paths":[{"backend":{"serviceName":"service-unsecure","servicePort":27017},"path":"/"}]}}]}} |
    Then the step should succeed
    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | foo.bar.com:80:<%= cb.router_ip[0] %> |
      | http://foo.bar.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1"

    # updating the service
    When I run the :patch client command with:
      | resource      | ingress      |
      | resource_name | path-ingress |
      | p             | {"spec":{"rules":[{"host":"foo.bar.com","http":{"paths":[{"backend":{"serviceName":"service-unsecure-2","servicePort":27017}}]}}]}} |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | foo.bar.com:80:<%= cb.router_ip[0] %> |
      | http://foo.bar.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-2"
    """

  # @author zzhao@redhat.com
  # @case_id OCP-18793
  Scenario: adding or updating host value of ingress resource is not permitted by default
    Given the master version >= "3.10"
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/test-ingress.json" replacing paths:
      | ["spec"]["rules"][0]["http"]["paths"][0]["backend"]["servicePort"] | 27017 |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | ingress      |
      | resource_name | test-ingress |
    Then the step should succeed
    And the output should contain "foo.bar.com"

    # adding one more hostname to ingress is not permitted
    When I run the :patch client command with:
      | resource      | ingress      |
      | resource_name | test-ingress |
      | p             | {"spec":{"rules":[{"host":"foo.bar.com","http":{"paths":[{"backend":{"serviceName":"service-unsecure","servicePort":27017}}]}},{"host":"one.more.com"}]}} |
    Then the step should fail
    And the output should contain "cannot change hostname"

    # updating the hostname is not permitted
    When I run the :patch client command with:
      | resource      | ingress      |
      | resource_name | test-ingress |
      | p             | {"spec":{"rules":[{"host":"new.hostname.com","http":{"paths":[{"backend":{"serviceName":"service-unsecure","servicePort":27017}}]}}]}} |
    Then the step should fail
    And the output should contain "cannot change hostname"

  # @author zzhao@redhat.com
  # @case_id OCP-18794
  @admin
  @destructive
  Scenario: adding or updating host value of ingress resource is permitted when disabling the admission control
    # modify master-config to allow ingress hostname change
    Given the master version >= "3.10"
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        openshift.io/IngressAdmission:
          configuration:
            apiVersion: v1
            allowHostnameChanges: true
            kind: IngressAdmissionConfig
          location: ''
    """
    And the step should succeed
    And the master service is restarted on all master nodes

    Given I switch to the first user
    And I have a project
    And I store default router IPs in the :router_ip clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/test-ingress.json" replacing paths:
      | ["spec"]["rules"][0]["http"]["paths"][0]["backend"]["servicePort"] | 27017 |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | ingress      |
      | resource_name | test-ingress |
    Then the step should succeed
    And the output should contain "foo.bar.com"

    # adding one more hostname to the ingress
    When I run the :patch client command with:
      | resource      | ingress      |
      | resource_name | test-ingress |
      | p             | {"spec":{"rules":[{"host":"foo.bar.com","http":{"paths":[{"backend":{"serviceName":"service-unsecure","servicePort":27017}}]}},{"host":"one.more.com"}]}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | ingress      |
      | resource_name | test-ingress |
    Then the step should succeed
    And the output should contain "foo.bar.com,one.more.com"

    # updating the hostname
    When I run the :patch client command with:
      | resource      | ingress      |
      | resource_name | test-ingress |
      | p             | {"spec":{"rules":[{"host":"new.hostname.com","http":{"paths":[{"backend":{"serviceName":"service-unsecure","servicePort":27017}}]}}]}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | ingress      |
      | resource_name | test-ingress |
    Then the step should succeed
    And the output should contain "new.hostname.com"
    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | new.hostname.com:80:<%= cb.router_ip[0] %> |
      | http://new.hostname.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1"

