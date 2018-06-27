Feature: svcat related command

  # @author zhsun@redhat.com
  # @case_id OCP-18644
  @admin
  @destructive
  Scenario: Check svcat subcommand - version
    When I run the :install admin command with:
      | _tool       | svcat                 |
      | command     | plugin                | 
    Then the step should succeed
    And the output should contain:
      | Plugin has been installed           |
   
    #get help info
    When I run the :version admin command with:
      | _tool       | svcat                 |
      | h           |                       | 
    Then the step should succeed
    And the output by order should contain:
      | Usage:                              |
      |   svcat version [flags]             |
      | Examples:                           |
      |   svcat version                     |
      |   svcat version --client            |
      | Flags:                              |
      |   -c, --client                      |
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | h           |                       | 
    Then the step should succeed
    And the output by order should contain:
      | Usage:                              |
      |   oc plugin svcat version [flags]   |
      | Options:                            |
      |   -c, --client=true                 |

    #get version without option
    When I run the :version admin command with:
      | _tool       | svcat                 |
    Then the step should succeed
    And the output should match:
      | client:.*v[0-9].[0-9].[0-9]         |
      | server:.*v[0-9].[0-9]+.[0-9]        |
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
    Then the step should succeed
    And the output should match:
      | client:.*v[0-9].[0-9].[0-9]         |
      | server:.*v[0-9].[0-9]+.[0-9]        |

    #get version with option "-c,--client"
    When I run the :version admin command with:
      | _tool       | svcat                 |
      | client      |                       |
    Then the step should succeed
    And the output should match:
      | client:.*v[0-9].[0-9].[0-9]         |
    When I run the :version admin command with:
      | _tool       | svcat                 |
      | c           |                       |
    Then the step should succeed
    And the output should match:
      | client:.*v[0-9].[0-9].[0-9]         |
    
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | cmd_flag    | --client              |
    Then the step should fail
    And the output should match:
      | flag needs an argument              |
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | cmd_flag    | -c                    |
    Then the step should fail
    And the output should match:
      | flag needs an argument              |

    #In plugin mode must specify --client=true
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | cmd_flag    | --client              |
      | cmd_flag_val| true                  |
    Then the step should succeed
    And the output should match:
      | client:.*v[0-9].[0-9].[0-9]         |
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | cmd_flag    | -c                    |
      | cmd_flag_val| true                  |
    Then the step should succeed
    And the output should match:
      | client:.*v[0-9].[0-9].[0-9]         |
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | cmd_flag    | --client              |
      | cmd_flag_val| false                 |
    Then the step should succeed
    And the output should match:
      | client:.*v[0-9].[0-9].[0-9]         |
      | server: v[0-9].[0-9]+.[0-9].*       |
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | cmd_flag    | -c                    |
      | cmd_flag_val| false                 |
    Then the step should succeed
    And the output should match:
      | client:.*v[0-9].[0-9].[0-9]         |
      | server: v[0-9].[0-9]+.[0-9].*       |
 
    #get version with invalid option "--c,---client"
    When I run the :version admin command with:
      | _tool          | svcat              |
      | invalid_c      |                    |
    Then the step should fail
    And the output should match:
      | unknown flag    |
    When I run the :version admin command with:
      | _tool           | svcat             |
      | invalid_client  |                   |
    Then the step should fail
    And the output should match:
      | bad flag syntax |
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | cmd_flag    | --c                   |
    Then the step should fail
    And the output should match:
      | unknown flag                        |
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | cmd_flag    | ---client             |
    Then the step should fail
    And the output should match:
      | bad flag syntax                     |

  # @author zhsun@redhat.com
  # @case_id OCP-18649
  @admin
  @destructive
  Scenario: Check svcat subcommand - sync
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    
    #get help info
    When I run the :sync admin command with:
      | _tool       | svcat                  |
      | broker_name | :false                 |
      | h           |                        |
    Then the step should succeed
    And the output by order should contain:
      | Usage:                               |
      |   svcat sync broker [name] [flags]   |
    
    #svcat sync ansible-service-broker
    When I run the :sync admin command with:
      | _tool       | svcat                  |
      | broker_name | ansible-service-broker |
    Then the step should succeed
    And the output should match:
      | requested for broker.*ansible-service-broker |
    Given a pod becomes ready with labels:
      | deploymentconfig=asb                 |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %>      |
      | since         | 10s                  |
    Then the output should contain 1 times:
      | AnsibleBroker::Catalog               |

    #using aliase of sync
    When I run the :relist admin command with:
      | _tool       | svcat                  |
      | broker_name | ansible-service-broker |
    Then the step should succeed
    And the output should match:
      | requested for broker.*ansible-service-broker |
    Given a pod becomes ready with labels:
      | deploymentconfig=asb                 |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %>      |
      | since         | 5s                   |
    Then the output should contain 1 times:
      | AnsibleBroker::Catalog               |

    #using invalid broker name
    When I run the :sync admin command with:
      | _tool       | svcat                  |
      | broker_name | invalid-broker         |
    Then the step should fail
    And the output should match:
      | unable to get broker                 |
