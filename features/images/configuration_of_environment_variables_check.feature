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
      | bash                       |
      | -c                         |
      | curl -s <%= service.url %> ; env \| grep ENV ; env \| grep DISABLE_ASSET_COMPILATION|
    Then the step should succeed
    And the output should contain:
      | Welcome to an OpenShift v3 Demo App|
      | RACK_ENV=production                |
      | RAILS_ENV=production               |
      | DISABLE_ASSET_COMPILATION=ture     |

  # @author xiuwang@redhat.com
  # @case_id 499491
  Scenario: Check environment variables of perl-516-rhel7 image
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/perl516rhel7-env-sti.json |
    Then the step should succeed
    Given I wait for the "frontend" service to become ready
    When I execute on the pod:
      | bash                       |
      | -c                         |
      | curl -s <%= service.url %> ; env \| grep ENABLE_CPAN_TEST ; env \| grep CPAN_MIRROR|
    Then the step should succeed
    And the output should contain:
      | Everything is ok    |
      | ENABLE_CPAN_TEST=on |
      | CPAN_MIRROR=        |
