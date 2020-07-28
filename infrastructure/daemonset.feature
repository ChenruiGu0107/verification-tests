Feature: Features of daemonset
  # @author dma@redhat.com
  # @author weinliu@redhat.com
  # @case_id OCP-11525
  @admin
  Scenario: Deleting a DaemonSet will delete its pods as well
    Given I have a project
    Given I run the :patch admin command with:
      | resource      | namespace                                                        |
      | resource_name | <%=project.name%>                                                |
      | p             | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}} |
    Given I obtain test data file "daemon/daemonset.yaml"
    When I run the :create admin command with:
      | f | daemonset.yaml      |
      | n | <%= project.name %> |
    Then the step should succeed
    And I store the number of worker nodes to the :num_workers clipboard
    Given I store the workers in the :workers clipboard
    And <%= cb.num_workers %> pods become ready with labels:
      | name=hello-daemonset |
    Then I run the :get client command with:
      | resource | pod  |
      | o        | name |
    And the step should succeed
    Given evaluation of `@result[:response].strip` is stored in the :allpods clipboard
    Given I store in the clipboard the pods labeled:
      | name=hello-daemonset |
    Then the expression should be true> cb.num_workers == cb.pods.count
    And the expression should be true> (cb.workers.map(&:name) - cb.pods.map(&:node_name)).empty?
    When I run the :delete admin command with:
      | object_type       | daemonset           |
      | object_name_or_id | hello-daemonset     |
      | cascade           | false               |
      | n                 | <%= project.name %> |
    And the step should succeed
    And admin ensures "hello-daemonset" ds is deleted from the project
    When I run the :get client command with:
       | resource | pod  |
       | o        | name |
    Then the step should succeed
    And the expression should be true> @result[:response].strip == "<%= cb.allpods %>"
    Given I obtain test data file "daemon/daemonset.yaml"
    When I run the :create admin command with:
      | f | daemonset.yaml      |
      | n | <%= project.name %> |
    Then the step should succeed
    Given all pods in the project are ready
    And I store in the clipboard the pods labeled:
      | name=hello-daemonset |
    Then the expression should be true> cb.num_workers == cb.pods.count
    And the expression should be true> (cb.workers.map(&:name) - cb.pods.map(&:node_name)).empty?
    When I run the :delete admin command with:
      | object_type       | daemonset           |
      | object_name_or_id | hello-daemonset     |
      | cascade           | true                |
      | n                 | <%= project.name %> |
    Then the step should succeed
    Given admin ensures "hello-daemonset" ds is deleted from the project

  # @author dma@redhat.com
  # @case_id OCP-11183
  @admin
  @destructive
  Scenario: DaemonSet will remove/add pod when node is removed/added
    Given environment has at least 2 nodes
    Given I store the nodes in the :nodes clipboard
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    Given I obtain test data file "daemon/daemonset.yaml"
    When I run the :create admin command with:
      | f | daemonset.yaml |
      | n | <%= project.name %>                                                                      |
    And the step should succeed
    Given all pods in the project are ready
    Given I store in the clipboard the pods labeled:
      | name=hello-daemonset |
    Then the expression should be true> env.nodes.count == cb.pods.count
    And the expression should be true> (env.nodes.map(&:name) - cb.pods.map(&:node_name)).empty?
    Given I use the "<%= cb.nodes[0].name %>" node
    Given I register clean-up steps:
    """
    Given the node service is restarted on the host
    Then the expression should be true> cb.nodes.size == env.nodes(refresh: true).size
    """
    When I run the :get admin command with:
      | resource      | node                    |
      | resource_name | <%= cb.nodes[0].name %> |
      | o             | yaml                    |
    Then the step should succeed
    And I save the output to file> node.yaml
    When I run the :delete admin command with:
      | object_type       | node                    |
      | object_name_or_id | <%= cb.nodes[0].name %> |
    Then the step should succeed
    And admin ensures "<%= cb.nodes[0].name %>" node is deleted
    Then I wait up to 60 seconds for the steps to pass:
    """
    Given I store in the clipboard the pods labeled:
      | name=hello-daemonset |
    Then the expression should be true> env.nodes(refresh: true).count == cb.pods.count
    And the expression should be true> (env.nodes(refresh: true).map(&:name) - cb.pods.map(&:node_name)).empty?
    """
    When I run the :create admin command with:
      | f | node.yaml |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | node                    |
      | resource_name | <%= cb.nodes[0].name %> |
    Then the step should succeed
    And the output should match:
      | <%= cb.nodes[0].name %>\\s*Ready|
    """
    Then I wait up to 60 seconds for the steps to pass:
    """
    Given I store in the clipboard the pods labeled:
      | name=hello-daemonset |
    Then the expression should be true> env.nodes(refresh: true).count == cb.pods.count
    And the expression should be true> (env.nodes(refresh: true).map(&:name) - cb.pods.map(&:node_name)).empty?
    """
