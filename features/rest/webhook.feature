Feature: Webhook REST Related Tests

  # @author cryan@redhat.com
  # @case_id OCP-11693 OCP-11875
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
      | generic | GitHub    | ImageChange | github    | generic/testdata/ | push-generic.json |                |         |
      | github  | Generic   | ImageChange | generic   | github/testdata/  | pushevent.json    | X-Github-Event | push    |

  # @author yantan@redhat.com
  # @case_id OCP-12632
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
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/github/testdata/pingevent.json"
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

  # @author yantan@redhat.com dyan@redhat.com
  # @case_id 438841 438853
  Scenario Outline: Trigger build manually with webhook contained invalid/blank commit ID or branch name 
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:2.2 |
      | app_repo     | https://github.com/openshift-qe/ruby-ex#test-tcms438840|
    Then the step should succeed
    Given the "ruby-ex-1" build completes
    When I get project BuildConfig as JSON
    And evaluation of `@result[:parsed]['items'][0]['spec']['triggers'][<row>]['<type>']['secret']` is stored in the :secret_name clipboard
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/<path><file>"
    And I replace lines in "<file>":
      | refs/heads/master | refs/heads/test123 |
      | <url_before>      | <url_after>        |
    Then the step should succeed
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-ex/webhooks/<%= cb.secret_name %>/<type>
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
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-ex/webhooks/<%= cb.secret_name %>/<type>
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
      | generic | 1   | generic/testdata/ | push-generic.json |                |         | git://mygitserver/myrepo.git | https://github.com/openshift-qe/ruby-ex |
      | github  | 0   | github/testdata/  | pushevent.json    | X-Github-Event | push    |                              |                                         |

  # @author yantan@redhat.com dyan@redhat.com
  # @case_id 438840 438851
  Scenario Outline: Trigger build manually with webhook contained specified branch and commit
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:2.2 |
      | app_repo     | https://github.com/openshift-qe/ruby-ex#test-tcms438840 |
    Then the step should succeed
    Given the "ruby-ex-1" build completes
    When I get project BuildConfig as JSON
    And evaluation of `@result[:parsed]['items'][0]['spec']['triggers'][<row>]['<type>']['secret']` is stored in the :secret_name clipboard
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/<path><file>"
    And I replace lines in "<file>":
      | refs/heads/master                        | refs/heads/test-tcms438840               | 
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051 | 89af0dd3183f71b9ec848d5cc2b55599244de867 |
      | <url_before>                             | <url_after>                              |
    Then the step should succeed
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-ex/webhooks/<%= cb.secret_name %>/<type>
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
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby-ex/webhooks/<%= cb.secret_name %>/<type>
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
      | generic | 1   | generic/testdata/ | push-generic.json |                |         | git://mygitserver/myrepo.git | https://github.com/openshift-qe/ruby-ex | 
      | github  | 0   | github/testdata/  | pushevent.json    | X-Github-Event | push    |                              |                                         |

  # @author cryan@redhat.com
  # @case_id OCP-11270
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
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/generic/testdata/push-generic-envs.json"
    And I replace lines in "push-generic-envs.json":
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051 ||
      | EXAMPLE    | TEST  |
      | sample-app | valid |
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby22-sample-build/webhooks/secret101/generic
    :method: post
    :headers:
      :content-type: application/json
      :openshift: generic
    :payload: <%= File.read("push-generic-envs.json").to_json %>
    """
    Then the step should succeed
    Given the "ruby22-sample-build-2" build becomes :running
    When I run the :describe client command with:
      | resource | pod                         |
      | name     | ruby22-sample-build-2-build |
    Then the step should succeed
    And the output should contain:
      | TEST  |
      | valid |
      | EXAMPLE    |
      | sample-app |

  # @author dyan@redhat.com
  # @case_id OCP-10832
  Scenario: Existing parameter can be overlapped via generic webhook
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby22-sample-build |
      | p | {"spec": {"triggers": [{"type": "Generic","generic": {"secret": "secret101","allowEnv": true}}]}} |
    Then the step should succeed
    Given the "ruby22-sample-build-1" build becomes :running
    When I run the :cancel_build client command with:
      | build_name | ruby22-sample-build-1 |
    Then the step should succeed
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/master/pkg/build/webhook/generic/testdata/push-generic-envs.json"
    And I replace lines in "push-generic-envs.json":
      | 9bdc3a26ff933b32f3e558636b58aea86a69f051 ||
      | sample-app | sample-php-app |
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/oapi/v1/namespaces/<%= project.name %>/buildconfigs/ruby22-sample-build/webhooks/secret101/generic
    :method: post
    :headers:
      :content_type: application/json
      :openshift: generic
    :payload: <%= File.read("push-generic-envs.json").to_json %>
    """
    Then the step should succeed
    Given the "ruby22-sample-build-2" build becomes :running
    When I run the :describe client command with:
      | resource | pod                         |
      | name     | ruby22-sample-build-2-build |
    Then the step should succeed
    And the output should contain "sample-php-app"
    And the output should not contain "sample-app"

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
  
  # @author wewang@redhat.com
  # @case_id OCP-9663
  @admin
  @destructive
  Scenario: Verify guestbook example of Atomic Host works
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/authorization/scc/scc_privileged.yaml"
    Given the following scc policy is created: scc_privileged.yaml
    Then the step should succeed
    And I run the :patch admin command with:
      | resource      | scc     |
      | resource_name | scc-pri |
      | p             | {"groups":["system:serviceaccounts:default","system:serviceaccounts:<%= project.name %>"]} |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/509014/redis-master-controller.yaml |
    Then the step should succeed
    Then a pod becomes ready with labels:
      | app=redis,role=master |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/kubernetes/kubernetes/f6f013b992441379a67bf98a5ba4b7e975c3470e/examples/guestbook/redis-master-service.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/kubernetes/kubernetes/f6f013b992441379a67bf98a5ba4b7e975c3470e/examples/guestbook/redis-slave-controller.yaml |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | app=redis,role=slave  |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/kubernetes/kubernetes/f6f013b992441379a67bf98a5ba4b7e975c3470e/examples/guestbook/redis-slave-service.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/cases/509014/frontend-controller.yaml |
    Then the step should succeed
    And 3 pods become ready with labels:
      | app=guestbook,tier=frontend |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/kubernetes/kubernetes/f6f013b992441379a67bf98a5ba4b7e975c3470e/examples/guestbook/frontend-service.yaml  |
    Then the step should succeed
    When I expose the "frontend" service
    Then the step should succeed
    And I wait for a web server to become available via the route
    And the output should contain "Guestbook"     
