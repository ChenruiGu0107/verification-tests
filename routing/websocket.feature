Feature: Testing websocket features

  # @author hongli@redhat.com
  # @case_id OCP-17146
  Scenario: haproxy router support websocket via edge route
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/websocket/pod.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/websocket/service_unsecure.json |
    Then the step should succeed
    When I run the :create_route_edge client command with:
      | name    | wss-edge    |
      | service | ws-unsecure |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | (echo SecureWebsocketTesting ; sleep 3) \| ws wss://<%= route("wss-edge", service("ws-unsecure")).dns(by: user) %>/echo |
    Then the step should succeed
    And the output should contain "< SecureWebsocketTesting"
    """
