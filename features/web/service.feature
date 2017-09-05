Feature: services related feature on web console

  # @author wsun@redhat.com
  # @case_id OCP-10602
  Scenario: Access services from web console
    Given I login via web console
    Given I have a project
    # oc process -f file | oc create -f -
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc477695/hello.json"
    Then the step should succeed
    When I perform the :check_service_list_page web console action with:
      | project_name | <%= project.name %> |
      | service_name | hello-service       |
    Then the step should succeed
    When I perform the :check_one_service_page web console action with:
      | project_name | <%= project.name %>        |
      | service_name | hello-service              |
      | selectors    | name=hello-pod             |
      | type         | ClusterIP                  |
      | routes       | http://www.hello.com/testpath1 |
      | target_port  | 5555                       |
    Then the step should succeed
    When I replace resource "route" named "hello-route":
      | testpath1 | testpath2 |
    Then the step should succeed
    When I perform the :check_one_service_page web console action with:
      | project_name | <%= project.name %>        |
      | service_name | hello-service              |
      | selectors    | name=hello-pod             |
      | type         | ClusterIP                  |
      | routes       | http://www.hello.com/testpath2 |
      | target_port  | 5555                       |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/tc/tc477695/new_route.json |
      | n | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_one_service_page web console action with:
      | project_name | <%= project.name %>        |
      | service_name | hello-service              |
      | selectors    | name=hello-pod             |
      | type         | ClusterIP                  |
      | routes       | http://www.hello1.com      |
      | target_port  | 5555                       |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | route             |
      | object_name_or_id | hello-route |
      | n | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_one_service_page web console action with:
      | project_name | <%= project.name %>   |
      | service_name | hello-service         |
      | selectors    | name=hello-pod        |
      | type         | ClusterIP             |
      | routes       | http://www.hello1.com |
      | target_port  | 5555                  |
    Then the step should succeed
    When I replace resource "service" named "hello-service":
      | 5555 | 5556 |
    Then the step should succeed
    When I perform the :check_one_service_page web console action with:
      | project_name | <%= project.name %>     |
      | service_name | hello-service           |
      | selectors    | name=hello-pod          |
      | type         | ClusterIP               |
      | routes       | http://www.hello1.com   |
      | target_port  | 5556                    |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | service             |
      | object_name_or_id | hello-service |
      | n | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_deleted_service web console action with:
      | project_name    | <%= project.name %> |
      | service_name    | hello-service       |
      | service_warning | The service details could not be loaded |
    Then the step should succeed

  # @author etrott@redhat.com
  # @case_id OCP-10359
  Scenario: Group services on overview page
    # Given the master version >= "3.4"
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json" replacing paths:
      | ["metadata"]["name"]           | service-unsecure-1 |
      | ["metadata"]["labels"]["name"] | service-unsecure-1 |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json" replacing paths:
      | ["metadata"]["name"]           | service-unsecure-2 |
      | ["metadata"]["labels"]["name"] | service-unsecure-2 |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :group_services web console action with:
      | primary_service_name | service-unsecure   |
      | service_name         | service-unsecure-1 |
    Then the step should succeed
    When I perform the :check_service_group_entry web console action with:
      | primary_service_name | service-unsecure   |
      | service_name         | service-unsecure-1 |
    Then the step should succeed
    When I perform the :open_create_route_page_from_service_page web console action with:
      | project_name | <%= project.name%>  |
      | service_name | service-unsecure-1  |
    Then the step should succeed
    When I perform the :create_unsecured_route_pointing_to_two_services web console action with:
      | project_name    | <%= project.name%> |
      | route_name      | service-unsecure-1 |
      | service_name    | service-unsecure-1 |
      | first_svc_name  | service-unsecure-1 |
      | second_svc_name | service-unsecure-2 |
      | weight_one      | 1                  |
      | weight_two      | 1                  |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_service_group_with_route web console action with:
      | project_name         | <%= project.name %> |
      | primary_service_name | service-unsecure-1  |
      | service_name         | service-unsecure-1  |
    Then the step should succeed
    When I perform the :check_service_group_with_route web console action with:
      | project_name         | <%= project.name %> |
      | primary_service_name | service-unsecure-1  |
      | service_name         | service-unsecure-2  |
    Then the step should succeed
    When I perform the :group_services web console action with:
      | primary_service_name | service-unsecure   |
      | service_name         | service-unsecure-2 |
    Then the step should succeed
    When I perform the :check_service_group_entry web console action with:
      | primary_service_name | service-unsecure |
      | service_name         | service-unsecure |
    Then the step should succeed
    When I perform the :check_service_group_entry web console action with:
      | primary_service_name | service-unsecure   |
      | service_name         | service-unsecure-1 |
    Then the step should succeed
    When I perform the :check_service_group_entry web console action with:
      | primary_service_name | service-unsecure   |
      | service_name         | service-unsecure-2 |
    Then the step should succeed
    When I perform the :remove_service_from_group web console action with:
      | service_name | service-unsecure-1 |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I perform the :check_service_group_entry web console action with:
      | primary_service_name | service-unsecure   |
      | service_name         | service-unsecure-1 |
    Then the step should fail
    """
    When I perform the :remove_service_from_group web console action with:
      | service_name | service-unsecure-2  |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I perform the :check_service_group_entry web console action with:
      | primary_service_name | service-unsecure   |
      | service_name         | service-unsecure-2 |
    Then the step should fail
    """

  # @author etrott@redhat.com
  # @case_id OCP-11416
  Scenario: Display details on service page for LoadBalancer type service
    Given the master version >= "3.5"
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    When I run the :create_service_loadbalancer client command with:
      | name | hello-openshift |
      | tcp  | 5678:8080       |
    Then the step should succeed
    When I run the :create_route_passthrough client command with:
      | name     | myroute                 |
      | service  | hello-openshift         |
      | hostname | www.hello-openshift.com |
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
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/ExternalSvc-with-label-ports.yaml"
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
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    Given the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
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
