Feature: service related scenarios
  # @author yinzhou@redhat.com
  # @case_id 535538
  @admin
  Scenario: Create clusterip service
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/hello-openshift.json |
    Then the step should succeed
    When I run the :create client command with:
      | help |  |
    Then the step should succeed
    And the output should contain "Create a service"
    When I run the :create_service client command with:
      | createservice_type | |
      | help               | |
    Then the step should succeed
    And the output should contain:
      | Available Commands: |
      | clusterip           |
      | loadbalancer        |
    When I run the :create_service client command with:
      | createservice_type  | clusterip       |
      | name                | hello-openshift |
      | tcp                 | <%= rand(6000..9000) %>:8080       |
    Then the step should succeed
    Given I wait for the "hello-openshift" service to become ready
    And I select a random node's host
    When I run commands on the host:
      | curl <%= service.url %> |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift! |
    When I run the :delete client command with:
      | object_type       | service         |
      | object_name_or_id | hello-openshift |
    Then the step should succeed
    When I run the :create_service client command with:
      | createservice_type  | clusterip       |
      | name                | hello-openshift |
      | clusterip           | 172.30.250.227  |
      | tcp                 | <%= rand(6000..9000) %>:8080       |
    Then the step should succeed
    Given I wait for the "hello-openshift" service to become ready
    And I select a random node's host
    When I run commands on the host:
      | curl <%= service.url %> |
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift! |
    When I run the :create_service client command with:
      | createservice_type  | clusterip       |
      | name                | hello-openshift |
    Then the step should fail
    And the output should contain:
      | tcp port |
    When I run the :create_service client command with:
      | createservice_type  | clusterip       |
      | name                | hello-pod       |
      | tcp                 | 5678:8080       |
      | dry_run             | true            |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | svc       |
      | resource_name | hello-pod |
    Then the step should fail

