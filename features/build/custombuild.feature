Feature: custombuild.feature

  # @author wzheng@redhat.com
  # @case_id OCP-11443
  @smoke
  Scenario: Build with custom image - origin-custom-docker-builder
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json |
    Then the step should succeed
    And I create a new application with:
      | template | ruby-helloworld-sample |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    Given I wait for the pod named "frontend-1-deploy" to die
    Given 2 pods become ready with labels:
      | name=frontend |
    When I get project service named "frontend" as JSON
    Then the step should succeed
    And evaluation of `@result[:parsed]['spec']['clusterIP']` is stored in the :service_ip clipboard
    When I get project pods as JSON
    Then the step should succeed
    Given evaluation of `@result[:parsed]['items'][1]['metadata']['name']` is stored in the :pod_name clipboard
    Given I wait up to 120 seconds for the steps to pass:
    """
    When I run the :exec client command with:
      | pod | <%= cb.pod_name %> |
      |oc_opts_end||
      | exec_command | curl |
      | exec_command_arg | <%= cb.service_ip%>:5432 |
    Then the output should contain "Hello from OpenShift v3"
    """

  # @author dyan@redhat.com
  # @case_id OCP-11104
  Scenario: Custom build with imageStreamImage in buildConfig
    Given I have a project
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc479017/custombuild-template.json"
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I get project istag named "origin-custom-docker-builder:latest" as JSON
    Then the step should succeed
    """
    And evaluation of `@result[:parsed]['image']['metadata']['name']` is stored in the :imagestreamimage clipboard
    When I replace resource "bc" named "ruby-sample-build":
      | ImageStreamTag | ImageStreamImage |
      | :latest        | @<%= cb.imagestreamimage %> |
    And I run the :cancel_build client command with:
      | build_name | ruby-sample-build-1 |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build completed
    When I run the :describe client command with:
      | resource | build |
      | name | ruby-sample-build-2 |
    Then the output should contain:
      | Custom |
      | DockerImage openshift/origin-custom-docker-builder@<%= cb.imagestreamimage %> |
    When I replace resource "bc" named "ruby-sample-build":
      | <%= cb.imagestreamimage %> | <%= cb.imagestreamimage[0..15] %> |
    And I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-3" build completed
    When I run the :describe client command with:
      | resource | build |
      | name | ruby-sample-build-3 |
    Then the output should contain:
      | Custom |
      | DockerImage openshift/origin-custom-docker-builder@<%= cb.imagestreamimage %> |
    When I replace resource "bc" named "ruby-sample-build":
      | <%= cb.imagestreamimage[0..15] %> | invalid |
    And I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the output should contain:
      | imagestreamimage |
      | not found        |
    When I replace resource "bc" named "ruby-sample-build":
      | invalid |        |
    And I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the output should contain:
      | ImageStreamImages must be retrieved with <name>@<id> |

  # @author shiywang@redhat.com
  # @case_id OCP-11872
  Scenario: S2I build failure reason display if use incorrect config in buildconfig
    Given I have a project
    #1
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    And the "ruby22-sample-build-1" build was created
    And the "ruby22-sample-build-1" build completed
    When I run the :patch client command with:
      | resource      | buildconfig         |
      | resource_name | ruby22-sample-build |
      | p             | {"spec":{"output":{"to":{"name":"origin-ruby22-123sample:latest"}}}} |
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Then the step should succeed
    And the "ruby22-sample-build-2" build was created
    When I run the :get client command with:
      | resource      | build                 |
      | resource_name | ruby22-sample-build-2 |
    And the output should contain "InvalidOutputReference"
    And I delete all resources from the project
    #2
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    And the "ruby22-sample-build-1" build was created
    And the "ruby22-sample-build-1" build completed
    When I run the :patch client command with:
      | resource      | buildconfig         |
      | resource_name | ruby22-sample-build |
      | p             | {"spec":{"strategy":{"sourceStrategy":{"from":{"kind":"DockerImage","name":"docker.io/openshift/rubyyyy-20-centos7:latest","namespace":null}}}}} |
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Then the step should succeed
    And the "ruby22-sample-build-2" build was created
    And the "ruby22-sample-build-2" build failed
    When I run the :get client command with:
      | resource      | build                 |
      | resource_name | ruby22-sample-build-2 |
    And the output should contain "PullBuilderImageFailed"
    And I delete all resources from the project
    #3
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    And the "ruby22-sample-build-1" build was created
    And the "ruby22-sample-build-1" build completed
    When I run the :patch client command with:
      | resource      | buildconfig         |
      | resource_name | ruby22-sample-build |
      | p             | {"spec":{"source":{"git":{"uri":"https://github123.com/openshift/ruby-hello-world.git"}}}} |
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Then the step should succeed
    And the "ruby22-sample-build-2" build was created
    And the "ruby22-sample-build-2" build failed
    When I run the :get client command with:
      | resource      | build                 |
      | resource_name | ruby22-sample-build-2 |
    And the output should contain "FetchSourceFailed"
    And I delete all resources from the project
    #4
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    And the "ruby22-sample-build-1" build was created
    And the "ruby22-sample-build-1" build completed
    When I run the :patch client command with:
      | resource      | buildconfig         |
      | resource_name | ruby22-sample-build |
      | p             | {"spec":{"postCommit":{"args":["bundle123","exec","rake","test"]}}} |
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Then the step should succeed
    And the "ruby22-sample-build-2" build was created
    And the "ruby22-sample-build-2" build failed
    When I run the :get client command with:
      | resource      | build                 |
      | resource_name | ruby22-sample-build-2 |
    And the output should contain "PostCommitHookFailed"
