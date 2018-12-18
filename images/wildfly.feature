Feature: wildfly.feature

  # @author wzheng@redhat.com
  Scenario Outline: hot deploy test for image wildfly
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/wildfly                                        |
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
