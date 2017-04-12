Feature: Node management
  # @author chaoyang@redhat.com
  # @case_id OCP-11084
  @admin
  Scenario: admin can get nodes
    Given I have a project
    When I run the :get admin command with:
      |resource|nodes|
    Then the step should succeed
    Then the outputs should contain "Ready"


  # @author yinzhou@redhat.com
  # @case_id OCP-11706
  @admin
  Scenario: The valid client cert and key should be accepted when connect to kubelet	
    Given I use the first master host
    And I run commands on the host:
      | curl https://<%= host.hostname %>:10250/spec/ --cert /etc/origin/master/master.kubelet-client.crt  --cacert /etc/origin/master/ca.crt --key /etc/origin/master/master.kubelet-client.key |
    Then the step should succeed


  # @author yinzhou@redhat.com
  # @case_id OCP-10712,OCP-11190,OCP-11755,OCP-11529
  @admin
  @destructive
  Scenario: Anonymous user can fetch metrics/stats after grant permission to it
    Given I use the first master host
    When I run commands on the host:
      | curl -X GET -k https://<%= node.name %>:10250/stats/ |
    And the output should contain "Forbidden"
    Given config of all nodes is merged with the following hash:
    """
    authConfig:
      authenticationCacheSize: 1000
      authenticationCacheTTL: "1m"
      authorizationCacheSize: 1000
      authorizationCacheTTL: "1m"
    """
    Then the step should succeed
    And the node service is restarted on all nodes
    Given cluster role "system:node-reader" is added to the "system:unauthenticated" group
    And 62 seconds have passed
    When I run commands on the host:
      | curl -X GET -k https://<%= node.name %>:10250/stats/ |
    And the output should not contain "Forbidden"
    Given I have a project
    When I run commands on the host:
      | curl -X GET -k https://<%= node.name %>:10250/stats/ -H "Authorization: Bearer <%= user.get_bearer_token.token %> " |
    And the output should contain "Forbidden"
    Given cluster role "system:node-reader" is added to the "first" user
    And 62 seconds have passed
    When I run commands on the host:
      | curl -X GET -k https://<%= node.name %>:10250/stats/ -H "Authorization: Bearer <%= user.get_bearer_token.token %> " |
    And the output should not contain "Forbidden"
    When I find a bearer token of the deployer service account
    When I run commands on the host:
      | curl -X GET -k https://<%= node.name %>:10250/stats/ -H "Authorization: Bearer <%= service_account.get_bearer_token.token %> " |
    And the output should contain "Forbidden"
    Given cluster role "system:node-reader" is added to the "system:serviceaccount:<%= project.name %>:deployer" service account
    And 62 seconds have passed
    When I run commands on the host:
      | curl -X GET -k https://<%= node.name %>:10250/stats/ -H "Authorization: Bearer <%= service_account.get_bearer_token.token %> " |
    And the output should not contain "Forbidden"
