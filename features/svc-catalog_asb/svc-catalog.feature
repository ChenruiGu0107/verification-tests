Feature: Service-catalog related scenarios
 
  # @author chezhang@redhat.com
  # @case_id OCP-15600
  @admin
  @destructive
  Scenario: service-catalog walkthrough example
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
    the step should fail
    """
    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | param | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Message.*The instance was provisioned successfully"
    """

    # Create servicebinding
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed
    Given I check that the "my-secret" secret exists
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | servicebinding |
    Then the output should match "Message.*Injected bind result"
    """

    # Delete servicebinding
    When I run the :delete client command with:
      | object_type       | servicebinding |
      | object_name_or_id | ups-binding    |
    Then the step should succeed
    Given I wait for the resource "servicebinding" named "ups-binding" to disappear within 60 seconds
    And I wait for the resource "secret" named "my-secret" to disappear within 60 seconds

    # Delete serviceinstance
    When I run the :delete client command with:
      | object_type       | serviceinstance |
      | object_name_or_id | ups-instance    |
    Then the step should succeed
    Given I wait for the resource "serviceinstance" named "ups-instance" to disappear within 60 seconds

    # Delete ups broker
    When I switch to cluster admin pseudo user
    When I run the :delete client command with:
      | object_type       | clusterservicebroker |
      | object_name_or_id | ups-broker           |
    Then the step should succeed
    And I wait for the resource "clusterservicebrokers" named "ups-broker" to disappear within 60 seconds
    When I run the :get client command with:
      | resource | clusterserviceclass                                                       |
      | o        | custom-columns=CLASSNAME:.metadata.name,EXTERNAL\ NAME:.spec.externalName |
    Then the output should not contain "user-provided"

  # @author chezhang@redhat.com
  # @case_id OCP-14833
  @admin
  Scenario: Confirm service-catalog image working well
    When I switch to cluster admin pseudo user
    And I use the "kube-service-catalog" project
    Given 1 pods become ready with labels:
      | app=apiserver |
    When I execute on the pod:
      | sh |
      | -c |
      | /usr/bin/service-catalog --version; /usr/bin/service-catalog --help |
    Then the output by order should match:
      | v[0-9].[0-9].[0-9] |
      | apiserver          |
      | controller-manager |
    Given 1 pods become ready with labels:
      | app=controller-manager |
    When I execute on the pod:
      | sh |
      | -c |
      | /usr/bin/service-catalog --version; /usr/bin/service-catalog --help |
    Then the output by order should match:
      | v[0-9].[0-9].[0-9] |
      | apiserver          |
      | controller-manager |
    Given I use the "openshift-ansible-service-broker" project
    And 1 pods become ready with labels:
      | app=openshift-ansible-service-broker |
    When I execute on the pod:
      | sh |
      | -c |
      | /usr/bin/asbd --version; /usr/bin/asbd --help |
    Then the output by order should match:
      | [0-9].[0-9].[0-9]   |
      | Application Options |
      | Help Options        |

  # @author chezhang@redhat.com
  # @case_id OCP-15604
  @admin
  @destructive
  Scenario: Create/get/update/delete for ClusterServiceBroker resource	
    Given I have a project
    And evaluation of `project.name` is stored in the :ups_broker_project clipboard

    # Deploy ups broker
    Given I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | clusterservicebroker |
      | object_name_or_id | ups-broker           |
    the step should fail
    """
    When I switch to cluster admin pseudo user
    And I use the "<%= cb.ups_broker_project %>" project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | param | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
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

    #Check yaml output of clusterservicebroker
    When I run the :get client command with:
      | resource | clusterservicebroker/ups-broker |
      | o        | yaml                            |
    Then the output should match:
      | kind:\\s+ClusterServiceBroker                                            |
      | generation                                                               |
      | name:\\s+ups-broker                                                      |
      | relistBehavior                                                           |
      | relistDuration                                                           |
      | relistRequests                                                           |
      | url:\\s+http://ups-broker.<%= cb.ups_broker_project %>.svc.cluster.local |
      | reconciledGeneration                                                     |

    #Update clusterservicebroker
    When I run the :patch client command with:
      | resource | clusterservicebroker/ups-broker                                                          |
      | p        | {"spec":{"url": "http://testups-broker.<%= cb.ups_broker_project %>.svc.cluster.local"}} |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should match "Error getting broker catalog.*testups-broker"
    """
    When I run the :patch client command with:
      | resource | clusterservicebroker/ups-broker                                                      |
      | p        | {"spec":{"url": "http://ups-broker.<%= cb.ups_broker_project %>.svc.cluster.local"}} |
    Then the step should succeed
    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should match "Message.*Successfully fetched catalog entries from broker"
    """

    # Delete ups broker
    When I switch to cluster admin pseudo user
    When I run the :delete admin command with:
      | object_type       | clusterservicebroker |
      | object_name_or_id | ups-broker           |
    Then the step should succeed
    And I wait for the resource "clusterservicebrokers" named "ups-broker" to disappear within 60 seconds
    When I run the :get client command with:
      | resource | clusterserviceclass                                                       |
      | o        | custom-columns=CLASSNAME:.metadata.name,EXTERNAL\ NAME:.spec.externalName |
    Then the output should not contain "user-provided"

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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | param | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Message.*The instance was provisioned successfully"
    """

    # Create two servicebindings
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                      |
      | param | BINDING_NAME=ups-binding-1                                                                               |
      | param | SECRET_NAME=my-secret-1                                                                                  |
    Then the step should succeed
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                      |
      | param | BINDING_NAME=ups-binding-2                                                                               |
      | param | SECRET_NAME=my-secret-2                                                                                  |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | param | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                       |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Message.*The instance was provisioned successfully"
    """

    # Create a servicebinding
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                      |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                      |
      | param | BINDING_NAME=ups-binding-2                                                                               |
      | param | SECRET_NAME=my-secret-2                                                                                  |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | param | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                       |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | param | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Message.*The instance was provisioned successfully"
    """

    # Create servicebinding
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                      |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | param | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                       |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed
    And I wait up to 10 seconds for the steps to pass:
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
    And I wait up to 10 seconds for the steps to pass:
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | param | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance/ups-instance |
    Then the output should match "Message.*The instance was provisioned successfully"
    """

    # Create servicebinding and Check yaml of servicebinding
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                      |
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
  # @case_id OCP-15602
  @admin
  @destructive
  Scenario: Create/get/update/delete for Clusterserviceclass/Clusterserviceplan resource
    Given I have a project

    # Deploy ups broker
    Given admin ensures "ups-broker" clusterservicebroker is deleted after scenario

    When I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | param | UPS_BROKER_PROJECT=<%= project.name %>                                                                  |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | clusterservicebroker/ups-broker |
    Then the output should contain "Successfully fetched catalog entries from broker"
    """
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['user-provided-service'].name` is stored in the :class_id clipboard

    # Check clusterserviceclass yaml
    When I run the :get client command with:
      | resource | clusterserviceclass/<%= cb.class_id %> |
      | o        | yaml                                   |
    Then the output should match:
      | bindable                                |
      | clusterServiceBrokerName:\\s+ups-broker |
      | description                             |
      | externalID                              |
      | externalName                            |
      | planUpdatable                           |

    # Check clusterserviceplan yaml
    When I run the :get client command with:
      | resource | clusterserviceplan                                                                                                 |
      | o        | custom-columns=NAME:.metadata.name,CLASS\ NAME:.spec.clusterServiceClassRef.name,EXTERNAL\ NAME:.spec.externalName |
    Then the output should contain "<%= cb.class_id %>"
    And evaluation of `cluster_service_class(cb.class_id).plans.first.name` is stored in the :plan_id clipboard
    When I run the :get client command with:
      | resource | clusterserviceplan/<%= cb.plan_id %> |
      | o        | yaml                                 |
    Then the output should match:
      | clusterServiceBrokerName:\\s+ups-broker |
      | clusterServiceClassRef                  |
      | description                             |
      | externalID                              |
      | externalName                            |
      | free                                    |

    # Update clusterserviceclasses and clusterserviceplans
    Given I successfully patch resource "clusterserviceclass/<%= cb.class_id %>" with:
      | {"metadata":{"labels":{"app":"test-class"}}} |
    And I successfully patch resource "clusterserviceplan/<%= cb.plan_id %>" with:
      | {"metadata":{"labels":{"app":"test-plan"}}} |

    # Delete the clusterserviceclass/clusterserviceplan/clusterservicebroker
    Given I ensures "<%= cb.class_id %>" clusterserviceclasses is deleted
    And I ensures "<%= cb.plan_id %>" clusterserviceplans is deleted
    And I ensures "ups-broker" clusterservicebroker is deleted
    When I run the :get client command with:
      | resource | clusterserviceclass                                        |
      | o        | custom-columns=BROKER\ NAME:.spec.clusterServiceBrokerName |
    Then the output should not contain "ups-broker"
    When I run the :get client command with:
      | resource | clusterserviceplan                                         |
      | o        | custom-columns=BROKER\ NAME:.spec.clusterServiceBrokerName |
    Then the output should not contain "ups-broker"

  # @author chezhang@redhat.com
  # @case_id OCP-16413
  @admin
  @destructive
  Scenario: Use generation instead of checksum for ServiceInstance
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And the "ansible-service-broker" cluster service broker is recreated
    And I save the first service broker registry prefix to :prefix clipboard
    And I switch to the first user
    Given I have a project
    # Provision DB apb
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                |
      | param | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-postgresql-apb                                                          |
      | param | PLAN_EXTERNAL_NAME=dev                                                                                       |
      | param | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                       |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-postgresql-apb").uid(user: user)` is stored in the :db_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml      |
      | param | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                                       |
      | param | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                                |
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.5","postgresql_password":"test"} |
      | param | UID=<%= cb.db_uid %>                                                                                                         |
      | n     | <%= project.name %>                                                                                                          |
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
    Given a pod becomes ready with labels:
      | app=rhscl-postgresql-apb |
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
      | p        | {"spec":{"url": "https://testasb.openshift-ansible-service-broker.svc:1338/ansible-service-broker"}} |
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
      | p        | {"spec":{"url": "https://asb.openshift-ansible-service-broker.svc:1338/ansible-service-broker"}} |
    Then the step should succeed

    # Check instance yaml when provision updating
    When I wait up to 120 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | serviceinstance/<%= cb.prefix %>-postgresql-apb |
      | o        | yaml                                            |
    Then the output by order should contain:
      | generation: 2                                         |
      | message: The instance is being updated asynchronously |
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
    Given a pod becomes ready with labels:
      | app=rhscl-postgresql-apb |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | param | USER_PROJECT=<%= project.name %>                                                                       |
    Then the step should succeed
    And I check that the "ups-instance" serviceinstance exists

    # Create servicebinding and Check yaml of servicebinding
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | param | USER_PROJECT=<%= project.name %>                                                                      |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-broker-template.yaml |
      | param | UPS_BROKER_PROJECT=<%= cb.ups_broker_project %>                                                         |
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
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-instance-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                       |
    Then the step should succeed
    And I wait for the "ups-instance" service_instance to become ready up to 60 seconds

    # Create servicebinding and Check yaml of servicebinding
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/ups-binding-template.yaml |
      | param | USER_PROJECT=<%= cb.user_project %>                                                                      |
    Then the step should succeed
    Given I check that the "ups-binding" servicebinding exists
    And I ensure "ups-binding" servicebinding is deleted
And I ensure "ups-instance" serviceinstance is deleted
