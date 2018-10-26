Feature: wildfly.feature

  # @author wzheng@redhat.com
  # @case_id OCP-14125,OCP-16891
  Scenario Outline: Tune maven memory limits in wildfly image with MAVEN_OPTS	
    Given I have a project
    When I run the :new_app client command with:
      | <param>      | <image>                                            |
      | app_repo     | https://github.com/openshift-qe/openshift-jee-sample.git |
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

  # @author wzheng@redhat.com
  Scenario Outline: hot deploy test for image wildfly-101-centos7
    Given I have a project
    When I run the :new_app client command with:
      | docker_image | openshift/wildfly-101-centos7                            |
      | app_repo     | https://github.com/openshift-qe/openshift-jee-sample.git |
      | env          | AUTO_DEPLOY_EXPLODED=<env>                               |
    Then the step should succeed
    Given the "openshift-jee-sample-1" build completed
    Given a pod becomes ready with labels:
      | app=openshift-jee-sample |
    And I git clone the repo "https://github.com/openshift-qe/openshift-jee-sample.git"
    When I run the :cp client command with:
      | source | openshift-jee-sample/SampleApp.war                            |
      | dest   | <%= pod.name %>:/wildfly/standalone/deployments/SampleApp.war |
    And the step should succeed
    When I expose the "openshift-jee-sample" service
    And evaluation of `route("openshift-jee-sample", service("openshift-jee-sample")).dns` is stored in the :route_host clipboard
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= cb.route_host %>/SampleApp/HelloWorld" url
    And the output should contain "<output>"
    """

    Examples:
      | env   | output        |
      | true  | qeistesting   | # @case_id OCP-14103
      | false | Not Found     | # @case_id OCP-14129
