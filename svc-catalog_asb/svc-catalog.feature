Feature: Service-catalog related scenarios

  # @author chezhang@redhat.com
  # @case_id OCP-15571
  @admin
  @destructive
  Scenario: Delete ServiceInstance when it have multi ServiceBinding
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard

    # Deploy ups broker
    Given I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | clusterservicebroker |
      | object_name_or_id | ups-broker           |
    the step should succeed
    """
    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should contain "Successfully fetched catalog entries from broker"
    When I run the :get client command with:
      | resource | clusterserviceclass                                                       |
      | o        | custom-columns=CLASSNAME:.metadata.name,EXTERNAL\ NAME:.spec.externalName |
    Then the output should contain "user-provided"
    """

    #Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Message.*The instance was provisioned successfully"
    """

    # Create two servicebindings
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
      | p | BINDING_NAME=ups-binding-1                                                                               |
      | p | SECRET_NAME=my-secret-1                                                                                  |
    Then the step should succeed
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
      | p | BINDING_NAME=ups-binding-2                                                                               |
      | p | SECRET_NAME=my-secret-2                                                                                  |
    Then the step should succeed
    Given I check that the "my-secret-1" secret exists
    And I check that the "my-secret-2" secret exists
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | servicebinding |
    Then the output should match 2 times:
      | Message.*Injected bind result |
    """

    # Delete the serviceinstance directly
    When I run the :delete client command with:
      | wait              | false           |
      | object_type       | serviceinstance |
      | object_name_or_id | ups-instance    |
    Then the step should succeed
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance |
    Then the output should match "DeprovisionBlockedByExistingCredentials.*ServiceBindings.*must be removed"
    """
    # Check ServiceInstance and ServiceBinding status after 6mins
    Given 360 seconds have passed
    And I check that the "ups-instance" serviceinstance exists
    And I check that the "ups-binding-1" servicebinding exists
    And I check that the "ups-binding-2" servicebinding exists
    And I check that the "my-secret-1" secret exists
    And I check that the "my-secret-2" secret exists

    # Delete servicebinding ups-binding-1
    When I run the :delete client command with:
      | object_type       | servicebinding |
      | object_name_or_id | ups-binding-1  |
    Then the step should succeed

    # Check ServiceInstance and ServiceBinding status after 6mins
    Given 360 seconds have passed
    And I check that the "ups-instance" serviceinstance exists
    And I wait for the resource "servicebinding" named "ups-binding-1" to disappear
    And I check that the "ups-binding-2" servicebinding exists
    And I wait for the resource "secret" named "my-secret-1" to disappear
    And I check that the "my-secret-2" secret exists

    # Delete servicebinding ups-binding-2
    When I run the :delete client command with:
      | object_type       | servicebinding |
      | object_name_or_id | ups-binding-2  |
    Then the step should succeed

    # Check ServiceInstance and ServiceBinding status after 6mins
    Given 360 seconds have passed
    And I wait for the resource "serviceinstance" named "ups-instance" to disappear
    And I wait for the resource "servicebinding" named "ups-binding-1" to disappear
    And I wait for the resource "servicebinding" named "ups-binding-2" to disappear
    And I wait for the resource "secret" named "my-secret-1" to disappear
    And I wait for the resource "secret" named "my-secret-2" to disappear

  # @author chezhang@redhat.com
  # @case_id OCP-15566
  @admin
  @destructive
  Scenario: Delete serviceInstance when it with or without related ServiceBinding
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard

    # Deploy ups broker
    Given I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | clusterservicebroker |
      | object_name_or_id | ups-broker           |
    the step should succeed
    """
    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should contain "Successfully fetched catalog entries from broker"
    When I run the :get client command with:
      | resource | clusterserviceclass                                                       |
      | o        | custom-columns=CLASSNAME:.metadata.name,EXTERNAL\ NAME:.spec.externalName |
    Then the output should contain "user-provided"
    """

    #Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Message.*The instance was provisioned successfully"
    """

    # Delete serviceinstance directly
    When I run the :delete client command with:
      | object_type       | serviceinstance |
      | object_name_or_id | ups-instance    |
    Then the step should succeed
    Given I wait for the resource "serviceinstance" named "ups-instance" to disappear within 60 seconds

    #Re-Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Message.*The instance was provisioned successfully"
    """

    # Create a servicebinding
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | servicebinding |
    Then the output should match "Message.*Injected bind result"
    """
    Given I check that the "my-secret" secret exists

    # Delete serviceinstance directly
    When I run the :delete client command with:
      | object_type       | serviceinstance |
      | object_name_or_id | ups-instance    |
    Then the step should succeed
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance |
    Then the output should match "DeprovisionBlockedByExistingCredentials.*ServiceBindings.*must be removed"
    """

    # Create the second servicebinding
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
      | p | BINDING_NAME=ups-binding-2                                                                               |
      | p | SECRET_NAME=my-secret-2                                                                                  |
    Then the step should fail
    And the output should match "forbidden: ServiceBinding.*nstance that is being deleted"

    # Delete servicebinding ups-binding
    When I run the :delete client command with:
      | object_type       | servicebinding |
      | object_name_or_id | ups-binding    |
    Then the step should succeed

    # Check ServiceInstance and ServiceBinding status after 6mins
    Given 360 seconds have passed
    And I wait for the resource "serviceinstance" named "ups-instance" to disappear
    And I wait for the resource "servicebinding" named "ups-binding" to disappear
    And I wait for the resource "secret" named "my-secret" to disappear

  # @author chezhang@redhat.com
  # @case_id OCP-15603
  @admin
  @destructive
  Scenario: Create/get/update/delete for ServiceInstance resource
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard

    # Deploy ups broker
    Given I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | clusterservicebroker |
      | object_name_or_id | ups-broker           |
    the step should succeed
    """
    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should contain "Successfully fetched catalog entries from broker"
    When I run the :get client command with:
      | resource | clusterserviceclass                                                       |
      | o        | custom-columns=CLASSNAME:.metadata.name,EXTERNAL\ NAME:.spec.externalName |
    Then the output should contain "user-provided"
    """

    #Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Message.*The instance was provisioned successfully"
    """

    #Update serviceinstance
    When I run the :patch client command with:
      | resource | serviceinstance/ups-instance                    |
      | p        | {"metadata":{"labels":{"app":"test-instance"}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource   | serviceinstance/ups-instance |
      | show_label | true                         |
    Then the output should contain "app=test-instance"

    #Delete serviceinstance
    When I run the :delete client command with:
      | object_type       | serviceinstance |
      | object_name_or_id | ups-instance    |
    Then the step should succeed
    And I ensure "ups-instance" serviceinstance is deleted

  # @author chezhang@redhat.com
  # @case_id OCP-15605
  @admin
  @destructive
  Scenario: Create/get/update/delete for ServiceBinding resource
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard

    # Deploy ups broker
    Given I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | clusterservicebroker |
      | object_name_or_id | ups-broker           |
    the step should succeed
    """
    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should contain "Successfully fetched catalog entries from broker"
    When I run the :get client command with:
      | resource | clusterserviceclass                                                       |
      | o        | custom-columns=CLASSNAME:.metadata.name,EXTERNAL\ NAME:.spec.externalName |
    Then the output should contain "user-provided"
    """

    #Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Message.*The instance was provisioned successfully"
    """

    # Create servicebinding
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed
    Given I check that the "my-secret" secret exists
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | servicebinding |
    Then the output should match "Message.*Injected bind result"
    """

    #Update servicebinding
    When I run the :patch client command with:
      | resource | servicebinding/ups-binding                     |
      | p        | {"metadata":{"labels":{"app":"test-binding"}}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource   | servicebinding/ups-binding |
      | show_label | true                       |
    Then the output should contain "app=test-binding"

    # Delete servicebinding
    When I run the :delete client command with:
      | object_type       | servicebinding |
      | object_name_or_id | ups-binding    |
    Then the step should succeed
    Given I ensure "ups-binding" servicebinding is deleted
    And I wait for the resource "secret" named "my-secret" to disappear within 60 seconds

  # @author chezhang@redhat.com
  # @case_id OCP-15592
  @admin
  @destructive
  Scenario: Use generation instead of checksum for ClusterServiceBroker/ServiceBinding
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard

    # Deploy ups broker
    Given I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | clusterservicebroker |
      | object_name_or_id | ups-broker           |
    the step should succeed
    """
    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should contain "Successfully fetched catalog entries from broker"
    When I run the :get client command with:
      | resource | clusterserviceclass                                                       |
      | o        | custom-columns=CLASSNAME:.metadata.name,EXTERNAL\ NAME:.spec.externalName |
    Then the output should contain "user-provided"
    """

    #Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Message.*The instance was provisioned successfully"
    """

    # Check yaml of clusterservicebroker
    When I run the :get admin command with:
      | resource | clusterservicebroker/ups-broker |
      | o        | yaml                            |
    Then the output should not contain "checksum"
    And the output should contain:
      | generation: 1           |
      | reconciledGeneration: 1 |

    #Check yaml of clusterservicebroker again after update clusterservicebroker to invalid url
    When I run the :patch admin command with:
      | resource | clusterservicebroker/ups-broker                                                          |
      | p        | {"spec":{"url": "http://testups-broker.<%= cb.ups_broker_project %>.svc.cluster.local"}} |
    Then the step should succeed
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource | clusterservicebroker/ups-broker |
      | o        | yaml                            |
    Then the output should not contain "checksum"
    And the output should contain:
      | generation: 2           |
      | reconciledGeneration: 1 |
    """

    # Create servicebinding and check yaml of servicebinding
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | servicebinding/ups-binding |
      | o        | yaml                       |
    Then the output should not contain "checksum"
    And the output should contain:
      | generation: 1           |
      | reconciledGeneration: 0 |
    """

    #Check yaml of clusterservicebroker again after update clusterservicebroker to valid url
    When I run the :patch admin command with:
      | resource | clusterservicebroker/ups-broker                                                      |
      | p        | {"spec":{"url": "http://ups-broker.<%= cb.ups_broker_project %>.svc.cluster.local"}} |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource | clusterservicebroker/ups-broker |
      | o        | yaml                            |
    Then the output should not contain "checksum"
    And the output should contain:
      | generation: 3           |
      | reconciledGeneration: 3 |
    """

    # Create servicebinding and check yaml of servicebinding
    When I wait up to 300 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | servicebinding/ups-binding |
      | o        | yaml                       |
    Then the output should not contain "checksum"
    And the output should contain:
      | generation: 1           |
      | reconciledGeneration: 1 |
    """

  # @author chezhang@redhat.com
  # @case_id OCP-15907
  @admin
  @destructive
  Scenario: Check servicebinding status information about in-progress and completed operations
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard

    # Deploy ups broker
    Given I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | clusterservicebroker |
      | object_name_or_id | ups-broker           |
    the step should succeed
    """
    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should contain "Successfully fetched catalog entries from broker"
    When I run the :get client command with:
      | resource | clusterserviceclass                                                       |
      | o        | custom-columns=CLASSNAME:.metadata.name,EXTERNAL\ NAME:.spec.externalName |
    Then the output should contain "user-provided"
    """

    #Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Message.*The instance was provisioned successfully"
    """

    # Create servicebinding and Check yaml of servicebinding
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed
    Given I check that the "my-secret" secret exists
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | servicebinding/ups-binding |
    Then the output by order should match:
      | Message:\\s+Injected bind result |
      | Reason:\\s+InjectedBindResult    |
      | Status:\\s+True                  |
      | Type:\\s+Ready                   |
      | External Properties              |
      | User Info                        |
      | Groups                           |
      | UID                              |
      | Username                         |
    """

  # @author chezhang@redhat.com
  # @case_id OCP-16413
  @admin
  @destructive
  Scenario: Use generation instead of checksum for ServiceInstance
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And the "ansible-service-broker" cluster service broker is recreated after scenario
    And I save the first service broker registry prefix to :prefix clipboard
    And I switch to the first user
    Given I have a project
    # Provision DB apb
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                |
      | p | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-postgresql-apb                                                          |
      | p | PLAN_EXTERNAL_NAME=dev                                                                                       |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                       |
      | p | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-postgresql-apb").uid(user: user)` is stored in the :db_uid clipboard
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml      |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                                       |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                                |
      | p | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.5","postgresql_password":"test"} |
      | p | UID=<%= cb.db_uid %>                                                                                                         |
      | n | <%= project.name %>                                                                                                          |
    Then the step should succeed
    # Check instance yaml while provisioning
    When I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | serviceinstance/<%= cb.prefix %>-postgresql-apb |
      | o        | yaml                                            |
    Then the output should contain:
      | generation: 1           |
      | reason: Provisioning    |
      | reconciledGeneration: 0 |
    """

    # Check instance yaml when provision succeed
    Given I wait for the "<%= cb.prefix %>-postgresql-apb" service_instance to become ready up to 360 seconds
    And dc with name matching /postgresql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deployment=<%= cb.dc_1.first.name %>-1 |

    When I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | serviceinstance/<%= cb.prefix %>-postgresql-apb |
      | o        | yaml                                            |
    Then the output should contain:
      | generation: 1                   |
      | reason: ProvisionedSuccessfully |
      | reconciledGeneration: 1         |
    """

    # Update spec.url of clusterservicebroker to a to a invalid value
    When I run the :patch admin command with:
      | resource | clusterservicebroker/ansible-service-broker                                                          |
      | p        | {"spec":{"url": "https://testasb.ansible-service-broker.svc:1338/ansible-service-broker"}} |
    Then the step should succeed

    # update plan of serviceinstance to "prod"
    When I run the :patch client command with:
      | resource | serviceinstance/<%= cb.prefix %>-postgresql-apb     |
      | p        | {"spec":{"clusterServicePlanExternalName": "prod"}} |
    Then the step should succeed
    
    # Check instance yaml when provision updating fail 
    When I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | serviceinstance/<%= cb.prefix %>-postgresql-apb |
      | o        | yaml                                            |
    Then the output by order should match:
      | generation: 2                        |
      | message.*The update call failed      |
      | reason: ErrorCallingUpdateInstance   |
      | currentOperation: Update             |
      | externalProperties                   |
      | clusterServicePlanExternalID         |
      | clusterServicePlanExternalName: dev  |
      | parameters                           |
      | userInfo                             |
      | inProgressProperties:                |
      | clusterServicePlanExternalID         |
      | clusterServicePlanExternalName: prod |
      | parameters                           |
      | userInfo                             |
      | reconciledGeneration: 1              |
    """
    # Update spec.url of clusterservicebroker to a to a valid value
    When I run the :patch admin command with:
      | resource | clusterservicebroker/ansible-service-broker                                                      |
      | p        | {"spec":{"url": "https://asb.ansible-service-broker.svc:1338/ansible-service-broker"}} |
    Then the step should succeed
    
    # Check instance yaml when provision updating
    When I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | serviceinstance/<%= cb.prefix %>-postgresql-apb |
      | o        | yaml                                            |
    Then the output by order should match:
      | generation: 2                                         |
      | message.*The instance is being updated asynchronously |
      | reason: UpdatingInstance                              |
      | status: "False"                                       |
      | currentOperation: Update                              |
      | externalProperties                                    |
      | clusterServicePlanExternalID                          |
      | clusterServicePlanExternalName: dev                   |
      | parameters                                            |
      | userInfo                                              |
      | inProgressProperties:                                 |
      | clusterServicePlanExternalID                          |
      | clusterServicePlanExternalName: prod                  |
      | parameters                                            |
      | userInfo                                              |
      | reconciledGeneration: 1                               |
    """
   
    # Check instance yaml when provision updated succeed
    Given I wait for the resource "dc" named "<%= cb.dc_1.first.name %>" to disappear within 360 seconds
    Given I wait for the "<%= cb.prefix %>-postgresql-apb" service_instance to become ready up to 240 seconds
    And dc with name matching /postgresql/ are stored in the :dc_2 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_2.first.name %> |

    When I wait up to 300 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | serviceinstance/<%= cb.prefix %>-postgresql-apb |
      | o        | yaml                                            |
    Then the output should contain:
      | generation: 2                                      |
      | message: The instance was updated successfully     |
      | reason: InstanceUpdatedSuccessfully                |
      | status: "True"                                     |
      | externalProperties                                 |
      | clusterServicePlanExternalID                       |
      | clusterServicePlanExternalName: prod               |
      | parameters                                         |
      | userInfo                                           |
      | reconciledGeneration: 2                            |
    """

  # @author chezhang@redhat.com
  # @case_id OCP-16646
  @admin
  @destructive
  Scenario: ServiceBinding should be deleted succeed while broker not started
    Given I have a project
    Given admin ensures "ups-broker" clusterservicebroker is deleted after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-3.7.yaml |
    Then the step should succeed
    #Provision a serviceinstance
    Given I switch to the first user
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= project.name %>                                                                       |
    Then the step should succeed
    And I check that the "ups-instance" serviceinstance exists

    # Create servicebinding and Check yaml of servicebinding
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= project.name %>                                                                      |
    Then the step should succeed
    Given I check that the "ups-binding" servicebinding exists
    And I ensure "ups-binding" servicebinding is deleted
    And I ensure "ups-instance" serviceinstance is deleted

  # @author chezhang@redhat.com
  # @case_id OCP-16644
  @admin
  @destructive
  Scenario: ServiceBinding should be deleted succeed while bind to a unbindable clusterserviceclass
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard
    Given admin ensures "ups-broker" clusterservicebroker is deleted after scenario
    Then I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should contain "Successfully fetched catalog entries from broker"
    """
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['user-provided-service'].name` is stored in the :class_id clipboard
    Given I successfully patch resource "clusterserviceclass/<%= cb.class_id %>" with:
      | spec:\n  bindable: false |

    #Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait for the "ups-instance" service_instance to become ready up to 60 seconds

    # Create servicebinding and Check yaml of servicebinding
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed
    Given I check that the "ups-binding" servicebinding exists
    And I ensure "ups-binding" servicebinding is deleted
    And I ensure "ups-instance" serviceinstance is deleted

  # @author chezhang@redhat.com
  # @case_id OCP-18595
  @admin
  @destructive
  Scenario: Serviceinstance/Servicebinding/UserProject can be deleted after lost broker
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard
    Given admin ensures "ups-broker" clusterservicebroker is deleted after scenario
    Then I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should contain "Successfully fetched catalog entries from broker"
    """
    Given I ensure "ups-broker" deployment is deleted
    And I switch to the first user
    And I use the "<%= cb.user_project %>" project
    And I register clean-up steps:
    """
    I run the :patch client command with:
      | resource | serviceinstance/ups-instance     |
      | p        | {"metadata":{"finalizers":null}} |
      | n        | <%= cb.user_project %>           |
    the step should succeed
    I ensure "ups-instance" serviceinstance is deleted
    """
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
Then the step should succeed
    Given I check that the "ups-instance" serviceinstance exists
    And I check that the "ups-binding" servicebinding exists
    And I ensure "ups-binding" servicebinding is deleted
    When I run the :delete client command with:
      | wait              | false           |
      | object_type       | serviceinstance |
      | object_name_or_id | ups-instance    |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance |
    Then the output should match "DeprovisionCallFailed"
    """

  # @author chezhang@redhat.com
  # @case_id OCP-15921
  @admin
  @destructive
  Scenario: Controller should give up retry after a timeout configured on the controller
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard

    # Update daemonset/controller-manager in kube-service-catalog project
    Given I switch to cluster admin pseudo user
    And I use the "kube-service-catalog" project
    And the "ansible-service-broker" cluster service broker is recreated after scenario
    And the "controller-manager" daemonset is recreated by admin in the "kube-service-catalog" project after scenario
    When I run the :patch client command with:
      | resource | daemonset/controller-manager |
      | type     | json                         |
      | p        | [{"op": "add", "path": "/spec/template/spec/containers/0/args/1", "value": "--reconciliation-retry-duration"}, {"op": "add", "path": "/spec/template/spec/containers/0/args/2", "value": "30s"} ] |
    Then the step should succeed
    And "controller-manager" daemonset becomes ready in the "kube-service-catalog" project

    # Deploy ups-broker
    Given admin ensures "ups-broker" clusterservicebroker is deleted after scenario
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should contain "Successfully fetched catalog entries from broker"
    """

    # Provision serviceinstance/servicebinding by TCs
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    And I register clean-up steps:
    """
    I run the :patch client command with:
      | resource | servicebinding/ups-binding       |
      | p        | {"metadata":{"finalizers":null}} |
      | n        | <%= cb.user_project %>           |
    the step should succeed
    I run the :patch client command with:
      | resource | serviceinstance/ups-instance     |
      | p        | {"metadata":{"finalizers":null}} |
      | n        | <%= cb.user_project %>           |
    the step should succeed
    I ensure "ups-binding" servicebinding is deleted
    I ensure "ups-instance" serviceinstance is deleted
    """
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait for the "ups-instance" service_instance to become ready up to 60 seconds
    When I run the :patch admin command with:
      | resource | clusterservicebroker/ups-broker                                                          |
      | p        | {"spec":{"url": "http://testups-broker.<%= cb.ups_broker_project %>.svc.cluster.local"}} |
    Then the step should succeed
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed

    # check "ErrorReconciliationRetryTimeout" event in description
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe admin command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should match "ErrorReconciliationRetryTimeout.*Stopping reconciliation retries"
    When I run the :describe client command with:
      | resource | servicebinding/ups-binding |
    Then the output should match "ErrorReconciliationRetryTimeout.*Stopping reconciliation retries"
    """
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
      | p | INSTANCE_NAME=ups-instance-1                                                                              |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance-1 |
    Then the output should match "ErrorReconciliationRetryTimeout.*Stopping reconciliation retries"
    """
    And I ensure "ups-instance-1" serviceinstance is deleted

  # @author zitang@redhat.com
  # @case_id OCP-18847
  @admin
  @destructive
  Scenario: [svc-catalog] controller doesn't send multiple provision/deprovison/etc requests to ups-broker  
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard
   
    Given admin ensures "user-provided" cluster_service_class is deleted after scenario 
    Given admin ensures "ups-broker" cluster_service_broker is deleted after scenario

    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    Given I wait for the "ups-broker" cluster_service_broker to become ready up to 120 seconds
    Given cluster service classes are indexed by external name in the :csc clipboard
    And the expression should be true> cb.csc["user-provided-service"]!=nil

    #Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait for all service_instance in the project to become ready up to 60 seconds
    And evaluation of `service_instance.external_id` is stored in the :instance_id clipboard
    # Create servicebinding
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed
    Given I check that the "my-secret" secret exists
    And I wait for the "ups-binding" service_binding to become ready up to 60 seconds
    And evaluation of `service_binding.external_id` is stored in the :binding_id clipboard

    # Delete the resources
    Given I ensure "ups-binding" service_binding is deleted
    And I ensure "ups-instance" service_instance is deleted
    Then I wait for the resource "secret" named "my-secret" to disappear within 60 seconds
    
    #check the ups-broker  pod log 
    When I switch to cluster admin pseudo user
    And I run the :logs client command with:
      | resource_name | deployment/ups-broker        |
      | n             | <%= cb.ups_broker_project %> |
      | since         | 3m                           |
    Then the step should succeed
    And the output should match 1 times:
      | \s+CreateServiceInstance <%= cb.instance_id %> |
      | \s+Bind.*<%= cb.binding_id %>            |
      | \s+UnBind.*<%= cb.binding_id %>                |
      | \s+RemoveServiceInstance <%= cb.instance_id %>  | 


  # @author qwang@redhat.com
  # @case_id OCP-16458
  @admin
  @destructive
  Scenario: A user who has access to get the auth secret can create a broker resource successfully
    # 1. Login as an ordinary user1
    Given I have a project
    Given secret with name matching /default-token-.*/ are stored in the :secret1 clipboard
    # 2. Login as system admin, create broker role
    Given I switch to cluster admin pseudo user
    And admin ensures "clusterservicebroker-admin" cluster_role is deleted after scenario
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/broker-role.yaml
    Then the step should succeed
    # 3. Add role to the ordinary user1
    When I run the :oadm_policy_add_cluster_role_to_user admin command with:
      | role_name | clusterservicebroker-admin |
      | user_name | <%= user(0).name %>        |
    Then the step should succeed
    When I run the :oadm_policy_who_can admin command with:
      | verb     |  create                |
      | resource |  clusterservicebrokers |
    Then the step should succeed
    And the output should match:
      | <%= user(0).name %> |
    # 4. Verify user1 has access to its auth secret, so user1 can create a broker
    Given I switch to the first user
    When I run the :policy_can_i client command with:
      | verb         | create                |
      | resource     | clusterservicebrokers |
    Then the step should succeed
    And the output should contain "yes"
    And I ensure "abroker" cluster_service_broker is deleted after scenario
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/broker.yaml" replacing paths:
      | ["spec"]["authInfo"]["bearer"]["secretRef"]["namespace"] | <%= project.name %> |
      | ["spec"]["authInfo"]["bearer"]["secretRef"]["name"]      | <%= cb.secret1.first.name %>  |
    Then the step should succeed
    # 5. Login as another ordinary user2
    Given I switch to the second user
    When I run the :new_project client command with:
      | project_name | atestproject2 |
    Then the step should succeed
    Given secret in the "atestproject2" project with name matching /default-token-.*/ are stored in the :secret2 clipboard
    # 6. Verify user1 doesn't have access to user2's auth secret, so user1 can't create a broker with user2's auth secret
    Given I switch to the first user
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/broker.yaml" replacing paths:
      | ["metadata"]["name"]                                     | bbroker            |
      | ["spec"]["authInfo"]["bearer"]["secretRef"]["namespace"] | atestproject2      |
      | ["spec"]["authInfo"]["bearer"]["secretRef"]["name"]      | <%= cb.secret2.first.name %> |
    Then the step should fail
    And the output should contain:
      | clusterservicebrokers.servicecatalog.k8s.io "bbroker" is forbidden: broker forbidden access to auth secret (<%= cb.secret2.first.name %>) |
 

  # @author qwang@redhat.com
  # @case_id OCP-16460
  @admin
  @destructive 
  Scenario: A user who has access to get the auth secret can upate a broker resource successfully
    # 1. Login as an ordinary user1
    Given I have a project
    Given secret with name matching /default-token-.*/ are stored in the :secret1 clipboard
    # 2. Login as system admin, create broker role
    Given I switch to cluster admin pseudo user
    And admin ensures "clusterservicebroker-admin" cluster_role is deleted after scenario
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/broker-role.yaml
    Then the step should succeed
    # 3. Add role to the ordinary user1
    When I run the :oadm_policy_add_cluster_role_to_user admin command with:
      | role_name | clusterservicebroker-admin |
      | user_name | <%= user(0).name %>        |
    Then the step should succeed
    When I run the :oadm_policy_who_can admin command with:
      | verb     |  create                |
      | resource |  clusterservicebrokers |
    Then the step should succeed
    And the output should match:
      | <%= user(0).name %> |
    # 4. Verify user1 has access to its auth secret, so user1 can create a broker
    Given I switch to the first user
    When I run the :policy_can_i client command with:
      | verb         | create                |
      | resource     | clusterservicebrokers |
    Then the step should succeed
    And the output should contain "yes"
    And I ensure "abroker" cluster_service_broker is deleted after scenario
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/broker.yaml" replacing paths:
      | ["spec"]["authInfo"]["bearer"]["secretRef"]["namespace"] | <%= project.name %> |
      | ["spec"]["authInfo"]["bearer"]["secretRef"]["name"]      | <%= cb.secret1.first.name %>  |
    Then the step should succeed
    # 5. User1 update the broker with user1's another secret
    When I run the :policy_can_i client command with:
      | verb         | update                |
      | resource     | clusterservicebrokers |
    Then the step should succeed
    And the output should contain "yes"
    When I run the :patch client command with:
      | resource | clusterservicebrokers/abroker                                                 |
      | p        | {"spec":{"authInfo":{"bearer":{"secretRef":{"name": "<%= cb.secret1.last.name %>"}}}}} |
      | n        | <%= project.name %>                                                           |
    Then the step should succeed
    # 5. Login as another ordinary user2
    Given I switch to the second user
    When I run the :new_project client command with:
      | project_name | atestproject2 |
    Then the step should succeed
    Given secret in the "atestproject2" project with name matching /default-token-.*/ are stored in the :secret2 clipboard
    # 6. User1 update the broker with user2's secret 
    Given I switch to the first user
    When I run the :patch client command with:
      | resource | clusterservicebrokers/abroker                                                                              |
      | p        | {"spec":{"authInfo":{"bearer":{"secretRef":{"namespace": "atestproject2","name": "<%= cb.secret2.first.name %>"}}}}} |
      | n        | <%= project.name %>                                                                                        |
    Then the step should fail
    And the output should contain:
      | clusterservicebrokers.servicecatalog.k8s.io "abroker" is forbidden: broker forbidden access to auth secret (<%= cb.secret2.first.name %>) |

  # @author jiazha@redhat.com
  # @case_id OCP-16418
  @admin
  @destructive
  Scenario: Orphan mitigation for instances
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard 
    Given I switch to cluster admin pseudo user
    Given admin ensures "ups-broker" cluster_service_broker is deleted after scenario
    Given admin ensures "user-provided" cluster_service_class is deleted after scenario

    # Set up the ups-broker
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    Given I wait for the "ups-broker" cluster_service_broker to become ready up to 60 seconds

    # Changed the instance return code to 205
    And a pod becomes ready with labels:
      | app=ups-broker |
    When I run the :patch client command with:
      | resource | deployment/ups-broker |
      | p        | {"spec": {"template": {"spec": {"containers": [{"args": ["--alsologtostderr", "--port", "8080", "--provision", "205"], "name": "ups-broker", "image": "docker.io/aosqe/user-broker:latest"}]}}}} |
    Then the step should succeed
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | app=ups-broker |

    # Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed

    # Check the logs, 205 is an orphan resource
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Deprovision Status:             Succeeded"
    """
    And I ensure "ups-instance" service_instance is deleted

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project

    And I run the :logs client command with:
      | resource_name | deployment/ups-broker          |
      | since         | 3m                             |
    Then the step should succeed
    And the output should match:
      | createServiceInstance operation, the fake status code is: 205 |
      | CreateServiceInstance()                                       |
      | RemoveServiceInstance()                                       |
      | removeServiceInstance operation, the fake status code is: 200 |

    # Changed the instance return code to 408
    Given pod with name matching /ups-broker/ are stored in the :pod clipboard
    When I run the :patch client command with:
      | resource | deployment/ups-broker  |
      | p        | {"spec": {"template": {"spec": {"containers": [{"args": ["--alsologtostderr", "--port", "8080", "--provision", "408"], "name": "ups-broker"}]}}}} |
    Then the step should succeed
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | app=ups-broker |
      
    # Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed

    # Check the logs, 408 is NOT an orphan resource
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Deprovision Status:      NotRequired"
    """
    And I ensure "ups-instance" service_instance is deleted

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project

    And I run the :logs client command with:
      | resource_name | deployment/ups-broker          |
      | since         | 3m                             |
    Then the step should succeed
    And the output should match:
      | createServiceInstance operation, the fake status code is: 408 |
      | CreateServiceInstance()                                       |
    And the output should not match:
      | RemoveServiceInstance()                                       |
      | removeServiceInstance operation, the fake status code is: 200 |

    # Changed the instance return code to 500
    Given pod with name matching /ups-broker/ are stored in the :pod clipboard
    When I run the :patch client command with:
      | resource | deployment/ups-broker  |
      | p        | {"spec": {"template": {"spec": {"containers": [{"args": ["--alsologtostderr", "--port", "8080", "--provision", "500"], "name": "ups-broker"}]}}}} |
    Then the step should succeed
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | app=ups-broker |
      
    # Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed

    # Check the logs, 500 is an orphan resource
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Deprovision Status:             Succeeded"
    """
    And I ensure "ups-instance" service_instance is deleted

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project

    And I run the :logs client command with:
      | resource_name | deployment/ups-broker          |
      | since         | 3m                             |
    Then the step should succeed
    And the output should match:
      | createServiceInstance operation, the fake status code is: 500 |
      | CreateServiceInstance()                                       |
      | RemoveServiceInstance()                                       |
      | removeServiceInstance operation, the fake status code is: 200 |

  # @author jiazha@redhat.com
  # @case_id OCP-16420
  @admin
  @destructive
  Scenario: Orphan mitigation for bindings
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard 
    Given I switch to cluster admin pseudo user
    Given admin ensures "ups-broker" cluster_service_broker is deleted after scenario
    Given admin ensures "user-provided" cluster_service_class is deleted after scenario

    # Set up the ups-broker
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    Given I wait for the "ups-broker" cluster_service_broker to become ready up to 60 seconds

    # Changed the bind return code to 205
    And a pod becomes ready with labels:
      | app=ups-broker |
    When I run the :patch client command with:
      | resource | deployment/ups-broker |
      | p        | {"spec": {"template": {"spec": {"containers": [{"args": ["--alsologtostderr", "--port", "8080", "--bind", "205"], "name": "ups-broker", "image": "docker.io/aosqe/user-broker:latest"}]}}}} |
    Then the step should succeed
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | app=ups-broker |

    # Provision a serviceinstance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait for all service_instance in the project to become ready up to 60 seconds

    # Create a servicebinding
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project

    # Check the logs, 205 is an orphan resource
    And I run the :logs client command with:
      | resource_name | deployment/ups-broker          |
      | since         | 3m                             |
    Then the step should succeed
    And the output should match:
      | bind operation, the fake status code is: 205   |
      | Unbind operation, the fake status code is: 200 |

    # Delete servicebinding
    Given I use the "<%= cb.user_project %>" project
    And I ensure "ups-binding" service_binding is deleted
    
    # Changed the bind return code to 408
    Given I use the "<%= cb.ups_broker_project %>" project
    Given pod with name matching /ups-broker/ are stored in the :pod clipboard
    When I run the :patch client command with:
      | resource | deployment/ups-broker  |
      | p        | {"spec": {"template": {"spec": {"containers": [{"args": ["--alsologtostderr", "--port", "8080", "--bind", "408"], "name": "ups-broker"}]}}}} |
    Then the step should succeed
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | app=ups-broker |
    
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    # Create a servicebinding
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed

    # Check the logs, 408 is not orphan resource
    Given I switch to cluster admin pseudo user
    Given I use the "<%= cb.ups_broker_project %>" project
    And I run the :logs client command with:
      | resource_name | deployment/ups-broker          |
      | since         | 3m                             |
    Then the step should succeed
    And the output should match:
      | bind operation, the fake status code is: 408   |
    And the output should not match:
      | Unbind operation, the fake status code is: 200 |

    # Delete servicebinding
    Given I use the "<%= cb.user_project %>" project
    And I ensure "ups-binding" service_binding is deleted

    # Changed the bind return code to 500
    Given I use the "<%= cb.ups_broker_project %>" project
    When I run the :patch client command with:
      | resource | deployment/ups-broker  |
      | p        | {"spec": {"template": {"spec": {"containers": [{"args": ["--alsologtostderr", "--port", "8080", "--bind", "500"], "name": "ups-broker"}]}}}} |
    Then the step should succeed
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | app=ups-broker |

    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    # Create a servicebinding
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed

    # Check the logs, 500 is an orphan resource
    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    And I run the :logs client command with:
      | resource_name | deployment/ups-broker          |
      | since         | 3m                             |
    Then the step should succeed
    And the output should match:
      | bind operation, the fake status code is: 500   |
      | Unbind operation, the fake status code is: 200 |

    # Delete servicebinding and serviceinstance
    Given I use the "<%= cb.user_project %>" project
    And I ensure "ups-binding" service_binding is deleted
    And I ensure "ups-instance" service_instance is deleted
    
  # @author jiazha@redhat.com
  # @case_id OCP-18822
  @admin
  Scenario: [catalog] Better credentials remapping
    Given I have a project
    # Get the registry name from the configmap
    Given I save the first service broker registry prefix to :prefix clipboard
    # need to swtich back to normal user mode
    
    # Provision DB apb
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                               |
      | p | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-postgresql-apb                         |
      | p | PLAN_EXTERNAL_NAME=dev                                                      |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                      |
      | p | INSTANCE_NAMESPACE=<%= project.name %>                                      |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-postgresql-apb").uid(user: user)` is stored in the :db_uid clipboard
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml        |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                                         |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                                  |
      | p | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.5","postgresql_password":"test"}   |
      | p | UID=<%= cb.db_uid %>                                                                                                           |
      | n | <%= project.name %>                                                                                                            |
    Then the step should succeed
    And I wait for all service_instance in the project to become ready up to 360 seconds
    And dc with name matching /postgresql/ are stored in the :db clipboard
    And a pod becomes ready with labels:
      | deployment=<%= cb.db.first.name %>-1 |

    # string key
    Given a "bind1.yaml" file is created with the following lines:
    """
    ---
    apiVersion: servicecatalog.k8s.io/v1beta1
    kind: ServiceBinding
    metadata:
      name: bind1
      namespace: <%= project.name %>
    spec:
      instanceRef:
        name: <%= cb.prefix %>-postgresql-apb
      secretTransforms:
      - addKey:
          key: "test1"
          stringValue: "redhat"
    """

    When I run the :create client command with:
      | f | bind1.yaml |
    Then the step should succeed
    And I wait for the "bind1" secret to appear up to 180 seconds
    Then the expression should be true> secret.value_of("test1") == "redhat"

    # base64 value key
    Given a "bind2.yaml" file is created with the following lines:
    """
    ---
    apiVersion: servicecatalog.k8s.io/v1beta1
    kind: ServiceBinding
    metadata:
      name: bind2
      namespace: <%= project.name %>
    spec:
      instanceRef:
        name: <%= cb.prefix %>-postgresql-apb
      secretTransforms:
      - addKey:
          key: "test2"
          value: amlhbg==
    """
    When I run the :create client command with:
      | f | bind2.yaml |
    Then the step should succeed
    And I wait for the "bind2" secret to appear up to 180 seconds
    Then the expression should be true> secret.value_of("test2") == "jian"
    
    # quote an exist secret
    Given a "bind3.yaml" file is created with the following lines:
    """
    ---
    apiVersion: servicecatalog.k8s.io/v1beta1
    kind: ServiceBinding
    metadata:
      name: bind3
      namespace: <%= project.name %>
    spec:
      instanceRef:
        name: <%= cb.prefix %>-postgresql-apb
      secretTransforms:
      - addKeysFrom:
          secretRef: 
            namespace: openshift-console
            name: console-oauth-config
    """
    When I run the :create client command with:
      | f | bind3.yaml |
    Then the step should succeed
    And I wait for the "bind3" secret to appear up to 180 seconds
    When I run the :get client command with:
      | resource      | secret |
      | resource_name | bind3  |
      | o             | yaml   |
    Then the step should succeed
    And the output should contain "DB_HOST"
    And the output should contain "DB_NAME"
    
    # quote a non-exist secret
    Given a "bind4.yaml" file is created with the following lines:
    """
    ---
    apiVersion: servicecatalog.k8s.io/v1beta1
    kind: ServiceBinding
    metadata:
      name: bind4
      namespace: <%= project.name %>
    spec:
      instanceRef:
        name: <%= cb.prefix %>-postgresql-apb
      secretTransforms:
      - addKeysFrom:
          secretRef: 
            namespace: default
            name: fake
    """
    When I run the :create client command with:
      | f | bind4.yaml |
    Then the step should succeed
    Then I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | servicebinding |
      | resource_name | bind4          |
      | o             | yaml           |
    Then the step should succeed
    And the output should contain "Error injecting bind result"
    """
    
    #  Merge the existing keys to the credential secret
    Given a "bind5.yaml" file is created with the following lines:
    """
    ---
    apiVersion: servicecatalog.k8s.io/v1beta1
    kind: ServiceBinding
    metadata:
      name: bind5
      namespace: <%= project.name %>
    spec:
      instanceRef:
        name: <%= cb.prefix %>-postgresql-apb
      secretTransforms:
      - addKey:
          key: "my-new-key"
          jsonPathExpression: "key one is {.DB_USER}, key two is {.DB_NAME}"
    """
    When I run the :create client command with:
      | f | bind5.yaml |
    Then the step should succeed
    And I wait for the "bind5" secret to appear up to 180 seconds
    Then the expression should be true> secret.value_of("my-new-key") == "key one is admin, key two is admin"
    
    #  Remove a key from the credential secret
    Given a "bind6.yaml" file is created with the following lines:
    """
    ---
    apiVersion: servicecatalog.k8s.io/v1beta1
    kind: ServiceBinding
    metadata:
      name: bind6
      namespace: <%= project.name %>
    spec:
      instanceRef:
        name: <%= cb.prefix %>-postgresql-apb
      secretTransforms:
      - removeKey:
          key: "DB_HOST"
      - removeKey:
          key: "DB_NAME"
    """
    When I run the :create client command with:
      | f | bind6.yaml |
    Then the step should succeed
    And I wait for the "bind6" secret to appear up to 180 seconds
    When I run the :get client command with:
      | resource      | secret |
      | resource_name | bind6  |
      | o             | yaml   |
    Then the step should succeed
    And the output should not contain "DB_HOST"
    And the output should not contain "DB_NAME"

    # Remove all servicebindings
    When I run the :delete client command with:
      | object_type       | servicebinding |
      | object_name_or_id | bind1 |
      | object_name_or_id | bind2 |
      | object_name_or_id | bind3 |
      | object_name_or_id | bind4 |
      | object_name_or_id | bind5 |
      | object_name_or_id | bind6 |
    Then the step should succeed

    And I wait for the resource "servicebinding" named "bind1" to disappear within 180 seconds
    And I wait for the resource "servicebinding" named "bind2" to disappear within 180 seconds
    And I wait for the resource "servicebinding" named "bind3" to disappear within 180 seconds
    And I wait for the resource "servicebinding" named "bind4" to disappear within 180 seconds
    And I wait for the resource "servicebinding" named "bind5" to disappear within 180 seconds
    And I wait for the resource "servicebinding" named "bind6" to disappear within 180 seconds

    And I wait for the resource "secret" named "bind1" to disappear within 180 seconds
    And I wait for the resource "secret" named "bind2" to disappear within 180 seconds
    And I wait for the resource "secret" named "bind3" to disappear within 180 seconds
    And I wait for the resource "secret" named "bind4" to disappear within 180 seconds
    And I wait for the resource "secret" named "bind5" to disappear within 180 seconds
    And I wait for the resource "secret" named "bind6" to disappear within 180 seconds

  # @author jiazha@redhat.com
  # @case_id OCP-18640
  @admin
  @destructive
  Scenario: [catalog] allow users to rename bind credential secret keys
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard
    And I create a new project
    And evaluation of `project.name` is stored in the :user_project clipboard
    Given I switch to cluster admin pseudo user
    Given admin ensures "ups-broker" cluster_service_broker is deleted after scenario
    Given admin ensures "user-provided" cluster_service_class is deleted after scenario

    # config the service-catalog
    And I use the "kube-service-catalog" project
    And a pod becomes ready with labels:
      | app=controller-manager |
    # Enable gate: ResponseSchema=true
    And the "controller-manager" daemonset is recreated by admin in the "kube-service-catalog" project after scenario
    When I run the :patch client command with:
      | resource | daemonset/controller-manager |
      | p        | {"spec": {"template": {"spec": {"containers": [{"args": ["controller-manager", "--secure-port", "6443", "-v", "3", "--leader-election-namespace", "kube-service-catalog", "--leader-elect-resource-lock", "configmaps", "--cluster-id-configmap-namespace=kube-service-catalog", "--broker-relist-interval", "5m", "--feature-gates", "OriginatingIdentity=true", "--feature-gates", "AsyncBindingOperations=true", "--feature-gates", "NamespacedServiceBroker=true", "--feature-gates", "ResponseSchema=true"], "name": "controller-manager"}]}}}} |
    Then the step should succeed
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | app=controller-manager |

    # Set up the ups-broker
    And I use the "<%= cb.ups_broker_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | p | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
    Then the step should succeed
    Given I wait for the "ups-broker" cluster_service_broker to become ready up to 60 seconds

    # Check this instance: user-provided-service-with-schema
    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterserviceplan/4dbcd97c-c9d2-4c6b-9503-4401a789b558 |
    Then the output should match "Service Binding Create Response Schema"
    """

    # Provision this instance
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                       |
      | param | CLASS_NAME=user-provided-service-with-schemas                                                             |
    Then the step should succeed
    And I wait for the "ups-instance" service_instance to become ready up to 60 seconds

    # Create a servicebinding
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                      |
      | p | SECRET_NAME=ups-secret                                                                                   |
    Then the step should succeed
    And I wait for the "ups-binding" service_binding to become ready up to 60 seconds

    # Check the generated secret
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | secret/ups-secret        |
      | o        | yaml                     |
    Then the output should match:
      | special-key-1: c3BlY2lhbC12YWx1ZS0x |
      | special-key-2: c3BlY2lhbC12YWx1ZS0y |
    """

    # Create a servicebinding by renaming one key
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-rename-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                             |
      | p | BINDING_NAME=ups-binding-1                                                                                      |
      | p | SECRET_NAME=ups-secret-1                                                                                        |
      | p | OLD_KEY_2=""                                                                                                    |
      | p | NEW_KEY_2=""                                                                                                    |
    Then the step should succeed
    And I wait for the "ups-binding-1" service_binding to become ready up to 60 seconds
    
    # Check the generated secret
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | secret/ups-secret-1      |
      | o        | yaml                     |
    Then the output should match:
      | test-key-1: c3BlY2lhbC12YWx1ZS0x    |
      | special-key-2: c3BlY2lhbC12YWx1ZS0y |
    """

    # Create a servicebinding by renaming one non-exist key
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-rename-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                             |
      | p | BINDING_NAME=ups-binding-2                                                                                      |
      | p | SECRET_NAME=ups-secret-2                                                                                        |
      | p | OLD_KEY_1=special-key-3                                                                                         |
      | p | NEW_KEY_1=test                                                                                                  |
      | p | OLD_KEY_2=                                                                                                      |
      | p | NEW_KEY_2=                                                                                                      |
    Then the step should succeed
    And I wait for the "ups-binding-2" service_binding to become ready up to 60 seconds
    
    # Check the generated secret
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | secret/ups-secret-2      |
      | o        | yaml                     |
    Then the output should match:
      | special-key-1: c3BlY2lhbC12YWx1ZS0x |
      | special-key-2: c3BlY2lhbC12YWx1ZS0y |
    Then the output should not match:
      | special-key-3: c3BlY2lhbC12YWx1ZS0x |
    """

    # Create a servicebinding by renaming multi keys
    When I process and create:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-rename-template.yaml |
      | p | USER_PROJECT=<%= cb.user_project %>                                                                             |
      | p | BINDING_NAME=ups-binding-3                                                                                      |
      | p | SECRET_NAME=ups-secret-3                                                                                        |
    Then the step should succeed
    And I wait for the "ups-binding-3" service_binding to become ready up to 60 seconds
    
    # Check the generated secret
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | secret/ups-secret-3   |
      | o        | yaml                  |
    Then the output should match:
      | test-key-1: c3BlY2lhbC12YWx1ZS0x |
      | test-key-2: c3BlY2lhbC12YWx1ZS0y |
    """

    # Delete all servicebinding
    When I run the :delete client command with:
      | object_type       | servicebinding |
      | object_name_or_id | ups-binding    |
      | object_name_or_id | ups-binding-1  |
      | object_name_or_id | ups-binding-2  |
      | object_name_or_id | ups-binding-3  |
    Then the step should succeed

    # Check related secrets
    When I run the :get client command with:
      | resource | secret                 |
    Then the output should not contain:
      | ups-secret                        |
      | ups-secret-1                      |
      | ups-secret-2                      |
      | ups-secret-3                      |

   And I ensure "ups-instance" service_instance is deleted

  # @author jiazha@redhat.com
  # @case_id OCP-19958
  @admin
  @destructive
  Scenario: Add a way to filter which service classes and plans are created for a cluster broker
    Given I switch to cluster admin pseudo user
    And the "ansible-service-broker" cluster service broker is recreated after scenario
    And I save the first service broker registry prefix to :prefix clipboard
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-mysql-apb'].name` is stored in the :class_id clipboard
    
    # filter: class spec.externalName ==
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                                                                 |
      | p        | {"spec": {"catalogRestrictions": {"serviceClass": ["spec.externalName==<%= cb.prefix %>-postgresql-apb"]}}} |
    Then the step should succeed

    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | clusterserviceclass  |
    Then the output should contain:
      | <%= cb.prefix %>-postgresql-apb |
      | ansible-service-broker          |
    Then the output should not contain:
      | <%= cb.prefix %>-mediawiki-apb  |
      | <%= cb.prefix %>-mysql-apb      |
      | <%= cb.prefix %>-mariadb-apb    |
    """

    # filter: class spec.externalName !=
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                                                                 |
      | p        | {"spec": {"catalogRestrictions": {"serviceClass": ["spec.externalName!=<%= cb.prefix %>-postgresql-apb"]}}} |
    Then the step should succeed

    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | clusterserviceclass  |
    Then the output should not contain:
      | <%= cb.prefix %>-postgresql-apb |
    Then the output should contain:
      | <%= cb.prefix %>-mediawiki-apb  |
      | <%= cb.prefix %>-mysql-apb      |
      | <%= cb.prefix %>-mariadb-apb    |
      | ansible-service-broker          |
    """

    # filter: plan spec.free != true
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                              |
      | p        | {"spec": {"catalogRestrictions": {"serviceClass": [], "servicePlan": ["spec.free!=true"]}}} |
    Then the step should succeed

    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | clusterserviceclass  |
    Then the output should contain:
      | <%= cb.prefix %>-mysql-apb      |
      | ansible-service-broker          |
    Then the output should not contain:
      | <%= cb.prefix %>-mediawiki-apb  |
      | <%= cb.prefix %>-postgresql-apb |
      | <%= cb.prefix %>-mariadb-apb    |
    When I run the :get client command with:
      | resource | clusterserviceplan   |
    Then the output should contain:
      | prod                            |
    """

    # filter: class spec.externalName in 
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                                                                                                      |
      | p        | {"spec": {"catalogRestrictions": {"serviceClass": ["spec.externalName in (<%= cb.prefix %>-mediawiki-apb, <%= cb.prefix %>-postgresql-apb)"], "servicePlan":[]}}} |
    Then the step should succeed

    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | clusterserviceclass  |
    Then the output should contain:
      | <%= cb.prefix %>-mediawiki-apb  |
      | <%= cb.prefix %>-postgresql-apb |
      | ansible-service-broker          |
    Then the output should not contain:
      | <%= cb.prefix %>-mysql-apb      |
      | <%= cb.prefix %>-mariadb-apb    |
    """

    # filter: class spec.externalName notin 
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                                                                  |
      | p        | {"spec": {"catalogRestrictions": {"serviceClass": ["spec.externalName notin (<%= cb.prefix %>-mediawiki-apb, <%= cb.prefix %>-postgresql-apb)"]}}} |
    Then the step should succeed

    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | clusterserviceclass  |
    Then the output should not contain:
      | <%= cb.prefix %>-mediawiki-apb  |
      | <%= cb.prefix %>-postgresql-apb |
    Then the output should contain:
      | <%= cb.prefix %>-mysql-apb      |
      | <%= cb.prefix %>-mariadb-apb    |
      | ansible-service-broker          |
    """

    # filter: plan spec.externalName notin/ spec.free true 
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                                                     |
      | p        | {"spec": {"catalogRestrictions": {"serviceClass": [], "servicePlan": ["spec.externalName notin (default, dev)", "spec.free==true"]}}} |
    Then the step should succeed

    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | clusterserviceclass  |
    Then the output should contain:
      | <%= cb.prefix %>-mariadb-apb    |
      | <%= cb.prefix %>-postgresql-apb |
      | ansible-service-broker          |
    Then the output should not contain:
      | <%= cb.prefix %>-mysql-apb      |
      | <%= cb.prefix %>-mediawiki-apb  |
    """

    # filter: plan spec.externalName notin/ spec.free true 
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                                                     |
      | p        | {"spec": {"catalogRestrictions": {"serviceClass": ["spec.externalName in (<%= cb.prefix %>-postgresql-apb)"], "servicePlan": ["spec.free==true"]}}} |
    Then the step should succeed

    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | clusterserviceclass  |
    Then the output should contain:
      | <%= cb.prefix %>-postgresql-apb |
      | ansible-service-broker          |
    Then the output should not contain:
      | <%= cb.prefix %>-mysql-apb      |
      | <%= cb.prefix %>-mediawiki-apb  |
      | <%= cb.prefix %>-mariadb-apb    |
    When I run the :get client command with:
      | resource | clusterserviceplan   |
    Then the output should contain 1 times:
      | prod                            |
      | dev                             |
    """

    # filter: plan spec.externalName notin/ spec.free true /spec.externalName
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                                                     |
      | p        | {"spec": {"catalogRestrictions": {"serviceClass": ["spec.externalName in (<%= cb.prefix %>-mysql-apb)"], "servicePlan": ["spec.free==true", "spec.externalName notin (dev)"]}}} |
    Then the step should succeed

    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | clusterserviceclass  |
    Then the output should not contain:
      | <%= cb.prefix %>-postgresql-apb |
      | <%= cb.prefix %>-mysql-apb      |
      | <%= cb.prefix %>-mediawiki-apb  |
      | <%= cb.prefix %>-mariadb-apb    |
    When I run the :get client command with:
      | resource | clusterserviceplan   |
    Then the output should not contain:
      | dev                             |
      | prod                            |
    """

    # filter non-exist service class/plans: class+plan
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                                                     |
      | p        | {"spec": {"catalogRestrictions": {"serviceClass": ["spec.externalName in (<%= cb.prefix %>-test-apb)"], "servicePlan": ["spec.externalName notin (dev, prod)"]}}} |
    Then the step should succeed

    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | clusterserviceclass  |
    Then the output should not contain:
      | ansible-service-broker          |
    """

    # filter non-supported property to filter class/plan
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                                  |
      | p        | {"spec": {"catalogRestrictions": {"serviceClass": ["spec.bindable==true"], "servicePlan": []}}} |
    Then the step should fail
    
    # filter spec.serviceClass.name
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                                                        |
      | p        | {"spec": {"catalogRestrictions": {"serviceClass": [], "servicePlan": ["spec.clusterServiceClass.name==<%= cb.class_id %>"]}}} |
    Then the step should succeed

    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | clusterserviceclass  |
    Then the output should contain:
      | <%= cb.prefix %>-mysql-apb      |
    Then the output should not contain:
      | <%= cb.prefix %>-postgresql-apb |
      | <%= cb.prefix %>-mediawiki-apb  |
      | <%= cb.prefix %>-mariadb-apb    |
    When I run the :get client command with:
      | resource | clusterserviceplan   |
    Then the output should contain 1 times:
      | prod                            |
      | dev                             |
    """
