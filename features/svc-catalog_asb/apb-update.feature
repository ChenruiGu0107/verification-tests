Feature: Update sql apb related feature
 # @author zitang@redhat.com
  @admin
  Scenario Outline: [APB] Data will be preserved if version of PostgreSQL APB update	
    #get the registry name
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `YAML.load(config_map('broker-config').value_of('broker-config'))['registry'][0]['name']` is stored in the :prefix clipboard
    #provision postgresql
    Given I switch to the first user
    And I have a project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<db_name>                                                                                      |
      | param | CLASS_EXTERNAL_NAME=<db_name>                                                                                |
      | param | PLAN_EXTERNAL_NAME=<db_plan_1>                                                                               |
      | param | SECRET_NAME=<secret_name_1>                                                                                  |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<db_name>").uid` is stored in the :db_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml                 |
      | param | SECRET_NAME=<secret_name_1>                                                                                                             |
      | param | INSTANCE_NAME=<db_name>                                                                                                                 |
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"<db_version_1>","postgresql_password":"test"} |
      | param | UID=<%= cb.db_uid %>                                                                                                                    |
      | n     | <%= project.name %>                                                                                                                     |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deploymentconfig=postgresql-<db_version_1>-<db_plan_1>  |
    And I wait up to 80 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance                            |
    Then the step should succeed
    And the output should match 1 times:
      | Message:\\s+The instance was provisioned successfully |
    """
    #Add data to postgresql
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash                                | 
      | -c                                  |
      | psql -c 'CREATE DATABASE menagerie' |
    Then the step should succeed
    """
    And the output should contain:
      | CREATE DATABASE                     |
    When I execute on the pod:
      | bash                                                                                                                                      | 
      | -c                                                                                                                                        |
      | psql  -c 'CREATE TABLE pet (name VARCHAR(20), owner VARCHAR(20), species VARCHAR(20), sex CHAR(1), birth DATE, death DATE);' -d menagerie |
    Then the step should succeed
    And the output should contain:
      | CREATE TABLE                       |
    When I execute on the pod:
      | bash                                                                                                 | 
      |  -c                                                                                                  |
      |  psql -c "INSERT INTO pet VALUES ('Puffball','Diane','hamster','f','1999-03-30',NULL);" -d menagerie |
    Then the step should succeed
    And the output should contain:
      | INSERT 0 1                    |
    # update apb
    # create a update secret
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml  |
      | param | SECRET_NAME=<secret_name_2>                                                                                              |
      | param | INSTANCE_NAME=<db_name>                                                                                                  |
      | param | PARAMETERS={"postgresql_version":"<db_version_2>"}                                                                       |
      | param | UID=<%= cb.db_uid %>                                                                                                     |
      | n     | <%= project.name %>                                                                                                      |
    Then the step should succeed
    # update instance 

     When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-postgresql-apb      |
      | p         |{                                                     |
      |           | "spec": {                                            |
      |           |    "clusterServicePlanExternalName": "<db_plan_2>",  | 
      |           |    "parametersFrom": [                               |  
      |           |      {                                               | 
      |           |        "secretKeyRef": {                             |
      |           |          "key": "parameters",                        | 
      |           |          "name": "<secret_name_2>"                   | 
      |           |        }                                             |
      |           |      }                                               |
      |           |    ],                                                |
      |           |    "updateRequests": 1                               |
      |           |  }                                                   |
      |           |}                                                     |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deploymentconfig=postgresql-<db_version_2>-<db_plan_2>    |
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance                            |
    Then the step should succeed
    And the output should match 1 times:
      | Message:\\s+The instance was updated successfully     |
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash                                       | 
      | -c                                         |
      | psql -c 'SELECT * FROM pet;'  -d menagerie |
    Then the step should succeed
    """
    And the output should contain:
      |  Puffball             | 
     Examples:
      |db_name                         |db_plan_1 |db_plan_2 |secret_name_1                              |secret_name_2                                  |db_version_1 |db_version_2 |                                       
      |<%= cb.prefix %>-postgresql-apb |dev       |prod      |<%= cb.prefix %>-postgresql-apb-parameters |<%= cb.prefix %>-postgresql-apb-parameters-new |9.6          | 9.5     | # @case_id OCP-17306
      |<%= cb.prefix %>-postgresql-apb |dev       |prod      |<%= cb.prefix %>-postgresql-apb-parameters |<%= cb.prefix %>-postgresql-apb-parameters-new |9.5          | 9.6     | # @case_id OCP-17762

  #@author zitang@redhat.com
  @admin
  Scenario Outline: [APB] Data will be preserved if version of MySQL or MariaDB APB update  
    #get the registry name
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And evaluation of `YAML.load(config_map('broker-config').value_of('broker-config'))['registry'][0]['name']` is stored in the :prefix clipboard
    #provision mysql
    Given I switch to the first user
    And I have a project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<%= cb.prefix %>-<db_label>-apb                                                                |
      | param | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-<db_label>-apb                                                          |
      | param | PLAN_EXTERNAL_NAME=<db_plan_1>                                                                               |
      | param | SECRET_NAME=<%= cb.prefix %>-<db_label>-apb-parameters                                                       |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-<db_label>-apb").uid` is stored in the :db_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<%= cb.prefix %>-<db_label>-apb-parameters                                                                  |
      | param | INSTANCE_NAME=<%= cb.prefix %>-<db_label>-apb                                                                           |
      | param | PARAMETERS=<parameters_1>                                                                                               |
      | param | UID=<%= cb.db_uid %>                                                                                                    |
      | n     | <%= project.name %>                                                                                                     |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deploymentconfig=<pod_label>-<db_version_1>-<db_plan_1>  |
    And I wait up to 80 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance |
    Then the step should succeed
    And the output should match 1 times:
      | Message:\\s+The instance was provisioned successfully |
    """
    #Add data to postgresql
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash                                         | 
      | -c                                           |
      | mysql -u root -e 'CREATE DATABASE menagerie' |
    Then the step should succeed
    """
    When I execute on the pod:
      | bash                                                                                                                                               | 
      | -c                                                                                                                                                 |
      | mysql -u root -D  menagerie -e 'CREATE TABLE pet (name VARCHAR(20), owner VARCHAR(20), species VARCHAR(20), sex CHAR(1), birth DATE, death DATE);' |
    Then the step should succeed
    When I execute on the pod:
      | bash                                                                                                           | 
      |  -c                                                                                                            |
      |  mysql -u root -D  menagerie -e "INSERT INTO pet VALUES ('Puffball','Diane','hamster','f','1999-03-30',NULL);" |
    Then the step should succeed
    When I execute on the pod:
      | bash                                                | 
      | -c                                                  |
      |  mysql -u root -D  menagerie -e'SELECT * FROM pet;' |
    Then the step should succeed
    And the output should contain:
      |  Puffball             | 

    # update apb
    # create a update secret
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<%= cb.prefix %>-<db_label>-apb-parameters-new                                                              |
      | param | INSTANCE_NAME=<%= cb.prefix %>-<db_label>-apb                                                                           |
      | param | PARAMETERS=<parameters_2>                                                                                               |
      | param | UID=<%= cb.db_uid %>                                                                                                    |
      | n     | <%= project.name %>                                                                                                     |
    Then the step should succeed
    # update instance 

     When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-<db_label>-apb      |
      | p         |{                                                     |
      |           | "spec": {                                            |
      |           |    "clusterServicePlanExternalName": "<db_plan_2>",  | 
      |           |    "parametersFrom": [                               |  
      |           |      {                                               | 
      |           |        "secretKeyRef": {                             |
      |           |          "key": "parameters",                        | 
      |           |          "name": "<%= cb.prefix %>-<db_label>-apb-parameters-new"                   | 
      |           |        }                                             |
      |           |      }                                               |
      |           |    ],                                                |
      |           |    "updateRequests": 1                               |
      |           |  }                                                   |
      |           |}                                                     |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deploymentconfig=<pod_label>-<db_version_2>-<db_plan_2>    |
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance                        |
    Then the step should succeed
    And the output should match 1 times:
      | Message:\\s+The instance was updated successfully |
    """
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash                                                  | 
      | -c                                                    |
      |  mysql -u root   -D  menagerie -e'SELECT * FROM pet;' |
    Then the step should succeed
    """
    And the output should contain:
      |  Puffball             | 
    Examples:
     |db_label |pod_label    |parameters_1                                                                                                                          |parameters_2               |db_plan_1 |db_plan_2 |db_version_1 |db_version_2|                       
     |mysql   |mysql         |{"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.7","mysql_password":"test"}                                         |{"mysql_version":"5.6"}    |dev       |prod      |5.7          |5.6         | # @case_id OCP-17664
     |mysql   |mysql         |{"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.6","mysql_password":"test"}                                         |{"mysql_version":"5.7"}    |prod      |dev       |5.6          |5.7         | # @case_id OCP-17663
     |mariadb |rhscl-mariadb |{"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.2","mariadb_root_password":"test","mariadb_password":"test"} |{"mariadb_version":"10.1"} |prod       |dev      |10.2         |10.1        | # @case_id OCP-17671
     |mariadb |rhscl-mariadb |{"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.0","mariadb_root_password":"test","mariadb_password":"test"} |{"mariadb_version":"10.2"} |dev       |prod      |10.0         |10.2        | # @case_id OCP-17672

