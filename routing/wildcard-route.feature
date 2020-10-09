Feature: Testing wildcard routes
  # @author zzhao@redhat.com
  # @case_id OCP-11067
  Scenario: oc help information should contain option wildcard-policy
    Given I have a project
    When I run the :expose client command with:
      | resource | service   |
      | resource_name | service-secure |
      | help     |           |
    Then the step should succeed
    And the output should contain "--wildcard-policy="

    #check 'oc create route edge' help
    When I run the :create_route_edge client command with:
      | name   | route-edge |
      | help   |            |
    Then the step should succeed
    And the output should contain "--wildcard-policy="

    #Check 'oc create route passthrough' help
    When I run the :create_route_passthrough client command with:
      | name  | route-pass |
      | help  |            |
    Then the step should succeed
    And the output should contain "--wildcard-policy="

    #Test 'oc create route reencrypt' help
    When I run the :create_route_reencrypt client command with:
      | name | route-reen |
      | help |            |
    Then the step should succeed
    And the output should contain "--wildcard-policy="

  # @author hongli@redhat.com
  # @case_id OCP-30190
  @admin
  Scenario: set wildcardPolicy of routeAdmission to WildcardsAllowed
    Given the master version >= "4.5"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-30190" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctl-wildcard.yaml"
    When I run oc create over "ingressctl-wildcard.yaml" replacing paths:
      | ["metadata"]["name"] | test-30190                                    |
      | ["spec"]["domain"]   | <%= cb.subdomain.gsub("apps","test-30190") %> |
    Then the step should succeed

    # check the env in the router pod
    Given I use the "openshift-ingress" project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-30190 |
    And evaluation of `pod.ip` is stored in the :router_ip clipboard
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | env \| grep ROUTER_ALLOW_WILDCARD_ROUTES |
    Then the output should contain "true"
    """

    # create route in the first namespace
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/wildcard_route/caddy-docker.json"
    When I run the :create client command with:
      | f | caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    Given I obtain test data file "routing/unsecure/service_unsecure.json"
    When I run the :create client command with:
      | f | service_unsecure.json |
    Then the step should succeed
    Given I obtain test data file "routing/wildcard_route/route_edge.json"
    When I run the :create client command with:
      | f | route_edge.json |
    Then the step should succeed

    # check wildcards route works well
    Given I have a pod-for-ping in the project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -ksS | --resolve | wildcard.edge.example.com:443:<%= cb.router_ip %> | https://wildcard.edge.example.com |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1"
    When I execute on the pod:
      | curl | -ksS | --resolve | any.edge.example.com:443:<%= cb.router_ip %> | https://any.edge.example.com |
    Then the step should succeed
    And the output should contain "Hello-OpenShift-1"
    """

  # @author hongli@redhat.com
  # @case_id OCP-30191
  @admin
  Scenario: set wildcardPolicy of routeAdmission to WildcardsDisallowed
    Given the master version >= "4.5"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-30191" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctl-wildcard.yaml"
    When I run oc create over "ingressctl-wildcard.yaml" replacing paths:
      | ["metadata"]["name"]                         | test-30191                                    |
      | ["spec"]["domain"]                           | <%= cb.subdomain.gsub("apps","test-30191") %> |
      | ["spec"]["routeAdmission"]["wildcardPolicy"] | WildcardsDisallowed                           |
    Then the step should succeed

    # check the env in the router pod
    Given I use the "openshift-ingress" project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-30191 |
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | env \| grep ROUTER_ALLOW_WILDCARD_ROUTES |
    Then the output should contain "false"
    """

    # create route in the first namespace
    Given I switch to the first user
    And I use the "<%= cb.proj_name %>" project
    Given I obtain test data file "routing/wildcard_route/route_unsecure_test.example.com.json"
    When I run the :create client command with:
      | f | route_unsecure_test.example.com.json |
    Then the step should succeed

    # check wildcards route if admitted
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | route |
    Then the step should succeed
    And the output should match:
      | RouteNotAdmitted .*Subdomain |
    """

  # @author hongli@redhat.com
  # @case_id OCP-30192
  @admin
  Scenario: set wildcardPolicy of routeAdmission to invalid values
    Given the master version >= "4.5"
    And I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-30192" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    Given I obtain test data file "routing/operator/ingressctl-wildcard.yaml"
    When I run oc create over "ingressctl-wildcard.yaml" replacing paths:
      | ["metadata"]["name"]                         | test-30192                                    |
      | ["spec"]["domain"]                           | <%= cb.subdomain.gsub("apps","test-30192") %> |
      | ["spec"]["routeAdmission"]["wildcardPolicy"] | WildcardsDisallowed                           |
    Then the step should succeed
    Given I use the "openshift-ingress" project
    And a pod becomes ready with labels:
      | ingresscontroller.operator.openshift.io/deployment-ingresscontroller=test-30192 |

    # try to set invalid value
    When I run the :patch admin command with:
      | resource      | ingresscontroller                                     |
      | resource_name | test-30192                                            |
      | n             | openshift-ingress-operator                            |
      | p             | {"spec":{"routeAdmission":{"wildcardPolicy":"test"}}} |
      | type          | merge                                                 |
    Then the step should fail
    And the output should match:
      | is invalid:.*Unsupported value: "test" |
