Feature: oc_set_build_hook

  # @author cryan@redhat.com
  # @case_id 529758
  # @bug_id 1351797
  Scenario: Set post-build-commit on buildconfig via oc set build-hook
    Given I have a project
    And I process and create "https://raw.githubusercontent.com/openshift/rails-ex/master/openshift/templates/rails-postgresql.json"
    When I run the :set_build_hook client command with:
      | buildconfig | bc/rails-postgresql-example        |
      | post_commit | true                               |
      | command     | /bin/bash -c bundle exec rake test |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | rails-postgresql-example |
    Then the step should succeed
    #cancel first build to speed up process, as it's irrelevant to the test
    When I run the :cancel_build client command with:
      | build_name | rails-postgresql-example-1 |
    Given the "rails-postgresql-example-2" build completes
    When I run the :set_build_hook client command with:
      | buildconfig | bc/rails-postgresql-example        |
      | post_commit | true                               |
      | script | bundle exec rake test |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | rails-postgresql-example |
    Then the step should succeed
    Given the "rails-postgresql-example-3" build completes
    When I run the :set_build_hook client command with:
      | buildconfig | bc/rails-postgresql-example        |
      | post_commit | true                               |
      | args | bundle exec rake test |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | rails-postgresql-example |
    Then the step should succeed
    Given the "rails-postgresql-example-4" build completes
