Feature: REST related features
  # @author xiaocwan@redhat.com
  # @case_id OCP-12188
  Scenario: The user should be system:anonymous user when access api without certificate and Bearer token
    Given I log the message> set up OpenShift with an identity provider that supports 'challenge: true'
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/apis/user.openshift.io/v1/users/~
    :method: :get
    :headers:
      :accept: text/html
    :max_redirects: 0
    """
    Then the step should fail
    And the expression should be true> @result[:exitstatus] == 403

  # @author cryan@redhat.com
  # @case_id OCP-12629
  Scenario: Could know the user or group's rights via ResourceAccessReview
    Given I have a project
    When I perform the :post_local_resource_access_reviews rest request with:
      | project_name | <%= project.name %> |
      | resource | pods |
      | verb | list |
    Then the step should succeed
    When I run the :policy_who_can client command with:
      | verb | list |
      | resource | replicationcontrollers |
    Then the output should contain "<%= user.name %>"
    When I run the :policy_who_can client command with:
      | verb | update |
      | resource | pods |
    Then the output should contain "<%= user.name %>"
