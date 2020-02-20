Feature: buildconfig.feature

  # @author cryan@redhat.com
  # @case_id OCP-9556
  Scenario: Buildconfig spec part cannot be updated
    Given I have a project
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/php-56-rhel7-stibuild.json |
    Then the step should succeed
    Given I save the output to file> tcms495017_out.json
    When I run the :create client command with:
      | f | tcms495017_out.json |
    Then the step should succeed
    When I replace resource "bc" named "php-sample-build":
      | ImageStreamTag | ImageStreamTag123 |
    Then the step should fail
    And the output should contain "spec.output.to.kind: Invalid value: "ImageStreamTag123""
    When I replace resource "bc" named "php-sample-build":
      | Git | Git123 |
    Then the step should succeed
    And the output should contain "replaced"
    And the output should not contain "Git123"
    When I replace resource "bc" named "php-sample-build":
      | Source | Source123 |
    Then the step should succeed
    And the output should contain "replaced"
    And the output should not contain "Source123"

  # @author wzheng@redhat.com
  # @case_id OCP-10701
  Scenario: Build go failed if pending time exceeds completionDeadlineSeconds limitation
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sourcebuildconfig.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | buildconfig  |
      | name     | source-build |
    Then the step should succeed
    And the output should match "Fail Build After:\s+5s"
    When I run the :start_build client command with:
      | buildconfig | source-build |
    Then the step should succeed
    And the "source-build-1" build was created
    And the "source-build-1" build failed

  # @author wzheng@redhat.com
  # @case_id OCP-11699
  Scenario: Start build from invalid/blank buildConfig/build
    Given I have a project
    When I run the :start_build client command with:
      | buildconfig | invalid |
    Then the step should fail
    And the output should contain "not found"
    When I run the :start_build client command with:
      | from_build| invalid |
    Then the step should fail
    And the output should contain "not found"

  # @author xiazhao@redhat.com
  # @case_id OCP-12442
  Scenario: Do incremental builds for sti-build in openshift
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc482207/bc.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    # Test clean build firstly
    When I run the :build_logs client command with:
      | build_name      | ruby-sample-build-1 |
    Then the output should match "Clean build will be performed"
    # Test incremental build secondly
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    And the "ruby-sample-build-2" build was created
    And the "ruby-sample-build-2" build completed
    When I run the :build_logs client command with:
      | build_name      | ruby-sample-build-2 |
    Then the output should match "Saving build artifacts from image"

  # @author gpei@redhat.com
  # @case_id OCP-9557
  Scenario: Build spec cannot be updated
    Given I have a project
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    When I replace resource "build" named "ruby-sample-build-1":
      | ImageStreamTag | ImageStreamTag123 |
    Then the step should fail
    And the output should contain "Invalid value: "ImageStreamTag123""
    When I replace resource "build" named "ruby-sample-build-1":
      | Git | Git123 |
    Then the step should succeed
    And the output should contain "replaced"
    When I run the :describe client command with:
      | resource     | build                    |
      | name         | ruby-sample-build-1      |
    Then the output should not contain "Git123"
    When I replace resource "build" named "ruby-sample-build-1":
      | Source | Source123 |
    Then the step should succeed
    And the output should contain "replaced"
    When I run the :describe client command with:
      | resource     | build                    |
      | name         | ruby-sample-build-1      |
    Then the output should not contain "Source123"

  # @author cryan@redhat.com
  # @case_id OCP-11181
  Scenario: Warning appears if completionDeadlineSeconds set to invalid value
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sourcebuildconfig.json |
    Then the step should succeed
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | source-build |
      | p | {"spec": {"completionDeadlineSeconds": -5}} |
    Then the step should fail
    And the output should contain "greater than 0"
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | source-build |
      | p | {"spec": {"completionDeadlineSeconds": "abc"}} |
    Then the step should fail
    And the output should contain "unrecognized type"
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sourcebuildconfig.json"
    Then the step should succeed
    Given I replace lines in "sourcebuildconfig.json":
      | "completionDeadlineSeconds": 5, | "completionDeadlineSeconds": -5, |
    When I run the :create client command with:
      | f | sourcebuildconfig.json |
    Then the step should fail
    And the output should contain "greater than 0"
    Given I replace lines in "sourcebuildconfig.json":
      | "completionDeadlineSeconds": -5, | "completionDeadlineSeconds": "abc", |
    When I run the :create client command with:
      | f | sourcebuildconfig.json |
    Then the step should fail
    And the output should contain "invalid"

  # @author cryan@redhat.com
  # @case_id OCP-10606
  Scenario: STI build with imageStreamImage in buildConfig
    Given I have a project
    When I run the :import_image client command with:
      | image_name | ruby                   |
      | from       | centos/ruby-25-centos7 |
      | confirm    | true                   |
    Then the step should succeed
    When I get project is named "ruby" as YAML
    Then the output should match "name:\s+ruby"
    And evaluation of `@result[:parsed]["status"]["tags"][0]["items"][0]["image"]` is stored in the :imagesha clipboard
   # When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json"
    When I run the :new_app client command with:
      | image_stream | ruby                                    |
      | app_repo     | https://github.com/openshift-qe/ruby-ex |
    Then the step should succeed
    And the "ruby-ex-1" build completes
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                               |
      | resource_name | ruby-ex                                                                                                                   |
      | p | {"spec": {"strategy": {"sourceStrategy": {"from": {"kind": "ImageStreamImage","name": "ruby@<%= cb.imagesha %>"}}},"type": "Source"}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | buildconfig |
      | name     | ruby-ex     |
    Then the step should succeed
    And the output should contain "ImageStreamImage"
    #And the output should match:
    #| ImageStreamImage\s+ruby@<%= cb.imagesha %> |
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    Given the "ruby-ex-2" build completes
    When I run the :describe client command with:
      | resource | build     |
      | name     | ruby-ex-2 |
    Then the step should succeed
    And the output should match "DockerImage\s+centos/ruby-25-centos7@<%= cb.imagesha %>"
    #And the output should match:
    #  | DockerImage\s+centos/ruby-22-centos7@<%= cb.imagesha %> |
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                            |
      | resource_name | ruby-ex                                                                                                                |
      | p             | {"spec": {"strategy": {"sourceStrategy": {"from": {"kind": "ImageStreamImage","name": "ruby@123"}}},"type": "Source"}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should fail
    And the output should match "(not found|unable to find)"
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                         |
      | resource_name | ruby-ex                                                                                                             |
      | p             | {"spec": {"strategy": {"sourceStrategy": {"from": {"kind": "ImageStreamImage","name": "ruby@"}}},"type": "Source"}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should fail
    And the output should match "must (be retrieved|have a name and ID)"

  # @author wewang@redhat.com
  # @case_id OCP-11172
  Scenario: Add ENV to DockerStrategy buildConfig and Dockerfile when do docker build
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/ruby-rhel7-multivars.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    Given 2 pods become ready with labels:
      | name=frontend |
    When I execute on the pod:
      | env |
    Then the output should contain "RACK_ENV=production"
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby-sample-build |
      | p | {"spec": {"strategy": {"dockerStrategy": {"env": [{"name": "EXAMPLE","value": "sample-app"}, {"name":"HTTP_PROXY","value":"http://incorrect.proxy:3128"}]}}}} |
    Then the step should succeed
    When I get project build_config named "ruby-sample-build" as JSON
    Then the output should contain "HTTP_PROXY"
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Given the "ruby-sample-build-2" build was created
    And the "ruby-sample-build-2" build failed
    When I run the :logs client command with:
      | resource_name | build/ruby-sample-build-2 |
    Then the output should match "lookup incorrect.proxy|Name or service not known"

  # @author haowang@redhat.com
  # @case_id OCP-12120
  Scenario: Trigger multiple builds from a single image update
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | centos/ruby-25-centos7~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    Then the "ruby-25-centos7" image stream was created
    And the "ruby-hello-world-1" build was created
    When I run the :new_build client command with:
      | image_stream | ruby-25-centos7                      |
      | code         | https://github.com/sclorg/ruby-ex |
      | name         | ruby-ex                              |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    When I run the :tag client command with:
      | source_type | docker                 |
      | source      | centos/ruby-22-centos7 |
      | dest        | ruby-25-centos7:latest |
    Then the step should succeed
    And the "ruby-hello-world-2" build was created
    And the "ruby-ex-2" build was created

  # @author wzheng@redhat.com
  # @case_id OCP-12016
  Scenario: S2I build failure reason display if use incorrect runtime image
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/invalid_runtime_image.json |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | extended-build-from-repo |
    Then the step should succeed
    When the "extended-build-from-repo-1" build failed
    And I run the :get client command with:
      | resource | build |
    Then the output should contain:
      | GenericS2IBuildFailed |
    When I run the :describe client command with:
      | resource | build |
    Then the output should contain:
      | BuildFailed |

  # @author wzheng@redhat.com
  # @case_id OCP-11690
  Scenario: S2I build failure reason display if use incorrect assemble script
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:latest                                            |
      | app_repo     | https://github.com/openshift-qe/ruby-hello-world#invalidassemble |
    Then the step should succeed
    When the "ruby-hello-world-1" build failed
    And I run the :get client command with:
      | resource | build |
    Then the step should succeed
    And the output should match:
      | [Ff]ail |
    When I run the :describe client command with:
      | resource | build |
    Then the step should succeed
    And the output should match:
      | [Ff]ail |

  # @author wzheng@redhat.com
  # @case_id OCP-12837
  Scenario: S2I extended build failure reason display if use incorrect sourcePath
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/invalid_sourcePath.json |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | extended-build-from-repo |
    Then the step should succeed
    When the "extended-build-from-repo-1" build failed
    And I run the :get client command with:
      | resource | build |
    Then the step should succeed
    And the output should contain:
      | FetchRuntimeArtifactsFailed |
    When I run the :describe client command with:
      | resource | build |
    Then the step should succeed
    And the output should contain:
      | Failed to fetch specified runtime artifacts |

  # @author dyan@redhat.com
  # @case_id OCP-14476
  # @bug_id 1377795
  Scenario: Redact proxy users and passwords in build logs
    Given I have a project
    And I have a proxy configured in the project
    When I run the :new_build client command with:
      | app_repo | openshift/nodejs~https://github.com/sclorg/nodejs-ex                    |
      | e        | http_proxy=http://tester:redhat@<%= cb.proxy_ip %>:<%= cb.proxy_port %> |
      | e        | https_proxy=http://tester:redhat@<%= cb.proxy_ip %>:<%= cb.proxy_port %>|
      | e        | HTTP_PROXY=http://tester:redhat@<%= cb.proxy_ip %>:<%= cb.proxy_port %> |
      | e        | HTTPS_PROXY=http://tester:redhat@<%= cb.proxy_ip %>:<%= cb.proxy_port %>|
      | e        | NO_PROXY=.cluster.local,.svc,127.0.0.1,localhost                        |
    Then the step should succeed
    Given the "nodejs-ex-1" build completes
    When I run the :logs client command with:
      | resource_name | build/nodejs-ex-1 |
    Then the step should succeed
    And the output should contain "Using HTTP proxy http://redacted@<%= cb.proxy_ip %>:<%= cb.proxy_port %>"
    And the output should not contain:
      | passwd |

  # @author xiuwang@redhat.com
  # @case_id OCP-23639
  Scenario: Do incremental builds for binary build
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/OCP-23639/imagestream.yaml |
    Then the step should succeed
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/OCP-23639/build_config.yaml |
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/OCP-23639/sti-app.tar"
    When I run the :start_build client command with:
      | buildconfig  | sti-bc      |
      | from_archive | sti-app.tar |
    Then the step should succeed
    And the "sti-bc-2" build was created
    Given the "sti-bc-2" build completed
    When I run the :logs client command with:
      | resource_name | build/sti-bc-2 |
    And the output should contain "Downloading"
    When I run the :start_build client command with:
      | buildconfig  | sti-bc      |
      | from_archive | sti-app.tar |
    Then the step should succeed
    And the "sti-bc-3" build was created
    Given the "sti-bc-3" build completed
    When I run the :logs client command with:
      | resource_name | build/sti-bc-3|
    And the output should not contain "Downloading"
    And the output should contain:
      | COPY --from=cached /tmp/artifacts.tar /tmp/artifacts.tar |
      | COPY upload/src /tmp/src |

  # @author xiuwang@redhat.com
  # @case_id OCP-23781
  Scenario: Use shell variable in build config environment variable section
    Given I have a project
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/OCP-23639/imagestream.yaml |
    Then the step should succeed
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/OCP-23781/build_config.yaml |
    Then the step should succeed
    And the "env-var-bc-1" build was created
    Given the "env-var-bc-1" build completed

  # @author wewang@redhat.com
  # @case_id OCP-11469
  Scenario: Docker build with imageStreamImage in buildConfig
    Given I have a project
    When I run the :import_image client command with:
      | image_name | ruby                   |
      | from       | centos/ruby-25-centos7 |
      | confirm    | true                   |
    Then the step should succeed
    And the expression should be true> image_stream("ruby").exists?(user: user)
    And evaluation of `image_stream_tag("ruby:latest").digest` is stored in the :imagesha clipboard
    When I run the :new_app client command with:
      | image_stream | ruby                                          |
      | app_repo     | https://github.com/openshift/ruby-hello-world |
      | strategy     | docker                                        |
    Then the step should succeed
    And the "ruby-hello-world-1" build completes
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                               |
      | resource_name | ruby-hello-world                                                                                                          |
      | p | {"spec": {"strategy": {"dockerStrategy": {"from": {"kind": "ImageStreamImage","name": "ruby@<%= cb.imagesha %>"}}},"type": "Source"}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    Given the "ruby-hello-world-2" build completes
    When I run the :describe client command with:
      | resource | build              |
      | name     | ruby-hello-world-2 |
    Then the step should succeed
    And the output should match "DockerImage\s+centos/ruby-25-centos7@<%= cb.imagesha %>"
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                            |
      | resource_name | ruby-hello-world                                                                                                       |
      | p             | {"spec": {"strategy": {"dockerStrategy": {"from": {"kind": "ImageStreamImage","name": "ruby@123"}}},"type": "Source"}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should fail
    And the output should match "(not found|unable to find)"
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                         |
      | resource_name | ruby-hello-world                                                                                                    |
      | p             | {"spec": {"strategy": {"dockerStrategy": {"from": {"kind": "ImageStreamImage","name": "ruby@"}}},"type": "Source"}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should fail
    And the output should match "must (be retrieved|have a name and ID)"
