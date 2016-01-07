Feature: buildlogic.feature

    # @author haowang@redhat.com
    # @case_id 515806
    @admin
    Scenario: if build fails to schedule because of quota, after the quota increase, the build should start
    Given I have a project
    Then I use the "<%= project.name %>" project
    And I run the :create admin command with:
      | f | https://raw.githubusercontent.com/wanghaoran1988/v3-testfiles/master/build/quota_pods.yaml |
      | n | <%= project.name %> |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/test-buildconfig.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    When I run the :get client command with:
      | resource | build |
    Then the output should contain:
      | New (CannotCreateBuildPod) |
    When I run the :delete admin command with:
      | object_type       | resourcequota       |
      | object_name_or_id | quota               |
      | n                 | <%= project.name %> |
    Then the step should succeed
    And the "ruby-sample-build-1" build becomes running

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
