Feature: Api proxy related cases
  
  # @author wjiang@redhat.com
  # @case_id OCP-11531
  # @bug_id 1346167
  @admin
  Scenario: Cluster-admin can access both http and https pods and services via the API proxy
    Given I have a project
    Given the first user is cluster-admin
    When I run the :new_app client command with:
      |app_repo | openshift/hello-openshift:latest |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=hello-openshift |
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
      |app_repo |liggitt/client-cert:latest       |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=client-cert |
    # check https service proxy
    # there need slowdown the network
    And I wait up to 60 seconds for the steps to pass:
    """
    When I perform the :proxy_get_request_to_resource rest request with:
      | project_name  | <%= project.name %> |
      | protocol_type | https               |
      | resource_type | services            |
      | resource_name | client-cert         |
      | port_name     | 9443-tcp            |
    Then the step should succeed
    And the output should match:
      |system:master-proxy|
    """
    # check https pod proxy
    When I perform the :proxy_get_request_to_resource rest request with:
      | project_name  | <%= project.name %> |
      | protocol_type | https               |
      | resource_type | pods                |
      | resource_name | <%= pod.name  %>    |
      | port_name     | 9443                |
    Then the step should succeed
    And the output should match:
      |system:master-proxy|
