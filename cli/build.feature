Feature: build 'apps' with CLI

  # @author xxing@redhat.com
  # @case_id OCP-11134
  Scenario: Create a build config from a remote repository using branch
    Given I have a project
    When I run the :new_build client command with:
      | code         | https://github.com/openshift/ruby-hello-world#beta2 |
      | e            | key1=value1                                         |
      | e            | key2=value2                                         |
      | e            | key3=value3                                         |
      | image_stream | openshift/ruby                                      |
    Then the step should succeed
    When I get project build_config named "ruby-hello-world" as YAML
    Then the output should match:
      | uri:\\s+https://github.com/openshift/ruby-hello-world|
      | ref:\\s+beta2                                        |
      | name: key1                                           |
      | value: value1                                        |
      | name: key2                                           |
      | value: value2                                        |
      | name: key3                                           |
      | value: value3                                        |
    And I wait up to 20 seconds for the steps to pass:
    """
    When I get project builds
    Then the output should contain:
      | NAME                |
      | ruby-hello-world-1  |
    """
    When I get project imageStream
    Then the output should contain:
      | ruby-hello-world |

  # @author chunchen@redhat.com
  Scenario Outline: [origin_devexp_288] Push image with Docker credentials for build
    Given I have a project
    When I run the :create_secret client command with:
     | name        | sec-push                                                                        |
     | secret_type | generic                                                                         |
     | from_file   | .dockercfg=<%= expand_private_path(conf[:services, :docker_hub, :dockercfg]) %> | 
     | type        | kubernetes.io/dockercfg                                                         |
    Then the step should succeed
    When I run the :new_app client command with:
      | file            | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/<template_file> |
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    When I run the :describe client command with:
      | resource        | build               |
      | name            | ruby-sample-build-1 |
    Then the output should match:
      | Status:.*Complete                     |
      | Push Secret:.*sec\-push               |

    Examples:
      | template_file                                  |
      | tc476357/application-template-stibuild.json    | # @case_id OCP-11712
      | tc476356/application-template-dockerbuild.json | # @case_id OCP-11463
      | tc476355/application-template-custombuild.json | # @case_id OCP-11098

  # @author xxing@redhat.com
  # @case_id OCP-11140
  Scenario: Create an application with multiple images and same repo
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json |
    Then the step should succeed
    Given the "ruby" image stream was created
    And the "ruby" image stream becomes ready
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:latest |
      | image_stream | <%= project.name %>/ruby:2.0 |
      | code         | https://github.com/openshift/ruby-hello-world |
      | l            | app=test |
    And I wait up to 120 seconds for the steps to pass:
    """
    When I get project buildConfig
    Then the output should match:
      | NAME\\s+TYPE                 |
      | <%= Regexp.escape("ruby-hello-world") %>\\s+Source   |
      | <%= Regexp.escape("ruby-hello-world-1") %>\\s+Source |
    """
    When I run the :describe client command with:
      | resource | buildConfig      |
      | name     | ruby-hello-world |
    Then the output should match:
      | ImageStreamTag openshift/ruby |
    When I run the :describe client command with:
      | resource | buildConfig      |
      | name     | ruby-hello-world-1 |
    Then the output should match:
      | ImageStreamTag <%= Regexp.escape(project.name) %>/ruby:2.0 |
    Given the "ruby-hello-world-1" build completed
    Given the "ruby-hello-world-1-1" build completed
    Given I wait for the "ruby-hello-world" service to become ready up to 300 seconds
    And I get the service pods
    And I wait up to 120 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl                       |
      | -k                         |
      | <%= service.url %>         |
    Then the step should succeed
    """
    And the output should contain "Demo App"
    Given I wait for the "ruby-hello-world-1" service to become ready up to 300 seconds
    And I get the service pods
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
  # @case_id OCP-12243
  Scenario: Set dump-logs and restart flag for cancel-build in openshift
    Given I have a project
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json |
    Then the step should succeed
    Given I save the output to file> app-stibuild.json
    When I run the :create client command with:
      | f | app-stibuild.json |
    Then the step should succeed
    When I get project buildConfig
    Then the output should contain:
      | NAME              |
      | ruby-sample-build |
    # As the trigger of bc is "ConfigChange" and sometime the first build doesn't create quickly,
    # so wait the first build complete，wanna start manually for testing this cli well
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    And the "ruby-sample-build-2" build was created
    And the "ruby-sample-build-2" build becomes :running
    When I run the :cancel_build client command with:
      | build_name | ruby-sample-build-2 |
      | dump_logs  | true                |
    Then the output should match:
      | Build .* logs |
    # "cancelled" comes quickly after "failed" status, wait
    # "failed" has the same meaning
    Given the "ruby-sample-build-2" build was cancelled
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    And the "ruby-sample-build-3" build was created
    And the "ruby-sample-build-3" build becomes :running
    When I run the :cancel_build client command with:
      | build_name | ruby-sample-build-3 |
      | restart    | true                |
      | dump_logs  | true                |
    Then the output should match:
      | Build .* logs |
    Given the "ruby-sample-build-3" build was cancelled
    When I get project build
    # Should contain the new start build
    Then the output should match:
      | <%= Regexp.escape("ruby-sample-build-4") %>.+(?:Running)?(?:Pending)?|


  # @author xiaocwan@redhat.com
  # @case_id OCP-12309
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

    Given the "ruby-sample-build-1" build becomes :running
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
    Given the pod named "ruby-sample-build-2-build" becomes ready
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
  # @case_id OCP-11136
  Scenario: Create applications with multiple groups
    Given I create a new project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-centos7.json |
    Given the "ruby" image stream was created
    And the "ruby" image stream becomes ready
    Given the "postgresql" image stream was created
    And the "postgresql" image stream becomes ready
    When I run the :new_app client command with:
      | image_stream      | openshift/ruby                                                                                    |
      | image_stream      | <%= project.name %>/ruby:latest                                                                      |
      | docker_image      | <%= product_docker_repo %>rhscl/ruby-25-rhel7                                                     |
      | image_stream      | openshift/postgresql                                                                              |
      | image_stream      | <%= project.name %>/postgresql:latest                                                                |
      | docker_image      | <%= product_docker_repo %>rhscl/postgresql-10-rhel7                                               |
      | group             | openshift/ruby+openshift/postgresql                                                               |
      | group             | <%= project.name %>/ruby:latest+<%= project.name %>/postgresql:latest                                   |
      | group             | <%= product_docker_repo %>rhscl/ruby-25-rhel7+<%= product_docker_repo %>rhscl/postgresql-10-rhel7 |
      | code              | https://github.com/openshift/ruby-hello-world                                                     |
      | env               | POSTGRESQL_USER=user                                                                              |
      | env               | POSTGRESQL_DATABASE=db                                                                            |
      | env               | POSTGRESQL_PASSWORD=test                                                                          |
      | l                 | app=testapps                                                                                      |
      | insecure_registry | true                                                                                              |
    Then the step should succeed

    # we end up with total of 5 build configs in the project
    When evaluation of `CucuShift::BuildConfig.list(user: user, project: project)` is stored in the :bc clipboard
    Then the expression should be true> cb.bc.size == 6

    # we end upt with 3 services in the project
    When evaluation of `CucuShift::Service.list(user: user, project: project)` is stored in the :services clipboard
    Then the expression should be true> cb.services.size == 3

    # check all specified is tags are served by a service
    Given I store the image stream tag of the "openshift/ruby" image stream latest tag in the clipboard
    Given evaluation of `[ cb.tag, istag("ruby:latest"), istag("ruby-22-rhel7:latest") ]` is stored in the :istags clipboard
    When I repeat the following steps for each :svc in cb.services:
    """
    # service has a dc
    Given the expression should be true> dc(cb.svc.selector["deploymentconfig"])
    # check there is a build config that triggers dc with one of the istags
    When build configs that trigger the dc are stored in the :bc clipboard
    Then the expression should be true> cb.bc.any? {|bc| cb.istags.delete(bc.strategy.from) }

    # test that service becomes accessible
    When I expose the "8080" port of the "#{cb.svc.name}" service
    Then the step should succeed
    And I wait for the service to become ready up to 300 seconds
    And I wait for a web server to become available via the route
    And the output should contain "Demo App"
    """
    # all expected image stream tags have been used
    Then the expression should be true> cb.istags.empty?

  # @author cryan@redhat.com
  # @case_id OCP-12382
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
    And the output should contain "ruby-sample-build"
    And the "ruby-sample-build-1" build was created
    When I run the :cancel_build client command with:
      | build_name | ruby-sample-build-1 |
    Then the "ruby-sample-build-1" build was cancelled
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
      | follow      | true              |
      | wait        | true              |
      | _timeout    | 120               |
    And the output should contain:
      |Running: |
      |Finished in |
    When I run the :start_build client command with:
      | from_build | ruby-sample-build-1 |
      | follow     | true                |
      | wait       | true                |
      | _timeout   | 120                 |
    And the output should contain:
      |Running: |
      |Finished in |
    When I run the :patch client command with:
      | resource      | buildconfig                                                 |
      | resource_name | ruby-sample-build                                           |
      | p             | {"spec":{"source":{"git":{"uri":"https://nondomain.com"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
      | follow      | true              |
      | wait        | true              |
      | _timeout    | 120               |
    Then the output should contain "unable to access 'https://nondomain.com/"

  # @author cryan@redhat.com
  # @case_id OCP-11713
  Scenario: Add ENV with CustomStrategy when do custom build
    Given I have a project
    Given project role "system:build-strategy-custom" is added to the "first" user
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc479022/application-template-custombuild.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build completed
    When I run the :set_env client command with:
      | resource | pod                       |
      | env_name | ruby-sample-build-1-build |
      | list     | true                      |
    Then the output should contain "http_proxy=http://squid.example.com:3128"

  # @author cryan@redhat.com
  # @case_id OCP-11517
  Scenario: Add more ENV to DockerStrategy buildConfig when do docker build
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-docker.json"
    Given I replace lines in "ruby22rhel7-template-docker.json":
      | registry.access.redhat.com/ | <%= product_docker_repo %> |
    When I run the :new_app client command with:
      | file | ruby22rhel7-template-docker.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      |deployment=frontend-1|
    Given evaluation of `@pods[0].name` is stored in the :frontendpod clipboard
    When I run the :logs client command with:
      | resource_name | build/ruby-sample-build-1 |
    Then the output should contain:
      | ENV RACK_ENV=production  |
      | ENV RAILS_ENV=production |
    When I execute on the "<%= cb.frontendpod %>" pod:
      | env |
    Then the step should succeed
    And the output should contain "RACK_ENV=production"
    When I run the :patch client command with:
      | resource      | buildconfig       |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"strategy": {"dockerStrategy": {"env": [{"name": "DISABLE_ASSET_COMPILATION","value": "1"}, {"name":"RACK_ENV","value":"development"}]}}}} |
    Then the step should succeed
    When I get project buildconfig named "ruby-sample-build" as JSON
    Then the output should contain "DISABLE_ASSET_COMPILATION"
    And the output should contain "RACK_ENV"
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    When I run the :logs client command with:
      | resource_name | build/ruby-sample-build-2 |
      | f             |                           |
    Then the output should contain:
      | ENV "DISABLE_ASSET_COMPILATION"="1" |
      | "RACK_ENV"="development"  |
    Given 2 pods become ready with labels:
      |deployment=frontend-2|
    Given evaluation of `@pods[2].name` is stored in the :frontendpod2 clipboard
    When I execute on the "<%= cb.frontendpod2 %>" pod:
      | env |
    Then the step should succeed
    And the output should contain "RACK_ENV=development"

  # @author cryan@redhat.com
  # @case_id OCP-9595
  Scenario: Order builds according to creation timestamps
    Given I have a project
    And I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc470422/application-template-stibuild.json |
    Given the "ruby-22-centos7" image stream was created
    And the "ruby-22-centos7" image stream becomes ready
    And I run the :start_build client command with:
      | buildconfig |  ruby-sample-build |
    And I run the :start_build client command with:
      | buildconfig |  ruby-sample-build |
    And I run the :start_build client command with:
      | buildconfig |  ruby-sample-build |
    And I get project builds
    Then the output by order should match:
      | ruby-sample-build-1 |
      | ruby-sample-build-2 |
      | ruby-sample-build-3 |
      | ruby-sample-build-4 |

  # @author pruan@redhat.com
  # @case_id OCP-9732
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
    Given the pod named "sample-build-3-build" becomes present
    And I run the :cancel_build client command with:
      | build_name | sample-build-3 |
    And the output should contain:
      | sample-build-3 |
      | cancelled      |

  # @author pruan@redhat.com
  # @case_id OCP-10765
  Scenario: Recreate bc when previous bc is deleting pending
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/test-buildconfig.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build completed
    When I run the :patch client command with:
      | resource      | buildconfig       |
      | resource_name | ruby-sample-build |
      | p | {"metadata": {"annotations": {"openshift.io/build-config.paused": "true"}}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | buildConfig |
    Then the output should contain:
      | build-config.paused=true |
    And I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should fail
    And the output should contain:
      | can't instantiate from BuildConfig <%= project.name %>/ruby-sample-build: BuildConfig is paused |
    When I run the :start_build client command with:
      | from_build | ruby-sample-build-1 |
    Then the step should fail
    And the output should contain:
      | can't instantiate from BuildConfig <%= project.name %>/ruby-sample-build: BuildConfig is paused |
    Then I run the :delete client command with:
      | object_type | buildConfig |
      | object_name_or_id | ruby-sample-build |
    Then the step should succeed
    And I get project buildConfig
    Then the output should not contain:
      | ruby-sample-build |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/test-buildconfig.json |
    Then the step should succeed
    Then the "ruby-sample-build-1" build completed
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

  # @author pruan@redhat.com
  # @case_id OCP-11542
  Scenario: oc start-build with a directory passed,sti build type
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/sclorg/nodejs-ex |
    Then the step should succeed
    And the "nodejs-ex-1" build completed
    And I git clone the repo "https://github.com/sclorg/nodejs-ex"
    And I run the :start_build client command with:
      | buildconfig | nodejs-ex |
      | from_dir    | nodejs-ex |
    Given I wait for the steps to pass:
    """
    Given the pod named "nodejs-ex-2-build" becomes present
    """
    Given the pod named "nodejs-ex-2-build" status becomes :succeeded
    Given the "tmp/test/testfile" file is created with the following lines:
    """
    This is a test!
    """
    And I run the :start_build client command with:
      | buildconfig | nodejs-ex |
      | from_dir    | tmp/test |
    Then the step should succeed
    And I run the :get client command with:
      | resource | build |
    #since this bug #1466659,build always complete,after bug fix, will change back
    Given the pod named "nodejs-ex-3-build" status becomes :succeeded
    And I run the :start_build client command with:
      | buildconfig | nodejs-ex |
      | from_dir    | tmp/deadbeef |
    Then the step should fail
    And the output should contain:
      | deadbeef: no such file or directory |

  # @author pruan@redhat.com
  # @case_id OCP-11214
  Scenario: oc start-build with a directory passed ,using sti build type, with context-dir
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/sclorg/s2i-nodejs-container.git |
      | context_dir | 0.10/test/test-app/                      |
    Then the step should succeed
    Then the "sti-nodejs-1" build completed
    Given I git clone the repo "https://github.com/sclorg/s2i-nodejs-container.git"
    When I run the :start_build client command with:
      | buildconfig | sti-nodejs |
      | from_dir | sti-nodejs |
    And the "sti-nodejs-2" build completed

  # @author pruan@redhat.com
  # @case_id OCP-11766
  Scenario: oc start-build with a file passed,Docker build type
    Given I have a project
    When I run the :new_app client command with:
      | app_repo |  openshift/ruby:2.5~https://github.com/openshift/ruby-hello-world.git |
      | strategy |  docker                                                               |
    Then the step should succeed
    Then the "ruby-hello-world-1" build completed
    Given a "Dockerfile" file is created with the following lines:
    """
    FROM openshift/ruby-22-centos7
    USER default
    EXPOSE 8080
    ENV RACK_ENV production
    ENV RAILS_ENV production
    """
    And I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | from_file   | ./Dockerfile     |
    Then the step should succeed
    Then the "ruby-hello-world-2" build completed
    # start build with non-existing file
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world         |
      | from_file   | ./non-existing-file-name |
    Then the step should fail
    And the output should contain "no such file or directory"

  # @author pruan@redhat.com
  # @case_id OCP-12259
  Scenario: oc start-build with a zip,tar,or tar.gz passed,using Docker build type
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-docker.json |
    Then the step should succeed
    And the "ruby22-sample-build-1" build completes
    And I download a file from "https://github.com/openshift-qe/v3-testfiles/raw/master/build/shared_compressed_files/ruby-hello-world.zip"
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build         |
      | from_dir    | -                         |
      | _stdin      | <%= @result[:response] %> |
      | _binmode    |                           |
    Then the step succeeded
    Then the "ruby22-sample-build-2" build completes
    And I download a file from "https://github.com/openshift-qe/v3-testfiles/raw/master/build/shared_compressed_files/ruby-hello-world.tar"
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build         |
      | from_dir    | -                         |
      | _stdin      | <%= @result[:response] %> |
      | _binmode    |                           |
    Then the step succeeded
    Then the "ruby-sample-build-3" build completes
    And I download a file from "https://github.com/openshift-qe/v3-testfiles/raw/master/build/shared_compressed_files/ruby-hello-world.tar.gz"
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build         | 
      | from_dir    | -                         |
      | _stdin      | <%= @result[:response] %> |
      | _binmode    |                           |
    Then the step succeeded
    Then the "ruby-sample-build-4" build completes
    And I download a file from "https://github.com/openshift-qe/v3-testfiles/raw/master/build/shared_compressed_files/test.zip"
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build       |
      | from_dir    | -                         |
      | _stdin      | <%= @result[:response] %> |
      | _binmode    |                           |
    Then the step should succeed
    And the "ruby-sample-build-5" build fails

  # @author pruan@redhat.com
  # @case_id OCP-12295
  Scenario: oc start-build with a zip,tar,or tar.gz passed,using sti build type
    Given I have a project
    When I run the :new_app client command with:
      | app_repo |   https://github.com/sclorg/nodejs-ex |
    Then the step should succeed
    Then the "nodejs-ex-1" build completes
    And I download a file from "https://github.com/openshift-qe/v3-testfiles/raw/master/build/shared_compressed_files/nodejs-ex.zip"
    When I run the :start_build client command with:
      | buildconfig | nodejs-ex                 |
      | from_dir    | -                         |
      | _stdin      | <%= @result[:response] %> |
      | _binmode    |                           |
    Then the step succeeded
    Then the "nodejs-ex-2" build completes
    And I download a file from "https://github.com/openshift-qe/v3-testfiles/raw/master/build/shared_compressed_files/nodejs-ex.tar"
    When I run the :start_build client command with:
      | buildconfig | nodejs-ex                 |
      | from_dir    | -                         |
      | _stdin      | <%= @result[:response] %> |
      | _binmode    |                           |
    Then the step succeeded
    Then the "nodejs-ex-3" build completes
    And I download a file from "https://github.com/openshift-qe/v3-testfiles/raw/master/build/shared_compressed_files/nodejs-ex.tar.gz"
    When I run the :start_build client command with:
      | buildconfig | nodejs-ex                 |
      | from_dir    | -                         |
      | _stdin      | <%= @result[:response] %> |
      | _binmode    |                           |
    Then the step succeeded
    Then the "nodejs-ex-4" build completes
    And I download a file from "https://github.com/openshift-qe/v3-testfiles/raw/master/build/shared_compressed_files/test.zip"
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | nodejs-ex                 |
      | from_dir    | -                         |
      | _stdin      | <%= @result[:response] %> |
      | _binmode    |                           |
    Then the step should succeed
    # some environment versions have #1466659 and command may succeed
    And the "nodejs-ex-5" build fails

  # @author pruan@redhat.com
  # @case_id OCP-12322
  Scenario: oc start-build with a zip,tar,or tar.gz passed,using sti build type, with context-dir
    Given I have a project
    When I run the :new_app client command with:
      | app_repo    | https://github.com/sclorg/s2i-nodejs-container.git |
      | context_dir | 0.10/test/test-app/                         |
    Then the step should succeed
    And the "sti-nodejs-1" build completes
    And I download a file from "https://github.com/openshift-qe/v3-testfiles/raw/master/build/shared_compressed_files/sti-nodejs.zip"
    When I run the :start_build client command with:
      | buildconfig | sti-nodejs                |
      | from_dir    | -                         |
      | _stdin      | <%= @result[:response] %> |
      | _binmode    |                           |
    And the "sti-nodejs-2" build completes

  # @author pruan@redhat.com
  # @case_id OCP-10744
  Scenario: oc start-build with a directory passed ,using Docker build type
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-docker.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build completes
    And I git clone the repo "https://github.com/openshift/ruby-hello-world.git"
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
      | from_dir    | ruby-hello-world  |
    Then the step should succeed
    And the "ruby-sample-build-2" build completes
    Given I create the "tc512258" directory
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
      | from_dir    | tc512258          |
    Then the step should succeed
    And the "ruby-sample-build-3" build fails
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
      | from_dir    | dir_not_exist     | 
    Then the step should fail
    And the output should contain:
      | no such file or directory |

  # @author cryan@redhat.com
  # @case_id OCP-11778
  Scenario: Implement post-build command for s2i build
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
    Given the "ruby-sample-build-1" build completes
    When I run the :patch client command with:
      | resource      | buildconfig       |
      | resource_name | ruby-sample-build |
      | p | {"spec":{"postCommit":{"script":"bundle exec rake test"}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | buildconfig       |
      | resource_name | ruby-sample-build |
      | o             | json              |
    Then the output should contain "postCommit"
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Given the "ruby-sample-build-2" build completes
    When I run the :patch client command with:
      | resource      | buildconfig       |
      | resource_name | ruby-sample-build |
      | p | {"spec":{"postCommit":{"command": ["/bin/bash", "-c", "bundle exec rake test --verbose"], "args": null, "script":null}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Given the "ruby-sample-build-3" build completes
    When I run the :patch client command with:
      | resource      | buildconfig       |
      | resource_name | ruby-sample-build |
      | p | {"spec":{"postCommit": {"args": ["bundle","exec","rake","test","--verbose"]}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Given the "ruby-sample-build-4" build completes
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-sample-build |
      | p | {"spec":{"postCommit": {"args": ["--verbose"],"command":null, "script": "bundle exec rake test $1"}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Given the "ruby-sample-build-5" build completes

  # @author cryan@redhat.com
  # @case_id OCP-11561
  Scenario: Implement post-build command for quickstart: Django
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc519486/django.json |
    Given the "django-example-1" build completes
    When I run the :build_logs client command with:
      | build_name | django-example-1 |
    Then the output should match "Ran \d+ tests"
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc519486/django-postgresql.json |
    Given the "django-psql-example-1" build completes
    When I run the :build_logs client command with:
      | build_name | django-psql-example-1 |
    Then the output should match "Ran \d+ tests"

  # @author cryan@redhat.com
  # @case_id OCP-10785
  Scenario: Can't allocate out of limits resources to container which builder pod launched for docker build
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-docker.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig       |
      | resource_name | ruby-sample-build |
      | p | {"spec":{"resources": {"requests": {"cpu": "600m","memory": "200Mi"},"limits": {"cpu": "800m","memory": "200Mi"}}}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig       |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"source": {"git": {"uri": "git://github.com/openshift-qe/ruby-cgroup-test.git","ref":"memlarge"}}}} |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    Then I run the :delete client command with:
      | object_type       | builds              |
      | object_name_or_id | ruby-sample-build-1 |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Given the "ruby-sample-build-2" build fails
    When I run the :build_logs client command with:
      | build_name | ruby-sample-build-2 |
    Then the output should contain:
      | stress: FAIL |
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"source": {"git": {"uri": "git://github.com/openshift-qe/ruby-cgroup-test.git","ref":"cpularge"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-3" build was created
    Given the "ruby-sample-build-3" build completed
    When I run the :build_logs client command with:
      | build_name | ruby-sample-build-3 |
    Then the output should contain:
      | cat /sys/fs/cgroup/cpuacct,cpu/cpu.shares        |
      | 614                                              |
      | cat /sys/fs/cgroup/cpuacct,cpu/cpu.cfs_period_us |
      | 100000                                           |
      | cat /sys/fs/cgroup/cpuacct,cpu/cpu.cfs_quota_us  |
      | 80000                                            |

  # @author cryan@redhat.com
  # @case_id OCP-12487
  Scenario: Do sti build with the OnBuild instructions strategy and sti scripts via oc
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/template_onbuild.json |
    Given the "ruby-sample-build-1" build completes

  # @author cryan@redhat.com
  # @case_id OCP-12307
  Scenario: Do source builds with blank builder image
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc470327/python-34-rhel7-stibuild.json |
    Then the step should fail
    And the output should match:
      | spec.strategy.sourceStrategy.from.name: [Rr]equired value |

  # @author pruan@redhat.com
  # @case_id OCP-11777
  Scenario: Check cgroup info in container which builder pod launched for s2i build
    Given I have a project
    When I run the :new_app client command with:
      | app_repo |  openshift/ruby:latest~https://github.com/openshift-qe/ruby-cgroup-test |
    Then the step should succeed
    Given the "ruby-cgroup-test-1" build becomes :running
    And I wait up to 60 seconds for the steps to pass:
    """
    And I run the :logs client command with:
      | resource_name | bc/ruby-cgroup-test |
    And the output should contain:
      | ===Cgroup info===                                |
      | cat /sys/fs/cgroup/memory/memory.limit_in_bytes  |
      | cat /sys/fs/cgroup/cpuacct,cpu/cpu.shares        |
      | cat /sys/fs/cgroup/cpuacct,cpu/cpu.cfs_period_us |
      | cat /sys/fs/cgroup/cpuacct,cpu/cpu.cfs_quota_us  |
    """

  # @author cryan@redhat.com
  # @case_id OCP-9950
  Scenario: Check bad proxy in .s2i/environment when performing s2i build
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json"
    Given I replace lines in "ruby20rhel7-template-sti.json":
      | "uri": "https://github.com/openshift/ruby-hello-world.git" | "uri": "https://github.com/openshift-qe/ruby-hello-world-badproxy.git" |
    Given I process and create "ruby20rhel7-template-sti.json"
    Given the "ruby-sample-build-1" build finishes
    When I run the :logs client command with:
      | resource_name | build/ruby-sample-build-1 |
    Then the step should succeed
    And the output should contain "Could not fetch specs"

  # @author cryan@redhat.com
  # @case_id OCP-12500
  Scenario: Add ENV vars to .sti/environment when do sti build in openshift
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json"
    Given I replace lines in "ruby20rhel7-template-sti.json":
      | "uri": "https://github.com/openshift/ruby-hello-world.git" | "uri": "https://github.com/openshift-qe/ruby-hello-world-tc482216.git" |
    Given I process and create "ruby20rhel7-template-sti.json"
    Given the "ruby-sample-build-1" build completes
    Given 2 pods become ready with labels:
      | name=frontend |
    When I execute on the pod:
      | env |
    Then the output should contain "envtest1"

  # @author cryan@redhat.com
  # @case_id OCP-10630
  Scenario: Sync build status after delete its related pod
    Given I have a project
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/php-55-rhel7-stibuild.json"
    Then the step should succeed
    Given the pod named "php-sample-build-1-build" status becomes :running
    When I run the :delete client command with:
      | object_type | pod |
      | object_name_or_id | php-sample-build-1-build |
    Then the step should succeed
    Given the "php-sample-build-1" build finishes
    Given I get project builds
    Then the output should contain "Error"
    When I run the :start_build client command with:
      | buildconfig | php-sample-build |
    Then the step should succeed
    Given the pod named "php-sample-build-2-build" status becomes :running
    When I run the :delete client command with:
      | object_type | pod |
      | object_name_or_id | php-sample-build-2-build |
    Then the step should succeed
    Given the "php-sample-build-2" build finishes
    Given I get project builds
    Then the output should contain "Error"
    When I run the :start_build client command with:
      | buildconfig | php-sample-build |
    Then the step should succeed
    Given the "php-sample-build-3" build completes
    When I run the :delete client command with:
      | object_type | pod |
      | object_name_or_id | php-sample-build-3-build |
    Then the step should succeed
    When I run the :get client command with:
      | resource | builds |
      | resource_name | php-sample-build-3 |
    Then the output should contain "Complete"
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | php-sample-build |
      | p | {"spec": {"source": {"git": {"uri": "https://nonexist.com"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | php-sample-build |
    Then the step should succeed
    Given the "php-sample-build-4" build finishes
    When I run the :get client command with:
      | resource | builds |
      | resource_name | php-sample-build-4 |
    Then the output should contain "Failed"
    When I run the :delete client command with:
      | object_type | pod |
      | object_name_or_id | php-sample-build-4-build |
    Then the step should succeed

  # @author cryan@redhat.com
  # @case_id OCP-9892
  Scenario: Overriding builder image scripts by invalid scripts in buildConfig
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/test-buildconfig.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"strategy": {"sourceStrategy": {"scripts": "http:/foo.bar.com/invalid/assemble"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build finishes
    When I run the :logs client command with:
      | resource_name | build/ruby-sample-build-2 |
    Then the step should succeed
    And the output should match:
      | [Cc]ould not download |

  # @author cryan@redhat.com
  # @case_id OCP-9914
  Scenario: Overriding builder image scripts in buildConfig under invalid proxy
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/test-buildconfig.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"strategy": {"sourceStrategy": {"scripts": "https://raw.githubusercontent.com/dongboyan77/builderimage-scripts/master/bin"}}}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"strategy": {"sourceStrategy": {"env": [{"name":"http_proxy","value":"http://incorrect.proxy:3128"}]}}}} |
      Then the step should succeed
      When I run the :start_build client command with:
        | buildconfig | ruby-sample-build |
      Then the step should succeed
      Given the "ruby-sample-build-2" build finishes
      When I run the :logs client command with:
        | resource_name | build/ruby-sample-build-2 |
      Then the step should succeed
      And the output should match "error connecting to proxy|build error: could not download any scripts from URL|Could not fetch specs from https://rubygems.org/"

  # @author cryan@redhat.com
  # @case_id OCP-10772
  Scenario: Specify build apiVersion for custom build
    Given I have a project
    Given project role "system:build-strategy-custom" is added to the "first" user
    Then the step should succeed
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json"
    Then the step should succeed
    Given the "ruby-sample-build-1" build completes
    Given I get project buildconfigs
    Then the output should contain:
      | ruby-sample-build |
      | Custom            |
    When I run the :describe client command with:
      | resource | buildconfig       |
      | name     | ruby-sample-build |
    Then the output should contain:
      | ruby-sample-build |
      | Custom            |
    When I run the :set_env client command with:
      | resource | pod/ruby-sample-build-1-build |
      | list     | true                          |
    Then the step should succeed
    And the output should contain:
      | "apiVersion":"v1" |
    When I run the :patch client command with:
      | resource      | buildconfig       |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"strategy": {"customStrategy": {"buildAPIVersion": "v1"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build completes
    When I run the :set_env client command with:
      | resource | pod/ruby-sample-build-2-build |
      | list     | true                          |
    Then the step should succeed
    And the output should contain:
      | "apiVersion":"v1"      |
      | "buildAPIVersion":"v1" |

  # @author cryan@redhat.com
  # @case_id OCP-10655
  @admin
  @destructive
  Scenario: Allowing only certain users to create builds with a particular strategy
    Given cluster role "system:build-strategy-docker" is removed from the "system:authenticated" group
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-dockerbuild.json |
    Then the output should contain "build strategy Docker is not allowed"
    Given cluster role "system:build-strategy-docker" is added to the "first" user
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-dockerbuild.json |
    Given I get project builds
    Then the output should contain "ruby-sample-build-1"

  # @author cryan@redhat.com
  # @case_id OCP-10659
  @admin
  @destructive
  Scenario: Can't start a new build when disable a build strategy globally after buildconfig has been created
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-dockerbuild.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build becomes :running
    Given I get project builds
    Then the output should contain "ruby-sample-build-1"
    Given cluster role "system:build-strategy-docker" is removed from the "system:authenticated" group
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the output should contain "Docker is not allowed"

  # @author dyan@redhat.com
  # @case_id OCP-9859
  Scenario: oc new-build --binary should create BC according to the imagetype
    Given I have a project
    When I run the :new_build client command with:
      | binary | ruby |
    Then the step should succeed
    When I get project build_config named "ruby" as YAML
    Then the step should succeed
    And the output should contain:
      | sourceStrategy |
      | type: Source   |
    When I run the :new_build client command with:
      | binary | registry.access.redhat.com/rhscl/ruby-22-rhel7:latest |
      | to     | ruby1 |
    Then the step should succeed
    When I get project build_config named "ruby1" as YAML
    Then the step should succeed
    And the output should contain:
      | sourceStrategy |
      | type: Source   |
    When I run the :new_build client command with:
      | binary | ruby |
      | strategy | docker |
      | to     | ruby2 |
    Then the step should succeed
    When I get project build_config named "ruby2" as YAML
    Then the step should succeed
    And the output should contain:
      | dockerStrategy |
      | type: Docker   |

  # @author cryan@redhat.com
  # @case_id OCP-11772
  Scenario: Using a docker image as source input for new-build cmd--negetive test
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/ruby:latest |
      | app_repo | https://github.com/openshift/ruby-hello-world |
      | source_image | openshift/python:latest |
      | source_image_path | src/:/destination-dir |
      | name | app1 |
    Then the step should fail
    And the output should contain "relative path"
    When I run the :new_build client command with:
      | app_repo | openshift/ruby:latest |
      | app_repo | https://github.com/openshift/ruby-hello-world |
      | source_image | openshift/python:latest |
      | source_image_path | /non-existing-source/:destination-dir  |
      | name | app2 |
    Then the step should succeed
    Given the "app2-1" build failed
    When I run the :logs client command with:
      | resource_name | build/app2-1 |
    Then the output should contain "error copying source path"
    When I run the :new_build client command with:
      | app_repo | openshift/ruby:latest |
      | app_repo | https://github.com/openshift/ruby-hello-world |
      | source_image | openshift/python:latest |
      | source_image_path | /tmp:Dockerfile |
      | name | app3 |
    Then the step should succeed
    Given the "app3-1" build finishes
    When I run the :logs client command with:
      | resource_name | build/app3-1 |
    Then the output should contain "must be a directory"
    When I run the :new_build client command with:
      | app_repo | openshift/ruby:latest |
      | app_repo | https://github.com/openshift/ruby-hello-world |
      | source_image_path | /source-dir/:destiontion-dir/ |
      | name | app4 |
    Then the step should fail
    And the output should contain "source-image must be specified"
    When I run the :new_build client command with:
      | app_repo | openshift/ruby:latest |
      | app_repo | https://github.com/openshift/ruby-hello-world |
      | source_image | openshift/python:latest |
      | name | app5 |
    Then the step should fail
    And the output should contain "source-image-path must be specified"
    When I run the :new_build client command with:
      | app_repo | openshift/ruby:latest |
      | app_repo | https://github.com/openshift/ruby-hello-world |
      | source_image | openshift/python:latest |
      | source_image_path ||
      | name | app6 |
    Then the step should fail
    And the output should contain "source-image-path must be specified"

  # @author cryan@redhat.com
  # @case_id OCP-9913
  Scenario: Overriding builder image scripts by url scripts in buildConfig under proxy
    Given I have a project
    And I have a proxy configured in the project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/test-buildconfig.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"strategy": {"sourceStrategy": {"scripts": "https://raw.githubusercontent.com/openshift-qe/builderimage-scripts/master/bin"}}}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"strategy": {"sourceStrategy": {"env": [{"name": "http_proxy","value": "http://<%= cb.proxy_ip %>:3128"}]}}}} |
    Then the step should succeed
    When I get project build_config named "ruby-sample-build" as JSON
    Then the output should contain "http://<%= cb.proxy_ip %>:3128"
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given the "ruby-sample-build-2" build completes

  # @author cryan@redhat.com
  # @case_id OCP-11153
  @admin
  @destructive
  Scenario: Disabling a build strategy globally
    Given I have a project
    Given cluster role "system:build-strategy-docker" is removed from the "system:authenticated" group
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build completes
    When I run the :delete client command with:
      | all_no_dash ||
      | all||
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-dockerbuild.json |
    Then the step should fail
    And the output should contain "Docker is not allowed"
    When I run the :delete client command with:
      | all_no_dash ||
      | all||
    Then the step should succeed
    Given cluster role "system:build-strategy-source" is removed from the "system:authenticated" group
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should fail
    And the output should contain "Source is not allowed"

  # @author xiuwang@redhat.com
  # @case_id OCP-11238
  Scenario: Can't allocate out of limits resources to container which builder pod launched for s2i build
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig       |
      | resource_name | ruby-sample-build |
      | p | {"spec":{"resources": {"requests": {"cpu": "600m","memory": "200Mi"},"limits": {"cpu": "800m","memory": "200Mi"}}}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig       |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"source": {"git": {"uri": "git://github.com/openshift-qe/ruby-cgroup-test.git","ref":"memlarge"}}}} |
    Then the step should succeed
    Then I run the :delete client command with:
      | object_type       | builds              |
      | object_name_or_id | ruby-sample-build-1 |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
      | follow   | true |
      | wait     | true |
      | _timeout | 120  |
    And the output should contain:
      | stress: FAIL                                    |
      | cat /sys/fs/cgroup/memory/memory.limit_in_bytes |
      | 209715200                                       |
    When I run the :patch client command with:
      | resource      | buildconfig       |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"source": {"git": {"uri": "git://github.com/openshift-qe/ruby-cgroup-test.git","ref":"cpularge"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
      | follow   | true |
      | wait     | true |
      | _timeout | 120  |
    And the output should contain:
      | cat /sys/fs/cgroup/cpuacct,cpu/cpu.shares        |
      | 614                                              |
      | cat /sys/fs/cgroup/cpuacct,cpu/cpu.cfs_period_us |
      | 100000                                           |
      | cat /sys/fs/cgroup/cpuacct,cpu/cpu.cfs_quota_us  |
      | 80000                                            |

  # @author xiuwang@redhat.com
  # @case_id OCP-11558
  Scenario: Check cgroup info in container which builder pod launched for docker build
    Given I have a project
    When I run the :new_app client command with:
      | code | https://github.com/openshift-qe/ruby-cgroup-test |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                         |
      | resource_name | ruby-cgroup-test                                                                                                    |
      | p             | {"spec":{"resources": {"requests": {"cpu": "600m","memory": "200Mi"},"limits": {"cpu": "800m","memory": "200Mi"}}}} |
    And the "ruby-cgroup-test-1" build was created
    When I run the :cancel_build client command with:
      | build_name | ruby-cgroup-test-1 |
    Then the step should succeed
    And I run the :start_build client command with:
      | buildconfig | ruby-cgroup-test |
    And the "ruby-cgroup-test-2" build was created
    Given the "ruby-cgroup-test-2" build completed
    When I run the :build_logs client command with:
      | build_name  | ruby-cgroup-test-2 |
    And the output should contain:
      | RUN cp -r /sys/fs/cgroup/cpuacct,cpu/cpu* /tmp                     |
      | RUN cp -r /sys/fs/cgroup/memory/memory.limit_in_bytes /tmp/memlimit|
    Given I wait for the "ruby-cgroup-test" service to become ready up to 300 seconds
    And I get the service pods
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | cat /tmp/memlimit /tmp/cpu.shares /tmp/cpu.cfs_period_us /tmp/cpu.cfs_quota_us |
    Then the step should succeed
    """
    And the output should contain:
        | 209715200      |
        | 614            |
        | 100000         |
        | 80000          |

  # @author haowang@redhat.com
  # @case_id OCP-12150
  Scenario: oc start-build with a local git repo and commit using sti build type
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/sclorg/nodejs-ex |
    Then the step should succeed
    And the "nodejs-ex-1" build completed
    Given I wait for the "nodejs-ex" service to become ready up to 300 seconds
    When I expose the "nodejs-ex" service
    Then I wait for a web server to become available via the "nodejs-ex" route
    And the output should contain "Welcome to OpenShift"
    And I git clone the repo "https://github.com/sclorg/nodejs-ex"
    And I run the :start_build client command with:
      | buildconfig | nodejs-ex |
      | from_repo   | nodejs-ex |
    Then the step should succeed
    And the "nodejs-ex-2" build completed
    Given 1 pods become ready with labels:
      | app=nodejs-ex              |
      | deployment=nodejs-ex-2     |
    Then I wait for a web server to become available via the "nodejs-ex" route
    And the output should contain "Welcome to OpenShift"
    Given I replace lines in "nodejs-ex/views/index.html":
      | Welcome to OpenShift | Welcome all to OpenShift |
    Then the step should succeed
    And I commit all changes in repo "nodejs-ex" with message "update index.html"
    Then I get the latest git commit id from repo "nodejs-ex"
    When I run the :start_build client command with:
      | buildconfig | nodejs-ex|
      | from_repo   | nodejs-ex|
      | commit      | <%= cb.git_commit_id %> |
    Then the step should succeed
    And the "nodejs-ex-3" build completed
    Given 1 pods become ready with labels:
      | app=nodejs-ex              |
      | deployment=nodejs-ex-3     |
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | cat                       |
      | views/index.html          |
    And the output should contain "Welcome all to OpenShift"
    """
    When I run the :start_build client command with:
      | buildconfig | nodejs-ex|
      | from_repo   | nodejs-ex|
      | commit      | fffffffffffffffffffffffffffffffffffff |
    Then the step should fail
    When I run the :start_build client command with:
      | buildconfig | nodejs-ex|
      | from_repo   | no-exit  |
      | commit      | <%= cb.git_commit_id %> |
    Then the step should fail

  # @author haowang@redhat.com
  # @case_id OCP-12210
  Scenario: oc start-build with a local git repo and commit using sti build type, with context-dir
    Given I have a project
    When I run the :new_app client command with:
      | app_repo    | https://github.com/sclorg/s2i-nodejs-container.git |
      | context_dir | 0.10/test/test-app                          |
    Then the step should succeed
    And the "sti-nodejs-1" build completed
    Given I wait for the "sti-nodejs" service to become ready up to 300 seconds
    When I expose the "sti-nodejs" service
    Then I wait for a web server to become available via the "sti-nodejs" route
    And the output should contain "This is a node.js echo service"
    And I git clone the repo "https://github.com/sclorg/s2i-nodejs-container"
    And I run the :start_build client command with:
      | buildconfig | sti-nodejs |
      | from_repo   | sti-nodejs |
    Then the step should succeed
    And the "sti-nodejs-2" build completed
    Given 1 pods become ready with labels:
      | app=sti-nodejs              |
      | deployment=sti-nodejs-2     |
    Then I wait for a web server to become available via the "sti-nodejs" route
    And the output should contain "This is a node.js echo service"
    Given I replace lines in "sti-nodejs/0.10/test/test-app/server.js":
      | This is a node.js echo service | Welcome to OpenShift  |
    Then the step should succeed
    And I commit all changes in repo "sti-nodejs" with message "update server.js"
    Then I get the latest git commit id from repo "sti-nodejs"
    When I run the :start_build client command with:
      | buildconfig | sti-nodejs|
      | from_repo   | sti-nodejs|
      | commit      | <%= cb.git_commit_id %> |
    Then the step should succeed
    And the "sti-nodejs-3" build completed
    Given 1 pods become ready with labels:
      | app=sti-nodejs              |
      | deployment=sti-nodejs-3     |
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | cat                       |
      | server.js        |
    And the output should contain "Welcome to OpenShift"
    """
    When I run the :start_build client command with:
      | buildconfig | sti-nodejs|
      | from_repo   | sti-nodejs|
      | commit      | fffffffffffffffffffffffffffffffffffff |
    Then the step should fail
    When I run the :start_build client command with:
      | buildconfig | sti-nodejs|
      | from_repo   | no-exit  |
      | commit      | <%= cb.git_commit_id %> |
    Then the step should fail

  # @author haowang@redhat.com
  # @case_id OCP-12055
  Scenario: oc start-build with a local git repo and commit using Docker build type
    Given I have a project
    When I run the :new_app client command with:
      | app_repo    | https://github.com/openshift/ruby-hello-world |
      | strategy    | docker                          |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    Given I wait for the "ruby-hello-world" service to become ready up to 300 seconds
    When I expose the "ruby-hello-world" service
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And the output should contain "Welcome to an OpenShift v3 Demo App!"
    And I git clone the repo "https://github.com/openshift/ruby-hello-world"
    And I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | from_repo   | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-2" build completed
    Given 1 pods become ready with labels:
      | app=ruby-hello-world              |
      | deployment=ruby-hello-world-2     |
    Then I wait for a web server to become available via the "ruby-hello-world" route
    And the output should contain "Welcome to an OpenShift v3 Demo App!"
    Given I replace lines in "ruby-hello-world/views/main.erb":
      | Welcome to an OpenShift v3 Demo App! | Welcome all to an OpenShift v3 Demo App!  |
    Then the step should succeed
    And I commit all changes in repo "ruby-hello-world" with message "update server.js"
    Then I get the latest git commit id from repo "ruby-hello-world"
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world|
      | from_repo   | ruby-hello-world|
      | commit      | <%= cb.git_commit_id %> |
    Then the step should succeed
    And the "ruby-hello-world-3" build completed
    Given 1 pods become ready with labels:
      | app=ruby-hello-world              |
      | deployment=ruby-hello-world-3     |
    And I wait up to 20 seconds for the steps to pass:
    """
    When I execute on the pod:
      | cat                       |
      | views/main.erb            |
    And the output should contain "Welcome all to an OpenShift v3 Demo App!"
    """
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world|
      | from_repo   | ruby-hello-world|
      | commit      | fffffffffffffffffffffffffffffffffffff |
    Then the step should fail
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world|
      | from_repo   | no-exit  |
      | commit      | <%= cb.git_commit_id %> |
    Then the step should fail

  # @author yantan@redhat.com
  # @case_id OCP-11122
  Scenario: Sync pod status after delete its related build
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/php-56-rhel7-stibuild.json |
    Then the step should succeed
    Given the "php-sample-build-1" build becomes :pending
    When I run the :delete client command with:
      | object_type | build |
      | object_name_or_id| php-sample-build-1 |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the step should succeed
    And the output should not contain "php"
    """
    And I wait for the steps to pass:
    """
    When I get project replicationcontroller
    Then the output should not contain "frontend"
    """
    When I run the :start_build client command with:
      | buildconfig | php-sample-build |
    Given the "php-sample-build-2" build becomes :running
    When I get project pods
    Then the output should contain "php"
    When I run the :delete client command with:
      | object_type | builds|
      | all | true |
    Then the step should succeed
    And I wait up to 120 seconds for the steps to pass:
    """
    When I get project pods
    Then the step should succeed
    And the output should not contain "php"
    """
    When I run the :start_build client command with:
       | buildconfig | php-sample-build |
    Given the "php-sample-build-3" build becomes :complete
    Given the pod named "php-sample-build-3-build" status becomes :succeeded
    When I get project pods
    Then the output should contain "php"
    When I run the :delete client command with:
       | object_type | build |
       | object_name_or_id | php-sample-build-3 |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should not contain "php"
    """
    When I replace resource "bc" named "php-sample-build":
      | https://github.com/openshift-qe/php-example-app | https://github.com/openshift-qe/php-example-apptest |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | php-sample-build |
    Given the "php-sample-build-4" build becomes :failed
    When I get project pods
    Then the output should contain "php"
    When I run the :delete client command with:
      | object_type | build |
      | object_name_or_id |  php-sample-build-4|
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the output should not contain "php"
    """

  # @author cryan@redhat.com
  # @case_id OCP-10829
  Scenario: Cannot docker build with no inputs in buildconfig
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/nosrc-extended-test-bldr/master/nosrc-test.json"
    When I run the :create client command with:
      | f | nosrc-test.json |
    Then the step should fail
    And the output should contain "must provide a value"
    Given I replace lines in "nosrc-test.json":
      | "source": {}, | "source": { "type": "None" }, |
    When I run the :create client command with:
      | f | nosrc-test.json |
    Then the step should fail
    And the output should contain "must provide a value"

  # @author yantan@redhat.com
  # @case_id OCP-10668
  @admin
  @destructive
  Scenario: Allow STI builder images from running as root
    Given I have a project
    And SCC "privileged" is added to the "system:serviceaccounts:<%= project.name %>" group
    When I run the :new_build client command with:
      | name           | ruby-hello-world |
      | app_repo       | aosqe/ruby-20-centos7:user0~https://github.com/openshift-qe/ruby-hello-world-support-ruby2.0 |
    Then the step should succeed
    Given the "ruby-hello-world-1" build completes
    When I replace resource "bc" named "ruby-hello-world":
      | user0          | usernon     |
    Then the step should succeed
    When I replace resource "is" named "ruby-20-centos7":
      | user0          | usernon    |
    Then the step should succeed
    Given the "ruby-hello-world-2" build completes
    When I replace resource "bc" named "ruby-hello-world":
      | usernon        | userroot    |
    Then the step should succeed
    When I replace resource "is" named "ruby-20-centos7":
      | usernon        | userroot    |
    Then the step should succeed
    Given the "ruby-hello-world-3" build completes
    When I replace resource "bc" named "ruby-hello-world":
      | userroot       | userdefault |
    Then the step should succeed
    When I replace resource "is" named "ruby-20-centos7":
      | userroot       | userdefault |
    Then the step should succeed
    Given the "ruby-hello-world-4" build completes
    When I replace resource "bc" named "ruby-hello-world":
      | userdefault    | user1001    |
    Then the step should succeed
    When I replace resource "is" named "ruby-20-centos7":
      | userdefault    | user1001    |
    Then the step should succeed
    Given the "ruby-hello-world-5" build completes

  # @author cryan@redhat.com
  # @case_id OCP-10857
  Scenario: Show basic info about build reason when trigger build manually
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-docker.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | build               |
      | name     | ruby-sample-build-1 |
    Then the step should succeed
    When I run the :start_build client command with:
      | from_build | ruby-sample-build-1 |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | build               |
      | name     | ruby-sample-build-2 |
    Then the step should succeed
    And the output should contain "Manually triggered"
    When I get project builds named "ruby-sample-build-2" as YAML
    Then the step should succeed
    And the output should contain "Manually triggered"

  # @author cryan@redhat.com
  # @case_id OCP-9975
  Scenario: Generate new applications from docker compose via oc import docker-compose
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/docker-compose-nodejs-examples/master/05-nginx-express-redis-nodemon/docker-compose.yml"
    When I git clone the repo "https://github.com/openshift-qe/docker-compose-nodejs-examples.git"
    Then the step should succeed
    Given I replace lines in "docker-compose.yml":
      |./app | ./docker-compose-nodejs-examples/05-nginx-express-redis-nodemon/app |
    Given I replace lines in "docker-compose.yml":
      |./nginx | ./docker-compose-nodejs-examples/05-nginx-express-redis-nodemon/nginx |
    When I run the :import client command with:
      | command | docker-compose     |
      | f       | docker-compose.yml |
    Then the step should succeed
    Given the "web-1" build becomes :running
    Given I get project pods
    And the output should contain:
      | web-1   |
      | nginx-1 |
      | db-1    |
    When I run the :delete client command with:
      | all_no_dash |  |
      | all         |  |
    Then the step should succeed
    When I run the :import client command with:
      | command | docker-compose                                                             |
      | f       | docker-compose-nodejs-examples/02-express-redis-nodemon/docker-compose.yml |
    Then the step should succeed
    Given the "web-1" build becomes :running
    Given I get project pods
    And the output should contain:
      | web-1   |
      | db-1    |
    When I run the :import client command with:
      | command     | docker-compose                                                             |
      | f           | docker-compose-nodejs-examples/02-express-redis-nodemon/docker-compose.yml |
      | o           | json                                                                       |
      | as_template | test.json                                                                  |
    Then the step should succeed
    Given I save the output to file> test.json
    When I run the :delete client command with:
      | all_no_dash |  |
      | all         |  |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | test.json |
    Then the step should succeed
    Given the "web-1" build completes
    When I run the :import client command with:
      | command | docker-compose                                                             |
      | f       | docker-compose-nodejs-examples/02-express-redis-nodemon/docker-compose.yml |
      | dry_run | true                                                                       |
    Then the step should succeed

  # @author cryan@redhat.com
  # @case_id OCP-9626
  # @bug_id 1255502
  Scenario: Docker build with pulling image from internal docker registry
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/openshift-qe/docker-build |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | app=docker-build |
    When I run the :get client command with:
      | resource      | pod                                  |
      | resource_name | <%= pod.name %>                      |
      | template      | {{(index .spec.containers 0).image}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :imgid clipboard
    Given I create the "app2" directory
    And a "app2/Dockerfile" file is created with the following lines:
    """
    FROM <%= cb.imgid %>
    ENTRYPOINT ["sh", "/bin/hack_init.sh"]
    """
    #There is no 'success' check after this step, as the new-app command will
    #return Failed, as the docker-build imagestream already exists
    When I run the :new_app client command with:
      | app_repo          | app2          |
      | name              | app2          |
      | insecure_registry | true          |
    When I run the :start_build client command with:
      | buildconfig | app2            |
      | from_file   | app2/Dockerfile |
    Then the step should succeed
    Given the "app2-1" build completes
    When I run the :logs client command with:
      | resource_name | build/app2-1 |
    #Check output from original bz:
    And the output should not contain "reference failed"
    Given a pod becomes ready with labels:
      | app=app2 |

  # @author yantan@redhat.com
  # @case_id OCP-11159
  @admin
  @destructive
  Scenario: Allow STI builder images from running as root - using onbuild image
    Given I have a project
    And SCC "privileged" is added to the "system:serviceaccounts:<%= project.name %>" group
    When I run the :new_build client command with:
      | name           | ruby-hello-world |
      | app_repo       | aosqe/ruby-20-centos7:onbuild-user0~https://github.com/openshift-qe/ruby-hello-world-support-ruby2.0 |
    Then the step should succeed
    Given the "ruby-hello-world-1" build completes

  # @author haowang@redhat.com
  # @case_id OCP-11271
  Scenario: Change runpolicy to parallel build
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/ruby~https://github.com/openshift/ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-2" build was created
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-3" build was created
    When the "ruby-hello-world-1" build becomes :running
    Then the "ruby-hello-world-2" build is :new
    Then the "ruby-hello-world-3" build is :new
    When I run the :patch client command with:
      | resource      | bc                                |
      | resource_name | ruby-hello-world                  |
      | p             | {"spec":{"runPolicy":"Parallel"}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-4" build was created
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-5" build was created
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-6" build was created
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
    Then the step should succeed
    Then the "ruby-hello-world-2" build becomes :running
    And the "ruby-hello-world-3" build is :new
    And the "ruby-hello-world-4" build is :new
    And the "ruby-hello-world-5" build is :new
    And the "ruby-hello-world-6" build is :new
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-2 |
    Then the step should succeed
    And the "ruby-hello-world-3" build becomes :running
    And the "ruby-hello-world-4" build is :new
    And the "ruby-hello-world-5" build is :new
    And the "ruby-hello-world-6" build is :new
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-3 |
    Then the step should succeed
    Then the "ruby-hello-world-4" build becomes :running
    Then the "ruby-hello-world-5" build status is any of:
      | pending |
      | running |
    Then the "ruby-hello-world-6" build status is any of:
      | pending |
      | running |
    When I run the :patch client command with:
      | resource      | bc                              |
      | resource_name | ruby-hello-world                |
      | p             | {"spec":{"runPolicy":"Serial"}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-7" build was created
    And the "ruby-hello-world-7" build is :new
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-8" build was created
    And the "ruby-hello-world-8" build is :new
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-5 |
    Then the step should succeed
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-6 |
    Then the step should succeed
    And the "ruby-hello-world-7" build becomes :running
    Then the "ruby-hello-world-8" build is :new

  # @author haowang@redhat.com
  # @case_id OCP-11788
  Scenario: Serial runPolicy for Binary builds
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/ruby   |
      | binary   |                  |
      | name     | ruby-hello-world |
    Then the step should succeed
    And I download a file from "https://github.com/openshift-qe/v3-testfiles/raw/master/build/shared_compressed_files/ruby-hello-world.tar"
    Given evaluation of `@result[:response]` is stored in the :tarfile clipboard
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | from_dir    | -                |
      | _stdin      | <%= cb.tarfile%> |
      | _binmode    |                  |
    Then the step succeeded
    And the "ruby-hello-world-1" build was created
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | from_dir    | -                |
      | _stdin      | <%= cb.tarfile%> |
      | _binmode    |                  |
    Then the step succeeded
    And the "ruby-hello-world-2" build was created
    And the "ruby-hello-world-1" build is :complete
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | from_dir    | -                |
      | _stdin      | <%= cb.tarfile%> |
      | _binmode    |                  |
    Then the step succeeded
    And the "ruby-hello-world-3" build was created
    And the "ruby-hello-world-2" build is :complete

  # @author haowang@redhat.com
  # @case_id OCP-10834
  Scenario: Change Parallel runpolicy to SerialLatestOnly build
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc526202/bc.json |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-2" build was created
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-3" build was created
    And the "ruby-ex-1" build status is any of:
      | pending |
      | running |
    And the "ruby-ex-2" build status is any of:
      | pending |
      | running |
    And the "ruby-ex-3" build status is any of:
      | pending |
      | running |
    When I run the :patch client command with:
      | resource      | bc                                        |
      | resource_name | ruby-ex                                   |
      | p             | {"spec":{"runPolicy":"SerialLatestOnly"}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-4" build was created
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-5" build was created
    And the "ruby-ex-4" build was cancelled
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-6" build was created
    And the "ruby-ex-5" build was cancelled
    When the "ruby-ex-6" build completes
    When I run the :patch client command with:
      | resource      | bc                                |
      | resource_name | ruby-ex                           |
      | p             | {"spec":{"runPolicy":"Parallel"}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-7" build status is any of:
      | pending |
      | running |
    And the "ruby-ex-8" build status is any of:
      | pending |
      | running |

  # @author wewang@redhat.com
  # @case_id OCP-12516
  Scenario: Do sti build using image with onbuild instructions and without tar should build failed
    Given I have a project
    When I git clone the repo "https://github.com/openshift/ruby-hello-world"
    When I run the :new_app client command with:
      | app_repo | <%= localhost.workdir %>/ruby-hello-world |
      | docker_image | docker.io/aosqe/rubyonbuild:notar |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build failed
    When I run the :build_logs client command with:
      | build_name | ruby-hello-world-1 |
    Then the step should succeed
    Then the output should contain:
      | builder image uses ONBUILD instructions but ONBUILD is not allowed  |

  # @author pruan@redhat.com
  # @case_id OCP-10664
  Scenario: Simple error message return when no value followed with oc logs
    Given I have a project
    When I run the :logs client command with:
      | resource_name | |
    Then the step should fail
    And the output should contain:
      | error         |
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-dockerbuild.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build becomes :running
    When I run the :logs client command with:
      | resource_name | build\/|
    Then the step should fail
    And the output should contain:
      | arguments in resource/name form must have a single resource and name |
    When I run the :logs client command with:
      | resource_name | build\/ |
      | n             | default |
    Then the step should fail
    And the output should contain:
      | arguments in resource/name form must have a single resource and name |

  # @author cryan@redhat.com
  # @case_id OCP-10184
  # @bug_id 1357674
  @admin
  @destructive
  Scenario: Create new build without git installed
    Given I have a project
    #Edit scc to delete git in the pod
    Given scc policy "restricted" is restored after scenario
    And as admin I replace resource "scc" named "restricted":
      | MustRunAsRange | RunAsAny |
    #Allow oc to run inside the pod
    When I run the :policy_add_role_to_user client command with:
      | role           | edit    |
      | serviceaccount | default |
    Then the step should succeed
    #Create a pod to manipulate git/oc
    When I run the :run client command with:
      | name    | nogit                                      |
      | image   | <%= project_docker_repo %>openshift/origin |
      | env     | POD_NAMESPACE=<%= project.name %>          |
      | command | true                                       |
      | cmd     | sleep                                      |
      | cmd     | 360                                        |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=nogit |
    Given I execute on the pod:
      | bash                                                                                                                              |
      | -c                                                                                                                                |
      | cd /tmp; wget --no-check-certificate https://github.com/openshift/ruby-hello-world/archive/master.tar.gz; tar -xvzf master.tar.gz |
    Then the step should succeed
    Given I execute on the pod:
      | oc | new-app | --code=/tmp/ruby-hello-world-master | --name=test-no-git |
    Then the step should succeed
    When I get project buildconfigs
    Then the output should contain "Binary"
    Given I execute on the pod:
      | oc | new-app | --code=https://github.com/openshift/ruby-hello-world |
    Then the step should fail
    And the output should contain "Cannot find git"
    Given I execute on the pod:
      | oc | new-build | /tmp/ruby-hello-world-master | --to=test |
    When I get project buildconfigs
    Then the output should contain 2 times:
      | Binary |
    Given I execute on the pod:
      | oc | new-build | https://github.com/openshift/ruby-hello-world |
    Then the step should fail
    And the output should contain "Cannot find git"

  # @author cryan@redhat.com
  # @case_id OCP-10185
  # @bug_id 1357674
  Scenario: Create new build from git repository without origin remote defined
    Given I have a project
    When I git clone the repo "https://github.com/openshift/ruby-hello-world"
    Then the step should succeed
    When I remove the remote repository "origin" from the "ruby-hello-world" repo
    Then the step should succeed
    When I run the :new_app client command with:
      | app_repo | ruby-hello-world |
      | name     | newtest          |
    Then the step should succeed
    When I get project bc
    Then the output should contain "Binary"
    When I run the :new_build client command with:
      | app_repo | ruby-hello-world |
      | to       | test             |
    When I get project bc
    Then the output should contain 2 times:
      | Binary |

  # @author cryan@redhat.com
  # @bug_id 1368114
  Scenario Outline: image build behind proxy
    Given I have a project
    And I have a proxy configured in the project
    When I run the :new_build client command with:
      | app_repo | <image>~https://github.com/openshift/<repo>  |
      | e        | http_proxy=http://<%= cb.proxy_ip %>:3128    |
      | e        | https_proxy=http://<%= cb.proxy_ip %>:3128   |
      | e        | HTTP_PROXY=http://<%= cb.proxy_ip %>:3128    |
      | e        | HTTPS_PROXY=http://<%= cb.proxy_ip %>:3128   |
    Then the step should succeed
    Given the "<repo>-1" build completes
    When I run the :logs client command with:
      | resource_name | build/<repo>-1 |
    Then the step should succeed
    And the output should contain "Using HTTP proxy"
    Examples:
      | image                 | repo             |
      | openshift/nodejs:0.10 | nodejs-ex        | # @case_id OCP-10236
      | openshift/nodejs:4    | nodejs-ex        | # @case_id OCP-10238
      | openshift/nodejs:6    | nodejs-ex        | # @case_id OCP-13512
      | openshift/ruby:2.0    | ruby-hello-world | # @case_id OCP-10237
      | openshift/ruby:2.2    | ruby-hello-world | # @case_id OCP-10239
      | openshift/ruby:2.3    | ruby-hello-world | # @case_id OCP-10240
      | openshift/perl:5.16   | dancer-ex        | # @case_id OCP-10241
      | openshift/perl:5.20   | dancer-ex        | # @case_id OCP-10242
      | openshift/perl:5.24   | dancer-ex        | # @case_id OCP-10369
      | openshift/python:3.5  | django-ex        | # @case_id OCP-10243
      | openshift/python:3.4  | django-ex        | # @case_id OCP-10246
      | openshift/python:3.3  | django-ex        | # @case_id OCP-10245
      | openshift/python:2.7  | django-ex        | # @case_id OCP-10244
      | openshift/php:5.5     | cakephp-ex       | # @case_id OCP-14971
      | openshift/php:5.6     | cakephp-ex       | # @case_id OCP-14972
      | openshift/php:7.0     | cakephp-ex       | # @case_id OCP-14974

  # @author cryan@redhat.com
  # @case_id OCP-11634
  Scenario: Extended build with artifacts defined from runtime image label
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/test-for-s2i-extendbuild/master/extended-bc-artifacts-from-image.json |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | extended-bc-artifacts-from-image |
    Then the step should succeed
    Given the "extended-bc-artifacts-from-image-1" build completes

  # @author cryan@redhat.com
  # @case_id OCP-11346
  Scenario: Extended build with scripts come from different location
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/test-for-s2i-extendbuild/master/extended-bc-scripts-in-image.json |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | extended-build-from-image |
    Then the step should succeed
    Given the "extended-build-from-image-1" build completes
    When I run the :logs client command with:
      | resource_name | builds/extended-build-from-image-1 |
    Then the step should succeed
    And the output should contain:
      | I am assemble inside the builder image,forcePull |
      | I'm assemble-runtime inside the runtime image    |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/test-for-s2i-extendbuild/master/extended-bc-scripts-in-url.json |
    And I run the :start_build client command with:
      | buildconfig | extended-build-from-url |
    Then the step should succeed
    Given the "extended-build-from-url-1" build completes
    When I run the :logs client command with:
      | resource_name | builds/extended-build-from-url-1 |
    Then the step should succeed
    And the output should contain:
      | I am assemble from url        |
      | I'm assemble-runtime from url |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/test-for-s2i-extendbuild/master/extended-bc-scripts-in-repo.json |
    And I run the :start_build client command with:
      | buildconfig | extended-build-from-repo |
    Then the step should succeed
    Given the "extended-build-from-repo-1" build completes
    When I run the :logs client command with:
      | resource_name | builds/extended-build-from-repo-1 |
    Then the step should succeed
    And the output should contain:
      | I am assemble inside the source repo |
      | I'm assemble-runtime in source repo  |

  # @author cryan@redhat.com
  # @case_id OCP-11825
  @smoke
  Scenario: forcePull for extended build
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/test-for-s2i-extendbuild/master/extended-bc-forcePull.json |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | extended-build-from-image-forcepull |
    Then the step should succeed
    Given the "extended-build-from-image-forcepull-1" build completes
    When I run the :logs client command with:
      | resource_name | build/extended-build-from-image-forcepull-1 |
    Then the step should succeed
    And the output should contain:
      | Pulling image "docker.io/aosqe/extendedbuild_builder:latest" |
      | Pulling image "docker.io/aosqe/extendedbuild_runtime:latest" |

  # @author shiywang@redhat.com
  # @case_id OCP-11419
  Scenario: Supply oc new-build parameter list+env vars via a file
    Given I have a project
    Given a "test1.env" file is created with the following lines:
    """
    MYSQL_DATABASE=test
    """
    When I run the :new_build client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world |
      | strategy | source                                        |
      | env_file | test1.env                                     |
    And the step should succeed
    When I run the :set_env client command with:
      | resource | po/ruby-hello-world-1-build |
      | list     | true                        |
    And the output should match:
      | MYSQL_DATABASE |
      | test           |
    When I run the :delete client command with:
      | object_type | all  |
      | all         | true |
    Given a "test2.env" file is created with the following lines:
    """
    APPLE=CLEMENTINE
    """
    When I run the :new_build client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world |
      | strategy | source                                        |
      | to       | test                                          |
      | name     | test                                          |
      | env_file | -                                             |
      | _stdin   | <%= File.read("test2.env") %>                 |
    When I run the :set_env client command with:
      | resource | po/test-1-build |
      | list     | true                        |
    And the output should match:
      | APPLE      |
      | CLEMENTINE |

  # @author xiuwang@redhat.com
  # @case_id OCP-11025
  Scenario: oc start-build with url
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/OCP-11025/test-build.json |
    Then the step should succeed
    Given I download a file from "https://github.com/openshift/ruby-hello-world/archive/master.zip"
    When I run the :start_build client command with:
      | buildconfig | sample-build-github-archive |
      | from_archive| master.zip                  |
    Then the step should succeed
    Given the "sample-build-github-archive-1" build was created
    And the "sample-build-github-archive-1" build completed
    When I run the :start_build client command with:
      | buildconfig | sample-build-github-archive |
      | from_archive| https://github.com/openshift/ruby-hello-world/archive/master.zip |
    Then the step should succeed
    Given the "sample-build-github-archive-2" build was created
    And the "sample-build-github-archive-2" build completed
    Given I download a file from "https://raw.githubusercontent.com/openshift/ruby-hello-world/master/Gemfile"
    When I run the :start_build client command with:
      | buildconfig | sample-build |
      | from_file   | Gemfile      |
    Then the step should succeed
    Given the "sample-build-1" build was created
    And the "sample-build-1" build completed
    When I run the :start_build client command with:
      | buildconfig | sample-build |
      | from_file   | https://raw.githubusercontent.com/openshift/ruby-hello-world/master/Gemfile |
    Then the step should succeed
    Given the "sample-build-2" build was created
    And the "sample-build-2" build completed

  # @author xiuwang@redhat.com
  # @case_id OCP-19634
  Scenario: Insert configmap when create a buildconfig - Negative 
    Given I have a project
    Given a "configmap.test" file is created with the following lines:
    """
    color.good=purple
    color.bad=yellow
    """
    When I run the :create_configmap client command with:
      | name      | cmtest         |
      | from_file | configmap.test |
    Then the step should succeed
    When I run the :create_secret client command with:
      | name         | secrettest      |
      | secret_type  | generic         |
      | from_literal | aoskey=aosvalue |
    Then the step should succeed
    #Insert cm and secret to bc with multi-level dirs
    When I run the :new_build client command with:
      | app_repo       | https://github.com/openshift/ruby-hello-world |
      | image_stream   | ruby                                          |
      | build_config_map| cmtest:/aoscm/newdir                         |
      | build_secret   | secrettest:/aossecret/newdir                  |
    Then the step should succeed
    And the "ruby-hello-world-1" build completed
    #Insert cm and secret to bc with wrong format - failed
    When I run the :new_build client command with:
      | app_repo       | https://github.com/openshift/ruby-hello-world |
      | image_stream   | ruby                                          |
      | build_config_map| cmtest:../newdir                             |
      | build_secret   | secrettest:../newdir                          |
    Then the step should fail
    And the output should contain:
      | destination dir cannot start with '..'|
    #Add one cm twice - failed
    When I run the :new_build client command with:
      | app_repo       | https://github.com/openshift/ruby-hello-world |
      | image_stream   | ruby                                          |
      | build_config_map| cmtest:./newdir1                             |
      | build_config_map| cmtest:./newdir2                             |
    Then the step should fail
    And the output should contain:
      | configMap can be used just once| 

  # @author xiuwang@redhat.com
  # @case_id OCP-18963
  Scenario: Allow using a configmap as an input to a docker build - Negative
    Given I have a project
    Given a "configmap1.test" file is created with the following lines:
    """
    color.good=purple
    color.bad=yellow
    """
    When I run the :create_configmap client command with:
      | name      | cmtest1         |
      | from_file | configmap1.test |
    Then the step should succeed
    #Add a configmap with abs path -  failed
    When I run the :new_build client command with:
      | app_repo       | https://github.com/openshift/ruby-hello-world |
      | build_config_map| cmtest1:/newtest                             |
    Then the step should fail
    And the output should contain:
      | for the docker strategy, the configMap destination directory "/newtest" must be a relative path |
    #Add a configmap with a invalid name - failed
    When I run the :new_build client command with:
      | app_repo       | https://github.com/openshift/ruby-hello-world |
      | build_config_map| 2cm%!zadi:newtest                            |
    Then the step should fail
    And the output should contain:
      | invalid characters in filename |
    #Add a configmap with an unexisted cm - failed
    When I run the :new_build client command with:
      | app_repo       | https://github.com/openshift/ruby-hello-world |
      | build_config_map| unexisted:newtest                            |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | build               |
      | name     | ruby-hello-world-1  |
    Then the output should contain:
      | "unexisted" not found |
    When I run the :cancel_build client command with:
      | build_name | ruby-hello-world-1 |
    Then the step should succeed
    #Add configmap to an existing file - failed
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-hello-world |
      | p | {"spec":{"source":{"configMaps": [{"configMap": {"name": "cmtest1"}, "destinationDir": "./config.ru"}]}}} | 
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
      | follow      | true             |
      | wait        | true             |
    Then the output should contain "config.ru: not a directory"

  # @author xiuwang@redhat.com
  # @case_id OCP-18960
  Scenario: Allow configmaps as inputs to a s2i build 
    Given I have a project
    Given a "configmap1.test" file is created with the following lines:
    """
    color.good=purple
    color.bad=yellow
    """
    Given a "configmap2.test" file is created with the following lines:
    """
    color.good=brightyellow
    color.bad=black
    """
    When I run the :create_configmap client command with:
      | name      | cmtest1         |
      | from_file | configmap1.test |
    Then the step should succeed
    When I run the :create_configmap client command with:
      | name      | cmtest2         |
      | from_file | configmap2.test |
    Then the step should succeed
    #Add two configmaps with same abs destinationDir
    When I run the :new_build client command with:
      | app_repo       | https://github.com/openshift/ruby-hello-world |
      | image_stream   | ruby                                          |
      | build_config_map| cmtest1:/opt/app-root/src/newdir             |
      | build_config_map| cmtest2:/opt/app-root/src/newdir             |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc               |
      | name     | ruby-hello-world |
    Then the output should match:
      | Build ConfigMaps:\s+cmtest1->/opt/app-root/src/newdir,cmtest2->/opt/app-root/src/newdir|
    And the "ruby-hello-world-1" build completed
    Then evaluation of `image_stream("ruby-hello-world").docker_image_repository` is stored in the :user_image clipboard
    When I run the :run client command with:
      | name  | myapp                |
      | image | <%= cb.user_image %> |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=myapp-1 |
    When I execute on the pod:
      | ls | -l | newdir |
    Then the step should succeed
    And the output should contain:
      | configmap1.test -> ..data/configmap1.test |
      | configmap2.test -> ..data/configmap2.test |
