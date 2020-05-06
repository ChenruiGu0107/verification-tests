Feature: redis.feature

  # @author wzheng@redhat.com
  # @case_id OCP-13265
  Scenario: Deploy redis database using redis-ephemeral
    Given I have a project
    When I run the :new_app client command with:
      | template | redis-ephemeral            |
      | param    | REDIS_PASSWORD=redhat      |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=redis |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash                                                                         |
      | -c                                                                           |
      | redis-cli -h redis -p 6379 -c 'auth redhat; append mykey "hello"; get mykey' |
    Then the step should succeed
    And the output should contain:
      | hello |
    """
