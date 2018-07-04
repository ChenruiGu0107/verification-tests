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

  # @author zhsun@redhat.com
  # @case_id OCP-18653
  @admin
  Scenario: Check svcat subcommand - touch
    Given I save the first service broker registry prefix to :prefix clipboard
    And I have a project
    #get help info
    When I run the :touch_instance admin command with:
      | _tool       | svcat                  |
      | name        | :false                 |
      | h           |                        |
    Then the step should succeed
    And the output by order should contain:
      | Usage:                               |
      |   svcat touch instance [flags]       |
    #Provision a serviceinstance
    When I run the :provision client command with:
      | _tool            | svcat                           |
      | instance_name    | postgresql-instance             |
      | class            | <%= cb.prefix %>-postgresql-apb |
      | plan             | dev                             |
      | n                | <%= project.name %>             |
    Then the step should succeed
    When I run the :get client command with:
      | _tool            | svcat                           |
      | resource         | instances                       |
      | n                | <%= project.name %>             |
    Then the step should succeed
    And I wait for the "postgresql-instance" service_instance to become ready up to 360 seconds
    And dc with name matching /postgresql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %>         |
    When I run the :describe client command with:
      | resource | serviceinstance/postgresql-instance     |
    Then the output should match:
      | Update Requests:  0                                |
      | Message.*The instance was provisioned successfully |
    #svcat touch instance postgresql-instance
    When I run the :touch_instance admin command with:
      | _tool           | svcat                            |
      | name            | postgresql-instance              |
      | n               | <%= project.name %>              |
    Then the step should succeed
    And I wait for the "postgresql-instance" service_instance to become ready up to 360 seconds
    When I run the :describe client command with:
      | resource | serviceinstance/postgresql-instance     |
    Then the output should match:
      | Update Requests:  1                                |
      | Message.* The instance was updated successfully    |
    #negative test
    When I run the :touch_instance admin command with:
      | _tool       | svcat                  |
      | name        | :false                 |
    Then the step should fail
    And the output should match:
      | an instance name is required         |
    When I run the :touch_instance admin command with:
      | _tool       | svcat                  |
      | name        | invalid-instance       |
    Then the step should fail
    And the output should match:
      | unable to get instance               |

  # @case_id OCP-18685
  @admin
  @destructive
  Scenario Outline: Check svcat subcommand with additional parameters - get
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard

    # Deploy ups broker
    Given admin ensures "ups-broker" clusterservicebroker is deleted after scenario
    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | param | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the "ups-broker" cluster_service_broker to become ready up to 60 seconds
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['user-provided-service'].name` is stored in the :class_id clipboard
    And evaluation of `cluster_service_class(cb.class_id).plans.first.name` is stored in the :plan_id clipboard
    # Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait for the "ups-instance" service_instance to become ready up to 60 seconds
    # Create a servicebinding
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                      |
      | param | SECRET_NAME=my-secret                                                                                    |
    Then the step should succeed
    Given I check that the "my-secret" secret exists 
    And I wait for the "ups-binding" service_binding to become ready up to 60 seconds

    # get resource without option
    When I run the :get <user_type> command with:
      | _tool       | svcat              |
      | resource    | <resource_type>    |
    Then the step should succeed
    And the output should match:
      | <output_result>                  |
    # get resource filtered by resource name
    When I run the :get <user_type> command with:
      | _tool       | svcat              |
      | resource    | <resource_type>    |
      | name        | <resource_name>    |
    Then the step should succeed
    And the output should match:
      | <output_result>                  |
    # get resource using yaml|json format
    When I run the :get <user_type> command with:
      | _tool       | svcat              |
      | resource    | <resource_type>    |
      | name        | <resource_name>    |
      | o           | yaml               |
    Then the step should succeed
    And the output should match:
      | <output_yaml>                    |
    When I run the :get <user_type> command with:
      | _tool       | svcat              |
      | resource    | <resource_type>    |
      | name        | <resource_name>    |
      | o           | json               |
    Then the step should succeed
    And the output should match:
      | <output_json>                    |
    # get resource using aliases
    When I run the :get <user_type> command with:
      | _tool       | svcat              |
      | resource    | <resource_aliase1> |
    Then the step should succeed
    And the output should match:
      | <output_result>                  |
    When I run the :get <user_type> command with:
      | _tool       | svcat              |
      | resource    | <resource_aliase2> |
    Then the step should succeed
    And the output should match:
      | <output_result>                  |
    # get resource using uuid
    When I run the :get <user_type> command with:
      | _tool       | svcat              |
      | resource    | <resource_type>    |
      | uuid        | <uuid_value>       |
    Then the step should <status>
    And the output should contain:
      | <output_uuid>                    |

     Examples:
      |resource_type  |resource_aliase1 |resource_aliase2 |resource_name         |output_result            |output_yaml                         |output_json                            |user_type |uuid_value          |status     |output_uuid                  |
      |brokers        |broker           |brk              |ups-broker            |ups-broker               |name: ups-broker                    |"name": "ups-broker"                   |admin     |brokeruuid          |fail       |unknown flag                 | 
      |classes        |class            |cl               |user-provided-service |user-provided-service    |externalName: user-provided-service |"externalName": "user-provided-service"|client    |<%= cb.class_id %>  |succeed    |user-provided-service        |
      |plans          |plan             |pl               |premium               |premium                  |externalName: premium               |"externalName": "premium"              |client    |<%= cb.plan_id %>   |succeed    |default                      |
      |instances      |instance         |inst             |ups-instance          |ups-instance             |name: ups-instance                  |"name": "ups-instance"                 |client    |instanceuuid        |fail       |unknown flag                 |
      |bindings       |binding          |bnd              |ups-binding           |ups-binding              |name: ups-binding                   |"name": "ups-binding"                  |client    |bindinguuid         |fail       |unknown flag                 |


  # @author zhsun@redhat.com
  # @case_id OCP-18688
  @admin
  @destructive
  Scenario Outline: Check svcat subcommand with additional parameters - describe
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard

    # Deploy ups broker
    Given admin ensures "ups-broker" clusterservicebroker is deleted after scenario
    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | param | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the "ups-broker" cluster_service_broker to become ready up to 60 seconds
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['user-provided-service'].name` is stored in the :class_id clipboard
    And evaluation of `cluster_service_class(cb.class_id).plans.first.name` is stored in the :plan_id clipboard
    # Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait for the "ups-instance" service_instance to become ready up to 60 seconds
    # Create a servicebinding
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                      |
      | param | SECRET_NAME=my-secret                                                                                    |
    Then the step should succeed
    Given I check that the "my-secret" secret exists
    And I wait for the "ups-binding" service_binding to become ready up to 60 seconds

    # describe resource without option
    When I run the :describe <user_type> command with:
      | _tool       | svcat              |
      | resource    | <resource_type>    |
    Then the step should fail
    And the output should match:
      | <output_error>                   |
    # describe resource filtered by resource name
    When I run the :describe <user_type> command with:
      | _tool       | svcat              |
      | resource    | <resource_type>    |
      | name        | <resource_name>    |
    Then the step should succeed
    And the output should match:
      | <output_result>                  |
    # describe resource using aliases
    When I run the :describe <user_type> command with:
      | _tool       | svcat              |
      | resource    | <resource_aliase1> |
    Then the step should fail
    And the output should match:
      | <output_error>                   |
    When I run the :describe <user_type> command with:
      | _tool       | svcat              |
      | resource    | <resource_aliase2> |
    Then the step should fail
    And the output should match:
      | <output_error>                   |
    # describe resource using uuid
    When I run the :describe <user_type> command with:
      | _tool       | svcat              |
      | resource    | <resource_type>    |
      | uuid        | <uuid_value>       |
    Then the step should <status>
    And the output should match:
      | <output_uuid>                    |

     Examples:
      |resource_type |resource_aliase1 |resource_aliase2 |resource_name         |output_result                                    |output_error                            |user_type     |uuid_value               |status       |output_uuid                            |
      |brokers       |broker           |brk              |ups-broker            |Successfully fetched catalog entries from broker |a broker name is required               |admin         |broker                   |fail         |unknown flag                           |
      |classes       |class            |cl               |user-provided-service |Name:          user-provided-service             |a class name or uuid is required        |client        |<%= cb.class_id %>       |succeed      |Name:          user-provided-service   |
      |plans         |plan             |pl               |premium               |Name:          premium                           |a plan name or uuid is required         |admin         |<%= cb.plan_id %>        |succeed      |Name:          default                 |    
      |instances     |instance         |inst             |ups-instance          |The instance was provisioned successfully        |an instance name is required            |client        |instance                 |fail         |unknown flag                           |
      |bindings      |binding          |bnd              |ups-binding           |Injected bind result                             |a binding name is required              |client        |binding                  |fail         |unknown flag                           |
