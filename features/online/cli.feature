Feature: ONLY ONLINE Command Line Interface related scripts in this file

  # @author bingli@redhat.com
  # @case_id OCP-10127
  # @bug_id 1297910
  Scenario: [online]patch operation should use patched object to check admission control
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" status becomes :running
    When I run the :patch client command with:
      | resource      | pod             |
      | resource_name | hello-openshift |
      | p             | {"spec":{"containers":[{"name":"hello-openshift","image":"aosqe/hello-openshift"}]}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource   | pod                |
      | name       | hello-openshift    |
    Then the step should succeed
    And the output should match:
      | [Ii]mage.*aosqe/hello-openshift |
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the step should succeed
    And the output should match:
      | STATUS\\s+RESTARTS  |
      | [Rr]unning\\s+1     |
    """
