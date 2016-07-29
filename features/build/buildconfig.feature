Feature: buildconfig.feature

  # @author cryan@redhat.com
  # @case_id 495017
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
  # @case_id 508799
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
  # @case_id 470423
  Scenario: Start build from buildConfig/build
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:2.2 |
      | app_repo     | https://github.com/openshift/ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build finished
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    And the "ruby-hello-world-2" build was created
    And the "ruby-hello-world-2" build completed
    When I run the :start_build client command with:
      | from_build | ruby-hello-world-2 |
    Then the step should succeed
    And the "ruby-hello-world-3" build was created
    And the "ruby-hello-world-3" build completed

  # @author wzheng@redhat.com
  # @case_id 470420
  Scenario: Start build from invalid/blank buildConfig/build
    Given I have a project
    When I run the :start_build client command with:
      | buildconfig | invalid |
    Then the step should fail
    And the output should contain "buildconfigs "invalid" not found"
    When I run the :start_build client command with:
      | from_build| invalid |
    Then the step should fail
    And the output should contain "builds "invalid" not found"

  # @author xiazhao@redhat.com
  # @case_id 482207
  Scenario: Do incremental builds for sti-build in openshift
    Given I have a project
    And I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/application-template-stibuild_incremental_true.json"
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
  # @case_id 495026
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
  # @case_id 508800
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
    And the output should contain "char"
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
    And the output should contain "char"

  # @author cryan@redhat.com
  # @case_id 479016
  Scenario: STI build with imageStreamImage in buildConfig
    Given I have a project
    When I run the :import_image client command with:
      | image_name | ruby                   |
      | from       | centos/ruby-22-centos7 |
      | confirm    | true                   |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | is   |
      | resource_name | ruby |
      | o             | yaml |
    Then the output should match "name:\s+ruby"
    And evaluation of `@result[:parsed]["status"]["tags"][0]["items"][0]["image"]` is stored in the :imagesha clipboard
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-sti.json"
    Then the step should succeed
    And the "ruby22-sample-build-1" build completes
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                              |
      | resource_name | ruby22-sample-build                                                                                      |
      | p | {"spec":{"strategy":{"dockerStrategy":{"from":{"kind":"ImageStreamImage","name":"ruby@<%= cb.imagesha %>"}},"type":"Docker","sourceStrategy":null}}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | buildconfig           |
      | name     | ruby22-sample-build   |
    Then the step should succeed
    And the output should match "ImageStreamImage\s+ruby@<%= cb.imagesha %>"
    #And the output should match:
    #| ImageStreamImage\s+ruby@<%= cb.imagesha %> |
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Then the step should succeed
    Given the "ruby22-sample-build-2" build completes
    When I run the :describe client command with:
      | resource | build                 |
      | name     | ruby22-sample-build-2 |
    Then the step should succeed
    And the output should match "DockerImage\s+centos/ruby-22-centos7@<%= cb.imagesha %>"
    #And the output should match:
    #  | DockerImage\s+centos/ruby-22-centos7@<%= cb.imagesha %> |
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                                                                 |
      | resource_name | ruby22-sample-build                                                                                                                                         |
      | p             | {"spec":{"strategy":{"dockerStrategy":{"from":{"kind":"ImageStreamImage","name":"ruby@<%= cb.imagesha[0..15] %>"}},"type":"Docker","sourceStrategy":null}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Then the step should succeed
    Given the "ruby22-sample-build-3" build was created
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                                               |
      | resource_name | ruby22-sample-build                                                                                                                       |
      | p             | {"spec":{"strategy":{"dockerStrategy":{"from":{"kind":"ImageStreamImage","name":"ruby@123456" }},"type":"Docker","sourceStrategy":null}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Then the step should fail
    And the output should contain "not found"
    When I run the :patch client command with:
      | resource      | buildconfig                                                                                                                        |
      | resource_name | ruby22-sample-build                                                                                                                |
      | p             | {"spec":{"strategy":{"dockerStrategy":{"from":{"kind":"ImageStreamImage","name":"ruby@"}},"type":"Docker","sourceStrategy":null}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Then the step should fail
    And the output should contain "must be retrieved"

  # @author wewang@redhat.com
  # @case_id 507556
  Scenario: Add ENV to DockerStrategy buildConfig and Dockerfile when do docker build
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/ruby-rhel7-multivars.json |
    Then the step should succeed
    Given the "ruby22-sample-build-1" build was created
    And the "ruby22-sample-build-1" build completed
    Given 2 pods become ready with labels:
      | name=frontend |
    When I execute on the "<%= pod.name %>" pod:
      | env |
    Then the output should contain "RACK_ENV=production"
    When I run the :patch client command with:
      | resource | buildconfig |
      | resource_name | ruby22-sample-build |
      | p | {"spec": {"strategy": {"dockerStrategy": {"env": [{"name": "EXAMPLE","value": "sample-app"}, {"name":"HTTP_PROXY","value":"http://incorrect.proxy:3128"}]}}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource | buildconfig |
      | resource_name | ruby22-sample-build |
      | o | json |
    Then the output should contain "HTTP_PROXY"
    When I run the :start_build client command with:
      | buildconfig | ruby22-sample-build |
    Given the "ruby22-sample-build-2" build was created
    And the "ruby22-sample-build-2" build failed
    When I run the :build_logs client command with:
      | build_name | ruby22-sample-build-2 |
    Then the output should contain:
      | HTTPError Could not fetch specs from https://rubygems.org/  |

  # @author haowang@redhat.com
  # @case_id 498843
  Scenario: Rebuild image when the underlying image changed for Docker build
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    Then the "ruby-20-centos7" image stream was created
    And the "ruby-hello-world-1" build was created
    When I run the :tag client command with:
      | source_type | docker                 |
      | source      | centos/ruby-22-centos7 |
      | dest        | ruby-20-centos7:latest |
    Then the step should succeed
    And the "ruby-hello-world-2" build was created

  # @author haowang@redhat.com
  # @case_id 470323
  Scenario: Trigger multiple builds from a single image update
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    Then the "ruby-20-centos7" image stream was created
    And the "ruby-hello-world-1" build was created
    When I run the :new_build client command with:
      | image_stream | ruby-20-centos7                      |
      | code         | https://github.com/openshift/ruby-ex |
      | name         | ruby-ex                              |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    When I run the :tag client command with:
      | source_type | docker                 |
      | source      | centos/ruby-22-centos7 |
      | dest        | ruby-20-centos7:latest |
    Then the step should succeed
    And the "ruby-hello-world-2" build was created
    And the "ruby-ex-2" build was created

  # @author dyan@redhat.com
  # @case_id 470322
  Scenario: Trigger chain builds from a image update
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    Then the "ruby-20-centos7" image stream was created
    And the "ruby-hello-world-1" build was created
    Given the "ruby-hello-world-1" build becomes :complete
    When I run the :new_build client command with:
      | image_stream | ruby-hello-world                     |
      | code         | https://github.com/openshift/ruby-ex |
      | name         | ruby-ex                              |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    When I run the :tag client command with:
      | source_type | docker                 |
      | source      | centos/ruby-22-centos7 |
      | dest        | ruby-20-centos7:latest |
    Then the step should succeed
    And the "ruby-hello-world-2" build was created
    When the "ruby-hello-world-2" build becomes :complete
    Then the "ruby-ex-2" build was created

  # @author haowang@redhat.com
  # @case_id 479540 479541
  Scenario Outline: Build with images pulled from private repositories
    Given I have a project
    When I run the :new_secret client command with:
      | secret_name     | pull                                                                                   |
      | credential_file | .dockerconfigjson=<%= expand_private_path(conf[:services, :docker_hub, :dockercfg]) %> |
    Then the step should succeed
    When I run the :create client command with:
      | f | <template> |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    Then the "ruby-sample-build-1" build completes

    Examples:
      | template                                                                                                       |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc479540/test-buildconfig-docker.json |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc479541/test-buildconfig-s2i.json    |
