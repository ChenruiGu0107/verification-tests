Feature: Testing the isolation during build scenarios

  # @author zzhao@redhat.com
  # @bug_id 1487652
  @admin
  Scenario Outline: EgressNetworkPolicy constrained build process to extranet for multitenant plugin
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard

    # Create egress policy
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/egress-ingress/dns-egresspolicy2.json  |
      | n | <%= cb.proj1 %> |
    Then the step should succeed
    When I run the :new_app client command with:
      | app_repo | <repo> |
    Then the step should succeed
    And the "ruby-docker-test-1" build was created
    And I wait up to 200 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | build/ruby-docker-test-1 |
    Then the output should contain "sleep 10000"
    """
    When I run the :logs client command with:
      | resource_name | build/ruby-docker-test-1 |
    Then the output should contain 2 times:
      | access yahoo.com fail |
    And the output should contain "Network is unreachable"    

    Examples:
      | type   | repo                                                                   |
      | Docker | https://github.com/zhaozhanqi/ruby-docker-test/#network_isolation      | # @case_id OCP-15714
      | sti    | ruby~https://github.com/zhaozhanqi/ruby-docker-test/#network_isolation | # @case_id OCP-15715


  # @author zzhao@redhat.com
  # @bug_id 1487652
  Scenario Outline: Build-container is able to access other projects pod for subnet plugin
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `service("test-service").ip(user: user)` is stored in the :p1svcip clipboard
    And evaluation of `service("test-service").ports(user: user)[0].dig("port")` is stored in the :p1svcport clipboard

    Given I switch to the second user
    And I have a project
    When I run the :new_app client command with:
      | app_repo | <repo> |
    Then the step should succeed
    And the "ruby-docker-test-1" build was created
    When I run the :delete client command with:
      | object_type       | build         |
      | object_name_or_id | ruby-docker-test-1 |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | bc |
      | resource_name | ruby-docker-test |
      | p             | {"spec": {"strategy": {"<strategy>": {"env": [{"name": "SVC_IP","value": "<%= cb.p1svcip %>:<%= cb.p1svcport %>"}]}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-docker-test |
    Then the step should succeed
    And the "ruby-docker-test-2" build was created
    And I wait up to 100 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | build/ruby-docker-test-2 |
    Then the output should contain "Hello OpenShift"
    """

    Examples:
      | type   | repo                                                           | strategy       |
      | Docker | https://github.com/zhaozhanqi/ruby-docker-test/#isolation      | dockerStrategy | # @case_id OCP-15743
      | sti    | ruby~https://github.com/zhaozhanqi/ruby-docker-test/#isolation | sourceStrategy | # @case_id OCP-15742
