Feature: build 'apps' with CLI

  # @author xxing@redhat.com
  # @case_id 489753
  Scenario: Create a build config from a remote repository using branch
    Given I have a project
    When I run the :new_build client command with:
      | code    | https://github.com/openshift/ruby-hello-world#beta2 |
      | e       | key1=value1,key2=value2,key3=value3 |
    Then the step should succeed
    When I run the :get client command with:
      | resource          | buildConfig |
      | resource_name     | ruby-hello-world |
      | o                 | yaml        |
    Then the output should match:
      | uri:\\s+https://github.com/openshift/ruby-hello-world|
      | ref:\\s+beta2                                        |
      | name: key1                                           |
      | value: value1                                        |
      | name: key2                                           |
      | value: value2                                        |
      | name: key3                                           |
      | value: value3                                        |
    When I run the :get client command with:
      | resource | builds |
    Then the output should contain:
      | NAME                |
      | ruby-hello-world-1  |
    When I run the :get client command with:
      |resource| imageStream |
    Then the output should contain:
      | ruby-20-centos7  |
      | ruby-hello-world |

  # @author cryan@redhat.com
  # @case_id 489741
  Scenario: Create a build config based on the provided image and source code
    Given I have a project
    When I run the :new_build client command with:
      | code  | https://github.com/openshift/ruby-hello-world |
      | image | openshift/ruby                                |
      | l     | app=rubytest                                  |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc               |
      | name     | ruby-hello-world |
    Then the output should match:
      | URL:\\s+https://github.com/openshift/ruby-hello-world|
    Given the pod named "ruby-hello-world-1-build" becomes ready
    When I run the :get client command with:
      | resource | builds |
    Then the output should contain:
      | NAME                |
      | ruby-hello-world-1  |
    When I run the :get client command with:
      |resource| is |
    Then the output should contain:
      | ruby-hello-world |
    When I run the :new_build client command with:
      | app_repo |  openshift/ruby:2.0~https://github.com/openshift/ruby-hello-world.git |
      | strategy | docker                                                                |
      | name     | n1                                                                    |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc               |
      | name     | ruby-hello-world |
    Then the output should match:
      | URL:\\s+https://github.com/openshift/ruby-hello-world|
    Given the pod named "n1-1-build" becomes ready
    When I run the :get client command with:
      | resource | builds |
    Then the output should contain:
      | NAME                |
      | n1-1-build |
    When I run the :get client command with:
      |resource| is |
    Then the output should contain:
      | ruby-hello-world |

  # @author chunchen@redhat.com
  # @case_id 476356, 476357
  Scenario Outline: [origin_devexp_288] Push image with Docker credentials for build
    Given I have a project
    When I run the :new_app client command with:
      | app_repo        | <app_repo>                  |
      | context_dir     | <context_dir>               |
    Then the step should succeed
    Given the "<first_build_name>" build was created
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
    Given the "<second_build_name>" build was created
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | image_stream | openshift/ruby |
      | image_stream | <%= project.name %>/ruby:2.0 |
      | code         | https://github.com/openshift/ruby-hello-world |
      | l            | app=test |
    When I run the :get client command with:
      |resource| buildConfig |
    Then the output should match:
      | NAME\\s+TYPE                 |
      | <%= Regexp.escape("ruby-hello-world") %>\\s+Source   |
      | <%= Regexp.escape("ruby-hello-world-1") %>\\s+Source |
    When I run the :describe client command with:
      | resource | buildConfig      |
      | name     | ruby-hello-world |
    Then the output should match:
      | ImageStreamTag openshift/ruby:latest |
    When I run the :describe client command with:
      | resource | buildConfig      |
      | name     | ruby-hello-world-1 |
    Then the output should match:
      | ImageStreamTag <%= Regexp.escape(project.name) %>/ruby:2.0 |
    Given the "ruby-hello-world-1" build completed
    Given the "ruby-hello-world-1-1" build completed
    Given I wait for the "ruby-hello-world" service to become ready
    When I execute on the pod:
      | curl                       |
      | -k                         |
      | <%= service.url %>         |
    Then the step should succeed
    And the output should contain "Demo App"
    Given I wait for the "ruby-hello-world-1" service to become ready
    When I execute on the pod:
      | curl                       |
      | -k                         |
      | <%= service.url %>         |
    Then the step should succeed
    And the output should contain "Demo App"

  # @author xxing@redhat.com
  # @case_id 482198
  Scenario: Set dump-logs and restart flag for cancel-build in openshift
    Given I have a project
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json |
    Then the step should succeed
    Given I save the output to file>app-stibuild.json
    When I run the :create client command with:
      | f | app-stibuild.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource | buildConfig |
    Then the output should contain:
      | NAME              |
      | ruby-sample-build |
    # As the trigger of bc is "ConfigChange" and sometime the first build doesn't create quickly,
    # so wait the first build complete，wanna start maunally for testing this cli well
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    When I run the :cancel_build client command with:
      | build_name | ruby-sample-build-2 |
      | dump_logs  | true                |
    Then the output should contain:
      | Build logs for ruby-sample-build-2 |
    # "cancelled" comes quickly after "failed" status, wait
    # "failed" has the same meaning
    Given the "ruby-sample-build-2" build was cancelled
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    When I run the :cancel_build client command with:
      | build_name | ruby-sample-build-3 |
      | restart    | true                |
      | dump_logs  | true                |
    Then the output should contain:
      | Build logs for ruby-sample-build-3 |
    Given the "ruby-sample-build-3" build was cancelled
    When I run the :get client command with:
      | resource | build |
    # Should contain the new start build
    Then the output should match:
      | <%= Regexp.escape("ruby-sample-build-4") %>.+(?:Running)?(?:Pending)?|


  # @author xiaocwan@redhat.com
  # @case_id 482200
Scenario: Cancel a build in openshift 
    Given I have a project    
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json"
    Then the step should succeed
    When I get project buildConfigs
    Then the output should contain:
      | NAME              |
      | ruby-sample-build |
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build|
    Then the step should succeed
    And the "ruby-sample-build-1" build was created

    Given the "ruby-sample-build-1" build becomes running
    Then the step should succeed
   
    When I run the :cancel_build client command with:
      | build_name | ruby-sample-build-1 |
    Then the "ruby-sample-build-1" build was cancelled
    When I get project pods
    Then the output should not contain:
      |  ruby-sample-build-3-build  |
    
    When I get project builds
    Then the output should contain:
      |  ruby-sample-build-2  |
    When I get project pods
    Then the output should contain:
      |  ruby-sample-build-2-build  |

    When I run the :cancel_build client command with:
      | build_name | non-exist |
    Then the step should fail

    When the "ruby-sample-build-2" build completed
    And I run the :cancel_build client command with:
      | build_name | ruby-sample-build-2 |
    Then the "ruby-sample-build-2" build completed