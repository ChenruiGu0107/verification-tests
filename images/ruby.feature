Feature: ruby.feature

  # @author haowang@redhat.com
  Scenario Outline: Tune puma workers according to memory limit ruby-22-rhel7 ruby-20-rhel7
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/image/language-image-templates/<template> |
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
      | template                                                                                                                  |
      | tc521461/template.json  | # @case_id OCP-10810
      | tc521462/template.json  | # @case_id OCP-11257
      | OCP-13135/template.json | # @case_id OCP-13135
      | OCP-13136/template.json | # @case_id OCP-13136

  # @author xiuwang@redhat.com
  # @case_id OCP-12370
  Scenario: Tune puma workers according to memory limit ruby-rhel7
    Given I have a project
    Given I obtain test data file "image/language-image-templates/tc521462/template.json"
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
  Scenario Outline: Add RUBYGEM_MIRROR env var to Ruby S2I
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/ruby:<image>~https://github.com/sclorg/rails-ex |
      | e        | RUBYGEM_MIRROR=http://not/a/valid/index                      |
    Then the step should succeed
    Given the "rails-ex-1" build failed
    When I run the :logs client command with:
      | resource_name | bc/rails-ex |
    Then the output should contain "Could not fetch specs from http://not/a/valid/index/"
    Examples:
      | image |
      | 2.2   | # @case_id OCP-12274
      | 2.3   | # @case_id OCP-12303

