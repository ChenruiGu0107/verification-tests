Feature: Api proxy related cases

  # @author wjiang@redhat.com
  # @case_id OCP-11531
  # @bug_id 1346167
  Scenario: Can access both http and https pods and services via the API proxy
    Given I have a project
    When I run the :new_app client command with:
      | docker_image | quay.io/openshifttest/hello-openshift:openshift |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=hello-openshift |
    # check http service proxy
    When I perform the :proxy_get_request_to_resource rest request with:
      | project_name  | <%= project.name %> |
      | resource_type | services            |
      | resource_name | hello-openshift     |
      | protocol_type | http                |
      | port_name     | 8080-tcp            |
      | app_path      | /                   |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift! |
    # check http pod proxy
    When I perform the :proxy_get_request_to_resource rest request with:
      | project_name  | <%= project.name %>      |
      | protocol_type | http                     |
      | resource_type | pods                     |
      | resource_name | <%= pod.name  %> |
      | port_name     | 8080                     |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift! |


    When I run the :new_app client command with:
      | app_repo | quay.io/openshifttest/nginx-alpine:latest |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=nginx-alpine |
    # check https service proxy
    # there need slowdown the network
    And I wait up to 60 seconds for the steps to pass:
    """
    When I perform the :proxy_get_request_to_resource rest request with:
      | project_name  | <%= project.name %> |
      | protocol_type | https               |
      | resource_type | services            |
      | resource_name | nginx-alpine        |
      | port_name     | 8443-tcp            |
    Then the step should succeed
    """
    # check https pod proxy
    When I perform the :proxy_get_request_to_resource rest request with:
      | project_name  | <%= project.name %> |
      | protocol_type | https               |
      | resource_type | pods                |
      | resource_name | <%= pod.name  %>    |
      | port_name     | 8443                |
    Then the step should succeed
