Feature: build 'apps' with CLI

  # @author xxing@redhat.com
  # @case_id 489753
  Scenario: Create a build config from a remote repository using branch
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world#beta2 |
      | l        | app=test |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc |
      | name     | ruby-hello-world |
    Then the output should match:
      | URL:\s+https://github.com/openshift/ruby-hello-world|
      | Ref:\s+beta2                                        |
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed  
    When I run the :get client command with:
      | resource | builds |
    Then the output should contain:
      | NAME                |
      | ruby-hello-world-1  |
    When I run the :get client command with:
      |resource| is |
    Then the output should contain:
      | ruby-20-centos7  |
      | ruby-hello-world |

  # @author chunchen@redhat.com
  # @case_id 476356, 476357
  Scenario Outline: [origin_devexp_288] Push image with Docker credentials for build
    Given I have a project
    When I run the :new_app client command with:
      | app_repo        | <app_repo>                  |
      | context_dir     | <context_dir>               |
    Then the step should succeed
    Given the "<first_build_name>" was created
    And the "<first_build_name>" build completed
    When I run the :describe client command with:
      | resource        | build                       |
      | name            | <first_build_name>          |
    Then the output should match:
      | Status:.*Complete                             |
      | Push Secret:.*builder\-dockercfg\-[a-zA-Z0-9]+|
    When I run the :new_secret client command with:
      | secret_name     | sec-push                    |
      | credential_file | <dockercfg_file>            |
    Then the step should succeed
    When I run the :add_secret client command with:
      | sa_name         | builder                     |
      | secret_name     | sec-push                    |
    Then the step should succeed
    When I run the :new_app client command with:
      | file            | <template_file>             |
    Given the "<second_build_name>" was created
    And the "<second_build_name>" build completed
    When I run the :describe client command with:
      | resource        | build                       |
      | name            | <second_build_name>         |
    Then the output should match:
      | Status:.*Complete                             |
      | Push Secret:.*sec\-push                       |
    When I run the :build_logs client command with:
      | build_name      | <second_build_name>         |
    Then the output should match "Successfully pushed .*<output_image>"
    Examples:
      | app_repo                                                            | context_dir                  | first_build_name   | second_build_name          | template_file | output_image | dockercfg_file |
      | openshift/python-33-centos7~https://github.com/openshift/sti-python | 3.3/test/standalone-test-app | sti-python-1       | python-sample-build-sti-1  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc476357/application-template-stibuild.json        | aosqe\/python\-sample\-sti                  | <%= expand_private_path(conf[:services, :docker_hub, :dockercfg]) %>       | 
      | https://github.com/openshift/ruby-hello-world.git                   |                              | ruby-hello-world-1 | ruby-sample-build-1        | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc476356/application-template-dockerbuild.json     | aosqe\/ruby\-sample\-docker                 | <%= expand_private_path(conf[:services, :docker_hub, :dockercfg]) %>       |

  # @author xxing@redhat.com
  # @case_id 491409
  Scenario: Create an application with multiple images and same repo
    Given I create a new project
    And I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-centos7.json |
    Then the step should succeed
    Given I use the "<%= @projects[0].name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-centos7.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | image_stream | <%= @projects[0].name %>/ruby |
      | image_stream | <%= @projects[1].name %>/ruby |
      | code         | https://github.com/openshift/ruby-hello-world |
      | l            | app=test |
    When I run the :get client command with:
      |resource| buildConfig |
    Then the output should match:
      | NAME\s+TYPE                 |
      | ruby-hello-world\s+Source   |
      | ruby-hello-world-1\s+Source |
    When I run the :describe client command with:
      | resource | buildConfig      |
      | name     | ruby-hello-world |
    Then the output should match:
      | Image Reference:\s+ImageStreamTag <%= @projects[0].name %>/ruby:latest |
    When I run the :describe client command with:
      | resource | buildConfig      |
      | name     | ruby-hello-world-1 |
    Then the output should match:
      | Image Reference:\s+ImageStreamTag <%= @projects[1].name %>/ruby:latest |
    Given the "ruby-hello-world-1" build completed
    Given the "ruby-hello-world-1-1" build completed
    Given I wait for the "ruby-hello-world" service to become ready
    When I execute on the pod:
      | bash                       |
      | -c                         |
      | curl -k <%= service.url %> |
    Then the step should succeed
    And the output should contain "Demo App"
    Given I wait for the "ruby-hello-world-1" service to become ready
    When I execute on the pod:
      | bash                       |
      | -c                         |
      | curl -k <%= service.url %> |
    Then the step should succeed
    And the output should contain "Demo App"
