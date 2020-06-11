Feature: oc_expose.feature
  # @author yadu@redhat.com
  # @case_id OCP-11548
  Scenario: Use service port name as route port.targetPort after 'oc expose service'
    Given I have a project
    Given I obtain test data file "cases/515695/svc_with_name.yaml"
    When I run the :create client command with:
      | f | svc_with_name.yaml |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | svc      |
      | resource name | frontend |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | route                       |
      | resource_name | frontend                    |
      | template      | "{{.spec.port.targetPort}}" |
    Then the step should succeed
    And the output should contain "web"
    When I run the :delete client command with:
      | object_type       | service  |
      | object_name_or_id | frontend |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | route    |
      | object_name_or_id | frontend |
    Then the step should succeed
    Given I obtain test data file "cases/515695/svc_without_name.yaml"
    When I run the :create client command with:
      | f | svc_without_name.yaml |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | svc      |
      | resource name | frontend |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | route                       |
      | resource_name | frontend                    |
      | template      | "{{.spec.port.targetPort}}" |
    Then the step should succeed
    And the output should not contain "web"
