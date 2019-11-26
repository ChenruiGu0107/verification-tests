Feature: Testing Ingress Operator related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-21766
  @admin
  Scenario: Integrate router metrics with the monitoring component
    Given the master version >= "4.0"
    And I switch to cluster admin pseudo user
    And I use the "openshift-ingress" project
    Then the expression should be true> service_monitor('router-default').exists?
    Then the expression should be true> role_binding('prometheus-k8s').exists?
    Then the expression should be true> namespace('openshift-ingress').labels['openshift.io/cluster-monitoring'] == 'true'


  # @author hongli@redhat.com
  # @case_id OCP-21873
  @admin
  Scenario: the replicas of router deployment is controlled by ingresscontroller
    Given the master version >= "4.0"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-21873" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    # create custom ingresscontroller named test-21873 (replicas=1)
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/operator/ingresscontroller-test.yaml" replacing paths:
      | ["metadata"]["name"]                   | test-21873                                    |
      | ["spec"]["defaultCertificate"]["name"] | router-certs-default                          |
      | ["spec"]["domain"]                     | <%= cb.subdomain.gsub("apps","test-21873") %> |
    Then the step should succeed
    Given I use the "openshift-ingress" project
    And I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> deployment("router-test-21873").current_replicas(cached: false) == 1
    """
    # change replicas of custom ingresscontroller to 0
    When I run the :patch admin command with:
      | resource      | ingresscontroller          |
      | resource_name | test-21873                 |
      | n             | openshift-ingress-operator |
      | p             | {"spec":{"replicas": 0}}   |
      | type          | merge                      |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> deployment("router-test-21873").current_replicas(cached: false) == 0
    """


  # @author hongli@redhat.com
  # @case_id OCP-21143
  @admin
  Scenario: the wildcard route certificate of router is controlled by ingresscontroller
    Given the master version >= "4.0"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ingress" project
    And admin ensures "test-certs-21143" secret is deleted from the "openshift-ingress" project after scenario
    And admin ensures "test-21143" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    # create custom wildcard route certificate
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.key"
    When I run the :create_secret client command with:
      | secret_type    | tls              |
      | name           | test-certs-21143 |
      | cert           | ca.pem           |
      | key            | ca.key           |
    Then the step should succeed
    # create custom ingresscontroller which use above secrect
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/operator/ingresscontroller-test.yaml" replacing paths:
      | ["metadata"]["name"]                   | test-21143                                    |
      | ["spec"]["domain"]                     | <%= cb.subdomain.gsub("apps","test-21143") %> |
      | ["spec"]["defaultCertificate"]["name"] | test-certs-21143                              |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | deployment                                                  |
      | resource_name | router-test-21143                                           |
      | template      | {{(index .spec.template.spec.volumes 0).secret.secretName}} |
    Then the step should succeed
    And the output should contain "test-certs-21143"
    """


  # @author hongli@redhat.com
  # @case_id OCP-22636
  @admin
  Scenario: the namespaceSelector of router is controlled by ingresscontroller
    Given the master version >= "4.0"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    # create route in the project with label
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :label admin command with:
      | resource | namespace             |
      | name     | <%= cb.proj_name %>   |
      | key_val  | namespace=router-test |
    Then the step should succeed
    # create custom router with namespaceSelector
    Given I switch to cluster admin pseudo user
    And admin ensures "test-22636" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/operator/ingressctl-namespace-selector.yaml" replacing paths:
      | ["metadata"]["name"]                   | test-22636                                    |
      | ["spec"]["domain"]                     | <%= cb.subdomain.gsub("apps","test-22636") %> |
      | ["spec"]["defaultCertificate"]["name"] | router-certs-default                          |
    Then the step should succeed
    Given I use the "openshift-ingress" project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-22636 |
    # ensure only the route in the matched namespace is loaded
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | grep | <%= cb.proj_name %>:service-unsecure | haproxy.config |
    Then the step should succeed
    """
    When I execute on the pod:
      | grep | openshift-console:console | haproxy.config |
    Then the step should fail


  # @author hongli@redhat.com
  # @case_id OCP-22637
  @admin
  Scenario: the routeSelector of router is controlled by ingresscontroller
    Given the master version >= "4.0"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    # create route with label
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/service_unsecure.json |
    Then the step should succeed
    When I expose the "service-unsecure" service
    Then the step should succeed
    When I run the :label client command with:
      | resource | route             |
      | name     | service-unsecure  |
      | key_val  | route=router-test |
    Then the step should succeed
    # create custom router with routeSelector
    Given I switch to cluster admin pseudo user
    And admin ensures "test-22637" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/operator/ingressctl-route-selector.yaml" replacing paths:
      | ["metadata"]["name"]                   | test-22637                                    |
      | ["spec"]["domain"]                     | <%= cb.subdomain.gsub("apps","test-22637") %> |
      | ["spec"]["defaultCertificate"]["name"] | router-certs-default                          |
    Then the step should succeed
    Given I use the "openshift-ingress" project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-22637 |
    # ensure only matched route is loaded
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | grep | <%= cb.proj_name %>:service-unsecure | haproxy.config |
    Then the step should succeed
    """
    When I execute on the pod:
      | grep | openshift-console:console | haproxy.config |
    Then the step should fail

  # @author hongli@redhat.com
  # @case_id OCP-23168
  @admin
  Scenario: enable ROUTER_THREADS for haproxy router by default
    Given the master version >= "4.0"
    And I switch to cluster admin pseudo user
    And I use the "openshift-ingress" project
    And all default router pods become ready
    When I execute on the pod:
      | grep | nbthread | haproxy.config |
    Then the step should succeed
    And the output should contain "nbthread 4"

  # @author hongli@redhat.com
  # @case_id OCP-26150
  @admin
  Scenario: integrate ingress operator metrics with Prometheus
    Given the master version >= "4.0"
    And I switch to cluster admin pseudo user
    And I use the "openshift-ingress-operator" project
    Then the expression should be true> service_monitor('ingress-operator').exists?
    Then the expression should be true> role_binding('prometheus-k8s').exists?
    Then the expression should be true> namespace('openshift-ingress-operator').labels['openshift.io/cluster-monitoring'] == 'true'

