Feature: oc new-app related scenarios

  # @author xiaocwan@redhat.com
  # @case_id 538949
  Scenario: oc new-app handle arg variables in Dockerfiles
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/php-coder/s2i-test#use_arg_directive|
    # not caring if the resule could be succedd or not, only to test if $VAR is valid
    And the output should not contain:
      | parsing        |
      | invalid syntax |
