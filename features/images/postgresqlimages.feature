Feature: Postgresql images test

  # @author haowang@redhat.com
  # @case_id 511970
  Scenario: postgresql-ephemeral with postgresql-92-rhel7 image
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/postgresql-92-ephemeral-template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      |name=postgresql|

  # @author cryan@redhat.com
  # @case_id OCP-12251
  Scenario: Create nodejs postgresql applicaion - nodejs-010-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/nodejs-template-stibuild.json |
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

  # @author cryan@redhat.com
  # @case_id OCP-10858 OCP-11284 OCP-11292
  Scenario Outline: Check memory limits env vars when pod is set with memory limit - postgresql
    Given I have a project
    When I run the :new_app client command with:
      | name         | psql                              |
      | docker_image | <%= product_docker_repo %><image> |
      | env          | POSTGRESQL_USER=user              |
      | env          | POSTGRESQL_PASSWORD=redhat        |
      | env          | POSTGRESQL_DATABASE=sampledb      |
    Then the step should succeed
    Given I wait until the status of deployment "psql" becomes :running
    When I run the :patch client command with:
      | resource      | dc                                                                                                         |
      | resource_name | psql                                                                                                       |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"psql","resources":{"limits":{"memory":"256Mi"}}}]}}}}  |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"psql","resources":{"request":{"memory":"256Mi"}}}]}}}} |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=psql-1 |
    And I execute on the pod:
      | grep | shared_buffers | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "shared_buffers = 128MB"
    Given I execute on the pod:
      | grep | effective_cache_size | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "effective_cache_size = 256MB"
    Examples:
      | image                          |
      | openshift3/postgresql-92-rhel7 |
      | rhscl/postgresql-94-rhel7      |
      | rhscl/postgresql-95-rhel7      |

  # @author wewang@redhat.com
  # @case_id OCP-11793 OCP-11590 OCP-12388
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
      | openshift3/postgresql-92-rhel7 |
      | rhscl/postgresql-94-rhel7      |
      | rhscl/postgresql-95-rhel7      |

  # @author wewang@redhat.com
  # @case_id OCP-11959 OCP-12068 OCP-12409
  Scenario Outline: Use default values for memory limits env vars - postgresql
    Given I have a project
    When I run the :run client command with:
      | name   | psql                                                                         |
      | image  | <%= product_docker_repo %><image>                                            |
      | env    | POSTGRESQL_USER=user,POSTGRESQL_PASSWORD=redhat,POSTGRESQL_DATABASE=sampledb |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=psql-1 |
    And I execute on the pod:
      | grep | -i | shared_buffers | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "shared_buffers = 32MB"
    Given I execute on the pod:
      | grep | -i | effective_cache_size | var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "effective_cache_size = 128MB"

    Examples:
      | image                          |
      | openshift3/postgresql-92-rhel7 |
      | rhscl/postgresql-94-rhel7      |
      | rhscl/postgresql-95-rhel7      |
