Feature: Testing Ingress Operator related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-21766
  @admin
  Scenario: Integrate router metrics with the monitoring component
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-ingress" project
    Then the expression should be true> service_monitor('router-default').exists?
    Then the expression should be true> role_binding('prometheus-k8s').exists?
    Then the expression should be true> namespace('openshift-ingress').labels['openshift.io/cluster-monitoring'] == 'true'


  # @author hongli@redhat.com
  # @case_id OCP-21873
  @admin
  Scenario: the replicas of router deployment is controlled by ingresscontroller
    Given the master version >= "4.1"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-21873" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    # create custom ingresscontroller named test-21873 (replicas=1)
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/routing/operator/ingresscontroller-test.yaml" replacing paths:
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
    Given the master version >= "4.1"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ingress" project
    And admin ensures "test-certs-21143" secret is deleted from the "openshift-ingress" project after scenario
    And admin ensures "test-21143" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    # create custom wildcard route certificate
    Given I obtain test data file "routing/ca.pem"
    And I obtain test data file "routing/ca.key"
    When I run the :create_secret client command with:
      | secret_type    | tls              |
      | name           | test-certs-21143 |
      | cert           | ca.pem           |
      | key            | ca.key           |
    Then the step should succeed
    # create custom ingresscontroller which use above secrect
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/routing/operator/ingresscontroller-test.yaml" replacing paths:
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
    Given the master version >= "4.1"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    # create route in the project with label
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/edge/service_unsecure.json |
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
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/routing/operator/ingressctl-namespace-selector.yaml" replacing paths:
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
    Given the master version >= "4.1"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    # create route with label
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/edge/service_unsecure.json |
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
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/routing/operator/ingressctl-route-selector.yaml" replacing paths:
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
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-ingress" project
    And all default router pods become ready
    When I execute on the pod:
      | grep | nbthread | haproxy.config |
    Then the step should succeed
    And the output should contain "nbthread 4"

  # @author hongli@redhat.com
  @admin
  Scenario Outline: the tlsSecurityProfile of ingresscontroller can be set to Old, Intermediate, Modern and Custom
    Given the master version >= "4.1"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "<name>" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    # create custom ingresscontroller
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/routing/operator/<ingressctl>" replacing paths:
      | ["metadata"]["name"] | <name>                                    |
      | ["spec"]["domain"]   | <%= cb.subdomain.gsub("apps","<name>") %> |
    Then the step should succeed
    Given I use the "openshift-ingress" project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=<name> |
    # ensure tls cipher is correct
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | grep | ssl-min-ver | haproxy.config |
    Then the output should contain "<tls-version>"
    When I execute on the pod:
      | grep | ssl-default-bind-ciphers | haproxy.config |
    Then the output should contain "<ciphers>"
    """
    Examples:
      | name       | ingressctl                 | tls-version | ciphers                                                   |
      | test-25665 | ingressctl-tls-old.yaml    | TLSv1.1     | AES128-GCM-SHA256:AES256-GCM-SHA384                       | # @case_id OCP-25665
      | test-25666 | ingressctl-tls-intmd.yaml  | TLSv1.2     | ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305 | # @case_id OCP-25666
      | test-25667 | ingressctl-tls-modern.yaml | TLSv1.2     | ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305 | # @case_id OCP-25667
      | test-25668 | ingressctl-tls-custom.yaml | TLSv1.1     | ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256 | # @case_id OCP-25668

  # @author hongli@redhat.com
  # @case_id OCP-26150
  @admin
  Scenario: integrate ingress operator metrics with Prometheus
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-ingress-operator" project
    Then the expression should be true> service_monitor('ingress-operator').exists?
    Then the expression should be true> role_binding('prometheus-k8s').exists?
    Then the expression should be true> namespace('openshift-ingress-operator').labels['openshift.io/cluster-monitoring'] == 'true'

  # @author hongli@redhat.com
  @admin
  Scenario Outline: ingresscontroller can set proper endpointPublishingStrategy for all platforms
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-ingress-operator" project
    Then the expression should be true> ingress_controller('default').endpoint_publishing_strategy == "<type>"
    Examples:
      | type                |
      | LoadBalancerService | # @case_id OCP-21599
      | HostNetwork         | # @case_id OCP-29204

  # @author hongli@redhat.com
  # @case_id OCP-21883
  @admin
  Scenario: the PROXY protocol is enabled in AWS platform
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-ingress" project
    And all default router pods become ready
    When I execute on the pod:
      | grep | accept-proxy | haproxy.config |
    Then the step should succeed
    And the output should match 4 times:
      | bind .* accept-proxy |

  # @author hongli@redhat.com
  # @case_id OCP-29207
  @admin
  Scenario: the PROXY protocol is disabled in non-AWS platform
    Given the master version >= "4.1"
    And I switch to cluster admin pseudo user
    And I use the "openshift-ingress" project
    And all default router pods become ready
    When I execute on the pod:
      | grep | accept-proxy | haproxy.config |
    Then the step should fail

  # @author hongli@redhat.com
  # @case_id OCP-27560
  @admin
  Scenario: support NodePortService for custom Ingresscontroller
    Given the master version >= "4.4"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-27560" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/routing/operator/ingressctl-nodeport.yaml" replacing paths:
      | ["metadata"]["name"] | test-27560                                    |
      | ["spec"]["domain"]   | <%= cb.subdomain.gsub("apps","test-27560") %> |
    Then the step should succeed
    Then the expression should be true> ingress_controller('test-27560').endpoint_publishing_strategy == "NodePortService"

    # ensure the nodeport service is created
    Given I use the "openshift-ingress" project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-27560 |
    Then the expression should be true> service('router-nodeport-test-27560').exists?

  # @author hongli@redhat.com
  # @case_id OCP-27595
  @admin
  Scenario: set namespaceOwnership of routeAdmission to Strict
    Given the master version >= "4.4"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-27595" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctl-nsowner.yaml"
    When I run oc create over "ingressctl-nsowner.yaml" replacing paths:
      | ["metadata"]["name"]                             | test-27595                                    |
      | ["spec"]["domain"]                               | <%= cb.subdomain.gsub("apps","test-27595") %> |
      | ["spec"]["routeAdmission"]["namespaceOwnership"] | Strict                                        |
    Then the step should succeed

    # check the env in the router pod
    Given I use the "openshift-ingress" project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-27595 |
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | env |
    Then the output should contain:
      | ROUTER_DISABLE_NAMESPACE_OWNERSHIP_CHECK=false |
    """

    # create route in the first namespace
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    Given I obtain test data file "routing/reencrypt/service_secure.json"
    When I run the :create client command with:
      | f | service_secure.json |
    Then the step should succeed
    When I run the :create_route_reencrypt client command with:
      | name    | route-reen     |
      | service | service-secure |
      | path    | /test          |
    Then the step should succeed
    Given evaluation of `route("route-reen", service("service-secure")).dns` is stored in the :secure clipboard

    # switch to another user/namespace and create one same hostname with different path
    Given I switch to the second user
    And I have a project
    Given I obtain test data file "routing/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    Given I obtain test data file "routing/reencrypt/service_secure.json"
    When I run the :create client command with:
      | f | service_secure.json |
    Then the step should succeed
    When I run the :create_route_reencrypt client command with:
      | name     | route-reen       |
      | service  | service-secure   |
      | hostname | <%= cb.secure %> |
      | path     | /path/second     |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | route |
    Then the step should succeed
    And the output should contain "HostAlreadyClaimed"
    """

  # @author hongli@redhat.com
  # @case_id OCP-27596
  @admin
  Scenario: update the namespaceOwnership of routeAdmission
    Given the master version >= "4.4"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-27596" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctl-nsowner.yaml"
    When I run oc create over "ingressctl-nsowner.yaml" replacing paths:
      | ["metadata"]["name"]                             | test-27596                                    |
      | ["spec"]["domain"]                               | <%= cb.subdomain.gsub("apps","test-27596") %> |
      | ["spec"]["routeAdmission"]["namespaceOwnership"] | Strict                                        |
    Then the step should succeed

    # check the env in the router pod
    Given I use the "openshift-ingress" project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-27596 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | env \| grep NAMESPACE_OWNERSHIP |
    Then the output should contain:
      | ROUTER_DISABLE_NAMESPACE_OWNERSHIP_CHECK=false |
    """

    # update to InterNamespaceAllowed
    When I run the :patch admin command with:
      | resource      | ingresscontroller          |
      | resource_name | test-27596                 |
      | n             | openshift-ingress-operator |
      | p             | {"spec":{"routeAdmission":{"namespaceOwnership":"InterNamespaceAllowed"}}} |
      | type          | merge                      |
    Then the step should succeed
    Given I wait for the resource "pod" named "<%= cb.router_pod %>" to disappear
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-27596 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | env \| grep NAMESPACE_OWNERSHIP |
    Then the output should contain:
      | ROUTER_DISABLE_NAMESPACE_OWNERSHIP_CHECK=true |
    """

    # remove the spec from ingresscontroller, will use default value: Strict
    When I run the :patch admin command with:
      | resource      | ingresscontroller          |
      | resource_name | test-27596                 |
      | n             | openshift-ingress-operator |
      | p             | {"spec":{"routeAdmission":{"namespaceOwnership":null}}} |
      | type          | merge                      |
    Then the step should succeed
    Given I wait for the resource "pod" named "<%= cb.router_pod %>" to disappear
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-27596 |
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | env \| grep NAMESPACE_OWNERSHIP |
    Then the output should contain:
      | ROUTER_DISABLE_NAMESPACE_OWNERSHIP_CHECK=false |
    """

  # @author hongli@redhat.com
  # @case_id OCP-27605
  @admin
  Scenario: set namespaceOwnership of routeAdmission to invalid string
    Given the master version >= "4.4"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-27605" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctl-nsowner.yaml"
    When I run oc create over "ingressctl-nsowner.yaml" replacing paths:
      | ["metadata"]["name"] | test-27605                                    |
      | ["spec"]["domain"]   | <%= cb.subdomain.gsub("apps","test-27605") %> |
    Then the step should succeed
    Given I use the "openshift-ingress" project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-27605 |

    # try to set invalid value
    When I run the :patch admin command with:
      | resource      | ingresscontroller          |
      | resource_name | test-27605                 |
      | n             | openshift-ingress-operator |
      | p             | {"spec":{"routeAdmission":{"namespaceOwnership":"test"}}} |
      | type          | merge                      |
    Then the step should fail
    And the output should contain "invalid"

