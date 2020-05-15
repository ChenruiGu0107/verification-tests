Feature: general_db.feature
  # @author haowang@redhat.com
  # @case_id OCP-9723
  Scenario: Create mongodb resources via installed ephemeral template on web console
    Given I have a project
    When I run the :new_app client command with:
      | template | mongodb-ephemeral            |
      | param    | MONGODB_ADMIN_PASSWORD=admin |
    And a pod becomes ready with labels:
      | name=mongodb|
    And I wait up to 30 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -lc | mongo admin -u admin -padmin  --eval 'printjson(db.serverStatus())' |
    Then the step should succeed
    """
    And the output should contain:
      | "ok" : 1 |
