Feature: The apb tool related scenarios

  # @author jiazha@redhat.com
  # @case_id OCP-18560
  @admin
  Scenario: [APB] Check the apb tool subcommand - list
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `route('asb-1338').dns` is stored in the :asb_route clipboard

    When I switch to the first user
    Given the first user is cluster-admin
    When I run the :login client command with:
      | server   | https://<%= env.master_hosts[0].hostname %>:8443/ |
      | u | <%= @user.name %>     |
      | p | <%= @user.password %> |
    Then the step should succeed
    When I run the :list client command with:
      | _tool | apb |
    Then the step should succeed
    And the output should not contain "Exception"
		And the output should not contain "Error"
