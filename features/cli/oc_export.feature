Feature: oc exports related scenarios

  # @author pruan@redhat.com
  # @case_id OCP-12576
  Scenario: Export resource as json or yaml format by oc export
    Given I have a project
    And I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sample-php-centos7.json|
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
      | resource      | svc      |
      | name          | frontend |
      | output_format | json     |
    And evaluation of `JSON.parse(@result[:response])` is stored in the :export_svc clipboard
    Then the expression should be true> cb.export_svc['metadata']['labels']['template'] == "application-template-stibuild"
    Given I save the response to file> svc_output.json
    And I run the :export client command with:
      | resource      | dc       |
      | name          | frontend |
      | output_format | json     |
    And evaluation of `JSON.parse(@result[:response])` is stored in the :export_dc clipboard
    Then the expression should be true> cb.export_dc['spec']['triggers'].to_s.include? 'ConfigChange'
    Then the expression should be true> cb.export_dc['spec']['triggers'].to_s.include? 'ImageChange'
    Given I save the response to file> dc_output.json
    When I delete the project
    Then the step should succeed
    Given I create a new project
    And I run the :create client command with:
      | f | svc_output.json |
    Then the step should succeed
    And I run the :create client command with:
      | f | dc_output.json |
    Then the step should succeed
    And I run the :get client command with:
      | resource | svc |
    Then the step should succeed
    And the output should contain:
      | frontend |
    And I run the :get client command with:
      | resource | dc |
    Then the step should succeed
    And the output should match:
      | frontend.*[Cc]onfig.*[Ii]mage |

    # Export other various APIs resources, like extensions/v1beta1, autoscaling/v1, batch/v1
    # Cover bug 1546443 1553696 1552325 densely reported same issue
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc536600/hello-deployment-1.yaml |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/job/job.yaml                                |
    Then the step should succeed
    When I run the :autoscale client command with:
      | name | deployment/hello-openshift |
      | max  | 2                          |
    Then the step should succeed
    And I wait for the "hello-openshift" hpa to appear

    When I run the :export client command with:
      | resource  | deployment,hpa,job |
    Then the step should succeed
    # check for capitalized and missing fields (bug 1546443)
    And the output should not match "^ *[A-Z]"
    And the output should match "  metadata:$"
    And I save the output to file>export.yaml
    Given I ensure "hello-openshift" deployments is deleted
    And I ensure "hello-openshift" hpa is deleted
    And I ensure "pi" jobs is deleted
    When I run the :create client command with:
      | f | export.yaml |
    Then the step should succeed
    And I wait for the "hello-openshift" deployments to appear
    And I wait for the "hello-openshift" hpa to appear
    And I wait for the "pi" jobs to appear

  # @author pruan@redhat.com
  # @case_id OCP-12577
  Scenario: Export resource as template format by oc export
    Given I have a project
    And I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sample-php-centos7.json|
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
    And I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sample-php-centos7.json|
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
    And I run the :export client command with:
      | resource | svc |
      | name     | nonexist |
    Then the step should fail
    And the output should match:
      | [Ee]rror.*[Ss]ervices.*not found |
    And I run the :export client command with:
      | resource | dc |
      | name     | nonexist |
    Then the step should fail
    And the output should match:
      | eployment.*"nonexist" not found |
    And I run the :export client command with:
      | resource | svc |
      | l | name=nonexist|
    Then the step should fail
    And the output should contain:
      | no resources found - nothing to export |
    And I run the :export client command with:
      | resource | dc |
      | name     | frontend |
      | output_format | xyz |
    Then the step should fail
    And the output should contain:
      | error: output format "xyz" not recognized |

    # For sake of Online test in which one user can only create 1 project
    Given I ensure "<%= project.name %>" project is deleted
    And I create a new project
    And I run the :get client command with:
      | resource | svc |
    Then the step should succeed
    And the output should not contain:
      | template |
    And I run the :export client command with:
      | resource | svc |
      | all | true |
    Then the output should contain:
      | error: no resources found - nothing to export |

  # @author pruan@redhat.com
  # @case_id OCP-12598
  Scenario: Convert a file to specific version by oc export
    Given I have a project
    When I run the :export client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/deployment1v1beta3.json |
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
