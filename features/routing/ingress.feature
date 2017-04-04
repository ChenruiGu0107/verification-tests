Feature: Testing ingress object

  # @author: hongli@redhat.com
  # @case_id OCP-11069
  @admin
  @destructive
  Scenario: haproxy support ingress object
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    And cluster role "cluster-reader" is added to the "system:serviceaccount:default:router" service account
    And cluster role "system:service-serving-cert-controller" is added to the "system:serviceaccount:default:router" service account
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ENABLE_INGRESS=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

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
    Given cluster role "cluster-admin" is added to the "first" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/test-ingress.json |
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

  # @author: hongli@redhat.com
  # @case_id OCP-11438
  @admin
  @destructive
  Scenario: haproxy support ingress object with path
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    And cluster role "cluster-reader" is added to the "system:serviceaccount:default:router" service account
    And cluster role "system:service-serving-cert-controller" is added to the "system:serviceaccount:default:router" service account
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ENABLE_INGRESS=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

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
    Given cluster role "cluster-admin" is added to the "first" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/path-ingress.json |
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
    
  # @author: hongli@redhat.com
  # @case_id OCP-11692
  @admin
  @destructive
  Scenario: haproxy support ingress object with TLS
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    And cluster role "cluster-reader" is added to the "system:serviceaccount:default:router" service account
    And cluster role "system:service-serving-cert-controller" is added to the "system:serviceaccount:default:router" service account
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ENABLE_INGRESS=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

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

    # create secret and TLS ingress
    Given cluster role "cluster-admin" is added to the "first" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/mysecret.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/tls-ingress.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | ingress      |
      | resource_name | tls-ingress |
    Then the step should succeed
    And the output should contain "tls.ingress.com"

    Given I have a pod-for-ping in the project
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | tls.ingress.com:80:<%= cb.router_ip[0] %> |
      | http://tls.ingress.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1"
    When I execute on the "hello-pod" pod:
      | curl |
      | --resolve |
      | tls.ingress.com:443:<%= cb.router_ip[0] %> |
      | https://tls.ingress.com/ |
      | -k |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1"

  # @author: hongli@redhat.com
  # @case_id OCP-11874
  @admin
  @destructive
  Scenario: updating ingress object
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    And cluster role "cluster-reader" is added to the "system:serviceaccount:default:router" service account
    And cluster role "system:service-serving-cert-controller" is added to the "system:serviceaccount:default:router" service account
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ENABLE_INGRESS=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

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
    Given cluster role "cluster-admin" is added to the "first" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/path-ingress.json |
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
      | p             | {"spec":{"rules":[{"host":"foo.bar.com","http":{"paths":[{"backend":{"serviceName":"service-unsecure","servicePort":8080},"path":"/"}]}}]}} |
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
      | p             | {"spec":{"rules":[{"host":"foo.bar.com","http":{"paths":[{"backend":{"serviceName":"service-unsecure-2","servicePort":8080}}]}}]}} |
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

  # @author: hongli@redhat.com
  # @case_id OCP-12846 OCP-12848
  @admin
  @destructive
  Scenario: adding or updating host value of ingress resource is not permitted by default
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    And cluster role "cluster-reader" is added to the "system:serviceaccount:default:router" service account
    And cluster role "system:service-serving-cert-controller" is added to the "system:serviceaccount:default:router" service account
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ENABLE_INGRESS=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

    Given I switch to the first user
    And I have a project
    Given cluster role "cluster-admin" is added to the "first" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/test-ingress.json |
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
      | p             | {"spec":{"rules":[{"host":"foo.bar.com","http":{"paths":[{"backend":{"serviceName":"service-unsecure","servicePort":8080}}]}},{"host":"one.more.com"}]}} |
    Then the step should fail
    And the output should contain "cannot change hostname"

    # updating the hostname is not permitted
    When I run the :patch client command with:
      | resource      | ingress      |
      | resource_name | test-ingress |
      | p             | {"spec":{"rules":[{"host":"new.hostname.com","http":{"paths":[{"backend":{"serviceName":"service-unsecure","servicePort":8080}}]}}]}} |
    Then the step should fail
    And the output should contain "cannot change hostname"

  # @author: hongli@redhat.com
  # @case_id OCP-12847 OCP-12849
  @admin
  @destructive
  Scenario: adding or updating host value of ingress resource is permitted when disabling the admission control
    # modify master-config to allow ingress hostname change
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

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | deploymentconfig=router |
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    Given default router deployment config is restored after scenario
    And cluster role "cluster-reader" is added to the "system:serviceaccount:default:router" service account
    And cluster role "system:service-serving-cert-controller" is added to the "system:serviceaccount:default:router" service account
    When I run the :env client command with:
      | resource | dc/router |
      | e        | ROUTER_ENABLE_INGRESS=true |
    Then the step should succeed
    And I wait for the pod named "<%= cb.router_pod %>" to die
    And a pod becomes ready with labels:
      | deploymentconfig=router |

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
    Given cluster role "cluster-admin" is added to the "first" user
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ingress/test-ingress.json |
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
      | p             | {"spec":{"rules":[{"host":"foo.bar.com","http":{"paths":[{"backend":{"serviceName":"service-unsecure","servicePort":8080}}]}},{"host":"one.more.com"}]}} |
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
      | p             | {"spec":{"rules":[{"host":"new.hostname.com","http":{"paths":[{"backend":{"serviceName":"service-unsecure","servicePort":8080}}]}}]}} |
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

