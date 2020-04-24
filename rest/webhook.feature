Feature: Webhook REST Related Tests

  # @author yantan@redhat.com
  # @case_id OCP-12632
  Scenario: Webhook request check
    Given I have a project
    When I run the :new_app client command with:
      | image_stream    | openshift/ruby                                |
      | code            | https://github.com/openshift/ruby-hello-world |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | buildconfig         |
      | name     | ruby-hello-world |
    Then the step should succeed
    And the output should contain:
      | GitHub   |
      | Generic  |
    When I get project buildconfigs as JSON
    And evaluation of `@result[:parsed]['items'][0]['spec']['triggers'][0]['github']['secret']` is stored in the :secret_name clipboard
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/release-4.1/pkg/build/webhook/github/testdata/pingevent.json"
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/apis/build.openshift.io/v1/namespaces/<%= project.name %>/buildconfigs/ruby-hello-world/webhooks/<%= cb.secret_name %>/github
    :method: post
    :headers:
      :content_type: application/json
      :x_github_event: ping
    :payload: pingevent.json
    """
    Then the step should succeed

  # @author dyan@redhat.com
  Scenario Outline: Trigger build manually with webhook contained invalid/blank commit ID or branch name
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:latest |
      | app_repo     | https://github.com/openshift-qe/ruby-ex#test-tcms438840|
    Then the step should succeed
    Given the "ruby-ex-1" build completes
    When I get project buildconfigs as JSON
    And evaluation of `@result[:parsed]['items'][0]['spec']['triggers'][<row>]['<type>']['secret']` is stored in the :secret_name clipboard
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/<path><file>"
    And I replace lines in "<file>":
      | refs/heads/master | refs/heads/test123 |
      | <url_before>      | <url_after>        |
    Then the step should succeed
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/apis/build.openshift.io/v1/namespaces/<%= project.name %>/buildconfigs/ruby-ex/webhooks/<%= cb.secret_name %>/<type>
    :method: post
    :headers:
      :content-type: application/json
      :<header1>: <header2>
    :payload: <%= File.read("<file>").to_json %>
    """
    Then the step should succeed
    When I run the :get client command with:
      | resource | build |
    Then the step should succeed
    And the output should not contain "ruby-ex-2"
    When I replace lines in "<file>":
      | refs/heads/test123                        | refs/heads/test-tcms438840 |
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051  | 123456 |
    Then the step should succeed
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/apis/build.openshift.io/v1/namespaces/<%= project.name %>/buildconfigs/ruby-ex/webhooks/<%= cb.secret_name %>/<type>
    :method: post
    :headers:
      :content-type: application/json
      :<header1>: <header2>
    :payload: <%= File.read("<file>").to_json %>
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
    Examples:
      | type    | row | path              | file              | header1        | header2 | url_before                   | url_after |
      | generic | 1   | generic/testdata/ | push-generic.json |                |         | git://mygitserver/myrepo.git | https://github.com/openshift-qe/ruby-ex | # @case_id OCP-12764
      | github  | 0   | github/testdata/  | pushevent.json    | X-Github-Event | push    |                              |                                         |

  # @author dyan@redhat.com
  Scenario Outline: Trigger build manually with webhook contained specified branch and commit
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:latest |
      | app_repo     | https://github.com/openshift-qe/ruby-ex#test-tcms438840 |
    Then the step should succeed
    Given the "ruby-ex-1" build completes
    When I get project buildconfigs as JSON
    And evaluation of `@result[:parsed]['items'][0]['spec']['triggers'][<row>]['<type>']['secret']` is stored in the :secret_name clipboard
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/release-4.1/pkg/build/webhook/<path><file>"
    And I replace lines in "<file>":
      | refs/heads/master                        | refs/heads/test-tcms438840               |
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051 | 89af0dd3183f71b9ec848d5cc2b55599244de867 |
      | <url_before>                             | <url_after>                              |
    Then the step should succeed
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/apis/build.openshift.io/v1/namespaces/<%= project.name %>/buildconfigs/ruby-ex/webhooks/<%= cb.secret_name %>/<type>
    :method: post
    :headers:
      :content-type: application/json
      :<header1>: <header2>
    :payload: <%= File.read("<file>").to_json %>
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
    And I replace lines in "<file>":
      | 89af0dd3183f71b9ec848d5cc2b55599244de867 | |
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/apis/build.openshift.io/v1/namespaces/<%= project.name %>/buildconfigs/ruby-ex/webhooks/<%= cb.secret_name %>/<type>
    :method: post
    :headers:
      :content-type: application/json
      :<header1>: <header2>
    :payload: <%= File.read("<file>").to_json %>
    """
    Then the step should succeed
    Given the "ruby-ex-3" build completes
    When I run the :logs client command with:
      | resource_name | build/ruby-ex-3 |
    Then the step should succeed
    And the output should not contain:
      | "commit"      |
    Examples:
      | type    | row | path              | file              | header1        | header2 | url_before                   | url_after |
      | generic | 1   | generic/testdata/ | push-generic.json |                |         | git://mygitserver/myrepo.git | https://github.com/openshift-qe/ruby-ex | # @case_id OCP-12763
      | github  | 0   | github/testdata/  | pushevent.json    | X-Github-Event | push    |                              |                                         | # @case_id OCP-12760

  # @author shiywang@redhat.com
  # @case_id OCP-12513
  Scenario: Builder images with onbuild instructions and tar should build success
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | https://github.com/openshift/ruby-hello-world |
      | docker image | docker.io/ruby:2.1-onbuild |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed

  # @author shiywang@redhat.com
  # @case_id OCP-12514
  Scenario: Do sti build using image without tar and onbuild instruction should build successfully
    Given I have a project
    When I run the :new_app client command with:
      | docker image | docker.io/aosqe/ruby-20-centos7:notar~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed

  # @author shiywang@redhat.com
  # @case_id OCP-12515
  Scenario: Do sti build using image with onbuild instructions and without sh should build failed
    Given I have a project
    When I run the :new_app client command with:
      | docker image | docker.io/aosqe/rubyonbuild:nosh~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    And the "ruby-hello-world-1" build finished
    When I run the :logs client command with:
      | resource_name | pod/ruby-hello-world-1-build |
    And the output should contain "/bin/sh: No such file or directory"
