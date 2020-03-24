Feature:CRI related features
  # @author weinliu@redhat.com
  # @case_id OCP-14400
  @admin
  Scenario: check the CRI can be work fine with pod and accessing container by default setting	
    Given the master version == "3.6"
    And I use the first master host
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    When I execute on the pod:
      | hostname |
    Then the output by order should match:
      | hello-pod |
    When I run the :attach client command with:
      | pod      | hello-pod |
      | i        |           |
      | t        |           |
      | _timeout | 20        |
    Then the step should have timed out
    And evaluation of `rand(5001..7999)` is stored in the :port1 clipboard
    When I run the :port_forward background client command with:
      | pod       | hello-pod |
      | port_spec | <%= cb[:port1] %>:5000|   
    Then the step should succeed
        When I run the :exec client command with:
      | pod          | hello-pod |
      | exec_command | hostname  |
    Then the step should succeed
    And the output should contain "hello-pod"

  # @author weinliu@redhat.com
  # @case_id OCP-14452
  @destructive
  @admin
  Scenario: check the CRI can be working fine with pod and accessing container if disable parameter enable-cri
    Given the master version == "3.6"
    And I use the first master host
    And config of all nodes is merged with the following hash:
    """ 
    kubeletArguments:
     enable-cri:
     - 'false'
    """
    And the node service is restarted on all nodes 
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/infrastructure/podpreset/hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    When I execute on the pod:
      | hostname |
    Then the output by order should match:
      | hello-pod |
    When I run the :attach client command with:
      | pod         | hello-pod |
      | container   | hello-pod |
      | tty         | true      |
      | stdin       | true      |
      | _timeout    | 20        |
    Then the step should have timed out
    And evaluation of `rand(5001..7999)` is stored in the :port1 clipboard
    When I run the :port_forward background client command with:
      | pod       | hello-pod |
      | port_spec | <%= cb[:port1] %>:5000|   
    Then the step should succeed
        When I run the :exec client command with:
      | pod          | hello-pod |
      | exec_command | hostname  |
    Then the step should succeed
    And the output should contain "hello-pod"
