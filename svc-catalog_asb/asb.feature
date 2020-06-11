Feature: Ansible-service-broker related scenarios
  # @author zitang@redhat.com
  # @case_id OCP-15358
  @admin
  @destructive
  Scenario: ASB should support bootstrap on startup
    Given  I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project

    Given the "ansible-service-broker" cluster service broker is recreated after scenario
    And admin redeploys "asb" dc after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario

     # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    registry:
      - type: rhcc
        name: rhcc
        url: wrongregistry.access.stage.redhat.com
        fail_on_error: true
    broker:
      bootstrap_on_startup: false
    """
    And admin redeploys "asb" dc
    When I run the :logs client command with:
      | resource_name | dc/asb          |
      | c             | asb     |
      | since         | 3m              |
    Then the step should succeed
    And the output should contain:
      | Ansible Service Broker Starting |
    And the output should not contain:
      | AnsibleBroker::Bootstrap      |

    #Update configmap
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    broker:
      bootstrap_on_startup: true
    """
    When I run the :rollout_latest client command with:
      | resource      | dc/asb          |
    Then the step should succeed
    Then status becomes :failed of 1 pods labeled:
      | deploymentconfig=asb            |
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | dc/asb          |
      | c             | asb     |
      | since         | 3m              |
    Then the step should succeed
    And the output should contain:
      | AnsibleBroker::Bootstrap      |
   """

  # @author zhsun@redhat.com
  @admin
  Scenario Outline: [ASB] The serviceinstaces/servicebinddings should be deleted after deleted project
    Given I save the first service broker registry prefix to :prefix clipboard
    Given I have a project
    Given I obtain test data file "svc-catalog/serviceinstance-template.yaml"
    When I process and create:
      | f | serviceinstance-template.yaml |
      | p | INSTANCE_NAME=<db_name>                               |
      | p | CLASS_EXTERNAL_NAME=<db_name>                         |
      | p | PLAN_EXTERNAL_NAME=<db_plan>                          |
      | p | SECRET_NAME=<db_secret_name>                          |
      | p | INSTANCE_NAMESPACE=<%= project.name %>                |
    Then the step should succeed
    And evaluation of `service_instance("<db_name>").uid` is stored in the :db_uid clipboard

    Given I obtain test data file "svc-catalog/serviceinstance-parameters-template.yaml"
    When I process and create:
      | f | serviceinstance-parameters-template.yaml |
      | p | SECRET_NAME=<db_secret_name>                                                                                            |
      | p | INSTANCE_NAME=<db_name>                                                                                                 |
      | p | PARAMETERS=<db_parameters>                                                                                              |
      | p | UID=<%= cb.db_uid %>                                                                                            |
      | n | <%= project.name %>                                                                                                     |
    Then the step should succeed
    Given I wait for the "<db_name>" service_instance to become ready up to 300 seconds
    And dc with name matching /mysql/ are stored in the :dc_1 clipboard

    # DB apbs provision succeed
    Given a pod becomes ready with labels:
      | app=<db_label>            |

    And I wait up to 80 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance                            |
    Then the step should succeed
    And the output should match:
      | Message:\\s+The instance was provisioned successfully |
    """

   # Create servicebinding of DB apb
    Given I obtain test data file "svc-catalog/servicebinding-template.yaml"
   When I process and create:
      | f | servicebinding-template.yaml |
      | p | BINDING_NAME=<db_name>                                                                                      |
      | p | INSTANCE_NAME=<db_name>                                                                                     |
      | p | SECRET_NAME=<db_credentials>                                                                                |
      | n | <%= project.name %>                                                                                         |
    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | servicebinding                 |
    Then the output should match:
      | Message:\\s+Injected bind result          |
    """

    Given I ensure "<%= project.name %>" project is deleted
    And I wait up to 20 seconds for the steps to pass:
    """
    And admin check that there are no serviceinstance in the "<%= project.name %>" project
    And admin check that there are no servicebinding in the "<%= project.name %>" project
    """

    Examples:
      | db_name                         | db_credentials                              | db_plan | db_secret_name                             | db_parameters                                                                                                            | db_label                   |
      | <%= cb.prefix %>-mysql-apb      | <%= cb.prefix %>-mysql-apb-credentials      |  dev    | <%= cb.prefix %>-mysql-apb-parameters      | {"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.7","service_name":"mysql","mysql_password":"test"}     | <%= cb.dc_1.first.name %>  | # @case_id OCP-16661


  # @author zitang@redhat.com
  # @case_id OCP-16137
  @admin
  @destructive
  Scenario: [ASB] Ansible-service-broker check APBs version correctly
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project

    Given the "ansible-service-broker" cluster service broker is recreated after scenario
    Given admin redeploys "asb" dc after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario
    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    registry:
      - type: rhcc
        name: rh
        url:  https://registry.access.redhat.com
        org:
        tag:  v3.6
        white_list: [.*-apb$]
    """
    When admin redeploys "asb" dc
    And I run the :logs client command with:
      | resource_name | dc/asb          |
      | c             | asb     |
      | since         | 3m              |
    Then the step should succeed
    And the output should match:
      |  failed validation for the following reason:.*version |

  # @author zitang@redhat.com
  # @case_id OCP-18648
  @admin
  @destructive
  Scenario: [ASB] check apb bundle resource in crd when asb refresh
    Given cluster service classes are indexed by external name in the :csc clipboard
    Then the expression should be true> cb.csc.values.find {|c| c.cluster_svc_broker_name == "ansible-service-broker"}

    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project

    Given the "ansible-service-broker" cluster service broker is recreated after scenario
    Given admin redeploys "asb" dc after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario

    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    "broker":
      "refresh_interval": 90s
    """
    And admin redeploys "asb" dc

    When bundles with qualified name matching /postgresql-apb/ are stored in the :psql clipboard
    And bundles with qualified name matching /mediawiki-apb/ are stored in the :mediawiki clipboard
    Then evaluation of `cb.psql.first.name` is stored in the :bundle_id_1 clipboard
    And evaluation of `cb.mediawiki.first.name` is stored in the :bundle_id_2 clipboard

    #delete two bundles
    And admin ensure "<%= cb.bundle_id_1 %>" bundle is deleted
    And admin ensure "<%= cb.bundle_id_2 %>" bundle is deleted

    # asb will refresh after 'refresh_interval' and the bundles will come back
    Given admin wait for the "<%= cb.bundle_id_1 %>" bundle to appear in the "openshift-ansible-service-broker" project up to 90 seconds
    And admin wait for the "<%= cb.bundle_id_2 %>" bundle to appear in the "openshift-ansible-service-broker" project

  # @author zitang@redhat.com
  # @case_id OCP-18690
  @admin
  Scenario: [ASB] check crd resource bundlebindings.automationbroker.io
    Given I save the first service broker registry prefix to :prefix clipboard
    #provision mariadb
    Given I have a project
    And evaluation of `project.name` is stored in the :project_1 clipboard
    Given I obtain test data file "svc-catalog/serviceinstance-template.yaml"
    When I process and create:
      | f | serviceinstance-template.yaml |
      | p | INSTANCE_NAME=<%= cb.prefix %>-mariadb-apb                                                                   |
      | p | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-mariadb-apb                                                             |
      | p | PLAN_EXTERNAL_NAME=dev                                                                                       |
      | p | SECRET_NAME=<%= cb.prefix %>-mariadb-apb-parameters                                                          |
      | p | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-mariadb-apb").uid` is stored in the :db_uid clipboard
    And evaluation of `service_instance.external_id` is stored in the :instance_id clipboard
    Given I obtain test data file "svc-catalog/serviceinstance-parameters-template.yaml"
    When I process and create:
      | f | serviceinstance-parameters-template.yaml                         |
      | p | SECRET_NAME=<%= cb.prefix %>-mariadb-apb-parameters                                                                                             |
      | p | INSTANCE_NAME=<%= cb.prefix %>-mariadb-apb                                                                                                      |
      | p | PARAMETERS={"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.2","mariadb_root_password":"test","mariadb_password":"test"}|
      | p | UID=<%= cb.db_uid %>                                                                                                                            |
      | n | <%= project.name %>                                                                                                                             |
    Then the step should succeed
    And I wait for the service_instance to become ready up to 240 seconds
    And dc with name matching /mariadb/ are stored in the :db clipboard
    And a pod becomes ready with labels:
      | deployment=<%= cb.db.first.name %>-1 |
    # Create servicebinding of DB apb
    Given I obtain test data file "svc-catalog/servicebinding-template.yaml"
    When I process and create:
      | f | servicebinding-template.yaml |
      | p | BINDING_NAME=<%= cb.prefix %>-mariadb-apb-binding-1                                                         |
      | p | INSTANCE_NAME=<%= cb.prefix %>-mariadb-apb                                                                  |
      | p | SECRET_NAME=<%= cb.prefix %>-mariadb-apb-credentials-1                                                      |
      | n | <%= project.name %>                                                                                         |
    And I wait for the "<%= cb.prefix %>-mariadb-apb-binding-1" service_binding to become ready up to 120 seconds
    And evaluation of `service_binding.external_id` is stored in the :binding_id_1 clipboard
    #check bundlebinding
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    When I run the :describe client command with:
      | resource  | bundlebinding/<%= cb.binding_id_1 %>  |
    Then the step should succeed
    And the output by order should match:
      | Bundle Instance                    |
      |    Name:\\s+<%= cb.instance_id %>  |
      | Parameters                         |
    #create another 2 bindings
    Given I switch to the first user
    And I use the "<%= cb.project_1 %>" project
    Given I obtain test data file "svc-catalog/servicebinding-template.yaml"
    When I process and create:
      | f | servicebinding-template.yaml |
      | p | BINDING_NAME=<%= cb.prefix %>-mariadb-apb-binding-2                                                         |
      | p | INSTANCE_NAME=<%= cb.prefix %>-mariadb-apb                                                                  |
      | p | SECRET_NAME=<%= cb.prefix %>-mariadb-apb-credentials-2                                                      |
      | n | <%= project.name %>    |
    And I wait for the "<%= cb.prefix %>-mariadb-apb-binding-2" service_binding to become ready up to 120 seconds
    And evaluation of `service_binding.external_id` is stored in the :binding_id_2 clipboard
    Given I obtain test data file "svc-catalog/servicebinding-template.yaml"
    When I process and create:
      | f | servicebinding-template.yaml |
      | p | BINDING_NAME=<%= cb.prefix %>-mariadb-apb-binding-3                                                         |
      | p | INSTANCE_NAME=<%= cb.prefix %>-mariadb-apb                                                                  |
      | p | SECRET_NAME=<%= cb.prefix %>-mariadb-apb-credentials-3                                                      |
      | n  | <%= project.name %>    |
    And I wait for the "<%= cb.prefix %>-mariadb-apb-binding-3" service_binding to become ready up to 120 seconds
    And evaluation of `service_binding.external_id` is stored in the :binding_id_3 clipboard

    #check binding ref in bundeinstance
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    When I run the :describe client command with:
      | resource  | bundleinstance/<%= cb.instance_id %>  |
    Then the step should succeed
    And the output should contain:
      | <%= cb.binding_id_1 %>   |
      | <%= cb.binding_id_2 %>   |
      | <%= cb.binding_id_3 %>   |

    #delete 2 binding
    Given I switch to the first user
    And I use the "<%= cb.project_1 %>" project
    And I ensure "<%= cb.prefix %>-mariadb-apb-binding-1" service_binding is deleted
    And I ensure "<%= cb.prefix %>-mariadb-apb-binding-3" service_binding is deleted
    #check bundlebindings and binding  ref in bundeinstance
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And I wait for the resource "bundlebinding" named "<%= cb.binding_id_1 %>" to disappear within 60 seconds
    And I wait for the resource "bundlebinding" named "<%= cb.binding_id_3 %>" to disappear within 60 seconds
    When I run the :describe client command with:
      | resource  | bundleinstance/<%= cb.instance_id %>  |
    And the output should contain:
      | <%= cb.binding_id_2 %>    |
    And the output should not contain:
      | <%= cb.binding_id_1 %>    |
      | <%= cb.binding_id_3 %>    |
    #deprovision should succeed.
    Given I switch to the first user
    And I use the "<%= cb.project_1 %>" project
    And I ensure "<%= cb.prefix %>-mariadb-apb-binding-2" service_binding is deleted
    And I ensure "<%= cb.prefix %>-mariadb-apb" service_instance is deleted
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And I wait for the resource "bundlebinding" named "<%= cb.binding_id_2 %>" to disappear within 60 seconds
    And I wait for the resource "bundleinstance" named "<%= cb.instance_id %>" to disappear within 60 seconds


  # @author chezhang@redhat.com
  # @case_id OCP-18591
  @admin
  @destructive
  Scenario: Broker bootstrap succeed if one of the APB's contains bad base64 data
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    Given the "ansible-service-broker" cluster service broker is recreated after scenario
    Given I register clean-up steps:
    """
      I wait up to 150 seconds for the steps to pass:
        | When I run the :logs admin command with:                |
        | \| resource_name \| dc/asb \|                           |
        | \| c             \| asb     \|                                          |
        | \| namespace     \| openshift-ansible-service-broker\| |
        | Then the step should succeed                            |
        | And the output should contain "Broker successfully bootstrapped on startup" |
    """
    And the "asb" dc is recreated by admin in the "openshift-ansible-service-broker" project after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario

    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    registry:
      - type: dockerhub
        name: aosqe
        url: https://registry.hub.docker.com
        org:  aosqe
        tag:  latest
        white_list:
          - ".*-apb$"
    """
    And admin redeploys "asb" dc
    When I run the :logs client command with:
      | resource_name | dc/asb |
      | c             | asb     |
    Then the step should succeed
    And the output should match:
      | Failed to retrieve spec data for image.*illegal base64 data at input |

  # @author chezhang@redhat.com
  # @case_id OCP-19834
  @admin
  @destructive
  Scenario: Should not panic while using a invalid registry adapter
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    Given the "ansible-service-broker" cluster service broker is recreated after scenario
    Given I register clean-up steps:
    """
      I wait up to 150 seconds for the steps to pass:
        | When I run the :logs admin command with:                |
        | \| resource_name \| dc/asb \|                           |
        |      \| c             \| asb     \|                                   |
        | \| namespace     \| openshift-ansible-service-broker\| |
        | Then the step should succeed                            |
        | And the output should contain "Broker successfully bootstrapped on startup" |
    """
    And the "asb" dc is recreated by admin in the "openshift-ansible-service-broker" project after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario

    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    registry:
      - type: test
        name: test_name
    """
    When I run the :rollout_latest client command with:
      | resource | dc/asb |
    Then the step should succeed
    Then status becomes :failed of 1 pods labeled:
      | deployment=asb-2 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | pod/<%= pod.name %> |
      | c             |  asb   |
    Then the step should succeed
    And the output should match "Failed to initialize.*Registry err.*registry"
    And the output should not contain "panic"
    """

  # @author chezhang@redhat.com
  # @case_id OCP-20181
  @admin
  @destructive
  Scenario: User cannot use same username/passwd to provision mediawiki 3.11 or later
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And I save the first service broker registry prefix to :prefix clipboard

    # Checking clusterserviceplan of mediawiki
    And I switch to the first user
    Given I have a project
    And cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-mediawiki-apb'].name` is stored in the :mediawiki_class_id clipboard
    And evaluation of `cluster_service_class(cb.mediawiki_class_id).plans.first.name` is stored in the :mediawiki_plan_id clipboard
    When I run the :get client command with:
      | resource      | clusterserviceplan                                                                    |
      | resource_name | <%= cb.mediawiki_plan_id %>                                                           |
      | o             |  jsonpath={.spec.instanceCreateParameterSchema.properties.mediawiki_admin_user.title} |
    Then the output should match "Cannot be.*same.*as Admin User Password"

    # Provision mediawiki apb
    Given I obtain test data file "svc-catalog/serviceinstance-template.yaml"
    When I process and create:
      | f | serviceinstance-template.yaml |
      | p | INSTANCE_NAME=<%= cb.prefix %>-mediawiki-apb                                                                 |
      | p | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-mediawiki-apb                                                           |
      | p | SECRET_NAME=<%= cb.prefix %>-mediawiki-apb-parameters                                                        |
      | p | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance(cb.prefix + "-mediawiki-apb").uid` is stored in the :mediawiki_uid clipboard
    Given I obtain test data file "svc-catalog/serviceinstance-parameters-template.yaml"
    When I process and create:
      | f | serviceinstance-parameters-template.yaml                                                 |
      | p | SECRET_NAME=<%= cb.prefix %>-mediawiki-apb-parameters                                                                                                                   |
      | p | INSTANCE_NAME=<%= cb.prefix %>-mediawiki-apb                                                                                                                            |
      | p | PARAMETERS={"mediawiki_admin_user":"test","mediawiki_db_schema":"mediawiki","mediawiki_site_lang":"en","mediawiki_site_name":"MediaWiki","mediawiki_admin_pass":"test"} |
      | p | UID=<%= cb.mediawiki_uid %>                                                                                                                                             |
      | n | <%= project.name %>                                                                                                                                                     |
    Then the step should succeed

    Given I check that the "<%= cb.prefix %>-mediawiki-apb" serviceinstance exists
    And I check that the "<%= cb.prefix %>-mediawiki-apb-parameters" secret exists
    And I switch to cluster admin pseudo user
    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | project |
    Then evaluation of `@result[:stdout].scan(/#{cb.prefix}-mediawiki-apb-prov.*/)[0].split(" ")[0]` is stored in the :wiki_prov_prj clipboard
    """
    And admin ensure "<%= cb.wiki_prov_prj %>" project is deleted after scenario

    # Check log of sandbox pod
    Given I use the "<%= cb.wiki_prov_prj %>" project
    Given status becomes :failed of 1 pods labeled:
      | bundle-action=provision |
    And I wait up to 360 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | pod/<%= pod.name %> |
    Then the step should succeed
    And the output should contain "Mediawiki Admin User and Password cannot be the same value"
    """

  # @author zitang@redhat.com
  # @case_id OCP-20436
  @admin
  Scenario: [ASB] check apb dependencies
    Given I save the first service broker registry prefix to :prefix clipboard
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-mediawiki-apb']` is stored in the :media_wiki clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-mysql-apb']` is stored in the :mysql clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-postgresql-apb']` is stored in the :postgresql clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-mariadb-apb']` is stored in the :mariadb clipboard

    Then the expression should be true>  cb.mysql.dependencies.count { |e| e.start_with? 'registry.redhat.io/rhscl/mysql' } >= 1
    Then the expression should be true>  cb.mariadb.dependencies.count { |e| e.start_with? 'registry.redhat.io/rhscl/mariadb' } >= 2
    Then the expression should be true>  cb.postgresql.dependencies.count { |e| e.start_with? 'registry.redhat.io/rhscl/postgresql' } >= 3
    Then the expression should be true>  cb.media_wiki.dependencies.count { |e| e.start_with? 'registry.redhat.io/openshift3/mediawiki' } >= 1
