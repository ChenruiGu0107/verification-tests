Feature: Test Ingress API logging options

  # @author aiyengar@redhat.com
  # @case_id OCP-30059
  @admin
  Scenario: Create an ingresscontroller that logs to a sidecar container
    Given the master version >= "4.5"
    And I have a project 
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-30059" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctl-sidecar-log.yaml"
    And I run oc create over "ingressctl-sidecar-log.yaml" replacing paths:
      | ["metadata"]["name"]                   | test-30059                                    |
      | ["spec"]["domain"]                     | <%= cb.subdomain.gsub("apps","test-30059") %> |
      | ["spec"]["defaultCertificate"]["name"] | router-certs-default                          |
    Then the step should succeed

    # Ensure the router with a sidecar "log" container is spawned
    Given I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-30059 |
    And evaluation of `pod.name` is stored in the :router_pod clipboard
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Then the expression should be true> deployment('router-test-30059').exists?
    When I run the :get admin command with:
      | resource      | pod                                   |    
      | resource_name | <%= cb.router_pod %>                  |
      | n             | openshift-ingress                     |
      | o             | jsonpath='{.spec.containers[1].name}' |
    Then the step should succeed
    And the output should contain "logs"

    # Create  project resource and route followed by curl to generate access traffic
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/list_for_caddy.json"
    When I run oc create over "list_for_caddy.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed     
    And a pod becomes ready with labels:
      | name=caddy-pods |
    And evaluation of `pod.ip` is stored in the :caddy_pod_ip clipboard
    Then the expression should be true> service('service-unsecure').exists?

    Given I obtain test data file "routing/unsecure/route_unsecure.json"
    When I run oc create over "route_unsecure.json" replacing paths:
      | ["spec"]["host"] | <%= cb.proj_name %>.30059.example.com |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | --resolve | <%= cb.proj_name %>.30059.example.com:80:<%= cb.router_ip %> | --max-time | 10 |  http://<%= cb.proj_name %>.30059.example.com |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1"
    """

    # checking the access log on the sidecar container
    Given I switch to cluster admin pseudo user
    And I use the router project
    Given I run the :logs admin command with:
      | resource_name | pod/<%= cb.router_pod %> |
      | c             | logs                     |
      | tail          | 15                       |
    Then the step should succeed
    And the output should match:
      | service-unsecure:<%= cb.caddy_pod_ip %>:8080 |
 

   # @author aiyengar@redhat.com
   # @case_id OCP-30066
   @admin
   Scenario: Enable log-send-hostname in HAproxy configuration by default
     Given the master version >= "4.5"
     And I have a project 
     And I store default router subdomain in the :subdomain clipboard
     Given I switch to cluster admin pseudo user
     And admin ensures "test-30066" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
     Given I obtain test data file "routing/operator/ingressctl-sidecar-log.yaml"
     And I run oc create over "ingressctl-sidecar-log.yaml" replacing paths:
       | ["metadata"]["name"]                   | test-30066                                    |
       | ["spec"]["domain"]                     | <%= cb.subdomain.gsub("apps","test-30066") %> |
       | ["spec"]["defaultCertificate"]["name"] | router-certs-default                          |
     Then the step should succeed

    # Verify the presence of the parameter inside haproxy.config file
    Given I switch to cluster admin pseudo user
    And I use the router project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-30066 |
    Then the expression should be true> deployment('router-test-30066').exists?
    And I wait up to 30 seconds for the steps to pass:
    """ 
    When I execute on the pod:
      | grep | log-send-hostname | /var/lib/haproxy/conf/haproxy.config | -q |
    Then the step should succeed
    """


   # @author aiyengar@redhat.com
   # @case_id OCP-30060
   @admin
   Scenario: Create an ingresscontroller that logs to rsyslog instance
     Given the master version >= "4.5"
     And I have a project
     And evaluation of `project.name` is stored in the :proj_name clipboard
     And I store default router subdomain in the :subdomain clipboard

     # Create rsyslogd pod in the project
     Given I switch to cluster admin pseudo user
     And I use the "<%= cb.proj_name %>" project
     Given I obtain test data file "routing/operator/rsyslogd-pod.yaml"
     When I run the :create client command with:
       | f | rsyslogd-pod.yaml |
     Then the step should succeed
     And a pod becomes ready with labels:
       | name=rsyslogd |
     And evaluation of `pod.name` is stored in the :rsyslog_pod clipboard
     And evaluation of `pod.ip` is stored in the :rsyslog_ip clipboard

     # Create the ingresscontroller pointing to rsyslogd pod ip
     Given admin ensures "test-30060" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
     And I obtain test data file "routing/operator/ingressctl-rsyslog-log.yaml"
     And I run oc create over "ingressctl-rsyslog-log.yaml" replacing paths:
       | ["metadata"]["name"]                                              | test-30060                                    |
       | ["spec"]["domain"]                                                | <%= cb.subdomain.gsub("apps","test-30060") %> |
       | ["spec"]["defaultCertificate"]["name"]                            | router-certs-default                          |
       | ["spec"]["logging"]["access"]["destination"]["type"]              | Syslog                                        |
       | ["spec"]["logging"]["access"]["destination"]["syslog"]["address"] | <%= cb.rsyslog_ip %>                          |
     Then the step should succeed
     Given I use the router project
     And a pod becomes ready with labels:
       | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-30060 |
     And evaluation of `pod.ip` is stored in the :router_ip clipboard
     Then the expression should be true> deployment('router-test-30060').exists?

     # Create project resources
     Given I switch to the first user
     And I use the "<%= cb.proj_name %>" project
     Given I obtain test data file "routing/list_for_caddy.json"
     When I run oc create over "list_for_caddy.json" replacing paths:
       | ["items"][0]["spec"]["replicas"] | 1 |
     Then the step should succeed
     And a pod becomes ready with labels:
       | name=caddy-pods |
     And evaluation of `pod.ip` is stored in the :caddy_pod_ip clipboard
     Then the expression should be true> service('service-unsecure').exists?

     # Deploy route to test
     Given I obtain test data file "routing/unsecure/route_unsecure.json"
     When I run oc create over "route_unsecure.json" replacing paths:
       | ["spec"]["host"] | <%= cb.proj_name %>.30060.example.com |
     Then the step should succeed

     # Generate application traffic via curl
     Given I have a pod-for-ping in the project
     And I wait up to 30 seconds for the steps to pass:
     """
     When I execute on the pod:
       | curl | --resolve | <%= cb.proj_name %>.30060.example.com:80:<%= cb.router_ip %> | --max-time | 10 | http://<%= cb.proj_name %>.30060.example.com |
     Then the step should succeed
     And the output should contain "Hello-OpenShift-1"
     """

     # Check rsyslogd container for the logs
     And I wait up to 30 seconds for the steps to pass:
     """
     When I run the :logs client command with:
       | resource_name | pod/<%= cb.rsyslog_pod %> |
       | tail          | 10                        |
     Then the output should contain:
       | service-unsecure:<%= cb.caddy_pod_ip %>:8080 |
     """

