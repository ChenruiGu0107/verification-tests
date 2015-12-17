Feature: Configuration of environment variables check

  # @author xiuwang@redhat.com
  # @case_id 499488
  Scenario: Check environment variables of ruby-20-rhel7 image
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-env-sti.json |
    Then the step should succeed
    Given I wait for the "frontend" service to become ready
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    And the output should contain:
      | Welcome to an OpenShift v3 Demo App |
    When I execute on the pod:
      | env |
    Then the step should succeed
    And the output should contain:
      | RACK_ENV=production            |
      | RAILS_ENV=production           |
      | DISABLE_ASSET_COMPILATION=true |

  # @author xiuwang@redhat.com
  # @case_id 499491
  Scenario: Check environment variables of perl-516-rhel7 image
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/perl516rhel7-env-sti.json |
    Then the step should succeed
    Given I wait for the "frontend" service to become ready
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    And the output should contain:
      | Everything is OK |
    When I execute on the pod:
      | env |
    Then the step should succeed
    And the output should contain:
      | ENABLE_CPAN_TEST=on |
      | CPAN_MIRROR=        |
