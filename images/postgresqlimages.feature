Feature: Postgresql images test

  # @author cryan@redhat.com
  # @case_id OCP-12251
  Scenario: Create nodejs postgresql applicaion - nodejs-010-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/image/db-templates/nodejs-template-stibuild.json |
    Then the step should succeed
    Given the "nodejs-sample-build-1" build completes
    Given I get project routes
    Then the output should contain "route-edge"
    Given 2 pods become ready with labels:
      | deployment=frontend-1 |
    When I execute on the pod:
      | curl | localhost:8080 |
    Then the output should contain:
      | Hello |
      | 0.10  |
      | 9.2   |

  # @author wewang@redhat.com
  Scenario Outline: Use customized values for memory limits env vars - postgresql
    Given I have a project
    When I run the :new_app client command with:
      | name              | psql                                 |
      | docker_image      | <%= product_docker_repo %><image>    |
      | env               | POSTGRESQL_USER=user                 |
      | env               | POSTGRESQL_PASSWORD=redhat           |
      | env               | POSTGRESQL_DATABASE=sampledbt        |
      | env               | POSTGRESQL_SHARED_BUFFERS=16MB       |
      | env               | POSTGRESQL_EFFECTIVE_CACHE_SIZE=64MB |
      | insecure_registry | true                                 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=psql-1 |
    And I execute on the pod:
      | grep | -i | shared_buffers | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "shared_buffers = 16MB"
    Given I execute on the pod:
      | grep | -i | effective_cache_size | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "effective_cache_size = 64MB"
    Examples:
      | image                          |
      | rhscl/postgresql-95-rhel7      | # @case_id OCP-12388

  # @author wewang@redhat.com
  Scenario Outline: Use default values for memory limits env vars - postgresql
    Given I have a project
    When I run the :run client command with:
      | name   | psql                              |
      | image  | <%= product_docker_repo %><image> |
      | env    | POSTGRESQL_USER=user              |
      | env    | POSTGRESQL_PASSWORD=redhat        |
      | env    | POSTGRESQL_DATABASE=sampledb      |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=psql-1 |
    And I execute on the pod:
      | grep | -i | shared_buffers | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "shared_buffers = 32MB"
    Given I execute on the pod:
      | grep | -i | effective_cache_size | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "effective_cache_size = 128MB"

    Examples:
      | image                          |
      | rhscl/postgresql-94-rhel7      | # @case_id OCP-12068
      | rhscl/postgresql-95-rhel7      | # @case_id OCP-12409
