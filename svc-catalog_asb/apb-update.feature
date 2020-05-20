Feature: Update sql apb related feature
  # @author zitang@redhat.com
  @admin
  Scenario Outline: Plan of serviceinstance can recover from an invalid one
    Given I save the first service broker registry prefix to :prefix clipboard
    #provision postgresql
    And I have a project
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-template.yaml |
      | p | INSTANCE_NAME=<db_name>                                                                                      |
      | p | CLASS_EXTERNAL_NAME=<db_name>                                                                                |
      | p | PLAN_EXTERNAL_NAME=<db_plan_1>                                                                               |
      | p | SECRET_NAME=<secret_name>                                                                                    |
      | p | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<db_name>").uid` is stored in the :db_uid clipboard
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-parameters-template.yaml                 |
      | p | SECRET_NAME=<secret_name>                                                                                                               |
      | p | INSTANCE_NAME=<db_name>                                                                                                                 |
      | p | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"<db_version>","postgresql_password":"test"}   |
      | p | UID=<%= cb.db_uid %>                                                                                                                    |
      | n | <%= project.name %>                                                                                                                     |
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
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-template.yaml |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                |
      | p | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-postgresql-apb                                                          |
      | p | PLAN_EXTERNAL_NAME=dev                                                                                       |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                       |
      | p | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-postgresql-apb").uid` is stored in the :db_uid clipboard
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-parameters-template.yaml      |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                                       |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                                |
      | p | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.5","postgresql_password":"test"} |
      | p | UID=<%= cb.db_uid %>                                                                                                         |
      | n | <%= project.name %>                                                                                                          |
    Then the step should succeed
    Given I wait for the "<%= cb.prefix %>-postgresql-apb" service_instance to become ready up to 360 seconds
    And dc with name matching /postgresql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

    #update the secret,
    #delete then create a new
    Given I ensures "<%= cb.prefix %>-postgresql-apb-parameters" secret is deleted from the project
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-parameters-template.yaml      |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                                       |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                                |
      | p | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.4","postgresql_password":"test"} |
      | p | UID=<%= cb.db_uid %>                                                                                                         |
      | n | <%= project.name %>                                                                                                          |
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

  # @author chezhang@redhat.com
  # @case_id OCP-18590
  @admin
  Scenario: Servicebinding can be deleted when serviceinstance update to a invalid plan
    Given I save the first service broker registry prefix to :prefix clipboard
    #provision postgresql
    And I have a project
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-template.yaml |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                |
      | p | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-postgresql-apb                                                          |
      | p | PLAN_EXTERNAL_NAME=dev                                                                                       |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                       |
      | p | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-postgresql-apb").uid` is stored in the :db_uid clipboard
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-parameters-template.yaml      |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                                       |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                                |
      | p | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"9.5","postgresql_password":"test"} |
      | p | UID=<%= cb.db_uid %>                                                                                                         |
      | n | <%= project.name %>                                                                                                          |
    Then the step should succeed
    Given I wait for the "<%= cb.prefix %>-postgresql-apb" service_instance to become ready up to 360 seconds
    And dc with name matching /postgresql/ are stored in the :dc_1 clipboard
    And a pod becomes ready with labels:
      | deploymentconfig=<%= cb.dc_1.first.name %> |

    # Create servicebinding of DB apb
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/servicebinding-template.yaml |
      | p | BINDING_NAME=<%= cb.prefix %>-postgresql-apb                                                                |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                               |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-credentials                                                     |
      | n | <%= project.name %>                                                                                         |
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
  # @case_id OCP-18513
  @admin
  Scenario: Update instance to invalid plan then delete project will not cause catalog crashed
    Given I save the first service broker registry prefix to :prefix clipboard
    #provision database
    And I have a project
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-template.yaml |
      | p | INSTANCE_NAME=<%= cb.prefix %>-mysql-apb                                                                     |
      | p | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-mysql-apb                                                               |
      | p | PLAN_EXTERNAL_NAME=prod                                                                                      |
      | p | SECRET_NAME=<%= cb.prefix %>-mysql-apb-parameters                                                            |
      | p | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-mysql-apb").uid` is stored in the :db_uid clipboard
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-parameters-template.yaml |
      | p | SECRET_NAME=<%= cb.prefix %>-mysql-apb-parameters                                                                       |
      | p | INSTANCE_NAME=<%= cb.prefix %>-mysql-apb                                                                                |
      | p | PARAMETERS={"mysql_database":"devel","mysql_user":"devel","mysql_version":"5.6","mysql_password":"test"}                |
      | p | UID=<%= cb.db_uid %>                                                                                                    |
      | n | <%= project.name %>                                                                                                     |
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
