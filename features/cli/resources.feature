Feature: resouces related scenarios
  # @author pruan@redhat.com
  # @case_id 474088
  Scenario: Display resources in different formats
    Given I have a project
    When I create a new application with:
      | docker image | openshift/mysql-55-centos7                             |
      | code         | https://github.com/openshift/ruby-hello-world          |
    Then the step should succeed
    Then I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should contain:
      | mysql-55-centos7-1-deploy |
    Then I run the :get client command with:
      | resource | pods |
      | o        | json |
    And evaluation of `JSON.parse(@result[:response])` is stored in the :json_output clipboard
    Then the step should succeed
    And the expression should be true> cb.json_output['items'][0]['metadata']['name'].include? 'mysql-55-centos7'
    Then I run the :get client command with:
      | resource | pods |
      | o        | yaml |
    And evaluation of `YAML.parse(@result[:response])` is stored in the :yaml_output clipboard
    Then the step should succeed
    And the expression should be true> @result[:response].include? 'mysql-55-centos7'
    Then I run the :get client command with:
      | resource | pods |
      | o        | invalid-format |
    Then the output should contain:
      | error: output format "invalid-format" not recognized |
