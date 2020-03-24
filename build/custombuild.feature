Feature: custombuild.feature

  # @author dyan@redhat.com
  # @case_id OCP-11104
  @admin
  Scenario: Custom build with imageStreamImage in buildConfig
    Given cluster role "system:build-strategy-custom" is added to the "first" user
    Then the step should succeed
    Given I have a project
    When I process and create "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/tc479017/custombuild-template.json"
    Then the step should succeed
    Given the "ruby-sample-build-1" build completed
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I get project istag named "origin-custom-docker-builder:latest" as JSON
    Then the step should succeed
    """
    And evaluation of `@result[:parsed]['image']['metadata']['name']` is stored in the :imagestreamimage clipboard
    When I replace resource "bc" named "ruby-sample-build":
      | ImageStreamTag | ImageStreamImage |
      | :latest        | @<%= cb.imagestreamimage %> |
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
      | is invalid       |
    When I replace resource "bc" named "ruby-sample-build":
      | invalid |        |
    And I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the output should contain:
      | must have a name and ID |

  # @author shiywang@redhat.com
  # @case_id OCP-11872
  Scenario: S2I build failure reason display if use incorrect config in buildconfig
    Given I have a project
    #1
    When I run the :new_app client command with:
      | app_repo | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/ruby22rhel7-template-sti.json |
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
      | app_repo | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/ruby22rhel7-template-sti.json |
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
      | app_repo | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/ruby22rhel7-template-sti.json |
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
      | app_repo | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/ruby22rhel7-template-sti.json |
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
