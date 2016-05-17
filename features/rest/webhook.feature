Feature: Webhook REST Related Tests

  # @author cryan@redhat.com
  # @case_id 438843
  Scenario: Trigger build with generic webhook
    Given I have a project
    And I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json"
    Given I get project builds
    Then the output should contain "ruby-sample-build-1"
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"triggers": [{"type": "Generic","generic": {"secret": "secret101"}}]}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | buildconfig |
      | name | ruby-sample-build |
    Then the output should not contain:
      | GitHub |
      | ImageChange |
    When I git clone the repo "https://github.com/openshift/origin"
    Then the step should succeed
    And I replace lines in "origin/pkg/build/webhook/generic/fixtures/push-generic.json":
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051 ||
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-sample-build/webhooks/secret101/generic
    :method: post
    :headers:
      :Content-Type: application/json
    :payload: origin/pkg/build/webhook/generic/fixtures/push-generic.json
    """
    Then the step should succeed
    Given I get project builds
    Then the output should contain "ruby-sample-build-2"
    Given the "ruby-sample-build-2" build completes
    Given a pod becomes ready with labels:
      | deployment=frontend-2 |
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-sample-build/webhooks/secret101/github
    :method: post
    :headers:
      :Content-Type: application/json
    :payload: origin/pkg/build/webhook/generic/fixtures/push-generic.json
    """
    Then the step should fail
    Then the output should contain "not accept"

