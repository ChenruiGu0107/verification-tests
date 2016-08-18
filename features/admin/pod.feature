Feature: pod related features
  # @author pruan@redhat.com
  # @case_id 470710
  @admin
  Scenario: Expose shared memory of the pod--Clustered
    Given I have a project
    And I select a random node's host
    When I run the :new_app client command with:
      | app_repo | openshift/deployment-example |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | app=deployment-example |
    Given the system container id for the pod is stored in the clipboard
    And evaluation of `pod.container(user: user, name: 'deployment-example').id` is stored in the :container_id clipboard
    When I run commands on the host:
      | docker inspect <%= cb.container_id %> \|grep Mode |
    Then the step should succeed
    And the output should contain:
      | "NetworkMode": "container:<%= cb.system_pod_container_id %> |
      | "IpcMode": "container:<%= cb.system_pod_container_id %>     |
    When I run commands on the host:
      | docker inspect <%= cb.container_id %> \|grep Pid |
    Then the step should succeed
    And evaluation of `/"Pid":\s+(\d+)/.match(@result[:response])[1]` is stored in the :user_container_pid clipboard
    When I run commands on the host:
      | docker inspect <%= cb.system_pod_container_id %> \|grep Pid |
    Then the step should succeed
    And evaluation of `/"Pid":\s+(\d+)/.match(@result[:response])[1]` is stored in the :system_container_pid clipboard
    When I run commands on the host:
      | ls -l /proc/<%= cb.system_container_pid %>/ns |
    Then the step should succeed
    And evaluation of `/ipc:\[(\d+)\]/.match(@result[:response])[1]` is stored in the :system_ipc clipboard
    And evaluation of `/net:\[(\d+)\]/.match(@result[:response])[1]` is stored in the :system_net clipboard
    When I run commands on the host:
      | ls -l /proc/<%= cb.user_container_pid %>/ns |
    Then the step should succeed
    And evaluation of `/ipc:\[(\d+)\]/.match(@result[:response])[1]` is stored in the :user_ipc clipboard
    And evaluation of `/net:\[(\d+)\]/.match(@result[:response])[1]` is stored in the :user_net clipboard
    Then the expression should be true> cb.system_ipc == cb.user_ipc
    Then the expression should be true> cb.system_net == cb.user_net

  # @author pruan@redhat.com
  # @case_id 489257
  @admin
  Scenario: Expose shared memory of the pod via POSIX IPC sharing
    Given I have a project
    And I select a random node's host
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/container/sharememory.json |
    And the pod named "hello-openshift" becomes ready
    Given the system container id for the pod is stored in the clipboard
    And evaluation of `pod.container(user: user, name: 'hello-container1').id` is stored in the :container1_id clipboard
    And evaluation of `pod.container(user: user, name: 'hello-container2').id` is stored in the :container2_id clipboard
    When I run commands on the host:
      | docker inspect <%= cb.container1_id %> \|grep dshm|
    Then the step should succeed
    And evaluation of `/"Source":\s+"(.*)\/dshm/.match(@result[:response])[1]` is stored in the :inspect_1_out clipboard
    When I run commands on the host:
      | docker inspect <%= cb.container2_id %> \|grep dshm|
    Then the step should succeed
    And evaluation of `/"Source":\s+"(.*)\/dshm/.match(@result[:response])[1]` is stored in the :inspect_2_out clipboard
    Then the expression should be true> cb.inspect_1_out == cb.inspect_2_out
    When I run commands on the host:
      | ls -al <%= cb.inspect_1_out %> |
    Then the step should succeed
    And the output should contain "dshm"
    And I run the :delete client command with:
      | object_type       | pod             |
      | object_name_or_id | hello-openshift |
    Then the step should succeed
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run commands on the host:
      | ls -al <%= cb.inspect_1_out %> |
    And the output should contain "No such file or directory"
    """