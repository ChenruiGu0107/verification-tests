Feature: dockerbuild.feature
  # @author wzheng@redhat.com
  # @case_id 470418
  Scenario: Docker build with blank source repo
    Given I have a project 
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-docker-blankrepo.json |
    Then the step should succeed
    Given I save the output to file>blankrepo.json
    When I run the :create client command with:
      | f | blankrepo.json |
    Then the step should fail
    Then the output should contain "spec.source.git.uri: Required value"

  # @author wzheng@redhat.com
  # @case_id 470419
  Scenario: Push build with invalid github repo
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
    Then the output should contain "Invalid git source url: 123"

  # @author wzheng@redhat.com
  # @case_id 438849
  Scenario: Docker build with both SourceURI and context dir
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-context-docker.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | ruby-helloworld-sample |
    Then the step should succeed
    And the "ruby20-sample-build-1" build was created
    And the "ruby20-sample-build-1" build completed
    When I run the :describe client command with:
      | resource | buildconfig         |
      | name     | ruby20-sample-build |
    Then the step should succeed
    And the output should contain "ContextDir:"

  # @author wzheng@redhat.com
  # @case_id 438850
  Scenario: Docker build with invalid context dir
    Given I have a project
     When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-invalidcontext-docker.json |
     Then the step should succeed
     When I run the :new_app client command with:
       | template | ruby-helloworld-sample |
     Then the step should succeed
     And the "ruby20-sample-build-1" build was created
     And the "ruby20-sample-build-1" build failed
     When I run the :logs client command with:
       | resource_name| bc/ruby20-sample-build |
     Then the output should contain "/invalid/Dockerfile: no such file or directory"

  # @author haowang@redhat.com
  # @case_id 507555
  Scenario: Add empty ENV to DockerStrategy buildConfig when do docker build
    Given I have a project
    When I run the :new_app client command with:
      | file |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/application-template-dockerbuild-blankvar.json |
    Then the step should fail
    And the output should contain "invalid"

  # @author cryan@redhat.com
  # @case_id 512262
  Scenario: oc start-build with a file passed,sti build type
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/openshift/nodejs-ex |
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
  # @case_id 479296 
  Scenario: Custom build with dockerImage with specified tag
    Given I have a project
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
    And I run the :get client command with:
      | resource | builds |
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
  # @case_id 479297, 482273
  Scenario Outline: Docker and STI build with dockerImage with specified tag
    Given I have a project
    When I run oc create over "<template>" URL replacing paths:
      | ["spec"]["strategy"]["<strategy>"]["from"]["name"] | <%= product_docker_repo %>rhscl/ruby-22-rhel7:latest |
    Then the step should succeed
    Given the "ruby-sample-build-1" build completed
    When I run the :describe client command with:
      | resource | build |
      | name | ruby-sample-build-1 |
    Then the output should contain:
      | DockerImage <%= product_docker_repo %>rhscl/ruby-22-rhel7:latest |
    When I run the :patch client command with:
      | resource      | bc              |
      | resource_name | ruby-sample-build |
      | p             | {"spec":{"strategy":{"<strategy>":{"from":{"name":"<%= product_docker_repo %>rhscl/ruby-22-rhel7:incorrect"}}}}} |
    Then the step should succeed
    Given I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    And the "ruby-sample-build-2" build failed
    When I run the :describe client command with:
      | resource | build |
      | name | ruby-sample-build-2 |
    Then the output should contain:
      | Failed |
      | DockerImage <%= product_docker_repo %>rhscl/ruby-22-rhel7:incorrect |

    Examples:
      | template | strategy |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc479297/test-template-dockerbuild.json | dockerStrategy |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc482273/test-template-stibuild.json    | sourceStrategy |
 
