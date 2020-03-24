Feature: security and compliance related scenarios
  # @author xiyuan@redhat.com
  # @case_id OCP-28717
  @admin
  Scenario: FIPS mode checking command works for a cluster with fip mode on
    	       
    Given fips is enabled
    # check whether fips enabled for master node
    Given I store the masters in the :masters clipboard
    And I use the "<%= cb.masters[0].name %>" node
    When I run commands on the host:
      | update-crypto-policies --show |
    Then the step should succeed
    And the output should match:
      | FIPS |
    When I run commands on the host:
      | sysctl crypto.fips_enabled | 
    Then the step should succeed
    And the output should match:
      | crypto.fips_enabled = 1 |
    When I run commands on the host:
      | cat /etc/system-fips |
    Then the step should succeed
    And the output should contain:
      | RHCOS FIPS mode installation complete |

    # check whether fips mode enabled or not for worker node
    Given I store the workers in the :workers clipboard
    And I use the "<%= cb.workers[0].name %>" node
    When I run commands on the host:
      | sysctl crypto.fips_enabled |  
    Then the step should succeed
    And the output should match:
      | crypto.fips_enabled = 1 |
    When I run commands on the host:
      | cat /proc/sys/crypto/fips_enabled |
    Then the step should succeed
    And the output should contain:
      | 1 |

  # @author pdhamdhe@redhat.com
  # @case_id OCP-25822
  @admin
  @destructive
  Scenario: Refuse to disable FIPS mode by MCO

    Given fips is enabled

    # Create a MachineConfig on master & worker node to disable fips
    Given admin ensures "99-fips-master" machineconfig is deleted after scenario
    Given admin ensures "99-fips-worker" machineconfig is deleted after scenario
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/fips/fips-master-disable.yaml |
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/fips/fips-worker-disable.yaml |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | mc |
    Then the step should succeed
    And the output should contain:
      | 99-fips-master |
      | 99-fips-worker |
    
    # Verify if the fips is enable on master node
    Given I store the masters in the :masters clipboard
    And I use the "<%= cb.masters[0].name %>" node
    When I run commands on the host:
      | update-crypto-policies --show |
    Then the step should succeed
    And the output should match:
      | FIPS |
    When I run commands on the host:
      | sysctl crypto.fips_enabled |
    Then the step should succeed
    And the output should match:
      | crypto.fips_enabled = 1 |
    When I run commands on the host:
      | cat /etc/system-fips |
    Then the step should succeed
    And the output should contain:
      | RHCOS FIPS mode installation complete |

    # Reboot the master node
    When I run commands on the host:
      | systemctl reboot |
    Then the step should succeed
    And admin wait for the "<%=cb.masters[0].name%>" node to appear

    # Verify if fips mode is enable on master node after reboot
    When I run commands on the host: 
      | update-crypto-policies --show |
    Then the step should succeed
    And the output should match:
      | FIPS |
    When I run commands on the host:
      | sysctl crypto.fips_enabled |
    Then the step should succeed
    And the output should match:
      | crypto.fips_enabled = 1 |
    When I run commands on the host:
      | cat /etc/system-fips |
    Then the step should succeed
    And the output should contain:
      | RHCOS FIPS mode installation complete |

    # Verify if the fips is enable on RHCOS and RHEL worker node
    Given I store the workers in the :workers clipboard
    And I use the "<%= cb.workers[0].name %>" node
    When I run commands on the host:
      | sysctl crypto.fips_enabled |
    Then the step should succeed
    And the output should match:
      | crypto.fips_enabled = 1 |
    When I run commands on the host:
      | cat /proc/cmdline |
    Then the step should succeed
    And the output should contain:
      | fips=1 |
      
    # Reboot the worker node 
    When I run commands on the host:
      | systemctl reboot |
    Then the step should succeed
    And admin wait for the "<%=cb.workers[0].name%>" node to appear

    # Verify if the fips mode is enable on RHCOS and RHEL worker node after reboot
    When I run commands on the host:
      | sysctl crypto.fips_enabled |
    Then the step should succeed
    And the output should match:
      | crypto.fips_enabled = 1 |
    When I run commands on the host:
      | cat /proc/cmdline |
    Then the step should succeed
    And the output should contain:
      | fips=1 |      

  # @author pdhamdhe@redhat.com
  # @case_id OCP-25819
  @admin
  @destructive	
  Scenario: enable FIPS by MCO not supported

    Given fips is disabled

    # Create a MachineConfig on master & worker node to enable fips
    Given admin ensures "99-master-fips" machineconfig is deleted after scenario
    Given admin ensures "99-worker-fips" machineconfig is deleted after scenario  	    
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/fips/fips-master-enable.yaml |
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/fips/fips-worker-enable.yaml |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | mc |
    Then the step should succeed
    And the output should contain:
      | 99-master-fips | 
      | 99-worker-fips |

    # Verify if the fips is disable on master node
    Given I store the masters in the :masters clipboard
    And I use the "<%= cb.masters[0].name %>" node
    When I run commands on the host:
      | update-crypto-policies --show |
    Then the step should succeed
    And the output should match:
      | DEFAULT |
    When I run commands on the host: 
      | sysctl crypto.fips_enabled |
    Then the step should succeed
    And the output should match:
      | crypto.fips_enabled = 0 |
    When I run commands on the host:
      | cat /proc/sys/crypto/fips_enabled |
    Then the step should succeed
    And the output should contain:
      | 0 |
      
    # Reboot the master node
    When I run commands on the host:
      | systemctl reboot |
    Then the step should succeed
    And admin wait for the "<%=cb.masters[0].name%>" node to appear

    # Verify if fips mode is disable on master node after reboot
    When I run commands on the host:
      | update-crypto-policies --show |
    Then the step should succeed
    And the output should match:
      | DEFAULT |
    When I run commands on the host:
      | sysctl crypto.fips_enabled |
    Then the step should succeed
    And the output should match:
      | crypto.fips_enabled = 0 |
    When I run commands on the host:
      | cat /proc/sys/crypto/fips_enabled |
    Then the step should succeed
    And the output should contain:
      | 0 |

    # Verify if the fips is disable on RHCOS and RHEL worker node
    Given I store the workers in the :workers clipboard
    And I use the "<%=cb.workers[0].name%>" node
    When I run commands on the host:
      | sysctl crypto.fips_enabled |
    Then the step should succeed
    And the output should match:
      | crypto.fips_enabled = 0 |
    When I run commands on the host:
      | cat /proc/cmdline |
    Then the step should succeed
    And the output should not contain:
      | fips=1 |
      
    # Reboot the worker node 
    When I run commands on the host:
      | systemctl reboot |
    Then the step should succeed
    And admin wait for the "<%=cb.workers[0].name%>" node to appear

    # Verify if the fips mode is disable on RHCOS and RHEL worker node after reboot
    When I run commands on the host:
      | sysctl crypto.fips_enabled |
    Then the step should succeed
    And the output should match:
      | crypto.fips_enabled = 0 |
    When I run commands on the host:
      | cat /proc/cmdline |
    Then the step should succeed
    And the output should not contain:
      | fips=1 |
