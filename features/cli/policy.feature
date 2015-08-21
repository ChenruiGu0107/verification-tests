Feature: change the policy of user/service account

  # @author anli@redhat.com
  # @case_id 479042
  Scenario: Add/Remove a global role
    Given the first user is cluster-admin 
    Given I have a project
    When I run the :get client command with:
      | resource   | pod |
      | namespace  | default |
    And the output should not contain:
      | cannot list pods in project "default" |
    When I run the :oadm_remove_cluster_role_from_user admin command with:
      | role_name  | cluster-admin |
      | user_name  | <%= user.name %>                                 |
    Then the step should succeed
    When I run the :get client command with:
      | resource   | pod |
      | namespace  | default |
    And the output should contain:
      | cannot list pods in project "default" |
