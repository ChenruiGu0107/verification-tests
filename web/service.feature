Feature: services related feature on web console

  # @author etrott@redhat.com
  # @case_id OCP-11416
  Scenario: Display details on service page for LoadBalancer type service
    Given the master version >= "3.5"
    Given I create a new project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/hello-pod.json |
    Then the step should succeed
    When I run the :create_service_loadbalancer client command with:
      | name | hello-openshift |
      | tcp  | 5678:8080       |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name     | myroute                 |
      | service  | hello-openshift         |
    Then the step should succeed
    When I perform the :goto_one_service_page web console action with:
      | project_name | <%= project.name %> |
      | service_name | hello-openshift     |
    Then the step should succeed
    When I run the :check_resource_details_list_on_service_page web console action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-11039
  Scenario: Display details on service page for ExternalName type service
    Given the master version >= "3.5"
    Given I have a project
    When I obtain test data file "services/ExternalSvc-with-label-ports.yaml"
    Then the step should succeed
    And I replace lines in "ExternalSvc-with-label-ports.yaml":
      | myproject | <%= project.name %> |
    When I run the :create client command with:
      | f | ExternalSvc-with-label-ports.yaml |
    Then the step should succeed
    When I perform the :goto_one_service_page web console action with:
      | project_name | <%= project.name %> |
      | service_name | mysvc               |
    Then the step should succeed
    When I run the :check_resource_details_list_on_service_page web console action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-11040
  @admin
  Scenario: Service page should show the summary of what pods it is sending traffic to
    Given the master version >= "3.5"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/unsecure/service_unsecure.json |
    Then the step should succeed

    When I perform the :goto_one_service_page web console action with:
      | project_name | <%= project.name%> |
      | service_name | service-unsecure   |
    Then the step should succeed
    When I run the :check_resource_details_list_on_service_page web console action
    Then the step should succeed

    When I run the :patch admin command with:
      | resource      | endpoints          |
      | resource_name | service-unsecure   |
      | n             | <%= project.name%> |
      | type          | json               |
      | p             | [{"op": "replace", "path": "/subsets/0/addresses/0/targetRef/name", "value": "testpod"}] |
    Then the step should succeed

    And I run the :check_pod_without_endpoints_error_on_service_page web console action
    Then the step should succeed
