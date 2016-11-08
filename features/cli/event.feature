Feature: Event related scenarios
  # @author chezhang@redhat.com
  # @case_id 515451
  @admin
  Scenario: check event compressed in kube
    Given I have a project
    When I run the :new_app admin command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota_template.yaml |
      | param | CPU_VALUE=20    |
      | param | MEM_VALUE=1Gi   |
      | param | PV_VALUE=10     |
      | param | POD_VALUE=10    |
      | param | RC_VALUE=20     |
      | param | RQ_VALUE=1      |
      | param | SECRET_VALUE=10 |
      | param | SVC_VALUE=5     |
      | n     | <%= project.name %>            |
    Then the step should succeed
    When  I run the :describe client command with:
      | resource  | quota   |
      | name      | myquota |
    Then the output should match:
      | cpu\\s+0\\s+20                    |
      | memory\\s+0\\s+1Gi                |
      | persistentvolumeclaims\\s+0\\s+10 |
      | pods\\s+0\\s+10                   |
      | replicationcontrollers\\s+0\\s+20 |
      | resourcequotas\\s+1\\s+1          |
      | secrets\\s+9\\s+10                |
      | services\\s+0\\s+5                |
    When I run the :run client command with:
      | name      | nginx   |
      | image     | nginx   |
      | replicas  | 1       |
    Then the step should succeed
    When I get project events
    Then the output should match:
      | forbidden.*quota.*must specify cpu,memory |
    When  I run the :describe client command with:
      | resource  | dc      |
      | name      | nginx   |
    Then the output should match:
      | forbidden.*quota.*must specify cpu,memory |

  # @author chezhang@redhat.com
  # @case_id 515449
  Scenario: Check normal and warning information for kubernetes events
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    When I get project events
    Then the output should match:
      | hello-openshift.*Normal\\s+Scheduled |
      | hello-openshift.*Normal\\s+Pulled    |
      | hello-openshift.*Normal\\s+Created   |
      | hello-openshift.*Normal\\s+Started   |
    When  I run the :describe client command with:
      | resource  | pods             |
      | name      | hello-openshift  |
    Then the output should match:
      | Normal\\s+Scheduled |
      | Normal\\s+Pulled    |
      | Normal\\s+Created   |
      | Normal\\s+Started   |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/pod-invalid.yaml |
    Then the step should succeed
    And I wait up to 240 seconds for the steps to pass:
    """
    When I get project events
    Then the output should match:
      | hello-openshift-invalid.*Normal\\s+Scheduled   |
      | hello-openshift-invalid.*Warning\\s+FailedSync |
      | hello-openshift-invalid.*Normal\\s+BackOff     |
    And the output should match 3 times:
      | hello-openshift-invalid.*Warning\\s+Failed     |
    """
    When  I run the :describe client command with:
      | resource  | pods                    |
      | name      | hello-openshift-invalid |
    Then the output should match:
      | Normal\\s+Scheduled   |
      | Warning\\s+FailedSync |
      | Normal\\s+BackOff     |
    And the output should match 3 times:
      | Warning\\s+Failed     |

  # @author yanpzhan@redhat.com
  # @case_id 532269
  Scenario: Project should only watch its owned cache events
    When I run the :new_project client command with:
      | project_name | eventcache532269 |
    Then the step should succeed
    Given I switch to the second user
    When I run the :new_project client command with:
      | project_name | eventcache532269-1 |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | admin                              |
      | user_name | <%= user(0, switch: false).name %> |
      | n         | eventcache532269-1                 |
    Then the step should succeed
    Given I switch to the first user
    When I run the :get background client command with:
      | resource | secrets          |
      | o        | name             |
      | n        | eventcache532269 |
      | w        | true             |
    Then the step should succeed

    # Cucumber runs fast. If not wait here, oc get --watch would be killed at
    # once and have empty output, so wait some time for the output to show up
    Given 20 seconds have passed
    When I terminate last background process
    And evaluation of `@result[:response]` is stored in the :watchevent clipboard

    When I run the :get background client command with:
      | resource | secrets            |
      | o        | name               |
      | n        | eventcache532269-1 |
      | w        | true               |
    Then the step should succeed

    # Same reason as above
    Given 20 seconds have passed
    When I terminate last background process
    And evaluation of `@result[:response]` is stored in the :watchevent1 clipboard

    When I run the :get background client command with:
      | resource | secrets          |
      | o        | name             |
      | n        | eventcache532269 |
      | w        | true             |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | secrets            |
      | n           | eventcache532269-1 |
      | all         |                    |
    Then the step should succeed

    # Same reason as above
    Given 20 seconds have passed
    When I terminate last background process
    And the output should equal "<%= cb.watchevent %>"

    When I run the :get background client command with:
      | resource | secrets            |
      | o        | name               |
      | n        | eventcache532269-1 |
      | w        | true               |
    Then the step should succeed

    # Same reason as above
    Given 20 seconds have passed
    When I terminate last background process
    And the expression should be true> @result[:response] != "<%= cb.watchevent1 %>"

  # @author dma@redhat.com
  # @case_id 533910
  Scenario: Event should show full failed reason when readiness probe failed
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/tc533910/readiness-probe-exec.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" status becomes :running
    And I wait up to 120 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod       |
      | name     | hello-pod |
    Then the output should match:
      | Unhealthy\tReadiness probe failed:.*exec failed.*\/bin\/hello: no such file or directory |
    """
