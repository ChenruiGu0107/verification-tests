Feature: token feature
  # @author liyao@redhat.com
  # @case_id OCP-40587
  @admin
  Scenario: Audit log oauthaccesstoken creation and deletion
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | <%= user.name %>            |
      | password        | <%= user.password %>        |
      | config          | test.kubeconfig             |
      | skip_tls_verify | true                        |
    Then the step should succeed
    When I store the masters in the :masters clipboard
    And I use the "<%= cb.masters[0].name %>" node
    Given a "snippet_create" file is created with the following lines:
    """
    grep -hE '"requestURI":"/apis/oauth.openshift.io/v1/oauthaccesstokens","verb":"create"(.*)"userName":"<%= user.name %>"' /var/log/oauth-apiserver/audit.log | head -n 1
    """
    When I run commands on the host:
      | <%= File.read("snippet_create") %> |
    Then the step should succeed
    And the output should contain:
      | "userName":"<%= user.name %>" |
    When I run the :logout client command with:
      | config | test.kubeconfig |
    Then the step should succeed
    Given a "snippet_delete" file is created with the following lines:
    """
    grep -hE '"requestURI":"/apis/oauth.openshift.io/v1/oauthaccesstokens/[^"]+","verb":"delete","user":{"username":"<%= user.name %>"' /var/log/oauth-apiserver/audit.log | head -n 1
    """
    When I run commands on the host:
      | <%= File.read("snippet_delete") %> |
    Then the step should succeed
    And the output should contain:
      | "username":"<%= user.name %>" |
