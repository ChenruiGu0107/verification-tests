Feature: oc_set_build_hook

  # @author dyan@redhat.com
  # @case_id OCP-10875
  Scenario: Set invalid post-build-commit on buildconfig via oc set build-hook
    Given I have a project
    When I process and create "https://raw.githubusercontent.com/openshift/rails-ex/master/openshift/templates/rails-postgresql.json"
    Then the step should succeed
    Given the "rails-postgresql-example-1" build was created
    When I run the :cancel_build client command with:
      | build_name | rails-postgresql-example-1 |
    Then the step should succeed
    And I replace resource "bc" named "rails-postgresql-example":
      | script: bundle exec rake test ||
    Then the step should succeed
    When I run the :set_build_hook client command with:
      | buildconfig | bc/rails-postgresql-example |
      | post_commit | true                        |
      | o           | json                        |
      | script      | bundle exec rake test       |
    Then the step should succeed
    When I save the output to file> bc.json
    And I run the :set_build_hook client command with:
      | f           | bc.json |
      | post_commit | true    |
      | script      | xxxxx   |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | rails-postgresql-example |
    Then the step should succeed
    Given the "rails-postgresql-example-2" build failed
    When I run the :logs client command with:
      | resource_name    | build/rails-postgresql-example-2 |
    Then the step should succeed
    And the output should match:
      | build error |
      | xxxxx: command not found |
    When I run the :set_build_hook client command with:
      | buildconfig | bc/rails-postgresql-example |
      | post_commit | true                        |
      | remove      | true                        |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc                       |
      | name     | rails-postgresql-example |
    Then the step should succeed
    And the output should not match:
      | [Pp]ost [Cc]ommit [Hh]ook |

