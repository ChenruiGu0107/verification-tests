Feature: Ansible-service-broker related scenarios

  # @author jiazha@redhat.com
  @admin
  @smoke
  Scenario Outline: Provison mediawiki & DB application
    Given I have a project
    And evaluation of `project.name` is stored in the :org_proj_name clipboard
    # Get the registry name from the configmap
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `YAML.load(config_map('broker-config').value_of('broker-config'))['registry'][0]['name']` is stored in the :prefix clipboard
    # need to swtich back to normal user mode
    And I switch to the first user
    And I use the "<%= cb.org_proj_name %>" project

    # Provision mediawiki apb
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mediawiki-apb          |
      | param | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-mediawiki-apb    |
      | param | SECRET_NAME=<%= cb.prefix %>-mediawiki-apb-parameters |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                |
    Then the step should succeed
    And evaluation of `service_instance(cb.prefix + "-mediawiki-apb").uid(user: user)` is stored in the :mediawiki_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<%= cb.prefix %>-mediawiki-apb-parameters |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mediawiki-apb          |
      | param | UID=<%= cb.mediawiki_uid %>                           |
      | n     | <%= project.name %>                                   |
    Then the step should succeed

    # Provision DB apb
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<db_name>                               |
      | param | CLASS_EXTERNAL_NAME=<db_name>                         |
      | param | PLAN_EXTERNAL_NAME=<db_plan>                          |
      | param | SECRET_NAME=<db_secret_name>                          |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                |
    Then the step should succeed
    And evaluation of `service_instance("<db_name>").uid(user: user)` is stored in the :db_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<db_secret_name>                                                                                            |
      | param | INSTANCE_NAME=<db_name>                                                                                                 |
      | param | PARAMETERS=<db_parameters>                                                                                              |
      | param | UID=<%= cb.db_uid %>                                                                                            |
      | n     | <%= project.name %>                                                                                                     |
    Then the step should succeed
    And I wait for all service_instance in the project to become ready up to 360 seconds

    Given dc with name matching /mediawiki/ are stored in the :app clipboard
    And a pod becomes ready with labels:
      | deployment=<%= cb.app.first.name %>-1 |
    And evaluation of `pod` is stored in the :app_pod clipboard
    And dc with name matching /<db_pattern>/ are stored in the :db clipboard

    And a pod becomes ready with labels:
      | deployment=<%= cb.db.first.name %>-1 |

    Then I wait up to 80 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance                            |
    Then the step should succeed
    And the output should match 2 times:
      | Message:\\s+The instance was provisioned successfully |
    """

    # Create servicebinding of DB apb
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/servicebinding-template.yaml |
      | param | BINDING_NAME=<db_name>                                                                                      |
      | param | INSTANCE_NAME=<db_name>                                                                                     |
      | param | SECRET_NAME=<db_credentials>                                                                                |
      | n     | <%= project.name %>                                                                                         |
    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | servicebinding                 |
    Then the output should match:
      | Message:\\s+Injected bind result          |
    """

    # Add credentials to mediawiki application
    When I run the :patch client command with:
      | resource      | dc                        |
      | resource_name | <%= cb.app.first.name %>  |
      | p             | {"spec":{"template":{"spec":{"containers":[{"envFrom": [ {"secretRef":{ "name": "<db_credentials>"}}],"name": "<%= cb.app_pod.containers.first.name %>"}]}}}} |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=<%= cb.app.first.name %>-2     |

    # Access mediawiki's route
    And I wait up to 60 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route(cb.app.first.name).dns %>/index.php/Main_Page" url
    And the output should match "MediaWiki has been(?: successfully)? installed"
    """

    # Delete the servicebinding
    When I run the :delete client command with:
      | object_type        | servicebinding       |
      | object_name_or_id  | <db_name>            |
      | n                  | <%= project.name %>  |
    Then the step should succeed
    Given I wait for the resource "secret" named "<db_credentials>" to disappear within 180 seconds
    And I wait for the resource "servicebinding" named "<db_name>" to disappear within 180 seconds

    # Delete the serviceinstance
    When I run the :delete client command with:
      | object_type       | serviceinstance                   |
      | object_name_or_id | <db_name>                         |
      | object_name_or_id | <%= cb.prefix %>-mediawiki-apb    |
      | n                 | <%= project.name %>               |
    Then the step should succeed
    When I wait for the resource "serviceinstance" named "<db_name>" to disappear within 300 seconds
    And I wait for the resource "serviceinstance" named "<%= cb.prefix %>-mediawiki-apb" to disappear within 300 seconds
    And I wait for the resource "secret" named "<%= cb.prefix %>-mediawiki-apb-parameters" to disappear within 120 seconds
    And I wait for the resource "secret" named "<db_secret_name>" to disappear within 120 seconds
    Then I check that there are no pods in the project
    And I check that there are no dc in the project
    And I check that there are no rc in the project
    And I check that there are no services in the project
    And I check that there are no routes in the project

    Examples:
      | db_name                         | db_credentials                              | db_plan | db_secret_name                             | db_parameters                                                                                                                         | db_pattern           |
      | <%= cb.prefix %>-postgresql-apb | <%= cb.prefix %>-postgresql-apb-credentials |  dev    | <%= cb.prefix %>-postgresql-apb-parameters | {"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.5","postgresql_password":"test"}                     | postgresql | # @case_id OCP-15648
      | <%= cb.prefix %>-postgresql-apb | <%= cb.prefix %>-postgresql-apb-credentials |  prod   | <%= cb.prefix %>-postgresql-apb-parameters | {"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.5","postgresql_password":"test"}                     | postgresql | # @case_id OCP-17363
      | <%= cb.prefix %>-mysql-apb      | <%= cb.prefix %>-mysql-apb-credentials      |  dev    | <%= cb.prefix %>-mysql-apb-parameters      | {"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.7","service_name":"mysql","mysql_password":"test"}                  | mysql      | # @case_id OCP-16071
      | <%= cb.prefix %>-mysql-apb      | <%= cb.prefix %>-mysql-apb-credentials      |  prod   | <%= cb.prefix %>-mysql-apb-parameters      | {"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.7","service_name":"mysql","mysql_password":"test"}                  | mysql      | # @case_id OCP-17361
      | <%= cb.prefix %>-mariadb-apb    | <%= cb.prefix %>-mariadb-apb-credentials    |  dev    | <%= cb.prefix %>-mariadb-apb-parameters    | {"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.2","mariadb_root_password":"test","mariadb_password":"test"} | mariadb    | # @case_id OCP-15350
      | <%= cb.prefix %>-mariadb-apb    | <%= cb.prefix %>-mariadb-apb-credentials    |  prod   | <%= cb.prefix %>-mariadb-apb-parameters    | {"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.2","mariadb_root_password":"test","mariadb_password":"test"} | mariadb    | # @case_id OCP-17362
      | <%= cb.prefix %>-mariadb-apb    | <%= cb.prefix %>-mariadb-apb-credentials    |  dev    | <%= cb.prefix %>-mariadb-apb-parameters    | {"mysql_database":"admin","mysql_user":"admin","mariadb_version":"10.2","mysql_root_password":"test","mysql_password":"test"}         | mariadb    | # @case_id OCP-18241
      | <%= cb.prefix %>-mariadb-apb    | <%= cb.prefix %>-mariadb-apb-credentials    |  prod   | <%= cb.prefix %>-mariadb-apb-parameters    | {"mysql_database":"admin","mysql_user":"admin","mariadb_version":"10.2","mysql_root_password":"test","mysql_password":"test"}         | mariadb    | # @case_id OCP-18240

  # @author zitang@redhat.com
  # @case_id OCP-15354
  @admin
  Scenario: Check multiple broker support for service catalog
    Given admin checks that the "ansible-service-broker" cluster_service_broker exists
    And admin checks that the "template-service-broker" cluster_service_broker exists

    #Check ansible-service-broker  and template-service-broker run successfully
    When I switch to cluster admin pseudo user
    And I run the :describe client command with:
      | resource | clusterservicebroker/ansible-service-broker   |
    Then the output should match "Message:\s+Successfully fetched catalog entries from broker"
    When I run the :describe client command with:
      | resource | clusterservicebroker/template-service-broker  |
    Then the output should match "Message:\s+Successfully fetched catalog entries from broker"

  # @author zitang@redhat.com
  # @case_id OCP-15395
  @admin
  Scenario: Check the ASB with bearer token authn
    #Get asb route and ansible service broker  client secret
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `secret('asb-client').token` is stored in the :token clipboard
    And evaluation of `route('asb-1338').dns` is stored in the :asbUrl clipboard

    #Access the ASB api with valid token
    Given I switch to the first user
    And I have a project
    And I have a pod-for-ping in the project
    When I execute on the pod:
      | curl                                                       |
      | -H                                                         |
      | Authorization: Bearer <%= cb.token %>                      |
      | -sk                                                        |
      | https://<%= cb.asbUrl %>/ansible-service-broker/v2/catalog |
    Then the output should contain:
      | services      |
      | mediawiki-apb |
      | postgresql-apb |
      | mysql-apb |
      | mariadb-apb |
    #Access the ASB api with invalid token
     When I execute on the pod:
      | curl                                                       |
      | -H                                                         |
      | Authorization: Bearer XXXXXXXXXXXX                         |
      | -sk                                                        |
      | https://<%= cb.asbUrl %>/ansible-service-broker/v2/catalog |
    Then the output should contain "Unauthorized"

  # @author zitang@redhat.com
  # @case_id OCP-15972
  @admin
  Scenario: Support for APB dependencies and providerDisplayName
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `YAML.load(config_map('broker-config').value_of('broker-config'))['registry'][0]['name']` is stored in the :prefix clipboard

    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-mediawiki-apb']` is stored in the :media_wiki clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-mysql-apb']` is stored in the :mysql clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-postgresql-apb']` is stored in the :postgresql clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-mariadb-apb']` is stored in the :mariadb clipboard

    Then the expression should be true>  cb.mysql.dependencies.count { |e| e.start_with? 'registry.access.redhat.com/rhscl/mysql' } >= 2
    Then the expression should be true>  cb.mariadb.dependencies.count { |e| e.start_with? 'registry.access.redhat.com/rhscl/mariadb' } >= 2
    Then the expression should be true>  cb.postgresql.dependencies.count { |e| e.start_with? 'registry.access.redhat.com/rhscl/postgresql' } >= 2
    Then the expression should be true>  cb.media_wiki.dependencies.count { |e| e.start_with? 'registry.access.redhat.com/openshift3/mediawiki' } >= 1
    #check provider
    Then the expression should be true> cb.media_wiki.provider_display_name  == "Red Hat, Inc."
    Then the expression should be true> cb.mysql.provider_display_name  == "Red Hat, Inc."
    Then the expression should be true> cb.postgresql.provider_display_name  == "Red Hat, Inc."
    Then the expression should be true> cb.mariadb.provider_display_name  == "Red Hat, Inc."

    #Check dependencies and providerDisplayName in oc describe client classId
    When I run the :describe client command with:
      | resource  | clusterserviceclass           |
      | name        | <%= cb.media_wiki.name%>    |
      | name        | <%= cb.mysql.name%>         |
      | name        | <%= cb.postgresql.name%>    |
      | name        | <%= cb.mariadb.name%>       |
    Then the expression should be true> @result[:response].scan('registry.access.redhat.com/rhscl/mysql').length >= 2
    And the expression should be true> @result[:response].scan('registry.access.redhat.com/rhscl/mariadb').length >= 2
    And the expression should be true> @result[:response].scan('registry.access.redhat.com/rhscl/postgresql').length >= 2
    And the expression should be true> @result[:response].scan('registry.access.redhat.com/openshift3/mediawiki').length >= 1
    And the output should match 4 times:
      | Provider\s*Display\s*Name:\s*Red Hat, Inc.     |


  # @author jiazha@redhat.com
  # @case_id OCP-15878
  @admin
  @destructive
  Scenario: [ASB] Check asb bootstrap/catalog work fine
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    Given evaluation of `route("asb-1338").dns` is stored in the :asb_route clipboard
    And evaluation of `secret("asb-client").token` is stored in the :asb_token clipboard

    When I perform the HTTP request:
    """
    :url: https://<%= cb.asb_route %>/ansible-service-broker/v2/bootstrap
    :method: post
    :headers:
      :Authorization: Bearer <%= cb.asb_token %>
    """
    Then the step should succeed
    Then the output should contain "spec_count"
    And the output should not contain "0,"

    When I perform the HTTP request:
    """
    :url: https://<%= cb.asb_route %>/ansible-service-broker/v2/catalog
    :method: get
    :headers:
      :Authorization: Bearer <%= cb.asb_token %>
    """
    Then the output should match:
      | services                                                        |
      | name.*apb                                                       |
      | description                                                     |

  # @author zitang@redhat.com
  # @case_id OCP-18465
  @admin
  @destructive
  Scenario: [ASB]Check v3.7 APB binding succeed in v3.9 env
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    Given the "ansible-service-broker" cluster service broker is recreated
    And admin redeploys "asb" dc after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario
    # Update the configmap settings
    Given value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    registry:
      - type: rhcc
        name: old
        url:  https://registry.access.redhat.com
        org:
        tag:  v3.7
        white_list: [.*-apb$]
    """
    And admin redeploys "asb" dc
    #update clustserserviceclass
    When I run the :patch admin command with:
      | resource | clusterservicebroker/ansible-service-broker |
      |  p       | {                                           |
      |          |  "spec": {                                  |
      |          |    "relistDuration": "5m1s"                 |
      |          |  }                                          |
      |          |}                                            |
     Then the step should succeed
    #provision v3.7
    Given I switch to the first user
    And I have a project
    # Provision mediawiki apb
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=old-mediawiki-apb                       |
      | param | CLASS_EXTERNAL_NAME=old-mediawiki-apb                 |
      | param | SECRET_NAME=old-mediawiki-apb-parameters              |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                |
    Then the step should succeed
    And evaluation of `service_instance("old-mediawiki-apb").uid` is stored in the :mediawiki_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=old-mediawiki-apb-parameters              |
      | param | INSTANCE_NAME=old-mediawiki-apb                       |
      | param | UID=<%= cb.mediawiki_uid %>                           |
      | n     | <%= project.name %>                                   |
    Then the step should succeed

    # Provision DB apb
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=old-postgresql-apb                               |
      | param | CLASS_EXTERNAL_NAME=old-postgresql-apb                         |
      | param | PLAN_EXTERNAL_NAME=dev                                         |
      | param | SECRET_NAME=old-postgresql-apb-parameters                      |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                         |
    Then the step should succeed
    And evaluation of `service_instance("old-postgresql-apb").uid` is stored in the :db_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml     |
      | param | SECRET_NAME=old-postgresql-apb-parameters                                                                                   |
      | param | INSTANCE_NAME=old-postgresql-apb                                                                                            |
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.5","postgresql_password":"test"}|
      | param | UID=<%= cb.db_uid %>                                                                                                        |
      | n     | <%= project.name %>                                                                                                         |
    Then the step should succeed
    # mediawiki and DB apbs provision succeed
    Given a pod becomes ready with labels:
      | deployment=mediawiki123-1 |
    Given a pod becomes ready with labels:
      | app=rhscl-postgresql-apb  |
    Given I wait for the "old-postgresql-apb" service_instance to become ready up to 180 seconds
    Given I wait for the "old-mediawiki-apb" service_instance to become ready up to 180 seconds

    # Create servicebinding of DB apb
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/servicebinding-template.yaml |
      | param | BINDING_NAME=old-postgresql-apb                                                                             |
      | param | INSTANCE_NAME=old-postgresql-apb                                                                            |
      | param | SECRET_NAME=old-postgresql-apb-credentials                                                                  |
      | n     | <%= project.name %>                                                                                         |
    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | servicebinding |
    Then the output should match:
      | Message:\\s+Injected bind result |
    """
    # Add credentials to mediawiki application
    When I run the :patch client command with:
      | resource      | dc                                                        |
      | resource_name | mediawiki123                                              |
      | p             | {                                                         |
      |               |  "spec": {                                                |
      |               |    "template": {                                          |
      |               |      "spec": {                                            |
      |               |        "containers": [                                    |
      |               |          {                                                |
      |               |            "envFrom": [                                   |
      |               |              {                                            |
      |               |                "secretRef": {                             |
      |               |                  "name": "old-postgresql-apb-credentials" |
      |               |                }                                          |
      |               |              }                                            |
      |               |            ],                                             |
      |               |            "name": "mediawiki123"                         |
      |               |          }                                                |
      |               |        ]                                                  |
      |               |      }                                                    |
      |               |    }                                                      |
      |               |  }                                                        |
      |               |}                                                          |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=mediawiki123-2                 |

    # Access mediawiki's route
    And I wait up to 60 seconds for the steps to pass:
    """
    Then I wait up to 60 seconds for a web server to become available via the "mediawiki123" route
    And the output should contain "MediaWiki has been successfully installed"
    """

  # @author zitang@redhat.com
  # @case_id OCP-15358
  @admin
  @destructive
  Scenario: ASB should support bootstrap on startup
    Given  I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project

    Given the "ansible-service-broker" cluster service broker is recreated
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
      | since         | 3m              |
    Then the step should succeed
    And the output should contain:
      | AnsibleBroker::Bootstrap      |
   """

  # @author zitang@redhat.com
  # @case_id OCP-17148
  @admin
  @destructive
  Scenario: [ASB]Check APB binding in different process to extract credentials
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project

    Given the "ansible-service-broker" cluster service broker is recreated
    And admin redeploys "asb" dc after scenario
    And the "broker-config" configmap is recreated by admin in the "openshift-ansible-service-broker" project after scenario

    Given evaluation of `YAML.load(config_map('broker-config').value_of('broker-config'))['registry'][0]['name']` is stored in the :prefix clipboard
    #Given I save the first service broker registry prefix to :prefix clipboard
    #Update configmap
    When value of "broker-config" in configmap "broker-config" as YAML is merged with:
    """
    openshift:
      keep_namespace: true
    """
    And admin redeploys "asb" dc
    Given I switch to the first user
    And I have a project
    And evaluation of `project.name` is stored in the :project_1 clipboard
     # Provision mediawiki apb
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mediawiki-apb          |
      | param | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-mediawiki-apb    |
      | param | SECRET_NAME=<%= cb.prefix %>-mediawiki-apb-parameters |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                |
    Then the step should succeed
    And evaluation of `service_instance(cb.prefix + "-mediawiki-apb").uid` is stored in the :mediawiki_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<%= cb.prefix %>-mediawiki-apb-parameters |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mediawiki-apb          |
      | param | UID=<%= cb.mediawiki_uid %>                           |
      | n     | <%= project.name %>                                   |
    Then the step should succeed
    #provision postgresql apb
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                |
      | param | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-postgresql-apb                                                          |
      | param | PLAN_EXTERNAL_NAME=dev                                                                                       |
      | param | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                       |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-postgresql-apb").uid` is stored in the :db_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml      |
      | param | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                                       |
      | param | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                                |
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.5","postgresql_password":"test"} |
      | param | UID=<%= cb.db_uid %>                                                                                                         |
      | n     | <%= project.name %>                                                                                                          |
    Then the step should succeed

    And I wait for all service_instance in the project to become ready up to 360 seconds
    Given dc with name matching /mediawiki/ are stored in the :app clipboard
    And a pod becomes ready with labels:
      | deployment=<%= cb.app.first.name %>-1 |
    And evaluation of `pod` is stored in the :app_pod clipboard
    And dc with name matching /postgresql/ are stored in the :db clipboard
    And a pod becomes ready with labels:
      | deployment=<%= cb.db.first.name %>-1 |

    #check the provision sandbox
    Given I switch to cluster admin pseudo user
    When I run the :get client command with:
      | resource | project |
    Then evaluation of `@result[:stdout].scan(/#{cb.prefix}-postgresql-apb.*/)[0].split(" ")[0]` is stored in the :db_prov_prj clipboard
    Then evaluation of `@result[:stdout].scan(/#{cb.prefix}-mediawiki-apb.*/)[0].split(" ")[0]` is stored in the :wiki_prov_prj clipboard
    Given admin ensure "<%= cb.db_prov_prj %>" project is deleted after scenario
    And admin ensure "<%= cb.wiki_prov_prj %>" project is deleted after scenario
    And I use the "<%= cb.db_prov_prj %>" project
    When I run the :get client command with:
      | resource | secret |
    Then the output should contain 1 times:
      | Opaque |
    Given I switch to the first user
    And I use the "<%= cb.project_1 %>" project
    # Create servicebinding of DB apb
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/servicebinding-template.yaml |
      | param | BINDING_NAME=<%= cb.prefix %>-postgresql-apb                                                                |
      | param | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                               |
      | param | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-credentials                                                     |
      | n     | <%= project.name %>                                                                                         |
    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | servicebinding                 |
    Then the output should match:
      | Message:\\s+Injected bind result  |
    """
    # Add credentials to mediawiki application
    When I run the :patch client command with:
      | resource      | dc                                                                     |
      | resource_name | <%= cb.app.first.name %>                        |
      | p             | {                                                                      |
      |               |  "spec": {                                                             |
      |               |    "template": {                                                       |
      |               |      "spec": {                                                         |
      |               |        "containers": [                                                 |
      |               |          {                                                             |
      |               |            "envFrom": [                                                |
      |               |              {                                                         |
      |               |                "secretRef": {                                          |
      |               |                  "name": "<%= cb.prefix %>-postgresql-apb-credentials" |
      |               |                }                                                       |
      |               |              }                                                         |
      |               |            ],                                                          |
      |               |            "name": "<%= cb.app_pod.containers.first.name %>"         |
      |               |          }                                                             |
      |               |        ]                                                               |
      |               |      }                                                                 |
      |               |    }                                                                   |
      |               |  }                                                                     |
      |               |}                                                                       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=<%= cb.app.first.name %>-2 |

    # Access mediawiki's route successfully
    Then I wait up to 60 seconds for a web server to become available via the "<%= cb.app.first.name %>" route
    And the output should match "MediaWiki has been(?: successfully)? installed"

  # @author chezhang@redhat.com
  @admin
  Scenario Outline: Multiple Plans support for DB APBs
    # Get the registry name from the configmap
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And I save the first service broker registry prefix to :prefix clipboard

    # Swtich back to normal user and create first project
    And I switch to the first user
    Given I have a project

    # Provision DB apb with dev plan
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<db_name>                                                                                      |
      | param | CLASS_EXTERNAL_NAME=<db_name>                                                                                |
      | param | PLAN_EXTERNAL_NAME=dev                                                                                       |
      | param | SECRET_NAME=<db_secret_name>                                                                                 |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                                                                    |
    Then the step should succeed
    And evaluation of `service_instance("<db_name>").uid(user: user)` is stored in the :uid1 clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<db_secret_name>                                                                                            |
      | param | INSTANCE_NAME=<db_name>                                                                                                 |
      | param | PARAMETERS=<db_parameters>                                                                                              |
      | param | UID=<%= cb.uid1 %>                                                                                                      |
      | n     | <%= project.name %>                                                                                                  |
    Then the step should succeed

    # Checking provision succeed with dev plan
    Given a pod becomes ready with labels:
      | app=<db_label> |
    And I wait for the "<db_name>" service_instance to become ready up to 80 seconds

    # Create another project
    Given I create a new project

    # Provision DB apb with prod plan
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<db_name>                                                                                      |
      | param | CLASS_EXTERNAL_NAME=<db_name>                                                                                |
      | param | PLAN_EXTERNAL_NAME=prod                                                                                      |
      | param | SECRET_NAME=<db_secret_name>                                                                                 |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                                                                    |
    Then the step should succeed
    And evaluation of `service_instance("<db_name>").uid(user: user)` is stored in the :uid2 clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<db_secret_name>                                                                                            |
      | param | INSTANCE_NAME=<db_name>                                                                                                 |
      | param | PARAMETERS=<db_parameters>                                                                                              |
      | param | UID=<%= cb.uid2 %>                                                                                                      |
      | n     | <%= project.name %>                                                                                                  |
    Then the step should succeed

    # Checking provision succeed with prod plan
    Given a pod becomes ready with labels:
      | app=<db_label> |
    And I wait for the "<db_name>" service_instance to become ready up to 80 seconds

    Examples:
      | db_name                         | db_secret_name                             | db_parameters                                                                                                                         | db_label             |
      | <%= cb.prefix %>-postgresql-apb | <%= cb.prefix %>-postgresql-apb-parameters | {"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.5","postgresql_password":"test"}                     | rhscl-postgresql-apb | # @case_id OCP-15328
      | <%= cb.prefix %>-mariadb-apb    | <%= cb.prefix %>-mariadb-apb-parameters    | {"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.2","mariadb_root_password":"test","mariadb_password":"test"} | rhscl-mariadb-apb    | # @case_id OCP-16086
      | <%= cb.prefix %>-mysql-apb      | <%= cb.prefix %>-mysql-apb-parameters      | {"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.7","service_name":"mysql","mysql_password":"test"}                  | rhscl-mysql-apb      | # @case_id OCP-16087


  # @author zhsun@redhat.com
  @admin
  Scenario Outline:: [ASB] The serviceinstaces/servicebinddings should be deleted after deleted project
    Given I save the first service broker registry prefix to :prefix clipboard
    Given I have a project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<db_name>                               |
      | param | CLASS_EXTERNAL_NAME=<db_name>                         |
      | param | PLAN_EXTERNAL_NAME=<db_plan>                          |
      | param | SECRET_NAME=<db_secret_name>                          |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                |
    Then the step should succeed
    And evaluation of `service_instance("<db_name>").uid` is stored in the :db_uid clipboard

    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<db_secret_name>                                                                                            |
      | param | INSTANCE_NAME=<db_name>                                                                                                 |
      | param | PARAMETERS=<db_parameters>                                                                                              |
      | param | UID=<%= cb.db_uid %>                                                                                            |
      | n     | <%= project.name %>                                                                                                     |
    Then the step should succeed
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
   When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/servicebinding-template.yaml |
      | param | BINDING_NAME=<db_name>                                                                                      |
      | param | INSTANCE_NAME=<db_name>                                                                                     |
      | param | SECRET_NAME=<db_credentials>                                                                                |
      | n     | <%= project.name %>                                                                                         |
    And I wait up to 20 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | servicebinding                 |
    Then the output should match:
      | Message:\\s+Injected bind result          |
    """
    Given I ensure "<db_name>" servicebinding is deleted
    And I ensure "<db_name>" serviceinstance is deleted
    And I ensure "<%= project.name %>" project is deleted
    When I run the :get client command with:
      | resource | projects |
    Then the step should succeed
    And the output should not match:
      | <%= project.name %>   |

    Examples:
      | db_name                         | db_credentials                              | db_plan | db_secret_name                             | db_parameters                                                                                                            | db_label             |
      | <%= cb.prefix %>-mysql-apb      | <%= cb.prefix %>-mysql-apb-credentials      |  dev    | <%= cb.prefix %>-mysql-apb-parameters      | {"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.7","service_name":"mysql","mysql_password":"test"}     | rhscl-mysql-apb      | # @case_id OCP-16661


  # @author zhsun@redhat.com
  # @case_id OCP-16520
  @admin
  @destructive
  Scenario: [ASB] Add authentication to etcd using certificate
    Given the master version <= "3.9"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project

    When admin redeploys "asb" dc
    And I run the :logs client command with:
      | resource_name | dc/asb          |
      | since         | 3m              |
    Then the step should succeed
    And the output should contain "Endpoints: [https://asb-etcd.openshift-ansible-service-broker.svc:2379]"


  # @author zitang@redhat.com
  # @case_id OCP-16137
  @admin
  @destructive
  Scenario: [ASB] Ansible-service-broker check APBs version correctly
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    
    Given the "ansible-service-broker" cluster service broker is recreated
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
      | since         | 3m              |
    Then the step should succeed
    And the output should match:
      |  failed validation for the following reason:.*version.*out of bounds 1.0 <= 1.0 |

  # @author zitang@redhat.com
  # @case_id OCP-18648
  @admin
  @destructive
  Scenario: [ASB] check apb bundle resource in crd when asb refresh
    When I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project

    Given the "ansible-service-broker" cluster service broker is recreated
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
