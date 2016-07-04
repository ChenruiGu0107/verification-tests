Feature: Api proxy related cases
  
  # @author wjiang@redhat.com
  # @case_id 509124
  @admin
  Scenario: Cluster-admin can access both http and https pods and services via the API proxy
    Given I have a project
    Given the first user is cluster-admin
    When I run the :new_app client command with:
      |app_repo |nginx:1.10         |
    Then the step should succeed
    And I wait until the status of deployment "nginx" becomes :complete
    When I run the :get client command with:
      |resource |pods               |
      |l        |app=nginx          |
      |o        |yaml               |
    Then the step should succeed
    And the output is parsed as YAML
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :nginx_pod_name clipboard
    # check http service proxy
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/api/v1/proxy/namespaces/<%= project.name %>/services/http:nginx:8080-tcp/
    :method: :get
    :headers:
      :authorization: Bearer <%= user.get_bearer_token.token %>
    """
    Then the step should succeed
    And the output should contain:
      |Welcome to nginx!|

    # check http pod proxy
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/api/v1/proxy/namespaces/<%= project.name %>/pods/http:<%= cb.nginx_pod_name %>:8080/
    :method: :get
    :headers:
      :authorization: Bearer <%= user.get_bearer_token.token %>
    """
    Then the step should succeed
    And the output should contain:
      |Welcome to nginx!|


    When I run the :new_app client command with:
      |app_repo |liggitt/client-cert:latest       |
    Then the step should succeed
    And I wait until the status of deployment "client-cert" becomes :complete
    When I run the :get client command with:
      |resource |pods           |
      |l        |app=client-cert|
      |o        |yaml|
    Then the step should succeed
    And the output is parsed as YAML
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :client_cert_pod_name clipboard

    # check https service proxy
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/api/v1/proxy/namespaces/<%= project.name %>/services/https:client-cert:9443-tcp/
    :method: :get
    :headers:
      :authorization: Bearer <%= user.get_bearer_token.token %>
    """
    Then the step should succeed
    And the output should match:
      |system:master-proxy|

    # check https pod proxy
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/api/v1/proxy/namespaces/<%= project.name %>/pods/https:<%= cb.client_cert_pod_name %>:9443/
    :method: :get
    :headers:
      :authorization: Bearer <%= user.get_bearer_token.token %> 
    """
    Then the step should succeed
    And the output should match:
      |system:master-proxy|
