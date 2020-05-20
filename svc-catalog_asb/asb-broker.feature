Feature: ASB broker config related scenarios
  # @author chezhang@redhat.com
  # @case_id OCP-16635
  @admin
  @destructive
  Scenario: Should prevent relistDuration change to negative value in servicebroker
    Given I switch to cluster admin pseudo user
    And the "ansible-service-broker" cluster service broker is recreated after scenario

    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                 |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: -15m0s |
    Then the step should fail
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker              |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: abc |
    Then the step should fail
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker               |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: *%$# |
    Then the step should fail

    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker               |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: 0.5m |
    Then the step should succeed
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_behavior == "Duration"
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_duration_raw(cached: false) == "30s"

    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: 0s11m |
    Then the step should succeed
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_behavior == "Duration"
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_duration_raw(cached: false) == "11m0s"

    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker               |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: 600s |
    Then the step should succeed
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_behavior == "Duration"
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_duration_raw(cached: false) == "10m0s"


  # @author zitang@redhat.com
  # @case_id OCP-20960
  @admin
  Scenario: [ASB] check extracted credential secret when provision/bind/unbind/update/deprovision
    Given I save the first service broker registry prefix to :prefix clipboard
    And I have a project
    And evaluation of `project.name` is stored in the :user_project clipboard
    #provision postgresql apb
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-template.yaml |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                |
      | p | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-postgresql-apb                                                          |
      | p | PLAN_EXTERNAL_NAME=dev                                                                                       |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                       |
      | p | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-postgresql-apb").uid` is stored in the :db_uid clipboard
    And evaluation of `service_instance("<%= cb.prefix %>-postgresql-apb").external_id` is stored in the :instance_id clipboard
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-parameters-template.yaml      |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-parameters                                                                       |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                                                |
      | p | PARAMETERS={"postgresql_database":"admin","postgresql_user":"admin","postgresql_version":"10","postgresql_password":"test"} |
      | p | UID=<%= cb.db_uid %>                                                                                                         |
      | n | <%= project.name %>                                                                                                          |
    Then the step should succeed
    And I wait for the "<%= cb.prefix %>-postgresql-apb" service_instance to become ready up to 360 seconds
    And dc with name matching /postgresql/ are stored in the :db clipboard
    And a pod becomes ready with labels:
      | deployment=<%= cb.db.first.name %>-1 |

    # check secret in ansible-service-broker
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And I check that the "<%= cb.instance_id %>" secret exists
    When I run the :describe client command with:
      | resource           | secret     |
      | name               | <%= cb.instance_id %>   |
    And the output should contain:
      |   bundleAction=provision |
      |   bundleName=<%= cb.prefix %>-postgresql-apb |

    # create binding
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/servicebinding-template.yaml |
      | p | BINDING_NAME=<%= cb.prefix %>-postgresql-apb                                                                |
      | p | INSTANCE_NAME=<%= cb.prefix %>-postgresql-apb                                                               |
      | p | SECRET_NAME=<%= cb.prefix %>-postgresql-apb-credentials                                                     |
      | n | <%= project.name %>                                                                                         |
    Then the step should succeed
    And I wait for the "<%= cb.prefix %>-postgresql-apb" service_binding to become ready up to 60 seconds
    And evaluation of `service_binding("<%= cb.prefix %>-postgresql-apb").external_id` is stored in the :binding_id clipboard

    # check secret in ansible-service-broker
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And I check that the "<%= cb.binding_id %>" secret exists
    When I run the :describe client command with:
      | resource           | secret     |
      | name               | <%= cb.binding_id %>   |
    And the output should contain:
      |   bundleAction=bind |
      |   bundleName=<%= cb.prefix %>-postgresql-apb |

    # delete binding
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    And I ensure "<%= cb.prefix %>-postgresql-apb" service_binding is deleted

    # check secret
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And I wait for the resource "secret" named "<%= cb.binding_id %>" to disappear within 60 seconds

#    # update serviceinstance
#    Given I switch to the first user
#    And I use the "<%= cb.user_project %>" project
#    When I run the :patch client command with:
#      | resource  | serviceinstance/<%= cb.prefix %>-postgresql-apb      |
#      | p         |{                                                     |
#      |           | "spec": {                                            |
#      |           |    "clusterServicePlanExternalName": "prod"   |
#      |           |  }                                                   |
#      |           |}                                                     |
#    Then the step should succeed
#
#    # check secret in ansible-service-broker
#    Given I switch to cluster admin pseudo user
#    And I use the "openshift-ansible-service-broker" project
#    And I wait up to 60 seconds for the steps to pass:
#    """
#    When I run the :describe client command with:
#      | resource           | secret     |
#      | name               | <%= cb.instance_id %>   |
#    And the output should contain:
#      |   bundleAction=update |
#    """
#
    # delete serviceinstance and check secret
    Given I switch to the first user
    And I use the "<%= cb.user_project %>" project
    And I ensure "<%= cb.prefix %>-postgresql-apb" service_instance is deleted
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And I wait for the resource "secret" named "<%= cb.instance_id %>" to disappear within 60 seconds

  # @author zitang@redhat.com
  # @case_id OCP-19737
  @admin
  Scenario: extracted credential secret in ansible-service-broker namespace will be deleted when delete project
    Given I save the first service broker registry prefix to :prefix clipboard
    And I have a project
    And evaluation of `project.name` is stored in the :user_project clipboard
    #provision mariadb apb
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-template.yaml |
      | p | INSTANCE_NAME=<%= cb.prefix %>-mariadb-apb                                                                |
      | p | CLASS_EXTERNAL_NAME=<%= cb.prefix %>-mariadb-apb                                                          |
      | p | PLAN_EXTERNAL_NAME=dev                                                                                       |
      | p | SECRET_NAME=<%= cb.prefix %>-mariadb-apb-parameters                                                       |
      | p | INSTANCE_NAMESPACE=<%= project.name %>                                                                       |
    Then the step should succeed
    And evaluation of `service_instance("<%= cb.prefix %>-mariadb-apb").uid` is stored in the :db_uid clipboard
    And evaluation of `service_instance("<%= cb.prefix %>-mariadb-apb").external_id` is stored in the :instance_id clipboard
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/serviceinstance-parameters-template.yaml      |
      | p | SECRET_NAME=<%= cb.prefix %>-mariadb-apb-parameters                                                                       |
      | p | INSTANCE_NAME=<%= cb.prefix %>-mariadb-apb                                                                                |
      | p | PARAMETERS={"mariadb_database":"admin","mariadb_user":"admin","mariadb_version":"10.2","mariadb_root_password":"test","mariadb_password":"test"} |
      | p | UID=<%= cb.db_uid %>                                                                                                         |
      | n | <%= project.name %>                                                                                                          |
    Then the step should succeed
    And I wait for the "<%= cb.prefix %>-mariadb-apb" service_instance to become ready up to 360 seconds
    And dc with name matching /mariadb/ are stored in the :db clipboard
    And a pod becomes ready with labels:
      | deployment=<%= cb.db.first.name %>-1 |

    # create binding
    When I process and create:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/svc-catalog/servicebinding-template.yaml |
      | p | BINDING_NAME=<%= cb.prefix %>-mariadb-apb                                                                |
      | p | INSTANCE_NAME=<%= cb.prefix %>-mariadb-apb                                                               |
      | p | SECRET_NAME=<%= cb.prefix %>-mariadb-apb-credentials                                                     |
      | n | <%= project.name %>                                                                                         |
    Then the step should succeed
    And I wait for the "<%= cb.prefix %>-mariadb-apb" service_binding to become ready up to 60 seconds
    And evaluation of `service_binding("<%= cb.prefix %>-mariadb-apb").external_id` is stored in the :binding_id clipboard

    # check secret
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And I check that the "<%= cb.instance_id %>" secret exists
    And I check that the "<%= cb.binding_id %>" secret exists

    # delete project and check secret
    Given I switch to the first user
    And I ensure "<%= cb.user_project %>" project is deleted
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And I wait for the resource "secret" named "<%= cb.instance_id %>" to disappear within 60 seconds
    And I wait for the resource "secret" named "<%= cb.binding_id %>" to disappear within 60 seconds


  # @author zitang@redhat.com
  # @case_id OCP-20415
  @admin
  Scenario: [ASB] check broker /osb/ endpoint
    Given I switch to cluster admin pseudo user
    And the expression should be true> cluster_service_broker("ansible-service-broker").url.end_with? "/osb"
    When I run the :get client command with:
      | resource         | clusterrole    |
      | resource_name    |   access-ansible-service-broker-openshift-ansible-service-broker-role   |
      | o                | yaml           |
    Then the output should contain:
      | /osb    |
      | /osb/*  |
