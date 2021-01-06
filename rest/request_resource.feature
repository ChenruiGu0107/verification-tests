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

  # @author xiuwang@redhat.com
  # @case_id OCP-18984
  @admin
  Scenario: Request to view all imagestreams via registry catalog api
    Given I have a project
    Given I enable image-registry default route
    Given default image registry route is stored in the :registry_route clipboard
    When I perform the HTTP request:
    """
    :url: https://<%= cb.registry_route %>/v2/_catalog?n=5
    :method: :get
    :headers:
      :Authorization: Bearer <%= user.cached_tokens.first %>
    """
    Then the step should fail
    #Then the output should contain "401 Unauthorized"
    Given cluster role "registry-viewer" is added to the "first" user
    When I perform the HTTP request:
    """
    :url: https://<%= cb.registry_route %>/v2/_catalog?n=5
    :method: :get
    :headers:
      :Authorization: Bearer <%= user.cached_tokens.first %>
    """
    Then the step should succeed
    #Then the output should contain "401"

  # @author xiuwang@redhat.com
  # @case_id OCP-12958
  @admin
  Scenario: Read and write image signatures with registry endpoint
    Given I have a project
    When I run the :tag client command with:
      | source      | quay.io/openshifttest/hello-openshift@sha256:424e57db1f2e8e8ac9087d2f5e8faea6d73811f0b6f96301bc94293680897073 |
      | dest        | <%= project.name %>/ho:latest         |
    Then the step should succeed
    Then I wait up to 60 seconds for the steps to pass:
    """
    And evaluation of `image_stream_tag("ho:latest").digest` is stored in the :image_id clipboard
    """
    Given I enable image-registry default route
    Given default image registry route is stored in the :registry_route clipboard
    Given a "imagesignature.json" file is created with the following lines:
     """
     {
       "schemaVersion": 2,
       "type": "atomic",
       "name": "<%= cb.image_id %>@imagesignature12958test",
       "content": "MjIK"
      }
     """
    When I perform the HTTP request:
    """
    :url: https://<%= cb.registry_route %>/extensions/v2/<%= project.name %>/ho/signatures/<%= cb.image_id %>
    :method: PUT
    :headers:
      :content-type: application/json
      :Authorization: Bearer <%= user.cached_tokens.first %>
    :payload: <%= File.read("imagesignature.json").to_json %>
    """
    Then the step should fail
    Given cluster role "system:image-signer" is added to the "first" user
    When I perform the HTTP request:
    """
    :url: https://<%= cb.registry_route %>/extensions/v2/<%= project.name %>/ho/signatures/<%= cb.image_id %>
    :method: PUT
    :headers:
      :content-type: application/json
      :Authorization: Bearer <%= user.cached_tokens.first %>
    :payload: <%= File.read("imagesignature.json").to_json %>
    """
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | image              |
      | resource_name | <%= cb.image_id %> |
      | o             | yaml               |
    Then the step should succeed
    Then the output should contain:
      | signatures |
      | name: <%= cb.image_id %>@imagesignature12958test |
    When I run the :delete client command with:
      | object_type | imagesignature |
      | object_name_or_id | <%= cb.image_id %>@imagesignature12958test  |
    Then the step should succeed
