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
    Given I obtain test data file "routing/web-server-rc.yaml"
    When I run the :create client command with:
      | f | web-server-rc.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=web-server-rc |
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
    And the output should contain "second-test"
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
    Given I obtain test data file "routing/web-server-rc.yaml"
    When I run oc create over "web-server-rc.yaml" replacing paths:
      | ["items"][0]["metadata"]["name"] | web-pods |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=web-server-rc |
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
    And the output should contain "second-test"
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
      | nginx |
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
    Given I obtain test data file "routing/web-server-rc.yaml"
    When I run oc create over "web-server-rc.yaml" replacing paths:
      | ["items"][0]["metadata"]["name"] | web-pods |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=web-server-rc |
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
    And the output should contain "second-test"
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
      | ngi |
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
    Given I obtain test data file "routing/web-server-rc.yaml"
    When I run the :create client command with:
      | f | web-server-rc.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=web-server-rc |
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
    And the output should contain "Hello-OpenShift"
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
    Given I obtain test data file "routing/web-server-rc.yaml"
    When I run the :create client command with:
      | f | web-server-rc.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=web-server-rc |
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
    And the output should contain "Hello-OpenShift"
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
    Given I obtain test data file "routing/web-server-rc.yaml"
    When I run oc create over "web-server-rc.yaml" replacing paths:
      | f | web-server-rc.yaml |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=web-server-rc |
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
    And the output should contain "Hello-OpenShift"
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
    Given I obtain test data file "routing/web-server-rc.yaml"
    When I run the :create client command with:
      | f | web-server-rc.yaml|
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=web-server-rc |
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
    And the output should contain "Hello-OpenShift"
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


  # @author aiyengar@redhat.com
  # @case_id OCP-34231
  @admin
  Scenario: Configure Ingresscontroller to preserve existing header with "forwardedHeaderPolicy" set to Append
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-34231" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctrl-x_forwarded.yaml"
    And I run oc create over "ingressctrl-x_forwarded.yaml" replacing paths:
      | ["spec"]["domain"]   | <%= cb.subdomain.gsub("apps","test-34231") %> |
      | ["metadata"]["name"] | test-34231                                    |
    Then the step should succeed

    # Ensure the router gets spawned and the vital info is saved in the cb and check if the env has the "append" value set
    Given I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-34231 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Then the expression should be true> deployment('router-test-34231').exists?
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash | -lc | env \|grep -w "ROUTER_SET_FORWARDED_HEADERS=append" | -q |
    Then the step should succeed
    """

    # Deploy backend pods/services
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/header-test/dc.json"
    When I run the :create client command with:
      | f | dc.json |
    Then the step should succeed
    Given I obtain test data file "routing/header-test/insecure-service.json"
    When I run the :create client command with:
      | f | insecure-service.json |
    Then the step should succeed

    # Deploy route
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"]       | <%= cb.proj_name %>.34231.example.com |
      | ["metadata"]["name"]   | route-unsecure                        |
      | ["spec"]["to"]["name"] | header-test-insecure                  |
    Then the step should succeed

    # Generate app traffic and verify if the headers match the set value of "append"
    Given I have a pod-for-ping in the project
    And evaluation of `pod.ip` is stored in the :hello_pod_ip clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -sS | --resolve | <%= cb.proj_name %>.34231.example.com:80:<%= cb.router_ip %> | --max-time | 10 | http://<%= cb.proj_name %>.34231.example.com/ |
    Then the step should succeed
    And the output should match:
      | <%= cb.hello_pod_ip %>                                                           |
      | <%= cb.proj_name %>.34231.example.com                                            |
      | for=<%= cb.hello_pod_ip %>;host=<%= cb.proj_name %>.34231.example.com;proto=http |
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34233
  @admin
  Scenario: Configure Ingresscontroller to replace any existing Forwarded header with "forwardedHeaderPolicy" set to Replace
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-34233" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctrl-x_forwarded.yaml"
    And I run oc create over "ingressctrl-x_forwarded.yaml" replacing paths:
      | ["spec"]["domain"]                               | <%= cb.subdomain.gsub("apps","test-34233") %> |
      | ["metadata"]["name"]                             | test-34233                                    |
      | ["spec"]["httpHeaders"]["forwardedHeaderPolicy"] | Replace                                       |
    Then the step should succeed

    # Ensure the router gets spawned and the vital info is saved in the cb and check if the env has the "replace" value set
    Given I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-34233 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Then the expression should be true> deployment('router-test-34233').exists?
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash | -lc | env \|grep -w "ROUTER_SET_FORWARDED_HEADERS=replace" | -q |
    Then the step should succeed
    """

    # Deploy backend pods/services
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/header-test/dc.json"
    When I run the :create client command with:
      | f | dc.json |
    Then the step should succeed
    Given I obtain test data file "routing/header-test/insecure-service.json"
    When I run the :create client command with:
      | f | insecure-service.json |
    Then the step should succeed

    # Deploy route
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"]       | <%= cb.proj_name %>.34233.example.com |
      | ["metadata"]["name"]   | route-unsecure                        |
      | ["spec"]["to"]["name"] | header-test-insecure                  |
    Then the step should succeed

    # Generate app traffic and verify if the headers match the set value of "Replace"
    Given I have a pod-for-ping in the project
    And evaluation of `pod.ip` is stored in the :hello_pod_ip clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -sS | --resolve | <%= cb.proj_name %>.34233.example.com:80:<%= cb.router_ip %> | --max-time | 10 | http://<%= cb.proj_name %>.34233.example.com/ |
    Then the step should succeed
    And the output should match:
      | <%= cb.hello_pod_ip %>                                                           |
      | <%= cb.proj_name %>.34233.example.com                                            |
      | for=<%= cb.hello_pod_ip %>;host=<%= cb.proj_name %>.34233.example.com;proto=http |
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34234
  @admin
  Scenario: Configure Ingresscontroller to set the headers if they are not already set with "forwardedHeaderPolicy" set to Ifnone
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-34234" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctrl-x_forwarded.yaml"
    And I run oc create over "ingressctrl-x_forwarded.yaml" replacing paths:
      | ["spec"]["domain"]                               | <%= cb.subdomain.gsub("apps","test-34234") %> |
      | ["metadata"]["name"]                             | test-34234                                    |
      | ["spec"]["httpHeaders"]["forwardedHeaderPolicy"] | IfNone                                        |
    Then the step should succeed

    # Ensure the router gets spawned and the vital info is saved in the cb and check if the env has the "Ifnone" value set
    Given I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-34234 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Then the expression should be true> deployment('router-test-34234').exists?
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash | -lc | env \|grep -w "ROUTER_SET_FORWARDED_HEADERS=if-none" | -q |
    Then the step should succeed
    """

    # Deploy backend pods/services
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/header-test/dc.json"
    When I run the :create client command with:
      | f | dc.json |
    Then the step should succeed
    Given I obtain test data file "routing/header-test/insecure-service.json"
    When I run the :create client command with:
      | f | insecure-service.json |
    Then the step should succeed

    # Deploy route
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"]       | <%= cb.proj_name %>.34234.example.com |
      | ["metadata"]["name"]   | route-unsecure                        |
      | ["spec"]["to"]["name"] | header-test-insecure                  |
    Then the step should succeed

    # Generate app traffic and verify if the headers match the set value of "if-none"
    Given I have a pod-for-ping in the project
    And evaluation of `pod.ip` is stored in the :hello_pod_ip clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -sS | --resolve | <%= cb.proj_name %>.34234.example.com:80:<%= cb.router_ip %> | --max-time | 10 | http://<%= cb.proj_name %>.34234.example.com/ |
    Then the step should succeed
    And the output should match:
      | <%= cb.hello_pod_ip %>                                                           |
      | <%= cb.proj_name %>.34234.example.com                                            |
      | for=<%= cb.hello_pod_ip %>;host=<%= cb.proj_name %>.34234.example.com;proto=http |
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34235
  @admin
  Scenario: Configure Ingresscontroller to never set the headers and preserve existing with "forwardedHeaderPolicy" set to Never
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-34235" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctrl-x_forwarded.yaml"
    And I run oc create over "ingressctrl-x_forwarded.yaml" replacing paths:
      | ["spec"]["domain"]                               | <%= cb.subdomain.gsub("apps","test-34235") %> |
      | ["metadata"]["name"]                             | test-34235                                    |
      | ["spec"]["httpHeaders"]["forwardedHeaderPolicy"] | Never                                         |
    Then the step should succeed

    # Ensure the router gets spawned and the vital info is saved in the cb and check if the env has the "Never" value set
    Given I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-34235 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Then the expression should be true> deployment('router-test-34235').exists?
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash | -lc | env \|grep  ROUTER_SET_FORWARDED_HEADERS=never | -q |
    Then the step should succeed
    """

    # Deploy backend pods/services
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/header-test/dc.json"
    When I run the :create client command with:
      | f | dc.json |
    Then the step should succeed
    Given I obtain test data file "routing/header-test/insecure-service.json"
    When I run the :create client command with:
      | f | insecure-service.json |
    Then the step should succeed

    # Deploy route
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"]       | <%= cb.proj_name %>.34235.example.com |
      | ["metadata"]["name"]   | route-unsecure                        |
      | ["spec"]["to"]["name"] | header-test-insecure                  |
    Then the step should succeed

    # Generate app traffic and verify if the headers match the set value of "Never"
    Given I have a pod-for-ping in the project
    And evaluation of `pod.ip` is stored in the :hello_pod_ip clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
     | curl | -sS | --resolve | <%= cb.proj_name %>.34235.example.com:80:<%= cb.router_ip %> | --max-time | 10 | http://<%= cb.proj_name %>.34235.example.com |
    Then the step should succeed
    And the output should match "<%= cb.proj_name %>.34235.example.com"
    And the output should not contain "x-forwarded"
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34236
  @admin
  Scenario: "forwardedHeaderPolicy" option defaults to "Append" if none is defined in the ingresscontroller configuration
    Given the master version >= "4.6"
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash | -lc | env \|grep -w "ROUTER_SET_FORWARDED_HEADERS=append" | -q |
    Then the step should succeed
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34246
  @admin
  Scenario: Configure a different header policy for the route with "haproxy.router.openshift.io/set-forwarded-headers" annotations
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    # Check the default header policy for the router
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash | -lc | env \|grep  -w "ROUTER_SET_FORWARDED_HEADERS=append" | -q |
    Then the step should succeed
    """

    # Deploy pods/service in a project
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/header-test/dc.json"
    When I run the :create client command with:
      | f | dc.json |
    Then the step should succeed
    Given I obtain test data file "routing/header-test/insecure-service.json"
    When I run the :create client command with:
      | f | insecure-service.json |
    Then the step should succeed

    # Deploy route and add forwarded annotation to the route
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"]       | <%= cb.proj_name %>.34247.example.com |
      | ["metadata"]["name"]   | route-unsecure                        |
      | ["spec"]["to"]["name"] | header-test-insecure                  |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                     |
      | resourcename | route-unsecure                                            |
      | keyval       | haproxy.router.openshift.io/set-forwarded-headers=if-none |
    Then the step should succeed

    # switch to router project to verify the configurations inside proxy pods.
    Given I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash | -lc | grep -w "route-unsecure" haproxy.config -A3 \|grep "if-none" -q |
    Then the step should succeed
    """


  # @author aiyengar@redhat.com
  # @case_id OCP-34247
  @admin
  Scenario: Different Routes can have different policy with "haproxy.router.openshift.io/set-forwarded-headers" annotations
    Given the master version >= "4.6"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given all default router pods become ready
    Then evaluation of `pod.name` is stored in the :router_pod clipboard
    # Check the default header option for the router
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash | -lc | env \|grep -w "ROUTER_SET_FORWARDED_HEADERS=append" | -q |
    Then the step should succeed
    """

    # Deploy 2 pods/services in a project
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/abrouting/abtest-websrv1.yaml"
    When I run the :create client command with:
      | f | abtest-websrv1.yaml |
    Then the step should succeed
    Given I obtain test data file "routing/abrouting/abtest-websrv2.yaml"
    When I run the :create client command with:
      | f | abtest-websrv2.yaml |
    Then the step should succeed
    And all pods in the project are ready

    # Deploy two routes with independent/different annotations
    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"]     | <%= cb.proj_name %>.route-1.34247.example.com |
      | ["metadata"]["name"] | route-unsecure-1                              |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                     |
      | resourcename | route-unsecure-1                                          |
      | keyval       | haproxy.router.openshift.io/set-forwarded-headers=if-none |
    Then the step should succeed
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"]       | <%= cb.proj_name %>.route-2.34247.example.com |
      | ["metadata"]["name"]   | route-unsecure-2                              |
      | ["spec"]["to"]["name"] | service-unsecure-2                            |
    Then the step should succeed
    When I run the :annotate client command with:
      | resource     | route                                                   |
      | resourcename | route-unsecure-2                                        |
      | keyval       | haproxy.router.openshift.io/set-forwarded-headers=never |
    Then the step should succeed

    # Check the state in the haproxy configuration
    Given I switch to cluster admin pseudo user
    And I use the router project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.router_pod %>" pod:
      | bash | -lc | grep -w "route-unsecure-1" haproxy.config -A3 \|grep "if-none" -q |
      | bash | -lc | grep -w "route-unsecure-2" haproxy.config -A3 \|grep "never" -q   |
    Then the step should succeed
    """
