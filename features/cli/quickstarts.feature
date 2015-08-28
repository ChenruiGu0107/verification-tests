Feature: quickstarts.feature

  # @author cryan@redhat.com
  # @case_id 497474
  Scenario: Rails-ex quickstart test - ruby-20-centos7
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-centos7.json |
    Then the step should succeed
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/rails-ex/master/openshift/templates/rails-postgresql-tcms497474.json |
        | v | SOURCE_REPOSITORY_URL=https://github.com/openshift-qe/rails-ex.git|
    Given I save the output to file>railspsql.json
    When I run the :create client command with:
      | f | railspsql.json |
    Then the step should succeed
    When I expose the "rails-postgresql-example" service
    Then the step should succeed
    And I wait for a server to become available via the "rails-postgresql-example" route
    When I get project builds
    Then the step should succeed
    When I get project pods
    Then the step should succeed
    When I run the :env client command with:
      | resource | dc/frontend |
      | keyval   | RAILS_ENV=development |
    When I get project builds
    Then the step should succeed
    And the output should not contain "static"
