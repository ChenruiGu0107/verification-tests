Feature: buildlogic.feature

    # @author haowang@redhat.com
    # @case_id 515806
    @admin
    Scenario: if build fails to schedule because of quota, after the quota increase, the build should start
    Given I have a project
    Then I use the "<%= project.name %>" project
    And I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/quota_pods.yaml |
      | n | <%= project.name %> |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/test-buildconfig.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    When I run the :get client command with:
      | resource | build |
    Then the output should contain:
      |  (CannotCreateBuildPod) |
    When I run the :delete admin command with:
      | object_type       | resourcequota       |
      | object_name_or_id | quota               |
      | n                 | <%= project.name %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource | build |
    Then the output should not contain:
      |  (CannotCreateBuildPod) |

    # @author haowang@redhat.com
    # @case_id 515254
    Scenario: Build with specified Dockerfile via new-build -D
    Given I have a project
    Then I use the "<%= project.name %>" project
    And I run the :new_build client command with:
      # change to | FROM centos:7\nRUN yum install -y httpd | after gherkin3 gets version 3.1.3 or later
      | D     | noescape: $'FROM centos:7\nRUN yum install -y httpd' |
      | to    | myappis                                              |
      | name  | myapp                                                |
    Then the step should succeed
    And the "myapp-1" build was created
    And the "myapp-1" build completed

    # @author xiazhao@redhat.com
    # @case_id 501096
    Scenario: Result image will be tried to push after multi-build
    Given I have a project
    When I run the :new_app client command with:
      | file |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/php-55-rhel7-stibuild.json |
    Then the step should succeed
    # The 1st build should be triggered automatically
    And the "php-sample-build-1" build was created
    # Trigger the 2nd build in order for doing multi-builds
    When I run the :start_build client command with:
      | buildconfig | php-sample-build |
    Then the step should succeed
    And the "php-sample-build-2" build was created
    # Wait for the first 2 builds finished
    And the "php-sample-build-1" build finished
    And the "php-sample-build-2" build finished
    # Trigger the 3rd build, it should succeed
    When I run the :start_build client command with:
      | buildconfig | php-sample-build |
    Then the step should succeed
    And the "php-sample-build-3" build was created
    And the "php-sample-build-3" build completed
    When I run the :build_logs client command with:
      | build_name  | php-sample-build-3 |
    Then the output should match "Successfully pushed"

    # @author gpei@redhat.com
    # @case_id 515255
    Scenario: Create build without output
    Given I have a project
    Then I use the "<%= project.name %>" project
    And I run the :new_build client command with:
      | app_repo  | openshift/ruby:2.0~https://github.com/openshift/ruby-hello-world.git |
      | no-output | true                                                                 |
      | name      | myapp                                                                |
    Then the step should succeed
    And the "myapp-1" build was created
    And the "myapp-1" build completed
    When I run the :build_logs client command with:
      | build_name | myapp-1 |
    Then the output should contain "Build does not have an Output defined, no output image was pushed to a registry"
