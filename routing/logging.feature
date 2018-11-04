Feature: Testing HAProxy router logging related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-16902
  @admin
  @destructive
  Scenario: can set haproxy router logging facility by env
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    Given admin ensures new router pod becomes ready after following env added:
      | ROUTER_SYSLOG_ADDRESS=127.0.0.1 |
      | ROUTER_LOG_FACILITY=local2      |
    And evaluation of `pod.name` is stored in the :router_pod clipboard

    And I wait up to 10 seconds for the steps to pass:
    """
    When I execute on the "<%=cb.router_pod %>" pod:
      | grep | log | /var/lib/haproxy/conf/haproxy.config |
    Then the output should contain:
      | log 127.0.0.1 local2 warning |
    """

