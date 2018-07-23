Feature: Update sql apb related feature
 # @author zitang@redhat.com
  @admin
  Scenario Outline: [APB] Data will be preserved if version of PostgreSQL APB update
    Given I save the first service broker registry prefix to :prefix clipboard
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
    Given I wait for the "<db_name>" service_instance to become ready up to 360 seconds  
    And dc with name matching /postgresql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

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
    # create an update secret
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml                 |
      | param | SECRET_NAME=<secret_name_2>                                                                                                             |
      | param | INSTANCE_NAME=<db_name>                                                                                                                 |
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"<db_version_2>","postgresql_password":"test"} |
      | param | UID=<%= cb.db_uid %>                                                                                                                    |
      | n     | <%= project.name %>                                                                                                                     |
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
    #checking the old dc is deleted, new dc is created   
    Given I wait for the resource "dc" named "<%= cb.dc_1.first.name %>" to disappear within 240 seconds
    Given I wait for the "<db_name>" service_instance to become ready up to 240 seconds
    And dc with name matching /postgresql/ are stored in the :dc_2 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_2.first.name %> |
 
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
      |<%= cb.prefix %>-postgresql-apb |prod      |dev      |<%= cb.prefix %>-postgresql-apb-parameters |<%= cb.prefix %>-postgresql-apb-parameters-new |9.4          | 9.6     | # @case_id OCP-18561
      |<%= cb.prefix %>-postgresql-apb |dev       |prod     |<%= cb.prefix %>-postgresql-apb-parameters |<%= cb.prefix %>-postgresql-apb-parameters-new |9.6          | 9.4     | # @case_id OCP-18563

  #@author zitang@redhat.com
  @admin
  Scenario Outline: [APB] Data will be preserved if version of MySQL or MariaDB APB update  
    Given I save the first service broker registry prefix to :prefix clipboard
    #provision mysql
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
    Given I wait for the "<%= cb.prefix %>-<db_label>-apb" service_instance to become ready up to 360 seconds 
    And dc with name matching /<db_label>/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

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
    # create an update secret
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
    #checking the old dc is deleted, new dc is created   
    Given I wait for the resource "dc" named "<%= cb.dc_1.first.name %>" to disappear within 240 seconds
    Given I wait for the "<%= cb.prefix %>-<db_label>-apb" service_instance to become ready up to 240 seconds
    And dc with name matching /<db_label>/ are stored in the :dc_2 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_2.first.name %> |

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
     |db_label |pod_label    |parameters_1                                                                                                                          |parameters_2                                                                                                                          |db_plan_1 |db_plan_2 |db_version_1 |db_version_2|                       
     |mysql   |mysql         |{"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.7","mysql_password":"test"}                                         |{"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.6","mysql_password":"test"}                                         |dev       |prod      |5.7          |5.6         | # @case_id OCP-17664
     |mysql   |mysql         |{"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.6","mysql_password":"test"}                                         |{"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.7","mysql_password":"test"}                                        |prod      |dev       |5.6          |5.7         | # @case_id OCP-17663
     |mariadb |rhscl-mariadb |{"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.2","mariadb_root_password":"test","mariadb_password":"test"} |{"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.1","mariadb_root_password":"test","mariadb_password":"test"} |prod       |dev      |10.2         |10.1        | # @case_id OCP-17671
     |mariadb |rhscl-mariadb |{"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.0","mariadb_root_password":"test","mariadb_password":"test"} |{"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.2","mariadb_root_password":"test","mariadb_password":"test"} |dev       |prod      |10.0         |10.2        | # @case_id OCP-17672
     |mariadb |rhscl-mariadb |{"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.1","mariadb_root_password":"test","mariadb_password":"test"} |{"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.2","mariadb_root_password":"test","mariadb_password":"test"} |prod       |dev      |10.1         |10.2        | # @case_id OCP-18564
     |mariadb |rhscl-mariadb |{"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.2","mariadb_root_password":"test","mariadb_password":"test"} |{"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.0","mariadb_root_password":"test","mariadb_password":"test"} |prod      |prod      |10.2         |10.0        | # @case_id OCP-18565

 # @author zitang@redhat.com
  @admin
  Scenario Outline: Plan of serviceinstance can be updated
    Given I save the first service broker registry prefix to :prefix clipboard
    #provision postgresql
    And I have a project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<db_name>                                                                                      |
      | param | CLASS_EXTERNAL_NAME=<db_name>                                                                                |
      | param | PLAN_EXTERNAL_NAME=<db_plan_1>                                                                               |
      | param | SECRET_NAME=<secret_name>                                                                                    |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<db_name>").uid` is stored in the :db_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml                 |
      | param | SECRET_NAME=<secret_name>                                                                                                               |
      | param | INSTANCE_NAME=<db_name>                                                                                                                 |
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"<db_version>","postgresql_password":"test"}   |
      | param | UID=<%= cb.db_uid %>                                                                                                                    |
      | n     | <%= project.name %>                                                                                                                     |
    Then the step should succeed
    Given I wait for the "<db_name>" service_instance to become ready up to 360 seconds
    And dc with name matching /postgresql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

    # update instance 
     When I run the :patch client command with:
      | resource  | serviceinstance/<db_name>      |
      | p         |{                                                     |
      |           | "spec": {                                            |
      |           |    "clusterServicePlanExternalName": "<db_plan_2>"   | 
      |           |  }                                                   |
      |           |}                                                     |
    Then the step should succeed
    #checking the old dc is deleted, new dc is created   
    Given I wait for the resource "dc" named "<%= cb.dc_1.first.name %>" to disappear within 240 seconds
    Given I wait for the "<db_name>" service_instance to become ready up to 240 seconds
    When I run the :describe client command with:
      | resource  | serviceinstance/<db_name>      |
    Then the step should succeed
    And the output should match:
      | Reason:\\s+InstanceUpdatedSuccessfully |
    And the output should not contain:
      | UpdateInstanceCallFailed |
    And dc with name matching /postgresql/ are stored in the :dc_2 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_2.first.name %> |
    
     Examples:
      |db_name                         |db_plan_1 |db_plan_2 |secret_name                                |db_version |
      |<%= cb.prefix %>-postgresql-apb |prod      |dev       |<%= cb.prefix %>-postgresql-apb-parameters |9.5        | # @case_id OCP-16151
      |<%= cb.prefix %>-postgresql-apb |dev       |prod      |<%= cb.prefix %>-postgresql-apb-parameters |9.5        | # @case_id OCP-18249
      |<%= cb.prefix %>-postgresql-apb |dev       |prod      |<%= cb.prefix %>-postgresql-apb-parameters |9.5        | # @case_id OCP-18308

  # @author zitang@redhat.com
  @admin
  Scenario Outline: Plan of serviceinstance can recover from an invalid one 
    Given I save the first service broker registry prefix to :prefix clipboard
    #provision postgresql
    And I have a project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<db_name>                                                                                      |
      | param | CLASS_EXTERNAL_NAME=<db_name>                                                                                |
      | param | PLAN_EXTERNAL_NAME=<db_plan_1>                                                                               |
      | param | SECRET_NAME=<secret_name>                                                                                    |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<db_name>").uid` is stored in the :db_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml                 |
      | param | SECRET_NAME=<secret_name>                                                                                                               |
      | param | INSTANCE_NAME=<db_name>                                                                                                                 |
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"<db_version>","postgresql_password":"test"}   |
      | param | UID=<%= cb.db_uid %>                                                                                                                    |
      | n     | <%= project.name %>                                                                                                                     |
    Then the step should succeed
    Given I wait for the "<db_name>" service_instance to become ready up to 360 seconds
    And dc with name matching /postgresql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

    # update an invalid plan
     When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-postgresql-apb      |
      | p         |{                                                     |
      |           | "spec": {                                            |
      |           |    "clusterServicePlanExternalName": "<db_plan_2>"   | 
      |           |  }                                                   |
      |           |}                                                     |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance                            |
    Then the step should succeed
    And the output should match:
      | Message:.*ClusterServicePlan.*not exist     |
    """
    # update to the previous  plan
     When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-postgresql-apb      |
      | p         |{                                                     |
      |           | "spec": {                                            |
      |           |    "clusterServicePlanExternalName": "<db_plan_1>"   | 
      |           |  }                                                   |
      |           |}                                                     |
    Then the step should succeed
    Given I wait for the "<db_name>" service_instance to become ready up to 360 seconds

    # update an invalid plan again
     When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-postgresql-apb      |
      | p         |{                                                     |
      |           | "spec": {                                            |
      |           |    "clusterServicePlanExternalName": "<db_plan_2>"   | 
      |           |  }                                                   |
      |           |}                                                     |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance   |
    Then the step should succeed
    And the output should match:
      | Message:.*ClusterServicePlan.*not exist  |
    """
    # update to the previous  plan
     When I run the :patch client command with:
      | resource  | serviceinstance/<db_name>      |
      | p         |{                                                     |
      |           | "spec": {                                            |
      |           |    "clusterServicePlanExternalName": "<db_plan_3>"   | 
      |           |  }                                                   |
      |           |}                                                     |
    Then the step should succeed
    #checking the old dc is deleted, new dc is created   
    Given I wait for the resource "dc" named "<%= cb.dc_1.first.name %>" to disappear within 240 seconds
    Given I wait for the "<db_name>" service_instance to become ready up to 240 seconds
    And dc with name matching /postgresql/ are stored in the :dc_2 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_2.first.name %> |

     Examples:
      |db_name                         |db_plan_1 |db_plan_2 |db_plan_3|secret_name                                |db_version |                                
      |<%= cb.prefix %>-postgresql-apb |dev      | dev-123       |prod     |<%= cb.prefix %>-postgresql-apb-parameters |9.5    | # @case_id OCP-17298


  # @author zitang@redhat.com
  # @case_id OCP-16372
  @admin
  Scenario: UpdateRequests in serviceinstance will cause instance update
    Given I save the first service broker registry prefix to :prefix clipboard
    And I have a project
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
    Given I wait for the "<%= cb.prefix %>-postgresql-apb" service_instance to become ready up to 360 seconds
    And dc with name matching /postgresql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

    #update the secret,
    #delete then create a new
    Given I ensures "<%= cb.prefix %>-postgresql-apb-parameters" secret is deleted from the project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml      |
      | param | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                                       |
      | param | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                                |
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.4","postgresql_password":"test"} |
      | param | UID=<%= cb.db_uid %>                                                                                                         |
      | n     | <%= project.name %>                                                                                                          |
    Then the step should succeed
    When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-postgresql-apb      |
      | p         |{                                                     |
      |           | "spec": {                                            |
      |           |    "updateRequests": 1                               |
      |           |  }                                                   |
      |           |}                                                     |
    Then the step should succeed

    #checking the old dc is deleted, new dc is created   
    Given I wait for the resource "dc" named "<%= cb.dc_1.first.name %>" to disappear within 240 seconds
    Given I wait for the "<%= cb.prefix %>-postgresql-apb" service_instance to become ready up to 240 seconds
    And dc with name matching /postgresql/ are stored in the :dc_2 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_2.first.name %> |

  #@author zitang@redhat.com
  # @case_id OCP-18567
  @admin
  Scenario: [APB] Data created by normal user will be preserved if MySQL APB update
    Given I save the first service broker registry prefix to :prefix clipboard
    #provision mysql
    And I have a project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mysql-apb                                                                     |
      | param | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-mysql-apb                                                               |
      | param | PLAN_EXTERNAL_NAME=prod                                                                                      |
      | param | SECRET_NAME=<%= cb.prefix %>-mysql-apb-parameters                                                            |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-mysql-apb").uid` is stored in the :db_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<%= cb.prefix %>-mysql-apb-parameters                                                                       |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mysql-apb                                                                                |
      | param | PARAMETERS={"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.6","mysql_password":"test"}                |
      | param | UID=<%= cb.db_uid %>                                                                                                    |
      | n     | <%= project.name %>                                                                                                     |
    Then the step should succeed
    Given I wait for the "<%= cb.prefix %>-mysql-apb" service_instance to become ready up to 360 seconds
    And dc with name matching /mysql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

    #Add data to postgresql
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash                                                                                                                                                                | 
      | -c                                                                                                                                                                  |
      | mysql -u devel -ptest -h 127.0.0.1 -D devel  -e 'CREATE TABLE pet (name VARCHAR(20), owner VARCHAR(20), species VARCHAR(20), sex CHAR(1), birth DATE, death DATE);' |
    Then the step should succeed
    """
    When I execute on the pod:
      | bash                                                                                                                           | 
      |  -c                                                                                                                            |
      |  mysql -u devel -ptest -h 127.0.0.1 -D devel -e "INSERT INTO pet VALUES ('Puffball','Diane','hamster','f','1999-03-30',NULL);"; mysql -u devel -ptest -h 127.0.0.1 -D devel -e 'SELECT * FROM pet;'  |
    Then the step should succeed
    And the output should contain:
      |  Puffball             | 
    # update apb
    # create an update secret
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<%= cb.prefix %>-mysql-apb-parameters-new                                                                   |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mysql-apb                                                                                |
      | param | PARAMETERS={"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.7","mysql_password":"test"}                |
      | param | UID=<%= cb.db_uid %>                                                                                                    |
      | n     | <%= project.name %>                                                                                                     |
    Then the step should succeed
    # update instance 

     When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-mysql-apb                   |
      | p         |{                                                             |
      |           | "spec": {                                                    |
      |           |    "clusterServicePlanExternalName": "dev",                  | 
      |           |    "parametersFrom": [                                       |  
      |           |      {                                                       | 
      |           |        "secretKeyRef": {                                     |
      |           |          "key": "parameters",                                | 
      |           |          "name": "<%= cb.prefix %>-mysql-apb-parameters-new" | 
      |           |        }                                                     |
      |           |      }                                                       |
      |           |    ],                                                        |
      |           |    "updateRequests": 1                                       |
      |           |  }                                                           |
      |           |}                                                             |
    Then the step should succeed
    #checking the old dc is deleted, new dc is created   
    Given I wait for the resource "dc" named "<%= cb.dc_1.first.name %>" to disappear within 240 seconds
    Given I wait for the "<%= cb.prefix %>-mysql-apb" service_instance to become ready up to 240 seconds
    And dc with name matching /mysql/ are stored in the :dc_2 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_2.first.name %> |

    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash                                                                 | 
      | -c                                                                   |
      |  mysql -u devel -ptest -h 127.0.0.1 -D devel -e 'SELECT * FROM pet;' |
    Then the step should succeed
    """
    And the output should contain:
      |  Puffball             | 

  # @author zitang@redhat.com
  # @case_id OCP-18566
  @admin
  Scenario: [APB] Data created by normal user will be preserved if PostgresSQL APB update 
    Given I save the first service broker registry prefix to :prefix clipboard
    And I have a project
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
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.6","postgresql_password":"test"} |
      | param | UID=<%= cb.db_uid %>                                                                                                         |
      | n     | <%= project.name %>                                                                                                          |
    Then the step should succeed
    Given I wait for the "<%= cb.prefix %>-postgresql-apb" service_instance to become ready up to 360 seconds  
    And dc with name matching /postgresql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

    #Add data to postgresql
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash                                                                                                                                             | 
      | -c                                                                                                                                               |
      | psql -U admin  -c 'CREATE TABLE pet (name VARCHAR(20), owner VARCHAR(20), species VARCHAR(20), sex CHAR(1), birth DATE, death DATE);'  -d  admin |
    Then the step should succeed
    """
    And the output should contain:
      | CREATE TABLE                       |
    When I execute on the pod:
      | bash                                                                                                       | 
      |  -c                                                                                                        |
      |  psql  -U admin -c "INSERT INTO pet VALUES ('Puffball','Diane','hamster','f','1999-03-30',NULL);" -d admin |
    Then the step should succeed
    And the output should contain:
      | INSERT 0 1                    |
    # update apb
    # create an update secret
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml      |
      | param | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters-new                                                                   |
      | param | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                                |
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.4","postgresql_password":"test"} |
      | param | UID=<%= cb.db_uid %>                                                                                                         |
      | n     | <%= project.name %>                                                                                                          |
    Then the step should succeed
    # update instance 

     When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-postgresql-apb                    |
      | p         |{                                                                   |
      |           | "spec": {                                                          |
      |           |    "clusterServicePlanExternalName": "prod",                       | 
      |           |    "parametersFrom": [                                             |  
      |           |      {                                                             | 
      |           |        "secretKeyRef": {                                           |
      |           |          "key": "parameters",                                      | 
      |           |          "name": "<%= cb.prefix %>-postgresql-apb-parameters-new"  | 
      |           |        }                                                           |
      |           |      }                                                             |
      |           |    ],                                                              |
      |           |    "updateRequests": 1                                             |
      |           |  }                                                                 |
      |           |}                                                                   |
    Then the step should succeed
    #checking the old dc is deleted, new dc is created   
    Given I wait for the resource "dc" named "<%= cb.dc_1.first.name %>" to disappear within 240 seconds
    Given I wait for the "<%= cb.prefix %>-postgresql-apb" service_instance to become ready up to 240 seconds  
    And dc with name matching /postgresql/ are stored in the :dc_2 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_2.first.name %> |
    
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash                                            | 
      | -c                                              |
      | psql -U admin -c 'SELECT * FROM pet;'  -d admin |
    Then the step should succeed
    """
    And the output should contain:
      |  Puffball             |

  # @author chezhang@redhat.com
  # @case_id OCP-18590
  @admin
  Scenario: Servicebinding can be deleted when serviceinstance update to a invalid plan 
    Given I save the first service broker registry prefix to :prefix clipboard
    #provision postgresql
    And I have a project
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
    Given I wait for the "<%= cb.prefix %>-postgresql-apb" service_instance to become ready up to 360 seconds
    And dc with name matching /postgresql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

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
      | Message:\\s+Injected bind result          |
    """

    # update to an invalid plan
    When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-postgresql-apb      |
      | p         |{                                                     |
      |           | "spec": {                                            |
      |           |    "clusterServicePlanExternalName": "invalid-plan"  | 
      |           |  }                                                   |
      |           |}                                                     |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance |
    Then the step should succeed
    And the output should match:
      | Message:.*ClusterServicePlan.*not exist |
    """

    # Check related resources can be removed succeed.  
    Given I ensure "<%= cb.prefix %>-postgresql-apb" servicebinding is deleted
    And I ensure "<%= cb.prefix %>-postgresql-apb" serviceinstance is deleted
    And I ensure "<%= project.name %>" project is deleted

  # @author zitang@redhat.com
  # @case_id OCP-16311
  @admin
  Scenario: [ASB] Media wiki service instance can be updated
    Given I save the first service broker registry prefix to :prefix clipboard
    And I have a project  
    # Provision mediawiki apb
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mediawiki-apb          |
      | param | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-mediawiki-apb    |
      | param | SECRET_NAME=<%= cb.prefix %>-mediawiki-apb-parameters |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-mediawiki-apb").uid(user: user)` is stored in the :mediawiki_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<%= cb.prefix %>-mediawiki-apb-parameters |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mediawiki-apb          |
      | param | UID=<%= cb.mediawiki_uid %>                           |
      | n     | <%= project.name %>                                   |
    Then the step should succeed
    Given I wait for the "<%= cb.prefix %>-mediawiki-apb" service_instance to become ready up to 360 seconds
    And dc with name matching /mediawiki/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deployment=<%= cb.dc_1.first.name %>-1 |

    #update the media wiki with new parameters
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<%= cb.prefix %>-mediawiki-apb-parameters-new |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mediawiki-apb          |
      | param | UID=<%= cb.mediawiki_uid %>                           |
      | param | PARAMETERS={"mediawiki_admin_user":"admin","mediawiki_db_schema":"mediawiki","mediawiki_site_lang":"en","mediawiki_site_name":"MediaWikiNewName","mediawiki_admin_pass":"test"}                       |
      | n     | <%= project.name %>                                   |
    Then the step should succeed
    When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-mediawiki-apb      |
      | p         |{                                                     |
      |           | "spec": {                                            |
      |           |    "parametersFrom": [                               |  
      |           |      {                                               | 
      |           |        "secretKeyRef": {                             |
      |           |          "key": "parameters",                        | 
      |           |          "name": "<%= cb.prefix %>-mediawiki-apb-parameters-new"                | 
      |           |        }                                             |
      |           |      }                                               |
      |           |    ],                                                |
      |           |    "updateRequests": 1                               |
      |           |  }                                                   |
      |           |}                                                     |
    Then the step should succeed
    #the olddc will not be deleted like *sql-apb. but the dc and pod  will change
    Given a pod becomes ready with labels:
      | deployment=<%= cb.dc_1.first.name %>-2 |
    And the expression should be true> pod.env_var("MEDIAWIKI_SITE_NAME") == "MediaWikiNewName"
    And I wait for the "<%= cb.prefix %>-mediawiki-apb" service_instance to become ready up to 240 seconds

  # @author zitang@redhat.com
  # @case_id OCP-18513
  @admin
  Scenario: Update instance to invalid plan then delete project will not cause catalog crashed
    Given I save the first service broker registry prefix to :prefix clipboard
    #provision database
    And I have a project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-template.yaml |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mysql-apb                                                                     |
      | param | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-mysql-apb                                                               |
      | param | PLAN_EXTERNAL_NAME=prod                                                                                      |
      | param | SECRET_NAME=<%= cb.prefix %>-mysql-apb-parameters                                                            |
      | param | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-mysql-apb").uid` is stored in the :db_uid clipboard
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml |
      | param | SECRET_NAME=<%= cb.prefix %>-mysql-apb-parameters                                                                       |
      | param | INSTANCE_NAME=<%= cb.prefix %>-mysql-apb                                                                                |
      | param | PARAMETERS={"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.6","mysql_password":"test"}                |
      | param | UID=<%= cb.db_uid %>                                                                                                    |
      | n     | <%= project.name %>                                                                                                     |
    Then the step should succeed
    Given I wait for the "<%= cb.prefix %>-mysql-apb" service_instance to become ready up to 360 seconds
    And dc with name matching /mysql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

    # update an invalid plan
     When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-mysql-apb      |
      | p         |{                                                |
      |           | "spec": {                                       |
      |           |    "clusterServicePlanExternalName": "dev123"   | 
      |           |  }                                              |
      |           |}                                                |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance                  |
    Then the step should succeed
    And the output should match:
      | Message:.*ClusterServicePlan.*not exist     |
    """
    Given I ensure "<%= project.name %>" project is deleted
    Given 60 seconds have passed
    When I switch to cluster admin pseudo user
    And I use the "kube-service-catalog" project
    And all existing pods are ready with labels:
      | app=apiserver |
    And all existing pods are ready with labels:
      | app=controller-manager |


  # @author zitang@redhat.com
  # @case_id OCP-18514
  @admin
  Scenario: Updating invalid version will cause serviceinstance into error status 
    Given I save the first service broker registry prefix to :prefix clipboard
    #provision postgresql
    And I have a project
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
    Given I wait for the "<%= cb.prefix %>-postgresql-apb" service_instance to become ready up to 360 seconds
    And dc with name matching /postgresql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

    #update the secret,
    # create a update secret
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml      |
      | param | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters-new                                                                   |
      | param | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                                |
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.1","postgresql_password":"test"} |
      | param | UID=<%= cb.db_uid %>                                                                                                         |
      | n     | <%= project.name %>                                                                                                          |
    Then the step should succeed
    # update instance 
     When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-postgresql-apb                    |
      | p         |{                                                                   |
      |           | "spec": {                                                          |
      |           |    "parametersFrom": [                                             |  
      |           |      {                                                             | 
      |           |        "secretKeyRef": {                                           |
      |           |          "key": "parameters",                                      | 
      |           |          "name": "<%= cb.prefix %>-postgresql-apb-parameters-new"  | 
      |           |        }                                                           |
      |           |      }                                                             |
      |           |    ],                                                              |
      |           |    "updateRequests": 1                                             |
      |           |  }                                                                 |
      |           |}                                                                   |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance   |
    Then the step should succeed
    And the output should match 1 times:
      | ^\s+Message:.*unknown enum parameter value |
      | Reason:\\s+UpdateInstanceCallFailed        |
      | Status:\\s+False                           |
      | Type:\\s+Ready                             |
    """
     # update to the previous  version
     When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-postgresql-apb               |
      | p         |{                                                              |
      |           | "spec": {                                                     |
      |           |    "parametersFrom": [                                        |  
      |           |      {                                                        | 
      |           |        "secretKeyRef": {                                      |
      |           |          "key": "parameters",                                 | 
      |           |          "name": "<%= cb.prefix %>-postgresql-apb-parameters" | 
      |           |        }                                                      |
      |           |      }                                                        |
      |           |    ],                                                         |
      |           |    "updateRequests": 2                                        |
      |           |  }                                                            |
      |           |}                                                              |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance   |
    Then the step should succeed
    And the output should match 1 times:
      | ^\s+Message:\\s+The instance was updated successfully |
      | Reason:\\s+InstanceUpdatedSuccessfully                |
      | Status: \\s+True                                      |
      | Type:\\s+Ready                                        |
    """
    And the output by order should match:
      | Events: | 
      | Normal\s+InstanceUpdatedSuccessfully |


  # @author zitang@redhat.com
  # @case_id OCP-18500
  @admin
  Scenario: Update un-updatable parameters in the ServiceInstance will cause serviceinstance error
    Given I save the first service broker registry prefix to :prefix clipboard
    #provision postgresql
    And I have a project
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
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.6","postgresql_password":"test"} |
      | param | UID=<%= cb.db_uid %>                                                                                                         |
      | n     | <%= project.name %>                                                                                                          |
    Then the step should succeed
    Given I wait for the "<%= cb.prefix %>-postgresql-apb" service_instance to become ready up to 360 seconds
    And dc with name matching /postgresql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

    #update the secret,
    # create a update secret
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/svc-catalog/serviceinstance-parameters-template.yaml        |
      | param | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters-new                                                                     |
      | param | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                                  |
      | param | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.6","postgresql_password":"newnew"} |
      | param | UID=<%= cb.db_uid %>                                                                                                           |
      | n     | <%= project.name %>                                                                                                            |
    Then the step should succeed
    # update instance 

     When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-postgresql-apb                     |
      | p         |{                                                                    |
      |           | "spec": {                                                           |
      |           |    "parametersFrom": [                                              |  
      |           |      {                                                              | 
      |           |        "secretKeyRef": {                                            |
      |           |          "key": "parameters",                                       | 
      |           |          "name": "<%= cb.prefix %>-postgresql-apb-parameters-new"   | 
      |           |        }                                                            |
      |           |      }                                                              |
      |           |    ],                                                               |
      |           |    "updateRequests": 1                                              |
      |           |  }                                                                  |
      |           |}                                                                    |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance   |
    Then the step should succeed
    And the output should match 1 times:
      | ^\s+Message:\\s+ClusterServiceBroker returned a failure for update call.*parameter not updatable  |
      | Reason:\\s+UpdateInstanceCallFailed                                                               |
      | Status: \\s+False                                                                                 |
      | Type:\\s+Ready                                                                                    |
    """
     # update to the previous  version
     When I run the :patch client command with:
      | resource  | serviceinstance/<%= cb.prefix %>-postgresql-apb                |
      | p         |{                                                               |
      |           | "spec": {                                                      |
      |           |    "parametersFrom": [                                         |  
      |           |      {                                                         | 
      |           |        "secretKeyRef": {                                       |
      |           |          "key": "parameters",                                  | 
      |           |          "name": "<%= cb.prefix %>-postgresql-apb-parameters"  | 
      |           |        }                                                       |
      |           |      }                                                         |
      |           |    ],                                                          |
      |           |    "updateRequests": 2                                         |
      |           |  }                                                             |
      |           |}                                                               |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | serviceinstance   |
    Then the step should succeed
    And the output should match 1 times:
      | ^\s+Message:\\s+The instance was updated successfully |
      | Reason:\\s+InstanceUpdatedSuccessfully                |
      | Status:\\s+True                                       |
      | Type:\\s+Ready                                        |
    """
