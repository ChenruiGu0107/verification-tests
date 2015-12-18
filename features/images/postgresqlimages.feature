Feature: Postgresql images test 

  # @author wewang@redhat.com
  # @case_id 473391 
  Scenario: Add env variables to postgresql-92-rhel7 image 
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/postgresql-92-rhel7-env-test.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      |name=database|
     When I execute on the pod:
      | env |
    Then the output should contain:
      | POSTGRESQL_SHARED_BUFFERS=64MB |
      | POSTGRESQL_MAX_CONNECTIONS=42  |
    When I execute on the pod:
      | psql | -c |show shared_buffers; |
    Then the output should contain:
      | shared_buffers |
      | 64MB           |
    And I execute on the pod:
      | psql | -c |show max_connections; |
    Then the output should contain:
      | max_connections |
      | 42              |


  # @author wewang@redhat.com
  # @case_id 508068 
  Scenario: Add env variables to postgresql-94-rhel7 image 
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/postgresql-94-rhel7-env-test.json|
    Then the step should succeed
    And a pod becomes ready with labels:
      |name=database|
     When I execute on the pod:
      | env  |
    Then the output should contain:
      | POSTGRESQL_SHARED_BUFFERS=64MB |
      | POSTGRESQL_MAX_CONNECTIONS=42  |
    When I execute on the pod:
      | psql | -c |show shared_buffers;|
    Then the output should contain:
      | shared_buffers |
      | 64MB           |
    And I execute on the pod:
      | psql | -c |show max_connections; |
    Then the output should contain:
      | max_connections |
      | 42              |













 
