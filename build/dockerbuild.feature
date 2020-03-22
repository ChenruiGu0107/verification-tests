Feature: dockerbuild.feature

  # @author wzheng@redhat.com
  Scenario Outline: Push build with invalid github repo
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti-invalidrepo.json |
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
      | Invalid git source url: 123                  |  # @case_id OCP-11444
      | '123' does not appear to be a git repository |  # @case_id OCP-17382

  # @author haowang@redhat.com
  # @case_id OCP-10693
  Scenario: Add empty ENV to DockerStrategy buildConfig when do docker build
    Given I have a project
    When I run the :new_app client command with:
      | file |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template-dockerbuild-blankvar.json |
    Then the step should fail
    And the output should contain "invalid"

  # @author cryan@redhat.com
  # @case_id OCP-11937
  Scenario: oc start-build with a file passed,sti build type
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/sclorg/nodejs-ex |
    Then the step should succeed
    Given the "nodejs-ex-1" build completed
    Given I download a file from "https://raw.githubusercontent.com/openshift/nodejs-ex/master/package.json"
    When I run the :start_build client command with:
      | buildconfig | nodejs-ex |
      | from_file | package.json |
    Then the step should succeed
    Given the "nodejs-ex-2" build completed
    When I run the :start_build client command with:
      | buildconfig | nodejs-ex |
      | from_file | nonexist.json |
    Then the step should fail
    And the output should contain "no such file"

  # @author yantan@redhat.com
  # @case_id OCP-10615
  Scenario: Custom build with dockerImage with specified tag
    Given I have a project
    Given project role "system:build-strategy-custom" is added to the "first" user
    Then the step should succeed
    And I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc479296/application-template-custombuild.json |
    Then the step should succeed
    And I run the :describe client command with:
      | resource | buildconfig |
      | name | ruby-sample-build |
    Then the step should succeed
    And the output should contain:
      |DockerImage openshift/origin-custom-docker-builder:latest|
    When I get project builds
    Then the step should succeed
    And I run the :describe client command with:
      | resource | builds|
    Then the step should succeed
    Then the output should contain:
      |DockerImage openshift/origin-custom-docker-builder:latest|
    When I replace resource "bc" named "ruby-sample-build":
      | openshift/origin-custom-docker-builder:latest  | openshift/origin-custom-docker-builder:a2aa234 |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    When I run the :logs client command with:
      | resource_name | bc/ruby-sample-build |
    And the output should contain:
      | timed out |

  # @author dyan@redhat.com
  # @case_id OCP-10789
  Scenario: Implement post-build command for docker build
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc479297/test-template-dockerbuild.json" replacing paths:
      | ["spec"]["strategy"]["dockerStrategy"]["from"]["name"] | <%= product_docker_repo %>rhscl/ruby-22-rhel7:latest |
      | ["spec"]["postCommit"]                                 | {"script":"bundle exec rake test"}                   |
    Then the step should succeed
    Given the "ruby-sample-build-1" build completed
    When I run the :logs client command with:
      | resource_name | build/ruby-sample-build-1 |
    Then the output should contain:
      | 1 runs, 1 assertions, 0 failures, 0 errors, 0 skips |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc479297/test-template-dockerbuild.json" replacing paths:
      | ["metadata"]["name"]                                   | ruby-sample-build2 |
      | ["spec"]["strategy"]["dockerStrategy"]["from"]["name"] | <%= product_docker_repo %>rhscl/ruby-22-rhel7:latest |
      | ["spec"]["postCommit"]                                 | {"command":["/bin/bash","-c","bundle exec rake test --verbose"]} |
    Then the step should succeed
    And the "ruby-sample-build2-1" build completed
    When I run the :logs client command with:
      | resource_name | build/ruby-sample-build2-1 |
    Then the output should contain:
      | 1 runs, 1 assertions, 0 failures, 0 errors, 0 skips |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc479297/test-template-dockerbuild.json" replacing paths:
      | ["metadata"]["name"]                                   | ruby-sample-build3 |
      | ["spec"]["strategy"]["dockerStrategy"]["from"]["name"] | <%= product_docker_repo %>rhscl/ruby-22-rhel7:latest |
      | ["spec"]["postCommit"]                                 | {"args":["bundle","exec","rake","test","--verbose"]} |
    Then the step should succeed
    And the "ruby-sample-build3-1" build completed
    When I run the :logs client command with:
      | resource_name | build/ruby-sample-build3-1 |
    Then the output should contain:
      | 1 runs, 1 assertions, 0 failures, 0 errors, 0 skips |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc479297/test-template-dockerbuild.json" replacing paths:
      | ["metadata"]["name"]                                   | ruby-sample-build4 |
      | ["spec"]["strategy"]["dockerStrategy"]["from"]["name"] | <%= product_docker_repo %>rhscl/ruby-22-rhel7:latest |
      | ["spec"]["postCommit"]                                 | {"args":["--verbose"],"script":"bundle exec rake test $1"} |
    Then the step should succeed
    And the "ruby-sample-build4-1" build completed
    When I run the :logs client command with:
      | resource_name | build/ruby-sample-build4-1 |
    Then the output should contain:
      | 1 runs, 1 assertions, 0 failures, 0 errors, 0 skips |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc479297/test-template-dockerbuild.json" replacing paths:
      | ["metadata"]["name"]                                   | ruby-sample-build5 |
      | ["spec"]["strategy"]["dockerStrategy"]["from"]["name"] | <%= product_docker_repo %>rhscl/ruby-22-rhel7:latest |
      | ["spec"]["postCommit"]                                 | {"command":["/bin/bash","-c","bundle exec rake test"],"args":["--verbose"]} |
    Then the step should succeed
    And the "ruby-sample-build5-1" build completed
    When I run the :logs client command with:
      | resource_name | build/ruby-sample-build5-1 |
    Then the output should contain:
      | 1 runs, 1 assertions, 0 failures, 0 errors, 0 skips |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc479297/test-template-dockerbuild.json" replacing paths:
      | ["metadata"]["name"]                                   | ruby-sample-build6 |
      | ["spec"]["strategy"]["dockerStrategy"]["from"]["name"] | <%= product_docker_repo %>rhscl/ruby-22-rhel7:latest |
      | ["spec"]["postCommit"]                                 | {"script":"bundle exec rake1 test --verbose"} |
    Then the step should succeed
    And the "ruby-sample-build6-1" build failed
    When I run the :logs client command with:
      | resource_name | build/ruby-sample-build6-1 |
    Then the output should contain:
      | bundler: command not found: rake1 |

  # @author wewang@redhat.com
  # @case_id OCP-11228
  @admin
  @destructive
  Scenario: Edit bc with an allowed strategy to use a restricted strategy
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-docker.json |
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
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
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
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-docker.json |
    Then the step should fail
    And the output should contain "build strategy Docker is not allowed"
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :policy_add_role_to_user admin command with:
      | role            |   system:build-strategy-docker |
      | user name       |   <%= user.name %>    |
      | n               |   <%= cb.proj_name %> |
    Then the step should succeed
    And I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-docker.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    Given I create a new project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-docker.json |
    Then the step should fail
    And the output should contain "build strategy Docker is not allowed"

  # @author wzheng@redhat.com
  # @case_id OCP-13450
  Scenario: Error in buildlog when Docker build with invalid context dir
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-invalidcontext-docker.json |
    Then the step should succeed
    When the "ruby20-sample-build-1" build failed
    And I run the :logs client command with:
      | resource_name | bc/ruby20-sample-build |
    And the output should contain:
      | no such file or directory |

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
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/OCP-12856/push-generic-build-args.json"
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
    Given the "ruby-hello-world-2" build was created
    When I run the :get client command with:
      | resource | build/ruby-hello-world-2 |
      | o        | yaml                     |
    Then the step should succeed
    And the output should match:
      | name:\\s+foo      |
      | value:\\s+default |
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
  # @case_id OCP-15479
  Scenario:  Setting nocache with wrong info when docker build request
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-dockerbuild.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
      | no-cache    | abc               |
    Then the step should fail
    And the output should contain:
      | Error: invalid argument "abc"   |

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
