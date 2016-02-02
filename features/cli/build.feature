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
      | n1-1 |
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
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      |resource| buildConfig |
    Then the output should match:
      | NAME\\s+TYPE                 |
      | <%= Regexp.escape("ruby-hello-world") %>\\s+Source   |
      | <%= Regexp.escape("ruby-hello-world-1") %>\\s+Source |
    """
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
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl                       |
      | -k                         |
      | <%= service.url %>         |
    Then the step should succeed
    """
    And the output should contain "Demo App"
    Given I wait for the "ruby-hello-world-1" service to become ready
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl                       |
      | -k                         |
      | <%= service.url %>         |
    Then the step should succeed
    """
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


  # @author xiuwang@redhat.com
  # @case_id 491258
  Scenario: Create applications with multiple groups
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json |
    Given the "ruby" image stream was created
    Given the "mysql" image stream was created
    Given the "postgresql" image stream was created
    When I run the :new_app client command with:
      | image_stream | openshift/ruby |
      | image_stream | <%= project.name %>/ruby:2.2 |
      | docker_image | <%= product_docker_repo %>rhscl/ruby-22-rhel7 |
      | image_stream | openshift/mysql |
      | image_stream | <%= project.name %>/mysql:5.5 |
      | docker_image | <%= product_docker_repo %>rhscl/mysql-56-rhel7 |
      | image_stream | openshift/postgresql |
      | image_stream | <%= project.name %>/postgresql:9.2 |
      | docker_image | <%= product_docker_repo %>rhscl/postgresql-94-rhel7 |
      | group        | openshift/ruby+openshift/mysql+openshift/postgresql |
      | group        | <%= project.name %>/ruby:2.2+<%= project.name %>/mysql:5.5+<%= project.name %>/postgresql:9.2 |
      | group        | <%= product_docker_repo %>rhscl/ruby-22-rhel7+<%= product_docker_repo %>rhscl/mysql-56-rhel7+<%= product_docker_repo %>rhscl/postgresql-94-rhel7 |
      | code         | https://github.com/openshift/ruby-hello-world |
      | env            | POSTGRESQL_USER=user,POSTGRESQL_DATABASE=db,POSTGRESQL_PASSWORD=test,MYSQL_ROOT_PASSWORD=test |
      | l            | app=testapps    | 
    Then the step should succeed
    When I run the :get client command with:
      |resource| buildConfig |
    Then the output should match:
      | NAME\\s+TYPE                 |
      | <%= Regexp.escape("ruby-hello-world") %>\\s+Source   |
      | <%= Regexp.escape("ruby-hello-world-1") %>\\s+Source |
      | <%= Regexp.escape("ruby-hello-world-2") %>\\s+Source |
    When I run the :describe client command with:
      | resource | buildConfig      |
      | name     | ruby-hello-world |
    Then the output should match:
      | ImageStreamTag ruby-22-rhel7:latest |
    When I run the :describe client command with:
      | resource | buildConfig        |
      | name     | ruby-hello-world-1 |
    Then the output should match:
      | ImageStreamTag openshift/ruby:latest |
    When I run the :describe client command with:
      | resource | buildConfig        |
      | name     | ruby-hello-world-2 |
    Then the output should match:
      | ImageStreamTag <%= Regexp.escape(project.name) %>/ruby:2.2 |
    Given the "ruby-hello-world-1" build completed
    Given the "ruby-hello-world-1-1" build completed
    Given the "ruby-hello-world-2-1" build completed
    Given I wait for the "mysql-56-rhel7" service to become ready
    When I run the :exec client command with:
      | pod          | <%= pod.name %>  |
      | c            | ruby-hello-world |
      | oc_opts_end  ||
      | exec_command | curl  |
      | exec_command | -s    |
      | exec_command | <%= service.ip %>:8080 |
    And the output should contain "Demo App"
    Given I wait for the "postgresql" service to become ready
    When I run the :exec client command with:
      | pod          | <%= pod.name %>    |
      | c            | ruby-hello-world-1 |
      | oc_opts_end  ||
      | exec_command | curl  |
      | exec_command | -s    |
      | exec_command | <%= service.ip %>:8080 |
    And the output should contain "Demo App"
    Given I wait for the "ruby-hello-world-2" service to become ready
    When I run the :exec client command with:
      | pod          | <%= pod.name %>    |
      | c            | ruby-hello-world-2 |
      | oc_opts_end  ||
      | exec_command | curl  |
      | exec_command | -s    |
      | exec_command | <%= service.ip %>:8080 |
    And the output should contain "Demo App"

  # @author cryan@redhat.com
  # @case_id 474049
  Scenario: Stream logs back automatically after start build
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json"
    Given I replace lines in "ruby22rhel7-template-sti.json":
      | registry.access.redhat.com/ | <%= product_docker_repo %> |
    When I run the :new_app client command with:
      | file | ruby22rhel7-template-sti.json |
    Then the step should succeed
    When I get project buildconfigs
    Then the step should succeed
    And the output should contain "ruby22-sample-build"
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
      | follow | true |
      | _timeout | 90 |
    And the output should contain:
      | Installing application source |
      | Building your Ruby application from source |
    When I run the :start_build client command with:
      | from_build | ruby22-sample-build-1 |
      | follow | true |
      | _timeout | 90 |
    And the output should contain:
      | Installing application source |
      | Building your Ruby application from source |
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby22-sample-build |
      | p | {"spec":{"source":{"git":{"uri":"https://nondomain.com"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
      | follow | true |
      | wait | true |
      | _timeout | 90 |
    Then the output should contain "unable to access 'https://nondomain.com/"

  # @author cryan@redhat.com
  # @case_id 479022
  Scenario: Add ENV with CustomStrategy when do custom build
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc479022/application-template-custombuild.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build completed
    When I run the :env client command with:
      | resource | pod |
      | env_name | ruby-sample-build-1-build |
      | list | true |
    Then the output should contain "http_proxy=http://squid.example.com:3128"

  # @author cryan@redhat.com
  # @case_id 507557
  Scenario: Add more ENV to DockerStrategy buildConfig when do docker build
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/cjryan/v3-testfiles/tc507557/templates/tc507557/application-template-dockerbuild-multivars.json"
    Given I replace lines in "application-template-dockerbuild-multivars.json":
      | registry.access.redhat.com/ | <%= product_docker_repo %> |
    When I run the :new_app client command with:
      | file | application-template-dockerbuild-multivars.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      |deployment=frontend-1|
    Given evaluation of `@pods[0].name` is stored in the :frontendpod clipboard
    When I execute on the "<%= cb.frontendpod %>" pod:
      | env |
    Then the step should succeed
    And the output should contain "RACK_ENV=production"

  # @author cryan@redhat.com
  # @case_id 498212
  Scenario: Order builds according to creation timestamps
    Given I have a project
    And I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    And I run the :start_build client command with:
      | buildconfig |  ruby-sample-build |
    And I run the :start_build client command with:
      | buildconfig |  ruby-sample-build |
    And I run the :start_build client command with:
      | buildconfig |  ruby-sample-build |
    And I run the :get client command with:
      | resource | builds |
    Then the output by order should match:
      | ruby-sample-build-1 |
      | ruby-sample-build-2 |
      | ruby-sample-build-3 |

  # @author pruan@redhat.com
  # @case_id 512096
  Scenario: Start build with option --wait
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc512096/test-build-cancle.json |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig | sample-build |
      | wait        | true         |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig | sample-build |
      | wait        | true         |
      | commit      | deadbeef     |
    Then the step should fail
    And I run the :start_build background client command with:
      | buildconfig | sample-build |
      | wait        | true         |
    Given the pod named "sample-build-3-build" is present
    And I run the :cancel_build client command with:
      | build_name | sample-build-3 |
    And the output should match:
      | Build sample-build-3 was cancelled |

  # @author pruan@redhat.com
  # @case_id 517369, 517370, 517367, 517368
  Scenario Outline: when delete the bc,the builds pending or running should be deleted
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc<number>/test-buildconfig.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build becomes <build_status>
    Then I run the :delete client command with:
      | object_type | buildConfig |
      | object_name_or_id | ruby-sample-build |
    Then the step should succeed
    And I run the :get client command with:
      | resource | buildConfig |
    Then the output should not contain:
      | ruby-sample-build |
    And I run the :get client command with:
      | resource | build |
    Then the output should not contain:
      | ruby-sample-build |

    Examples:
      | number | build_status |
      | 517369 | :pending     |
      | 517370 | :running     |
      | 517367 | :complete    |
      | 517368 | :failed      |

  # @author pruan@redhat.com
  # @case_id 517366
  Scenario: Recreate bc when previous bc is deleting pending
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc517366/test-buildconfig.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | buildConfig |
    Then the output should contain:
      | build-config.paused=true |
    And I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should fail
    And the output should match:
      | Error from server: fatal error generating Build from BuildConfig: can't instantiate from BuildConfig <%= project.name %>/ruby-sample-build: BuildConfig is paused |
    Then I run the :delete client command with:
      | object_type | buildConfig |
      | object_name_or_id | ruby-sample-build |
    Then the step should succeed
    And I run the :get client command with:
      | resource | buildConfig |
    Then the output should not contain:
      | ruby-sample-build |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/test-buildconfig.json |
    Then the step should succeed
    And I run the :delete client command with:
      | object_type | buildConfig |
      | object_name_or_id | ruby-sample-build |
      | cascade           | false             |
    Then the step should succeed
    And I run the :get client command with:
      | resource | buildConfig |
    Then the output should not contain:
      | ruby-sample-build |
    And I run the :get client command with:
      | resource | build |
    Then the output should contain:
      | ruby-sample-build |


