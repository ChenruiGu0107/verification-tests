Feature: REST related features
  # @author xiaocwan@redhat.com
  # @case_id 457806
  Scenario: [origin_platformexp_397]The user should be system:anonymous user when access api without certificate and Bearer token
    Given I log the message> set up OpenShift with an identity provider that supports 'challenge: true'
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/users/~
    :method: :get
    :headers:
      :accept: text/html
    :max_redirects: 0
    """
    Then the step should fail
    And the output should match:
      | system:anonymous.* cannot get users at the cluster scope |
      | eason.*orbidden |
    And the expression should be true> @result[:exitstatus] == 403

  # @author cryan@redhat.com
  # @case_id 470296
  Scenario: Could know the user or group's rights via ResourceAccessReview
    Given I have a project
    When I perform the :post_local_resource_access_reviews rest request with:
      | project_name | <%= project.name %> |
      | resource | pods |
      | verb | list |
    Then the step should succeed
    And the output should contain "system:nodes"
    When I run the :policy_who_can client command with:
      | verb | list |
      | resource | replicationcontrollers |
    Then the output should contain "<%= user.name %>"
    When I run the :policy_who_can client command with:
      | verb | update |
      | resource | pods |
    Then the output should contain "<%= user.name %>"
