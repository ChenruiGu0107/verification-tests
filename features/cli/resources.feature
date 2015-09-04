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
    Then I run the :get client command with:
      | resource | pods |
      | o        | json |
    And evaluation of `JSON.parse(@result[:response])` is stored in the :json clipboard
    And the expression should be true> cb.json['items'].any? {|p| p['metadata']['name'].include? 'mysql-55-centos7-1-deploy'}
    Then I run the :get client command with:
      | resource | pods |
      | o        | yaml |
    And evaluation of `YAML.load(@result[:response])` is stored in the :yaml clipboard
    And the expression should be true> cb.yaml['items'].any? {|p| p['metadata']['name'].include? 'mysql-55-centos7-1-deploy'}
    Then I run the :get client command with:
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
