Feature: oc_version.feature

  # @author chali@redhat.com
  # @case_id OCP-12077
  Scenario:Get server openshift version from oc version
    Given a "empty1" file is created with the following lines:
      |                 |
    When I run the :version client command with:
      | config | empty1 |
    Then the step should succeed
    And the output should match:
      | oc.*            |
      | kubernetes.*    |
    When I run the :version client command
    Then the step should succeed
    And the output should match:
      | oc.*            |
      | kubernetes.*    |
      | [Ss]erver.*     |
      | [Oo]penshift.*  |
    When I run the :config_view client command
    And I save the output to file> user1.kubeconfig
    Given I replace lines in "user1.kubeconfig":
      | <%= env.master_hosts[0].hostname %> | not<%= env.master_hosts[0].hostname %> |
    When I run the :version client command with:
      | config | user1.kubeconfig |
    Then the step should fail
    And the output should match:
      | oc.*                    |
      | kubernetes.*            |
      | ([Ee]rror.*\|[Uu]nable) |

