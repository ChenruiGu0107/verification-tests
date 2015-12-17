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
    Then the output should contain "spec.source.git.uri: required value"

  # @author wzheng@redhat.com
  # @case_id 470419
  Scenario: Push build with invalid github repo
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby22rhel7-template-docker-invalidrepo.json |
    Then the step should succeed
    When I run the :new_app client command with:
      | template | ruby-helloworld-sample |
    Then the step should succeed 
    And the "ruby22-sample-build-1" build was created
    And the "ruby22-sample-build-1" build failed
    When I run the :logs client command with:
      | resource_name | bc/ruby22-sample-build |
    Then the output should contain "Build error: Invalid git source url: 123"

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
