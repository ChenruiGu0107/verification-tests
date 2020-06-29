Feature: dockerbuild.feature

  # @author wzheng@redhat.com
  Scenario Outline: Push build with invalid github repo
    Given I have a project
    Given I obtain test data file "build/ruby22rhel7-template-sti-invalidrepo.json"
    When I run the :create client command with:
      | f | ruby22rhel7-template-sti-invalidrepo.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | ruby-helloworld-sample |
    Then the step should succeed
    And the "ruby22-sample-build-1" build was created
    And the "ruby22-sample-build-1" build failed
    When I run the :logs client command with:
      | resource_name | bc/ruby22-sample-build |
    Then the output should contain "<warning>"

    Examples:
      | warning                                      |
      | '123' does not appear to be a git repository | # @case_id OCP-17382

  # @author haowang@redhat.com
  # @case_id OCP-10693
  Scenario: Add empty ENV to DockerStrategy buildConfig when do docker build
    Given I have a project
    Given I obtain test data file "image/language-image-templates/application-template-dockerbuild-blankvar.json"
    When I run the :new_app client command with:
      | file | application-template-dockerbuild-blankvar.json |
    Then the step should fail
    And the output should contain "invalid"

  # @author wewang@redhat.com
  # @case_id OCP-11228
  @admin
  @destructive
  Scenario: Edit bc with an allowed strategy to use a restricted strategy
    Given I have a project
    Given I obtain test data file "build/ruby22rhel7-template-docker.json"
    When I run the :new_app client command with:
      | file | ruby22rhel7-template-docker.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    Given cluster role "system:build-strategy-docker" is removed from the "system:authenticated" group
    When I get project build_config named "ruby-sample-build" as JSON
    Then the step should succeed
    Given I save the output to file> bc.json
    And I replace lines in "bc.json":
      | Docker | Source |
      |dockerStrategy|sourceStrategy|
    When I run the :replace client command with:
      | f | bc.json |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the "ruby-sample-build-2" build was created

    Given I switch to the second user
    Given I have a project
    Given I obtain test data file "build/ruby22rhel7-template-sti.json"
    When I run the :new_app client command with:
      | file | ruby22rhel7-template-sti.json |
    Then the step should succeed
    When I get project build_config named "ruby-sample-build" as JSON
    Then the step should succeed
    Given I save the output to file> bc1.json
    And I replace lines in "bc1.json":
      | Source | Docker  |
      | sourceStrategy|dockerStrategy|
    When I run the :replace client command with:
      | f | bc1.json |
    Then the step should fail
    And the output should contain "build strategy Docker is not allowed"

  # @author wewang@redhat.com
  # @case_id OCP-11503
  @admin
  @destructive
  Scenario: Allowing only certain users in a specific project to create builds with a particular strategy
    Given I have a project
    Given cluster role "system:build-strategy-docker" is removed from the "system:authenticated" group
    Given I obtain test data file "build/ruby22rhel7-template-docker.json"
    When I run the :new_app client command with:
      | file | ruby22rhel7-template-docker.json |
    Then the step should fail
    And the output should contain "build strategy Docker is not allowed"
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :policy_add_role_to_user admin command with:
      | role            |   system:build-strategy-docker |
      | user name       |   <%= user.name %>    |
      | n               |   <%= cb.proj_name %> |
    Then the step should succeed
    Given I obtain test data file "build/ruby22rhel7-template-docker.json"
    And I run the :new_app client command with:
      | file | ruby22rhel7-template-docker.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    Given I create a new project
    Given I obtain test data file "build/ruby22rhel7-template-docker.json"
    When I run the :new_app client command with:
      | file | ruby22rhel7-template-docker.json |
    Then the step should fail
    And the output should contain "build strategy Docker is not allowed"

  # @author dyan@redhat.com
  # @case_id OCP-12856
  Scenario: Add ARGs in docker build via webhook trigger
    Given I have a project
    When I run the :new_build client command with:
      | code | https://github.com/openshift/ruby-hello-world |
      | build_arg   | ARG=VALUE        |
    Then the step should succeed
    When I get project buildconfigs as JSON
    And evaluation of `@result[:parsed]['items'][0]['spec']['triggers'][1]['generic']['secret']` is stored in the :secret_name clipboard
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/apis/build.openshift.io/v1/namespaces/<%= project.name %>/buildconfigs/ruby-hello-world/webhooks/<%= cb.secret_name %>/generic
    :method: post
    :headers:
      :content-type: application/json
    :payload: <%= File.read("#{BushSlicer::HOME}/features/tierN/testdata/templates/OCP-12856/push-generic-build-args.json").to_json %>
    """
    Then the step should succeed
    Given the "ruby-hello-world-2" build was created
    When I run the :get client command with:
      | resource | build/ruby-hello-world-2 |
      | o        | yaml                     |
    Then the step should succeed
    And the output should match:
      | name:\\s+foo      |
      | value:\\s+default |
    Given I obtain test data file "templates/OCP-12856/push-generic-build-args.json"
    When I replace lines in "push-generic-build-args.json":
      | foo      | ARG      |
      | default  | NEWVALUE |
    Then the step should succeed
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/apis/build.openshift.io/v1/namespaces/<%= project.name %>/buildconfigs/ruby-hello-world/webhooks/<%= cb.secret_name %>/generic
    :method: post
    :headers:
      :content-type: application/json
    :payload: <%= File.read("push-generic-build-args.json").to_json %>
    """
    Then the step should succeed
    Given the "ruby-hello-world-3" build was created
    When I run the :get client command with:
      | resource | build/ruby-hello-world-3 |
      | o        | yaml                     |
    Then the step should succeed
    And the output should match:
      | name:\\s+ARG       |
      | value:\\s+NEWVALUE |

  # @author dyan@redhat.com
  # @case_id OCP-13980
  Scenario: Add ARGs in build with invalid way
    Given I have a project
    When I run the :new_build client command with:
      | code     | https://github.com/openshift/ruby-hello-world |
      | strategy | source                                        |
      | to       | test                                          |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | build_arg   | ARG=VALUE        |
    Then the step should fail
    And the output should match:
      | [Cc]annot specify     |
      | not a [Dd]ocker build |
    Given the "ruby-hello-world-1" build was created
    When I run the :start_build client command with:
      | from_build | ruby-hello-world-1 |
      | build_arg  | ARG=VALUE          |
    Then the step should fail
    And the output should match:
      | [Cc]annot specify     |
      | not a [Dd]ocker build |
    When I run the :delete client command with:
      | all_no_dash | |
      | all         | |
    Then the step should succeed
    When I run the :new_build client command with:
      | code      | https://github.com/openshift/ruby-hello-world |
      | strategy  | source                                        |
      | to        | test                                          |
      | build_arg | ARG=VALUE                                     |
    Then the step should fail
    And the output should match:
      | [Cc]annot use             |
      | without a [Dd]ocker build |
    # start docker build with invalid args
    When I run the :new_build client command with:
      | code      | https://github.com/openshift/ruby-hello-world |
      | build_arg | ARG=VALUE                                     |
    Then the step should succeed
    Given the "ruby-hello-world-1" build was created
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | build_arg   | @#$%=INVALID     |
    Then the step should fail
    And the output should contain "error: build-arg @#$%=INVALID is invalid"
    When I git clone the repo "https://github.com/openshift/ruby-hello-world"
    And I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | from_dir    | ruby-hello-world |
      | build_arg   | ARG2=VALUE2      |
    Then the output should match:
      | binary builds is not supported |

  # @author wewang@redhat.com
  # @case_id OCP-16590
  @admin
  Scenario:  Should clean up temporary containers on node due to failed docker builds
    Given I have a project
    When I run the :new_build client command with:
      | D    | FROM openshift/origin:latest\nRUN exit 1 |
      | name | failing-build                            |
    Then the step should succeed
    And the "failing-build-1" build was created
    And the "failing-build-1" build failed
    When I get project pod named "failing-build-1-build"
    And evaluation of `pod.node_name` is stored in the :node clipboard
    Given I use the "<%= cb.node %>" node
    When I run commands on the host:
      | podman ps -a --no-trunc |
    Then the step should succeed
    And the output should not contain "/bin/sh -c 'exit 1'"

  # @author wewang@redhat.com
  # @case_id OCP-19541
  Scenario: Reuse existing imagestreams with new-build
    Given I have a project
    When I run the :new_build client command with:
      | D    | FROM node:8\nRUN echo "Test" |
      | name | node8                        |
    Then the step should succeed
    And the "node8-1" build was created
    And the "node8-1" build completed
    And I check that the "node8:latest" istag exists in the project
    When I run the :new_build client command with:
      | D    | FROM node:10\nRUN echo "Test" |
      | name | node10                        |
    Then the step should succeed
    And the "node10-1" build was created
    And the "node10-1" build completed
    And I check that the "node10:latest" istag exists in the project
    When I run the :new_build client command with:
      | D    | FROM node:noexist\nRUN echo "Test" |
      | name | nodenoexist                        |
    Then the step should fail
    And the output should contain "error: multiple images or templates matched "node:noexist""
    When I run the :new_build client command with:
      | D    | FROM node\nRUN echo "Test" |
      | name | nodewithouttag             |
    Then the step should succeed
    And the "nodewithouttag-1" build was created
    And the "nodewithouttag-1" build completed
    And I check that the "nodewithouttag:latest" istag exists in the project
    When I run the :new_app client command with:
      | app_repo | https://github.com/sclorg/nodejs-ex |
    Then the step should succeed
    And the istag named "nodejs:latest" does not exist in the project

  # @author wewang@redhat.com
  # @case_id OCP-25285
  Scenario: Builds should be configured to use mirrors in disconnected environments
    Given I have a project
    When I run the :new_build client command with:
      | D    | FROM quay.io/openshifttest/ruby-25-centos7@sha256:575194aa8be12ea066fc3f4aa9103dcb4291d43f9ee32e4afe34e0063051610b |
      | name | disconnect-build |
    Then the step should succeed
    And the "disconnect-build-1" build was created
    And the "disconnect-build-1" build failed
    When I run the :set_build_secret client command with:
      | bc_name     | disconnect-build |
      | secret_name | mirrorsecret     |
      | pull        | true             |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig | disconnect-build |
    Then the step should succeed
    And the "disconnect-build-2" build was created
    And the "disconnect-build-2" build completed
