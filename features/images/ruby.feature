Feature: ruby.feature

  # @author haowang@redhat.com
  # @case_id 521461 521462
  Scenario Outline: Tune puma workers according to memory limit ruby-22-rhel7 ruby-20-rhel7
    Given I have a project
    When I run the :create client command with:
      | f | <template> |
    Then the step should succeed
    Given the "rails-ex-1" build was created
    And the "rails-ex-1" build completed
    Given 1 pods become ready with labels:
      | app=rails-ex          |
      | deployment=rails-ex-1 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name    | <%= pod.name %> |
    Then the output should contain:
      | Min threads: 0, max threads: 16 |
    """

    Examples:
      | template |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/tc521461/template.json |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/tc521462/template.json |

  # @author xiuwang@redhat.com
  # @case_id 529326
  Scenario: Tune puma workers according to memory limit ruby-rhel7
    Given I have a project
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/tc521462/template.json"
    And I replace lines in "template.json":
      |ruby:2.2|ruby:2.3|
    When I run the :create client command with:
      | f | template.json |
    Then the step should succeed
    Given the "rails-ex-1" build was created
    And the "rails-ex-1" build completed
    Given 1 pods become ready with labels:
      | app=rails-ex          |
      | deployment=rails-ex-1 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name    | <%= pod.name %> |
    Then the output should contain:
      | Min threads: 0, max threads: 16 |
    """

  # @author dyan@redhat.com
  # @case_id 540196 540197
  Scenario Outline: Add RUBYGEM_MIRROR env var to Ruby S2I
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/ruby:<image>~https://github.com/openshift/rails-ex |
      | e        | RUBYGEM_MIRROR=http://not/a/valid/index                      |
    Then the step should succeed
    Given the "rails-ex-1" build failed
    When I run the :logs client command with:
      | resource_name | bc/rails-ex |
    Then the output should contain "Could not fetch specs from http://not/a/valid/index/"
    Examples:
      | image |
      | 2.2   |
      | 2.3   |

