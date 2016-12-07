Feature: perl.feature

  # @author dyan@redhat.com
  # @case_id 540191 540192 540193
  Scenario Outline: Add CPAN_MIRROR env var to Perl S2I
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/perl:<image>~https://github.com/openshift/dancer-ex |
      | e        | CPAN_MIRROR=http://not/a/valid/index                          |
    Then the step should succeed
    Given the "dancer-ex-1" build failed
    When I run the :logs client command with:
      | resource_name | bc/dancer-ex |
    Then the output should contain "http://not/a/valid/index/"
    Examples:
      | image |
      | 5.16  |
      | 5.20  |
      | 5.24  |

