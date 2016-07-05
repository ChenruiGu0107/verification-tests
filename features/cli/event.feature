Feature: Event related scenarios
  # @author chezhang@redhat.com
  # @case_id 515451
  @admin
  Scenario: check event compressed in kube
    Given I have a project
    When I run the :new_app admin command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota_template.yaml        |
      | param | CPU_VALUE=20,MEM_VALUE=1Gi,PV_VALUE=10,POD_VALUE=10,RC_VALUE=20,RQ_VALUE=1,SECRET_VALUE=10,SVC_VALUE=5 |
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
