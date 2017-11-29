Feature: wildfly.feature

  # @author wzheng@redhat.com
  # @case_id OCP-14125,OCP-16891
  Scenario Outline: Tune maven memory limits in wildfly image with MAVEN_OPTS	
    Given I have a project
    When I run the :new_app client command with:
      | <param>      | <image>                                            |
      | app_repo     | https://github.com/danmcp/openshift-jee-sample.git |
    Then the step should succeed
    Given the "openshift-jee-sample-1" build completed
    When I run the :set_env client command with:
      | resource | bc/openshift-jee-sample |
      | e        | MAVEN_OPTS=-Xmx1m       |
    When I run the :start_build client command with:
      | buildconfig | openshift-jee-sample |
    Then the step should succeed
    And the "openshift-jee-sample-2" build was created
    And the "openshift-jee-sample-2" build failed
    When I run the :logs client command with:
      | resource_name | bc/openshift-jee-sample |
    Then the output should contain "OutOfMemoryError"
    When I run the :set_env client command with:
      | resource | bc/openshift-jee-sample |
      | e        | MAVEN_OPTS=-Xmx50m      |
    When I run the :start_build client command with:
      | buildconfig | openshift-jee-sample |
    Then the step should succeed
    And the "openshift-jee-sample-3" build was created
    And the "openshift-jee-sample-3" build completed

    Examples:
      | param        | image                         |
      | image        | wildfly                       | # @case_id OCP-16891
      | docker_image | openshift/wildfly-101-centos7 | # @case_id OCP-14125
