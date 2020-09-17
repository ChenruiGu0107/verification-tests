Feature: Testing HTTP Headers related scenarios

  # @author aiyengar@redhat.com
  # @case_id OCP-34157
  @admin
  Scenario: capture and log specific http Request header via "httpCaptureHeaders" option
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-34157" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctrl-httpcaptureheaders.yaml"
    And I run oc create over "ingressctrl-httpcaptureheaders.yaml" replacing paths:
      | ["spec"]["domain"]   | <%= cb.subdomain.gsub("apps","test-34157") %> |
      | ["metadata"]["name"] | test-34157                                    |
    Then the step should succeed

    # Ensure the router gets spawned and the vital info is saved in the cb
    Given I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-34157 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Then the expression should be true> deployment('router-test-34157').exists?

    # Deploy backend pods/services
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/list_for_caddy.json"
    When I run oc create over "list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-pods |
    Then the expression should be true> service('service-unsecure').exists?

    # deploy route
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"] | <%= cb.proj_name %>.34157.example.com |
    Then the step should succeed

    # generate app traffic
    Given I have a pod-for-ping in the project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -sS | --resolve | <%= cb.proj_name %>.34157.example.com:80:<%= cb.router_ip %> | --max-time | 10 |  http://<%= cb.proj_name %>.34157.example.com/path/second/ |
    Then the step should succeed
    And the output should contain "second-test http-8080" 
    """

    # checking the access log for HTTP header containing the full URL parent URL
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | pod/<%= cb.router_pod %> |
      | c             | logs                     |
      | tail          | 10                       |
    Then the step should succeed
    And the output should match:
      | <%= cb.proj_name %>.34157.example.com |
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34163
  @admin
  Scenario: capture and log specific http Response headers via "httpCaptureHeaders" option
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-34163" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctrl-httpcaptureheaders.yaml"
    And I run oc create over "ingressctrl-httpcaptureheaders.yaml" replacing paths:
      | ["spec"]["domain"]   | <%= cb.subdomain.gsub("apps","test-34163") %> |
      | ["metadata"]["name"] | test-34163                                    |
    Then the step should succeed

    # Ensure the router gets spawned and the vital info is saved in the cb
    Given I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-34163 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Then the expression should be true> deployment('router-test-34163').exists?

    # Deploy backend pods/services
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/list_for_caddy.json"
    When I run oc create over "list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1        |
      | ["items"][0]["metadata"]["name"] | web-pods |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-pods |
    Then the expression should be true> service('service-unsecure').exists?

    # Deploy route     
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"] | <%= cb.proj_name %>.34163.example.com |
    Then the step should succeed

    # Generate app traffic
    Given I have a pod-for-ping in the project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -sS | --resolve | <%= cb.proj_name %>.34163.example.com:80:<%= cb.router_ip %> | --max-time | 10 |  http://<%= cb.proj_name %>.34163.example.com/path/second/ |
    Then the step should succeed
    And the output should contain "second-test http-8080"
    """

    # checking the access log for HTTP header containing the RESPONSE header
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | pod/<%= cb.router_pod %> |
      | c             | logs                     |
      | tail          | 10                       |
    Then the step should succeed
    And the output should match:
      | Caddy |
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34191
  @admin
  Scenario: The "httpCaptureHeaders" option strictly adheres to the maxlength parameter
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-34191" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctrl-httpcaptureheaders.yaml"
    And I run oc create over "ingressctrl-httpcaptureheaders.yaml" replacing paths:
      | ["spec"]["domain"]                                                              | <%= cb.subdomain.gsub("apps","test-34191") %> |
      | ["metadata"]["name"]                                                            | test-34191                                    |
      | ["spec"]["logging"]["access"]["httpCaptureHeaders"]["request"][0]["maxLength"]  | 15                                            |
      | ["spec"]["logging"]["access"]["httpCaptureHeaders"]["response"][0]["maxLength"] | 3                                             |
    Then the step should succeed

    # Ensure the router gets spawned and the vital info is saved in the cb
    Given I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-34191 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Then the expression should be true> deployment('router-test-34191').exists?

    # Deploy backend pods/services
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/list_for_caddy.json"
    When I run oc create over "list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1        |
      | ["items"][0]["metadata"]["name"] | web-pods |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-pods |
    Then the expression should be true> service('service-unsecure').exists?

    # Deploy route     
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"] | <%= cb.proj_name %>.34191.example.com |
    Then the step should succeed

    # Generate app traffic
    Given I have a pod-for-ping in the project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -sS | --resolve | <%= cb.proj_name %>.34191.example.com:80:<%= cb.router_ip %> | --max-time | 10 | http://<%= cb.proj_name %>.34191.example.com/path/second/ |
    Then the step should succeed
    And the output should contain "second-test http-8080"
    """

    # checking the access log for HTTP header containing the RESPONSE header
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | pod/<%= cb.router_pod %> |
      | c             | logs                     |
      | tail          | 10                       |
    Then the step should succeed
    And the output should match:
      | <%= cb.proj_name %>.34191 |
      | Cad |
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34166
  @admin
  Scenario: capture and log http cookies with specific prefixes via "httpCaptureCookies" option
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-34166" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctrl-httpheadercookies.yaml"
    And I run oc create over "ingressctrl-httpheadercookies.yaml" replacing paths:
      | ["spec"]["domain"]   | <%= cb.subdomain.gsub("apps","test-34166") %> |
      | ["metadata"]["name"] | test-34166                                    |
    Then the step should succeed

    # Ensure the router gets spawned and the vital info is saved in the cb
    Given I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-34166 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Then the expression should be true> deployment('router-test-34166').exists?

    # Deploy backend pods/services
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/list_for_caddy.json"
    When I run oc create over "list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-pods |
    Then the expression should be true> service('service-unsecure').exists?

    # Deploy route
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"] | <%= cb.proj_name %>.34166.example.com |
    Then the step should succeed

    # Generate app traffic
    Given I have a pod-for-ping in the project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -b | foobar-<%= cb.proj_name %>= | -sS | --resolve | <%= cb.proj_name %>.34166.example.com:80:<%= cb.router_ip %> | --max-time | 10 | http://<%= cb.proj_name %>.34166.example.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1 http-8080"
    """

    # checking the access log to verify the cookie with specfic set prefix is logged
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | pod/<%= cb.router_pod %> |
      | c             | logs                     |
      | tail          | 10                       |
    Then the step should succeed
    And the output should match:
      | foobar-<%= cb.proj_name %>= |
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34178
  @admin
  Scenario: capture and log http cookies with exact match via "httpCaptureCookies" option
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-34178" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctrl-httpheadercookies.yaml"
    And I run oc create over "ingressctrl-httpheadercookies.yaml" replacing paths:
      | ["spec"]["domain"]                                                  | <%= cb.subdomain.gsub("apps","test-34178") %> |
      | ["metadata"]["name"]                                                | test-34178                                    |
      | ["spec"]["logging"]["access"]["httpCaptureCookies"][0]["name"]      | foobar-<%= cb.proj_name %>                    |
      | ["spec"]["logging"]["access"]["httpCaptureCookies"][0]["matchType"] | Exact                                         |
    Then the step should succeed

    # Ensure the router gets spawned and the vital info is saved in the cb
    Given I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-34178 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Then the expression should be true> deployment('router-test-34178').exists?

    # Deploy backend pods/services
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/list_for_caddy.json"
    When I run oc create over "list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-pods |
    Then the expression should be true> service('service-unsecure').exists?

    # Deploy route
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"] | <%= cb.proj_name %>.34178.example.com |
    Then the step should succeed

    # Generate app traffic
    Given I have a pod-for-ping in the project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -b | foobar-<%= cb.proj_name %>= | -sS | --resolve | <%= cb.proj_name %>.34178.example.com:80:<%= cb.router_ip %> | --max-time | 10 | http://<%= cb.proj_name %>.34178.example.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1 http-8080"
    """

    # checking the access log to verify the exact set pattern is logged
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | pod/<%= cb.router_pod %> |
      | c             | logs                     |
      | tail          | 10                       |
    Then the step should succeed
    And the output should match:
      | foobar-<%= cb.proj_name %> |
    """

  # @author aiyengar@redhat.com
  # @case_id OCP-34189
  @admin
  Scenario: The "httpCaptureCookies" option strictly adheres to the maxlength parameter
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-34189" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctrl-httpheadercookies.yaml"
    And I run oc create over "ingressctrl-httpheadercookies.yaml" replacing paths:
      | ["spec"]["domain"]                                                   | <%= cb.subdomain.gsub("apps","test-34189") %> |
      | ["metadata"]["name"]                                                 | test-34189                                    |
      | ["spec"]["logging"]["access"]["httpCaptureCookies"][0]["matchType"]  | Prefix                                        |
      | ["spec"]["logging"]["access"]["httpCaptureCookies"][0]["maxLength"]  | 6                                             |
      | ["spec"]["logging"]["access"]["httpCaptureCookies"][0]["namePrefix"] | foobar-<%= cb.proj_name %>                    |
    Then the step should succeed

    # Ensure the router gets spawned and the vital info is saved in the cb
    Given I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-34189 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Then the expression should be true> deployment('router-test-34189').exists?

    # Deploy backend pods/services
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/list_for_caddy.json"
    When I run oc create over "list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-pods |
    Then the expression should be true> service('service-unsecure').exists?

    # Deploy route
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"] | <%= cb.proj_name %>.34189.example.com |
    Then the step should succeed

    # Generate app traffic
    Given I have a pod-for-ping in the project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -b | foobar-<%= cb.proj_name %>= | -sS | --resolve | <%= cb.proj_name %>.34189.example.com:80:<%= cb.router_ip %> | --max-time | 10 | http://<%= cb.proj_name %>.34189.example.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1 http-8080"
    """

    # checking the access log to check the length of the cookie name matches the set value of 3
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | pod/<%= cb.router_pod %> |
      | c             | logs                     |
      | tail          | 10                       |
    Then the step should succeed
    And the output should match:
      | foobar |
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34188
  @admin
  Scenario: capture and log http requests using UniqueID with custom logging format defined via "httpHeader" option
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-34188" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctrl-httpheadercookies.yaml"
    And I run oc create over "ingressctrl-httpheadercookies.yaml" replacing paths:
      | ["spec"]["domain"]                             | <%= cb.subdomain.gsub("apps","test-34188") %>                                     |
      | ["metadata"]["name"]                           | test-34188                                                                        | 
      | ["spec"]["httpHeaders"]["uniqueId"]["format"]  | '%{+Q}b'                                                                          |
      | ["spec"]["logging"]["access"]["httpLogFormat"] | '%ID %ci:%cp [%tr] %ft %s %TR/%Tw/%Tc/%Tr/%Ta %ST %B %CC %CS %tsc %hr %hs %{+Q}r' |
    Then the step should succeed

    # Ensure the router gets spawned and the vital info is saved in the cb
    Given I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-34188 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Then the expression should be true> deployment('router-test-34188').exists?

    # Deploy backend pods/services
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/list_for_caddy.json"
    When I run oc create over "list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=caddy-pods |
    Then the expression should be true> service('service-unsecure').exists?

    # Deploy route
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"]     | <%= cb.proj_name %>.34188.example.com |
      | ["metadata"]["name"] | route-unsecure                        |
    Then the step should succeed

    # Generate app traffic
    Given I have a pod-for-ping in the project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -sS | --resolve | <%= cb.proj_name %>.34188.example.com:80:<%= cb.router_ip %> | --max-time | 10 | http://<%= cb.proj_name %>.34188.example.com/ |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1 http-8080"
    """

    # checking the access log verify if the UniqueID pattern is logged and matches
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | pod/<%= cb.router_pod %> |
      | c             | logs                     |
      | tail          | 10                       |
    Then the step should succeed
    And the output should match:
      | be_http:<%= cb.proj_name %>:route-unsecure |
    """

