Feature: php image related tests
  # @author dyan@redhat.com
  Scenario Outline: Add COMPOSER_MIRROR env var to Php S2I
    Given I have a project
    When I run the :new_build client command with:
      | app_repo    | openshift/php:<image>~https://github.com/openshift-qe/cakephp-ex |
      | e           | COMPOSER_MIRROR=http://not/a/valid/index                         |
    Then the step should succeed
    Given the "cakephp-ex-1" build failed
    When I run the :logs client command with:
      | resource_name | bc/cakephp-ex |
    Then the output should contain "not allow connections to http://not/a/valid/index/"
    Examples:
      | image |
      | 5.5   | # @case_id OCP-11027
      | 5.6   | # @case_id OCP-11408
      | 7.0   | # @case_id OCP-11673
