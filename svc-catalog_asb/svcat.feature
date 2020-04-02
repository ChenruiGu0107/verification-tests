Feature: svcat related command

  # @author zhsun@redhat.com
  # @case_id OCP-18644
  @admin
  @destructive
  Scenario: Check svcat subcommand - version
    When I run the :install admin command with:
      | _tool        | svcat           |
      | command      | plugin          |
      | plugins_path | ~/.kube/plugins |
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

    #get version without option
    When I run the :version admin command with:
      | _tool       | svcat                 |
    Then the step should succeed
    And the output should match:
      | [C,c]lient.*v[0-9].[0-9]+.[0-9]     |
      | [S,s]erver.*v[0-9].[0-9]+.[0-9]     |
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
    Then the step should succeed
    And the output should match:
      | [C,c]lient.*v[0-9].[0-9]+.[0-9]     |
      | [S,s]erver.*v[0-9].[0-9]+.[0-9]     |

    #get version with option "-c,--client"
    When I run the :version admin command with:
      | _tool       | svcat                 |
      | client      |                       |
    Then the step should succeed
    And the output should match:
      | [C,c]lient.*v[0-9].[0-9]+.[0-9]     |
    When I run the :version admin command with:
      | _tool       | svcat                 |
      | c           |                       |
    Then the step should succeed
    And the output should match:
      | [C,c]lient.*v[0-9].[0-9]+.[0-9]     |

    #In plugin mode must specify --client=true
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | cmd_flag    | --client              |
      | cmd_flag_val| true                  |
    Then the step should succeed
    And the output should match:
      | [C,c]lient.*v[0-9].[0-9]+.[0-9]     |
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | cmd_flag    | -c                    |
      | cmd_flag_val| true                  |
    Then the step should succeed
    And the output should match:
      | [C,c]lient.*v[0-9].[0-9]+.[0-9]     |
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | cmd_flag    | --client              |
      | cmd_flag_val| false                 |
    Then the step should succeed
    And the output should match:
      | [C,c]lient.*v[0-9].[0-9]+.[0-9]     |
      | [S,s]erver.*v[0-9].[0-9]+.[0-9].*   |
    When I run the :plugin admin command with:
      | cmd_name    | svcat                 |
      | cmd_flag    | version               |
      | cmd_flag    | -c                    |
      | cmd_flag_val| false                 |
    Then the step should succeed
    And the output should match:
      | [C,c]lient.*v[0-9].[0-9]+.[0-9]     |
      | [S,s]erver.*v[0-9].[0-9]+.[0-9].*   |

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
      |   svcat sync broker                  |

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
      | since         | 15s                  |
    Then the output should contain:
      | AnsibleBroker::Catalog               |
    Given 15 seconds have passed
    When I run the :sync admin command with:
      | _tool       | svcat                  |
      | broker_name | ansible-service-broker |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deploymentconfig=asb                 |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %>      |
      | since         | 15s                  |
    Then the output should contain 1 times:
      | AnsibleBroker::Catalog               |

    #using aliase of sync
    Given 15 seconds have passed
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
      | since         | 15s                   |
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
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the "ups-broker" cluster_service_broker to become ready up to 60 seconds
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['user-provided-service'].name` is stored in the :class_id clipboard
    And evaluation of `cluster_service_class(cb.class_id).plans.first.name` is stored in the :plan_id clipboard
    # Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait for the "ups-instance" service_instance to become ready up to 60 seconds
    # Create a servicebinding
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
      | p | SECRET_NAME=my-secret                                                                                    |
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
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the "ups-broker" cluster_service_broker to become ready up to 60 seconds
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['user-provided-service'].name` is stored in the :class_id clipboard
    And evaluation of `cluster_service_class(cb.class_id).plans.first.name` is stored in the :plan_id clipboard
    # Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait for the "ups-instance" service_instance to become ready up to 60 seconds
    # Create a servicebinding
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
      | p | SECRET_NAME=my-secret                                                                                    |
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

  # @author zhsun@redhat.com
  # @case_id OCP-18659
  @admin
  @destructive
  Scenario: Check svcat subcommand with additional parameters - provision
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard

    #get help info
    When I run the :provision admin command with:
      | _tool            | svcat                    |
      | instance_name    | :false                   |
      | h                |                          |
    Then the step should succeed
    And the output by order should contain:
      | Usage:                                                       |
      |   svcat provision NAME --plan PLAN --class CLASS [flags]     |

    # Deploy ups broker
    Given admin ensures "ups-broker" clusterservicebroker is deleted after scenario
    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the "ups-broker" cluster_service_broker to become ready up to 120 seconds
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['user-provided-service'].name` is stored in the :class_id clipboard

    # Provision a serviceinstance without addtional optional flags
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I run the :provision client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | class            | user-provided-service    |
      | plan             | default                  |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance1                      |
      | Class:\\s+user-provided-service             |
      | Plan:\\s+default                            |
    #Provision a serviceinstance with option "-n --namespace"
    When I run the :provision client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance2            |
      | class            | user-provided-service    |
      | plan             | default                  |
      | n                | <%= cb.user_project %>   |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance2                      |
      | Class:\\s+user-provided-service             |
      | Plan:\\s+default                            |
    When I run the :provision client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance3            |
      | class            | user-provided-service    |
      | plan             | default                  |
      | namespace        | <%= cb.user_project %>   |
    Then the step should succeed
    #Provision a serviceinstance with option "-p --param"
    When I run the :provision client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance4            |
      | class            | user-provided-service    |
      | plan             | default                  |
      | p                | location=eastus          |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance4                      |
      | Class:\\s+user-provided-service             |
      | Plan:\\s+default                            |
      | Parameters:                                 |
      | \\s+location:\\s+eastus                     |
    When I run the :provision client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance5            |
      | class            | user-provided-service    |
      | plan             | default                  |
      | param            | location=eastus          |
    Then the step should succeed
    #Provision a serviceinstance with option "--params-json"
    When I run the :provision client command with:
      | _tool            | svcat                                               |
      | instance_name    | ups-instance6                                       |
      | class            | user-provided-service                               |
      | plan             | default                                             |
      | params_json      | {"location":"eastus","status":"disabled"}           |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance6                      |
      | Class:\\s+user-provided-service             |
      | Plan:\\s+default                            |  
      | Parameters:                                 |
      | \\s+location:\\s+eastus                     |
      | \\s+status:\\s+disabled                     |
    #Provision a serviceinstance with option "-s --secret"
    Given a "my-secret.yaml" file is created with the following lines:
    """
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: my-secret
    type: Opaque
    stringData:
      parameter:
        '{
          "location":"eastus",
          "password": "letmein"
        }'
    """
    When I run the :create client command with:
      | f     | my-secret.yaml |
    Then the step should succeed
    When I run the :provision client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance7            |
      | class            | user-provided-service    |
      | plan             | default                  |
      | secret           | my-secret[parameter]     |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance7                      |
      | Class:\\s+user-provided-service             |
      | Plan:\\s+default                            |
      | Parameters From:                            |
      | \\s+Secret:\\s+my-secret.parameter          |
    When I run the :provision client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance8            |
      | class            | user-provided-service    |
      | plan             | default                  |
      | s                | my-secret[parameter]     |
    Then the step should succeed
    When I run the :provision client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance11           |
      | class            | user-provided-service    |
      | plan             | default                  |
      | s                | my-secret[parameter]     |
      | param            | location=eastus          |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance11                     |
      | Class:\\s+user-provided-service             |
      | Plan:\\s+default                            |
      | Parameters:                                 |
      | \\s+location:\\s+eastus                     |
      | Parameters From:                            |
      | \\s+Secret:\\s+my-secret.parameter          |
    #Provision a serviceinstance with all options
    When I run the :provision client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance10           |
      | class            | user-provided-service    |
      | plan             | default                  |
      | secret           | my-secret[parameter]     |
      | params_json      | {"status":"disabled"}    |
      | n                | <%= cb.user_project %>   |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance10                     |
      | Class:\\s+user-provided-service             |
      | Plan:\\s+default                            |
      | Parameters:                                 |
      | \\s+status:\\s+disabled                     |
      | Parameters From:                            |
      | \\s+Secret:\\s+my-secret.parameter          |
    #Provision a serviceinstance with option "--external-id"
    When I run the :provision client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance12           |
      | class            | user-provided-service    |
      | plan             | default                  |
      | external_id      | externalid               |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance12                     |
      | Class:\\s+user-provided-service             |
      | Plan:\\s+default                            |

    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | _tool            | svcat                    |
      | resource         | instances                |
    Then the step should succeed
    And the output should match:
      |  ups-instance1.*Ready                       |                
      |  ups-instance10.*Ready                      |
      |  ups-instance11.*ErrorWithParameters        |
      |  ups-instance12.*Ready                      |
      |  ups-instance2.*Ready                       |
      |  ups-instance3.*Ready                       |
      |  ups-instance4.*Ready                       |
      |  ups-instance5.*Ready                       |
      |  ups-instance6.*Ready                       |
      |  ups-instance7.*Ready                       |   
      |  ups-instance8.*Ready                       | 
    """

  # @author zhsun@redhat.com
  # @case_id OCP-18674
  @admin
  @destructive
  Scenario: Check svcat subcommand with additional parameters - bind
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard
    
    #get help info
    When I run the :bind client command with:
      | _tool            | svcat                  |
      | instance_name    | :false                 |
      | h                |                        |
    Then the step should succeed
    And the output by order should contain:
      | Usage:                                    |
      |   svcat bind INSTANCE_NAME [flags]        |

    # Deploy ups broker
    Given admin ensures "ups-broker" clusterservicebroker is deleted after scenario
    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the "ups-broker" cluster_service_broker to become ready up to 60 seconds
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['user-provided-service'].name` is stored in the :class_id clipboard
    #Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I run the :provision client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | class            | user-provided-service    |
      | plan             | default                  |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance1                      |    
      | Class:\\s+user-provided-service             |
      | Plan:\\s+default                            |
    #Binding a serviceinstance without options
    When I run the :bind client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance1                      |
      | Secret:\\s+ups-instance1                    |
      | Instance:\\s+ups-instance1                  |
    #Binding a serviceinstance with option "--name"
    When I run the :bind client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | name             | ups-instance1-bind       |
    Then the step should succeed  
    And the output should match:
      | Name:\\s+ups-instance1-bind                 |   
      | Secret:\\s+ups-instance1-bind               |
      | Instance:\\s+ups-instance1                  |
    #Binding a serviceinstance with option "-n --namespace"
    When I run the :bind client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | name             | ups-instance1-bind1      |
      | n                | <%= cb.user_project %>   |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance1-bind1                |
      | Secret:\\s+ups-instance1-bind1              |
      | Instance:\\s+ups-instance1                  |
    When I run the :bind client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | name             | ups-instance1-bind2      |
      | namespace        | <%= cb.user_project %>   |
    Then the step should succeed
    #Binding a serviceinstance with option "-p --param"
    When I run the :bind client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | name             | ups-instance1-bind3      |
      | p                | location=eastus          |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance1-bind3                |
      | Secret:\\s+ups-instance1-bind3              |
      | Instance:\\s+ups-instance1                  |
      | Parameters:                                 |
      | \\s+location:\\s+eastus                     |
    When I run the :bind client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | name             | ups-instance1-bind4      |
      | param            | location=eastus          |
    Then the step should succeed
    #Binding a serviceinstance with option "--params-json"
    When I run the :bind client command with:
      | _tool            | svcat                                               |
      | instance_name    | ups-instance1                                       |
      | name             | ups-instance1-bind5                                 |
      | params_json      | {"location":"eastus","status":"disabled"}           |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance1-bind5                |
      | Secret:\\s+ups-instance1-bind5              |
      | Instance:\\s+ups-instance1                  |
      | Parameters:                                 |
      | \\s+location:\\s+eastus                     |
      | \\s+status:\\s+disabled                     |
    #Binding a serviceinstance with option "-s --secret"
    Given a "my-secret.yaml" file is created with the following lines:
    """
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: my-secret
    type: Opaque
    stringData:
      parameter:
        '{
          "location":"eastus",
          "password": "letmein"
        }'
    """
    When I run the :create client command with:
      | f     | my-secret.yaml |
    Then the step should succeed
    When I run the :bind client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | name             | ups-instance1-bind6      |
      | secret           | my-secret[parameter]     |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance1-bind6                |
      | Secret:\\s+ups-instance1-bind6              |
      | Instance:\\s+ups-instance1                  |
      | Parameters From:                            |
      | \\s+Secret:\\s+my-secret.parameter          |
    When I run the :bind client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | name             | ups-instance1-bind7      |
      | s                | my-secret[parameter]     |
    Then the step should succeed
    When I run the :bind client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | name             | ups-instance1-bind10     |
      | s                | my-secret[parameter]     |
      | param            | location=eastus          |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance1-bind10               |
      | Secret:\\s+ups-instance1-bind10             |
      | Instance:\\s+ups-instance1                  |
      | Parameters:                                 |
      | \\s+location:\\s+eastus                     |
      | Parameters From:                            |
      | \\s+Secret:\\s+my-secret.parameter          |
    #Binding a serviceinstance with option "--secret-name"
    When I run the :bind client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | name             | ups-instance1-bind8      |
      | secret_name      | ups-instance1-secret     |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance1-bind8                |
      | Secret:\\s+ups-instance1-secret             |
      | Instance:\\s+ups-instance1                  |
    #Binding a serviceinstance with all options
    When I run the :bind client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | name             | ups-instance1-bind9      |
      | secret           | my-secret[parameter]     |
      | params_json      | {"status":"disabled"}    |
      | n                | <%= cb.user_project %>   |
      | secret_name      | ups-instance1-secret1    |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance1-bind9                |
      | Secret:\\s+ups-instance1-secret1            |
      | Instance:\\s+ups-instance1                  |
      | Parameters:                                 |
      | \\s+status:\\s+disabled                     |
      | Parameters From:                            |
      | \\s+Secret:\\s+my-secret.parameter          | 
    #Binding a serviceinstance with option "--external-id"
    When I run the :bind client command with:
      | _tool            | svcat                    |
      | instance_name    | ups-instance1            |
      | name             | ups-instance1-bind11     |
      | external_id      | externalid               |
    Then the step should succeed
    And the output should match:
      | Name:\\s+ups-instance1-bind11               |
      | Secret:\\s+ups-instance1-bind11             |
      | Instance:\\s+ups-instance1                  |

    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | _tool            | svcat                    |
      | resource         | bindings                 |
    Then the step should succeed
    And the output should match:
      | ups-instance1.*Ready                        |   
      | ups-instance1-bind.*Ready                   |   
      | ups-instance1-bind1.*Ready                  |   
      | ups-instance1-bind10.*ErrorWithParameters   |   
      | ups-instance1-bind11.*Ready                 |   
      | ups-instance1-bind2.*Ready                  |   
      | ups-instance1-bind3.*Ready                  |   
      | ups-instance1-bind4.*Ready                  |   
      | ups-instance1-bind5.*Ready                  |   
      | ups-instance1-bind6.*Ready                  | 
      | ups-instance1-bind7.*Ready                  | 
      | ups-instance1-bind8.*Ready                  |
      | ups-instance1-bind9.*Ready                  |
    """
