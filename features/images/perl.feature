Feature: perl.feature

  # @author dyan@redhat.com
  Scenario Outline: Add CPAN_MIRROR env var to Perl S2I
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/perl:<image>~https://github.com/sclorg/dancer-ex |
      | e        | CPAN_MIRROR=http://not/a/valid/index                          |
    Then the step should succeed
    Given the "dancer-ex-1" build failed
    When I run the :logs client command with:
      | resource_name | bc/dancer-ex |
    Then the output should contain "http://not/a/valid/index/"
    Examples:
      | image |
      | 5.16  | # @case_id OCP-11856
      | 5.20  | # @case_id OCP-12005
      | 5.24  | # @case_id OCP-12107

