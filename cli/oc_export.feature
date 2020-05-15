Feature: oc exports related scenarios

  # @author pruan@redhat.com
  Scenario Outline: Export resource as json or yaml format by cli
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/build/sample-php-centos7.json|
    Then the step should succeed
    When I run the :get client command with:
      | _tool         | <tool>   |
      | resource      | svc      |
      | resource_name | frontend |
      | export        | true     |
      | output        | json     |
    Then the step should succeed
    And I save the response to file> svc_output.json
    When I run the :get client command with:
      | resource      | dc       |
      | resource_name | frontend |
      | export        | true     |
      | output        | json     |
    Then the step should succeed
    And I save the response to file> dc_output.json

    Given I delete the project
    When I create a new project
    Then the step should succeed
    When I run the :create client command with:
      | f | svc_output.json |
      | f | dc_output.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource | svc/frontend |
    Then the step should succeed
    When I run the :get client command with:
      | resource | dc/frontend |
    Then the step should succeed

    # Export other various APIs resources, like extensions/v1beta1, autoscaling/v1, batch/v1
    # Cover bug 1546443 1553696 1552325 densely reported same issue
    When I run the :create client command with:
      | _tool   | <tool>   |
      | f       | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/tc536600/hello-deployment-1.yaml |
      | f       | <%= BushSlicer::HOME %>/features/tierN/testdata/job/job.yaml                                |
    Then the step should succeed
    When I run the :autoscale client command with:
      | _tool   | <tool>                     |
      | name    | deployment/hello-openshift |
      | max     | 2                          |
    Then the step should succeed
    And I wait for the "hello-openshift" hpa to appear

    When I run the :get client command with:
      | _tool     | <tool>             |
      | resource  | deployment,hpa,job |
      | export    | true               |
      | output    | yaml               |
    Then the step should succeed
    # check for capitalized and missing fields (bug 1546443)
    And the output should not match "^ *[A-Z]"
    And the output should match "  metadata:$"
    And I save the output to file> export.yaml
    Given I ensure "hello-openshift" deployments is deleted
    And I ensure "hello-openshift" hpa is deleted
    And I ensure "pi" jobs is deleted
    When I run the :create client command with:
      | _tool     | <tool>             |
      | f         | export.yaml        |
    Then the step should succeed
    And I wait for the "hello-openshift" deployments to appear
    And I wait for the "hello-openshift" hpa to appear
    And I wait for the "pi" jobs to appear
#   # bug 1581585
#   When I run the :get client command with:
#     | resource       | clusterrole    |
#     | resource_name  | cluster-reader |
#     | export         | true           |
#     | output         | yaml           |
#   Then the step should succeed
#   And the output should contain "kind: ClusterRole"

    Examples:
      | tool     |
      | kubectl  | # @case_id OCP-21063

  # @author pruan@redhat.com
  # @case_id OCP-12594
  Scenario: Negative test for oc export
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/build/sample-php-centos7.json|
    Then the step should succeed
    When I run the :get client command with:
      | resource       | svc      |
      | resource_name  | nonexist |
      | export         | true     |
    Then the step should fail
    And the output should match:
      | [Ee]rror.*[Ss]ervices.*not found |
    When I run the :get client command with:
      | resource        | dc       |
      | resource_name   | nonexist |
      | export          | true     |
    Then the step should fail
    And the output should match:
      | eployment.*"nonexist" not found |
    When I run the :get client command with:
      | resource      | dc       |
      | resource_name | frontend |
      | output        | xyz      |
      | export        | true     |
    Then the step should fail
    And the output should match:
      | error: .*output format "xyz".* |
