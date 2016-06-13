Feature: Webhook REST Related Tests

  # @author cryan@redhat.com
  # @case_id 438843 438845
  Scenario Outline: Trigger build with webhook
    Given I have a project
    And I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json"
    Given the "ruby-sample-build-1" build completes
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"triggers": [{"type": "<type>","<type>": {"secret": "secret101"}}]}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | buildconfig |
      | name | ruby-sample-build |
    Then the output should not contain "<negative1>"
    Then the output should not contain "<negative2>"
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/<path><file>"
    And I replace lines in "<file>":
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051 ||
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-sample-build/webhooks/secret101/<type>
    :method: post
    :headers:
      :Content-Type: application/json
      :<header1>: <header2>
    :payload: <%= File.read("<file>").to_json %>
    """
    Then the step should succeed
    Given the "ruby-sample-build-2" build was created
    Given the "ruby-sample-build-2" build completes
    Given a pod becomes ready with labels:
      | deployment=frontend-2 |
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-sample-build/webhooks/secret101/<negative3>
    :method: post
    :headers:
      :Content-Type: application/json
    :payload: <%= File.read("<file>").to_json %>
    """
    Then the step should fail
    Then the output should contain "not accept"
    Examples:
      | type    | negative1 | negative2   | negative3 | path              | file              | header1        | header2 |
      | generic | GitHub    | ImageChange | github    | generic/fixtures/ | push-generic.json |                |         |
      | github  | Generic   | ImageChange | generic   | github/fixtures/  | pushevent.json    | X-Github-Event | push    |

  # @author yantan@redhat.com
  # @case_id 470417
  Scenario: Webhook request check
    Given I have a project
    When I run the :new_app client command with:
      | image_stream    | openshift/ruby:2.2 |
      | code            | https://github.com/openshift/ruby-hello-world |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | buildconfig         |
      | name     | ruby-hello-world |
    Then the step should succeed
    And the output should contain:
      | GitHub   |
      | Generic  |
    When I get project BuildConfig as JSON
    And evaluation of `@result[:parsed]['items'][0]['spec']['triggers'][0]['github']['secret']` is stored in the :secret_name clipboard
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/github/fixtures/pingevent.json"
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-hello-world/webhooks/<%= cb.secret_name %>/github
    :method: post
    :headers:
      :content_type: application/json
      :x_github_event: ping
    :payload: pingevent.json
    """
    Then the step should succeed

  # @author yantan@redhat.com
  # @case_id 438841
  Scenario: Trigger build manually with github webhook contained invalid/blank commit ID or branch name 
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:2.2 |
      | app_repo     | https://github.com/openshift-qe/ruby-ex#test-tcms438840|
    Then the step should succeed
    Given the "ruby-ex-1" build completes
    When I get project BuildConfig as JSON
    And evaluation of `@result[:parsed]['items'][0]['spec']['triggers'][0]['github']['secret']` is stored in the :secret_name clipboard
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/github/fixtures/pushevent.json"
    And I replace lines in "pushevent.json":
      | refs/heads/master | refs/heads/test123 |
    Then the step should succeed
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-ex/webhooks/<%= cb.secret_name %>/github
    :method: post
    :headers:
      :content-type: application/json
      :x-github-event: push
    :payload: <%= File.read("pushevent.json").to_json %>
    """
    Then the step should succeed
    When I run the :get client command with:
      | resource | build |
    Then the step should succeed
    And the output should not contain "ruby-ex-2"
    When I replace lines in "pushevent.json":
      | refs/heads/test123                        | refs/heads/test-tcms438840 |
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051  | 123456 |
    Then the step should succeed
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-ex/webhooks/<%= cb.secret_name %>/github
    :method: post
    :headers:
      :content-type: application/json
      :x-github-event: push
    :payload: <%= File.read("pushevent.json").to_json %>
    """
    Then the step should succeed
    When I run the :get client command with:
      | resource      | build |
    Then the step should succeed
    Given the "ruby-ex-2" build failed
    When I run the :logs client command with:
      | resource_name | build/ruby-ex-2 |
    Then the step should succeed
    And the output should contain:
      | error  |
      | 123456 |

  # @author yantan@redhat.com
  # @case_id 438840
  Scenario: Trigger build manually with github webhook contained specified branch and commit
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:2.2 |
      | app_repo     | https://github.com/openshift-qe/ruby-ex#test-tcms438840 |
    Then the step should succeed
    Given the "ruby-ex-1" build completes
    When I get project BuildConfig as JSON
    And evaluation of `@result[:parsed]['items'][0]['spec']['triggers'][0]['github']['secret']` is stored in the :secret_name clipboard
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/github/fixtures/pushevent.json"
    And I replace lines in "pushevent.json":
      | refs/heads/master                       | refs/heads/test-tcms438840               | 
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051| 89af0dd3183f71b9ec848d5cc2b55599244de867 |
    Then the step should succeed
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-ex/webhooks/<%= cb.secret_name %>/github
    :method: post
    :headers:
      :content-type: application/json
      :x-github-event: push
    :payload: <%= File.read("pushevent.json").to_json %>
    """
    Then the step should succeed
    Given the "ruby-ex-2" build completes
    When I run the :logs client command with:
      | resource_name | build/ruby-ex-2 |
    Then the step should succeed
    And the output should contain "89af0dd3183f71b9ec848d5cc2b55599244de867"
    When I expose the "ruby-ex" service
    Then I wait for a web server to become available via the "ruby-ex" route
    And the output should contain "autotest-438840"
    When I run the :describe client command with:
      | resource      | build     |
      | name          | ruby-ex-2 |
    Then the output should contain:
      | 89af0dd       |
    And I replace lines in "pushevent.json":
      | 89af0dd3183f71b9ec848d5cc2b55599244de867 | |
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-ex/webhooks/<%= cb.secret_name %>/github
    :method: post
    :headers:
      :content-type: application/json
      :x-github-event: push
    :payload: <%= File.read("pushevent.json").to_json %>
    """ 
    Then the step should succeed
    Given the "ruby-ex-3" build completes
    When I run the :logs client command with:
      | resource_name | build/ruby-ex-3 |
    Then the step should succeed
    And the output should not contain:
      | "commit"      |

  # @author cryan@redhat.com
  # @case_id 525850
  Scenario: New parameter can be passed via generic webhook
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby22-sample-build |
      | p | {"spec": {"triggers": [{"type": "Generic","generic": {"secret": "secret101","allowEnv": true}}]}} |
    Then the step should succeed
    #Cancel the first build to speed up the second generated by the webhook
    Given the "ruby22-sample-build-1" build becomes :running
    When I run the :cancel_build client command with:
      | build_name | ruby22-sample-build-1 |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/generic/fixtures/push-generic-envs.json"
    And I replace lines in "push-generic-envs.json":
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051 ||
      | sample-app | sample2-app |
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby22-sample-build/webhooks/secret101/generic
    :method: post
    :headers:
      :Content-Type: application/json
      :Openshift: generic
    :payload: <%= File.read("push-generic-envs.json").to_json %>
    """
    Then the step should succeed
    Given the "ruby22-sample-build-2" build becomes :running
    When I run the :describe client command with:
      | resource | pod                         |
      | name     | ruby22-sample-build-2-build |
    Then the step should succeed
    And the output should contain "sample2-app"
