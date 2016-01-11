Feature: oc_secrets.feature

  # @author cryan@redhat.com
  # @case_id 490968
  Scenario: Add secrets to serviceaccount via oc secrets add
    Given I have a project
    When I run the :secrets client command with:
      | action | new        |
      | name   | test       |
      | source | /etc/hosts |
    Then the step should succeed
    When I run the :secrets client command with:
      | action         | add                    |
      | serviceaccount | serviceaccount/default |
      | secrets_name   | secret/test            |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | serviceaccount |
      | name     | default        |
    Then the step should succeed
    And the output should contain:
      |Mountable secrets|
      |test|
    When I run the :secrets client command with:
      | action         | add                    |
      | serviceaccount | serviceaccount/default |
      | secrets_name   | secret/test            |
      | for            | pull                   |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | serviceaccount |
      | resource_name | default        |
      | o             | json           |
    Then the step should succeed
    And the output should contain:
      |"imagePullSecrets"|
      |"name": "test"    |
    When I run the :secrets client command with:
      | action         | add                    |
      | serviceaccount | serviceaccount/default |
      | secrets_name   | secret/test            |
      | for            | pull,mount             |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | serviceaccount |
      | resource_name | default        |
      | o             | json           |
    Then the step should succeed
    And the output should contain:
      |"imagePullSecrets"|
    And the output should contain 2 times:
      |"name": "test" |


  # @author qwang@redhat.com
  # @case_id 483167
  Scenario: CRUD operations on secrets
    Given I have a project
    # 1.1 Create a secret with a non-existing namespace 
    When I run the :create client command with:
      | filename  | https://raw.githubusercontent.com/qwang1/v3-testfiles/qwangtest/secrets/tc483167/mysecret.json |
      | namespace | non483167        |
    Then the step should fail
    And the output should contain "cannot create secrets in project"
    # 1.2 Create a secret with a correct namespace
    When I run the :create client command with:
      | filename  | https://raw.githubusercontent.com/qwang1/v3-testfiles/qwangtest/secrets/tc483167/mysecret.json |
    Then the step should succeed
    # 2. Describe a secret
    When I run the :describe client command with:
      | resource | secret   |
      | name     | mysecret |
    Then the output should contain:
      | password:	11 bytes |
      | username:	9 bytes  |
    # 3.1 Update a secret with a invalid namespace
    When I run the :patch client command with:
      | resource      | secret   |
      | resource_name | mysecret |
      | p             | {"metadata": {"namespace": "secrettest"}} |
    Then the step should fail
    And the output should contain "does not match the namespace"
    # 3.2 Update a secret with a invalid resource
    When I run the :patch client command with:
      | resource      | secret   |
      | resource_name | mysecret |
      | p             | {"metadata": {"name": "testsecret"}} |
    Then the step should fail
    And the output should contain "the name of the object (testsecret) does not match the name on the URL (mysecret)"
    # 3.3 Update a secret with a invalid content
    When I run the :patch client command with:
      | resource      | secret   |
      | resource_name | mysecret |
      | p             | {"data": {"username": "123"}} |
    Then the step should fail
    And the output should contain "illegal base64 data at input byte 0"
    # 3.4 Update a secret with a correct update object
    When I run the :patch client command with:
      | resource      | secret                             |
      | resource_name | mysecret                           |
      | p             | {"data": {"password": "dGVzdA=="}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | secret   |
      | name     | mysecret |
    Then the output should contain:
      | password:	4 bytes |
      | username:	9 bytes |
    # 4. Delete a secret
    When I run the :delete client command with:
      | object_type       | secret   |
      | object_name_or_id | mysecret |
    Then the step should succeed
    # 5. List secrets
    When I run the :get client command with:
      | resource | secret |
    Then the step should succeed
    And the output should not contain "mysecret"



