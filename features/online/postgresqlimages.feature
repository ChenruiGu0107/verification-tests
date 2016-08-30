Feature: ONLY ONLINE PostgreSQL images related feature's scripts in this file

  # @author etrott@redhat.com
  # @case_id 532768
  Scenario: Use customized values for memory limits env vars - postgresql-95-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/postgresql:9.5             |
      | env          | POSTGRESQL_USER=user                 |
      | env          | POSTGRESQL_DATABASE=sampledb         |
      | env          | POSTGRESQL_PASSWORD=redhat           |
      | env          | POSTGRESQL_SHARED_BUFFERS=16MB       |
      | env          | POSTGRESQL_EFFECTIVE_CACHE_SIZE=64MB |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=postgresql-1 |
    And I execute on the pod:
      | grep | -i | shared_buffers | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "shared_buffers = 16MB"
    Given I execute on the pod:
      | grep | -i | effective_cache_size | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "effective_cache_size = 64MB"

  # @author etrott@redhat.com
  # @case_id 532770
  Scenario: Use default values for memory limits env vars - postgresql-95-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/postgresql:9.5     |
      | env          | POSTGRESQL_USER=user         |
      | env          | POSTGRESQL_DATABASE=sampledb |
      | env          | POSTGRESQL_PASSWORD=redhat   |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=postgresql-1 |
    And I execute on the pod:
      | grep | -i | shared_buffers | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "shared_buffers = 128MB"
    Given I execute on the pod:
      | grep | -i | effective_cache_size | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "effective_cache_size = 256MB"

  # @author etrott@redhat.com
  # @case_id 532757
  Scenario: Check memory limits env vars when pod is set with memory limit - postgresql-95-rhel7
    Given I have a project
    When I run the :create client command with:
      | f   | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/tc532757/psql.json |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=psql-1 |
    And I execute on the pod:
      | grep | shared_buffers | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "shared_buffers = 64MB"
    Given I execute on the pod:
      | grep | effective_cache_size | /var/lib/pgsql/openshift-custom-postgresql.conf |
    Then the output should contain "effective_cache_size = 128MB"
