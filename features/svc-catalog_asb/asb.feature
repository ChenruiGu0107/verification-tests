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

    # mediawiki and DB apbs provision succeed
    Given a pod becomes ready with labels:
      | deployment=mediawiki123-1 |
    Given a pod becomes ready with labels:
      | app=<db_label>            |
    And I wait up to 80 seconds for the steps to pass:
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
      | resource_name | mediawiki123              |
      | p             | {"spec":{"template":{"spec":{"containers":[{"envFrom": [ {"secretRef":{ "name": "<db_credentials>"}}],"name": "mediawiki123"}]}}}} |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=mediawiki123-2                 |

    # Access mediawiki's route
    And I wait up to 60 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route("mediawiki123", service("mediawiki123")).dns(by: user) %>/index.php/Main_Page" url
    And the output should contain "MediaWiki has been successfully installed"
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
    # And I wait for the resource "secret" named "<%= cb.prefix %>-mediawiki-apb-parameters" to disappear within 120 seconds
    # And I wait for the resource "secret" named "<db_secret_name>" to disappear within 120 seconds
    Then I check that there are no pods in the project
    And I check that there are no dc in the project
    And I check that there are no rc in the project
    And I check that there are no services in the project
    And I check that there are no routes in the project

    Examples:
      | db_name                         | db_credentials                              | db_plan | db_secret_name                             | db_parameters                                                                                                                 | db_label             |
      | <%= cb.prefix %>-postgresql-apb | <%= cb.prefix %>-postgresql-apb-credentials |  dev    | <%= cb.prefix %>-postgresql-apb-parameters | {"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.5","postgresql_password":"test"}             | rhscl-postgresql-apb | # @case_id OCP-15648
      | <%= cb.prefix %>-postgresql-apb | <%= cb.prefix %>-postgresql-apb-credentials |  prod   | <%= cb.prefix %>-postgresql-apb-parameters | {"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.5","postgresql_password":"test"}             | rhscl-postgresql-apb | # @case_id OCP-17363
      | <%= cb.prefix %>-mysql-apb      | <%= cb.prefix %>-mysql-apb-credentials      |  dev    | <%= cb.prefix %>-mysql-apb-parameters      | {"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.7","service_name":"mysql","mysql_password":"test"}          | rhscl-mysql-apb      | # @case_id OCP-16071
      | <%= cb.prefix %>-mysql-apb      | <%= cb.prefix %>-mysql-apb-credentials      |  prod   | <%= cb.prefix %>-mysql-apb-parameters      | {"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.7","service_name":"mysql","mysql_password":"test"}          | rhscl-mysql-apb      | # @case_id OCP-17361
      | <%= cb.prefix %>-mariadb-apb    | <%= cb.prefix %>-mariadb-apb-credentials    |  dev    | <%= cb.prefix %>-mariadb-apb-parameters    | {"mysql_database":"admin","mysql_user":"admin","mariadb_version":"10.0","mysql_root_password":"test","mysql_password":"test"} | rhscl-mariadb-apb    | # @case_id OCP-15350
      | <%= cb.prefix %>-mariadb-apb    | <%= cb.prefix %>-mariadb-apb-credentials    |  prod   | <%= cb.prefix %>-mariadb-apb-parameters    | {"mysql_database":"admin","mysql_user":"admin","mariadb_version":"10.0","mysql_root_password":"test","mysql_password":"test"} | rhscl-mariadb-apb    | # @case_id OCP-17362

