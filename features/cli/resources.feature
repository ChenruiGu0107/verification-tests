Feature: resouces related scenarios
  # @author pruan@redhat.com
  # @case_id 474088
  Scenario: Display resources in different formats
    Given I have a project
    When I create a new application with:
      | docker image | openshift/mysql-55-centos7                             |
      | code         | https://github.com/openshift/ruby-hello-world          |
    Then the step should succeed
    Given the pod named "mysql-55-centos7-1-deploy" becomes ready
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should contain:
      | mysql-55-centos7-1-deploy |
    When I run the :get client command with:
      | resource | pods |
      | o        | json |
    And the output is parsed as JSON
    Then the expression should be true> @result[:parsed]['items'].any? {|p| p['metadata']['name'].include? 'mysql-55-centos7-1-deploy'}
    When I run the :get client command with:
      | resource | pods |
      | o        | yaml |
    And the output is parsed as YAML
    Then the expression should be true> @result[:parsed]['items'].any? {|p| p['metadata']['name'].include? 'mysql-55-centos7-1-deploy'}
    When I run the :get client command with:
      | resource | pods |
      | o        | invalid-format |
    Then the output should contain:
      | error: output format "invalid-format" not recognized |

  # @author cryan@redhat.com
  # @case_id 474089
  Scenario: Display resources with multiple options
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/e21d95cedad8f0ce06ff5d04ae9b978ce3d04d87/examples/sample-app/application-template-stibuild.json"
    And I run the :process client command with:
      |f|application-template-stibuild.json|
    And the step should succeed
    And I save the output to file> processed-stibuild.json
    When I run the :create client command with:
      |f|processed-stibuild.json|
    Then the step should succeed
    Given the pod named "ruby-sample-build-1-build" becomes ready
    #the w (watch) flag is set to false. Please set to true once timeouts are
    #implemented in steps.
    When I run the :get client command with:
      | resource   | pods  |
      | no_headers | false |
      | w          | false |
      | l          |       |
    Then the step should succeed
    Then the output should match "ruby-sample-build-1-build\s+1/1\s+Running\s+0"

  # @author xxia@redhat.com
  # @case_id 512023
  Scenario: oc replace with miscellaneous options
    Given I have a project
    And I run the :run client command with:
      | name         | mydc                      |
      | image        | openshift/hello-openshift |
      | -l           | label=mydc                |
    Then the step should succeed

    Given I wait until the status of deployment "mydc" becomes :running
    And I run the :get client command with:
      | resource      | dc                 |
      | resource_name | mydc               |
      | output        | yaml               |
    Then the step should succeed
    When I save the output to file>dc.yaml
    And I run the :replace client command with:
      | f     | dc.yaml |
      | force |         |
    Then the step should succeed
    And the output should contain:
      | "mydc" deleted  |
      | "mydc" replaced |

    Given a pod becomes ready with labels:
      | label=mydc |
    And evaluation of `pod.name` is stored in the :pod_name clipboard
    When I run the :replace client command with:
      | f       | dc.yaml |
      | force   |         |
      | cascade |         |
    Then the step should succeed
    When I wait for the resource "pod" named "<%= cb.pod_name %>" to disappear
    And I run the :get client command with:
      | resource | pod     |
      | l        | dc=mydc |
    Then the step should succeed
    And the output should not contain "<%= cb.pod_name %>"

    When I run the :run client command with:
      | name         | mypod                     |
      | image        | openshift/hello-openshift |
      | generator    | run-pod/v1                |
    Then the step should succeed
    Given the pod named "mypod" becomes ready 
    And I run the :get client command with:
      | resource      | pod                |
      | resource_name | mypod              |
      | output        | yaml               |
    Then the step should succeed
    When I save the output to file>pod.yaml
    And I run the :replace client command with:
      | f            | pod.yaml |
      | force        |          |
      | grace-period | 100      |
    # Currently, there is a bug https://bugzilla.redhat.com/show_bug.cgi?id=1285702 that makes the step *fail*
    Then the step should succeed
