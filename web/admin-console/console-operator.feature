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

  # @author yapei@redhat.com
  # @case_id OCP-33543
  @admin
  @destructive
  Scenario: force user log out when inactivity timeout is reached
    Given the master version >= "4.6"
    Given the first user is cluster-admin
    Given I register clean-up steps:
    """
    Given as admin I successfully merge patch resource "oauth.config/cluster" with:
      | {"spec":{"tokenConfig":{"accessTokenInactivityTimeout": null}}} |
    Given as admin I successfully merge patch resource "oauthclient/console" with:
      | {"accessTokenInactivityTimeoutSeconds":null} |
    """
    And I use the "openshift-console" project
    And evaluation of `deployment("console").generation_number(cached: false)` is stored in the :before_change clipboard
    Given as admin I successfully merge patch resource "oauth.config/cluster" with:
      | {"spec":{"tokenConfig":{"accessTokenInactivityTimeout": "600s"}}} |
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I get project configmap named "console-config" as JSON
    Then the output should match:
      | inactivityTimeoutSeconds: 600 |
    """
    And evaluation of `deployment("console").generation_number(cached: false)` is stored in the :after_first_change clipboard
    Then the expression should be true> <%= cb.after_first_change %> == <%= cb.before_change %> + 1

    Given as admin I successfully merge patch resource "oauthclient/console" with:
      | {"accessTokenInactivityTimeoutSeconds":300} |
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I get project configmap named "console-config" as JSON
    Then the output should match:
      | inactivityTimeoutSeconds: 300 |
    """
    And evaluation of `deployment("console").generation_number(cached: false)` is stored in the :after_second_change clipboard
    Then the expression should be true> <%= cb.after_second_change %> == <%= cb.after_first_change %> + 1
    Given number of replicas of the current replica set for the "console" deployment becomes:
      | desired  | 2 |
      | current  | 2 |
      | ready    | 2 |

    Given I open admin console in a browser
    When I run the :check_cluster_utilization_items web action
    Then the step should succeed
    Given 300 seconds have passed
    When I run the :check_on_login_page web action
    Then the step should succeed
    When I perform the :login_with_specified_idp web action with:
      | username | <%= user.auth_name %> |
      | password | <%= user.password  %> |
    Then the step should succeed
    When I run the :check_cluster_utilization_items web action
    Then the step should succeed
    Given 300 seconds have passed
    When I run the :check_on_login_page web action
    Then the step should succeed
