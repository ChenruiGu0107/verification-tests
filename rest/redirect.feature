Feature: REST features
  # @author chuyu@redhat.com
  # @case_id OCP-22470
  Scenario: 4.x the basic challenge will be shown when user pass the X-CSRF-TOKEN http header
    Given I log the message> set up OpenShift with an identity provider that supports 'challenge: true'
    When I perform the HTTP request:
    """
    :url: <%= env.authentication_url %>/oauth/authorize?response_type=token&client_id=openshift-challenging-client
    :method: :get
    :headers:
      :accept: text/html
    :max_redirects: 0
    """
    Then the step should fail
    And the expression should be true> @result[:exitstatus] == 401
    And the expression should be true> @result[:headers]["warning"][0].include? "A non-empty X-CSRF-Token header is required to receive basic-auth challenges"

    When I perform the HTTP request:
    """
    :url: <%= env.authentication_url %>/oauth/authorize?response_type=token&client_id=openshift-challenging-client
    :method: :get
    :headers:
      :accept: text/html
      :X-CSRF-Token: 1
    :max_redirects: 0
    """
    Then the step should fail
    And the expression should be true> @result[:exitstatus] == 401
    And the expression should be true> @result[:headers]["www-authenticate"].include? "Basic realm=\"openshift\""
