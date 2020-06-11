Feature: console-operator related

  # @author hasha@redhat.com
  # @case_id OCP-22343
  @admin
  Scenario: console operator and console deployment have resource limits	
    Given the master version >= "4.1"
    Given the first user is cluster-admin
    Given I use the "openshift-console" project
    Given 2 pods become ready with labels:
      | app=console  |
      | component=ui |
    Then the expression should be true> pod.containers.first.spec.cpu_request_raw == '10m' and pod.containers.first.spec.memory_request_raw == '100Mi'
    Given 2 pods become ready with labels:
      | app=console         |
      | component=downloads |
    Then the expression should be true> pod.containers.first.spec.cpu_request_raw == '10m' and pod.containers.first.spec.memory_request_raw == '50Mi'
    Given I use the "openshift-console-operator" project
    Given a pod becomes ready with labels:
      | name=console-operator |
    Then the expression should be true> pod.containers.first.spec.cpu_request_raw == '10m' and pod.containers.first.spec.memory_request_raw == '100Mi'

  # @author hasha@redhat.com
  # @case_id OCP-25230
  @admin
  @destructive
  Scenario: Check console sync error reason code
    Given the master version >= "4.2"
    Given the first user is cluster-admin
    Given I use the "openshift-console" project
    Given a pod becomes ready with labels:
      | component=ui |
    And evaluation of `pod.name` is stored in the :pod_name clipboard

    Given I obtain test data file "cases/console-operator-role.yaml"
    When I run the :apply client command with:
      | f          | console-operator-role.yaml |
      | overwrite  | true |
    Then the step should succeed
    Given I ensure "console" deployments is deleted
    And I wait for the resource "pod" named "<%= cb.pod_name %>" to disappear
    Then the expression should be true> cluster_operator('console').condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator('console').condition(type: 'Degraded')['message'].include? "DeploymentSyncDegraded"
    Then I wait for the steps to pass:
    """
    Given 2 pods become ready with labels:
      | component=ui |
    """
