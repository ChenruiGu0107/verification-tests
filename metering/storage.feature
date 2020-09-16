Feature: install metering with various backend storage configurations
  # @author pruan@redhat.com
  # @case_id OCP-32004
  @admin
  @destructive
  Scenario: install metering using sharePVC as storage
    Given the master version >= "4.1"
    Given I install metering service using:
      | meteringconfig | metering/configs/meteringconfig_sharedPVC.yaml |
      | storage_type   | sharedPVC                                      |

  # @author pruan@redhat.com
  # @case_id OCP-31392
  @admin
  @destructive
  Scenario: Use MySQL for the Hive Metastore database
    Given I remove metering service from the "openshift-metering" project
    And I setup a metering project
    And evaluation of `"qe"` is stored in the :db_username clipboard
    And evaluation of `"test"` is stored in the :db_password clipboard
    When I run the :new_app client command with:
      | image_stream | openshift/mysql:5.7                  |
      | env          | MYSQL_PASSWORD=<%= cb.db_password %> |
      | env          | MYSQL_USER=<%= cb.db_username %>     |
      | env          | MYSQL_DATABASE=hive                  |
      | l            | app=metering_db                      |
    And a pod becomes ready with labels:
      | app=metering_db |
    And evaluation of `service('mysql').ip` is stored in the :mysql_svc_ip clipboard

    Given I install metering service using:
      | meteringconfig | metering/configs/meteringconfig_sharedPVC_mysql_hivemetastore.yaml |
      | storage_type   | sharedPVC                                                          |
    When I run the :logs client command with:
      | resource_name | pod/hive-metastore-0 |
      | c             | metastore            |
    Then the output should contain:
      | underlying DB is MYSQL |
    # create a report to verify installation is working
    Given I get the "node-cpu-capacity" report and store it in the :res_tabular clipboard using:
      | query_type | namespace-cpu-usage |
    Then the step should succeed

  # @author pruan@redhat.com
  # @case_id OCP-32387
  @admin
  @destructive
  Scenario: install metering with HDFS as storage for hive-metastore
    Given the master version >= "4.1"
    Given I install metering service using:
      | storage_type | HDFS |

  # XXX: this test will fail until https://bugzilla.redhat.com/show_bug.cgi?id=1838845 is resolved
  # @author pruan@redhat.com
  # @case_id OCP-31408
  @admin
  @destructive
  Scenario: Use PostgreSQL for the Hive Metastore database
    Given I remove metering service from the "openshift-metering" project
    And I setup a metering project
    And evaluation of `"qe"` is stored in the :db_username clipboard
    And evaluation of `"test"` is stored in the :db_password clipboard
    When I run the :new_app client command with:
      | image_stream | openshift/postgresql:10                   |
      | env          | POSTGRESQL_PASSWORD=<%= cb.db_password %> |
      | env          | POSTGRESQL_USER=<%= cb.db_username %>     |
      | env          | POSTGRESQL_DATABASE=hive                  |
      | l            | app=metering_db                           |
    And a pod becomes ready with labels:
      | app=metering_db |
    And evaluation of `service('postgresql').ip` is stored in the :postgresql_svc_ip clipboard

    Given I install metering service using:
      | meteringconfig | metering/configs/meteringconfig_sharedPVC_postgresql_hivemetastore.yaml |
      | storage_type   | sharedPVC                                                               |
    When I run the :logs client command with:
      | resource_name | pod/hive-metastore-0 |
      | c             | metastore            |
    Then the output should contain:
      | underlying DB is POSTGRES |
    # create a report to verify installation is working
    Given I get the "node-cpu-capacity" report and store it in the :res_tabular clipboard using:
      | query_type | namespace-cpu-usage |
    Then the step should succeed
