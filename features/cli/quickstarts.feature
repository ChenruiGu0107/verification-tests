Feature: quickstarts.feature

  # @author cryan@redhat.com
  # @case_id 497474
  Scenario: Rails-ex quickstart test - ruby-20-centos7
    Given I have a project
    Given I create a new application with:
      | docker image | openshift/ruby-20-centos7~https://github.com/openshift/rails-ex |
      | name         | railsquickruby20cent7                                           |
    Then the step should succeed
    When I get project builds
    Then the step should succeed
    When I get project pods
    Then the step should succeed
