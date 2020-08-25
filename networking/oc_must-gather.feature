Feature: oc adm must-gather related scenarios

  # @author rbrattai@redhat.com
  # @case_id OCP-32388
  @admin
  Scenario: [SDN-975] Gather OVN network trace for customer analysis
    Given the env is using "OVNKubernetes" networkType
    Given the master version >= "4.6"
    Given I switch to cluster admin pseudo user
    When I run the :oadm_must_gather admin command with:
      | dest_dir     | ovn_must_gather                   |
      | oc_opts_end  |                                   |
      | exec_command | /usr/bin/gather_network_ovn_trace |
    Then the step should succeed
    And the expression should be true> Dir.glob('ovn_must_gather/*/network_trace/ovn-startup_trace').length == 1
    Given the "ovn_must_gather" directory is removed
