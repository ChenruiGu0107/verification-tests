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
    And the output should contain "spec.output.to.kind: invalid value 'ImageStreamTag123'"
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
    And the output should contain "Fail Build After:	5s"
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
  Scenario: Buildconfig spec part cannot be updated
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

