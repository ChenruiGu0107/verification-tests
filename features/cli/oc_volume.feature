Feature: oc_volume.feature

  # @author cryan@redhat.com
  # @case_id 491436
  Scenario: option '--all' and '--selector' can not be used together
    Given I have a project
    And I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world |
      | name         | myapp                |
    Then the step should succeed
    When I run the :volume client command with:
      | resource | pod |
      | all | true |
      | selector | frontend |
    Then the step should fail
    And the output should contain "either specify --selector or --all but not both"
