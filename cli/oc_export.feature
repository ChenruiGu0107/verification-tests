Feature: oc exports related scenarios

  # @author pruan@redhat.com
  Scenario Outline: Export resource as json or yaml format by cli
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/sample-php-centos7.json|
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
      | f       | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/deployment/tc536600/hello-deployment-1.yaml |
      | f       | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/job/job.yaml                                |
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
      | oc       | # @case_id OCP-12576
      | kubectl  | # @case_id OCP-21063

  # @author pruan@redhat.com
  # @case_id OCP-12577
  Scenario: Export resource as template format by oc export
    Given I have a project
    And I run the :create client command with:
      | filename | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/sample-php-centos7.json|
    Then the step should succeed
    And I create a new application with:
      | template | php-helloworld-sample |
    Then the step should succeed
    And I run the :get client command with:
      | resource | service |
    Then the step should succeed
    And the output should contain:
      | database |
      | frontend |
    And I run the :get client command with:
      | resource | dc |
    Then the step should succeed
    And the output should match:
      | database.*[Cc]onfig           |
      | frontend.*[Cc]onfig.*[Ii]mage |
    And I run the :export client command with:
      | resource | svc |
      | name     | frontend |
    Then the step should succeed
    And the output should contain:
      | template: application-template-stibuild |
    And I run the :export client command with:
      | resource | svc |
      | l | template=application-template-stibuild |
    Then the step should succeed
    And the output should contain:
      | template: application-template-stibuild |
    And evaluation of `@result[:response]` is stored in the :export_via_filter clipboard
    And I run the :export client command with:
      | resource | svc |
    And evaluation of `@result[:response]` is stored in the :export_all clipboard
    Given I save the response to file> export_all.yaml
    Then the expression should be true> cb.export_via_filter == cb.export_all
    When I delete the project
    Then the step should succeed
    And I create a new project
    And I run the :create client command with:
      | f | export_all.yaml |
    Then the step should succeed
    And I run the :get client command with:
      | resource | service |
    Then the step should succeed
    And the output should contain:
      | database |
      | frontend |

  # @author pruan@redhat.com
  # @case_id OCP-12594
  Scenario: Negative test for oc export
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/build/sample-php-centos7.json|
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

  # @author pruan@redhat.com
  # @case_id OCP-12598
  Scenario: Convert a file to specific version by oc export
    Given I have a project
    When I run the :export client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/deployment/deployment1v1beta3.json |
      | output_version | v1 |
      | output_format  | json |
    Given I save the response to file> export_489300_a.json
    And I run the :create client command with:
      | f | export_489300_a.json |
    Then the step should succeed
    When I run the :export client command with:
      | f | export_489300_a.json |
      | output_version | v1beta3 |
      | output_format | json |
    Then the step should succeed
