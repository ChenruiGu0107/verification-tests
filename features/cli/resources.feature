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
