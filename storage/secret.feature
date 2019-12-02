Feature: scenarios related with secret volume
  # @author lxia@redhat.com
  # @case_id OCP-26273
  Scenario: Secret encoded using base64
    Given I have a project
    When I run the :create_secret client command with:
      | secret_type  | generic                 |
      | name         | my-secret               |
      | from_literal | username=aos-storage-qe |
      | from_literal | password='abc$\*!cba'   |
    Then the step should succeed
    And the expression should be true> secret('my-secret').type == 'Opaque'
    And the expression should be true> secret('my-secret').raw_value_of('username') == 'YW9zLXN0b3JhZ2UtcWU='
    And the expression should be true> secret('my-secret').raw_value_of('password') == 'J2FiYyRcKiFjYmEn'
    When I get project secrets
    Then the step should succeed
    And the output should not contain:
      | aos-storage-qe |
      | abc$\*!cba     |
    When I run the :describe client command with:
      | resource | secret    |
      | name     | my-secret |
    Then the step should succeed
    And the output should match:
      | username:\s+14 bytes |
      | password:\s+12 bytes |
