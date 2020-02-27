Feature: oc_secrets.feature

  # @author xiaocwan@redhat.com
  # @case_id OCP-12033
  Scenario: [origin_platformexp_391] Operation should fail when lost argument for bundle secret
    When I run the :secrets client command with:
      | action | new        |
      | source | /etc/hosts |
    Then the step should not succeed
    And the output should contain:
      |  error: |
    When I run the :secrets client command with:
      | action | new        |
      | name   | test       |
    Then the step should not succeed
    And the output should contain:
      |  error: |

  # @author geliu@redhat.com
  # @case_id OCP-10915
  Scenario: Remove secret from SA
    Given a "test1/testfile1" file is created with the following lines:
    |test1|
    Given I have a project
    When I run the :create_secret client command with:
      | secret_type | generic         |
      | name        | testsecret1     |
      | from_file   | test1/testfile1 |
    Then the step should succeed

    When I run the :create_secret client command with:
      | secret_type | generic         |
      | name        | testsecret2     |
      | from_file   | test1/testfile1 |
    Then the step should succeed
 
    When I run the :secrets client command with:
      |action        | link        |
      |serviceaccount| default     |
      |secrets_name  | testsecret1 |
    Then the step should succeed
    
    When I run the :get client command with:
      | resource      | serviceaccount/default |
      | o             | json                   |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['secrets'].any? {|p| p['name'].include? 'testsecret1'}

    When I run the :secrets client command with:
      |action        | link        |
      |serviceaccount| default     |
      |secrets_name  | testsecret2 |
      |for           | pull        |
    Then the step should succeed
    
    When I run the :get client command with:
      | resource      | serviceaccount/default |
      | o             | json                   |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['imagePullSecrets'].any? {|p| p['name'].include? 'testsecret2'}
 
    When I run the :secrets client command with:
    | action         | unlink      |
    | serviceaccount | default     |
    | secrets_name   | testsecret1 |
    Then the step should succeed
 
    When I run the :get client command with:
      | resource      | serviceaccount/default |
      | o             | json                   |
    Then the step should succeed
    And the expression should be true> not @result[:parsed]['secrets'].any? {|p| p['name'].include? 'testsecret1'}
    And the expression should be true> @result[:parsed]['imagePullSecrets'].any? {|p| p['name'].include? 'testsecret2'}
    
    When I run the :secrets client command with:
      | action        | link        |
      | serviceaccount| default     |
      | secrets_name  | testsecret1 |
      | for           | pull,mount  |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | serviceaccount/default |
      | o             | json                   |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['secrets'].any? {|p| p['name'].include? 'testsecret1'}
    And the expression should be true> @result[:parsed]['imagePullSecrets'].any? {|p| p['name'].include? 'testsecret1'}

    When I run the :secrets client command with:
      | action         | unlink      |
      | serviceaccount | default     |
      | secrets_name   | testsecret1 |
      | secrets_name   | testsecret2 |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | serviceaccount/default|
    Then the step should succeed
    And the output should not contain "testsecret1"
    And the output should not contain "testsecret2"
    When I run the :secrets client command with:
    | action         | unlink    |
    | serviceaccount | default   |
    | secrets_name   | test-test |
    Then the step should fail
    And the output should match:
    | .*"test-test" not found| 
    When I run the :describe client command with:
      | resource | serviceaccount/default |
    Then the step should succeed
    And the output should not contain "testsecret1" 
    When I run the :secrets client command with:
      | action         | link                   |
      | serviceaccount | serviceaccount/default |
      | secrets_name   | secret/testsecret1     |
    Then the step should succeed  
    When I run the :get client command with:
      | resource      | serviceaccount/default |
      | o             | json                   |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['secrets'].any? {|p| p['name'].include? 'testsecret1'}
    When I run the :secrets client command with:
    | action         | unlink      |
    | serviceaccount | default     |
    | secrets_name   | testsecret1 |
    | secrets_name   | test-test   |
    Then the step should fail
    And the output should match:
    | .*test-test.* not found|
    When I run the :describe client command with:
      | resource | serviceaccount/default|
    Then the step should succeed
    And the output should not contain "testsecret1"
    When I run the :secrets client command with:
      | action         | link                   |
      | serviceaccount | serviceaccount/default |
      | secrets_name   | secrets/test-test      |
    Then the step should fail
    And the output should match:
    |.*test-test.* not found|
    When I run the :secrets client command with:
      | action         | link                        |
      | serviceaccount | serviceaccount/default-test |
      | secrets_name   | secret/testsecret1          |
    Then the step should fail
    And the output should match:
    | .*default-test.* not found|
    When I run the :secrets client command with:
    | action         | unlink                      |
    | serviceaccount | serviceaccount/default_test |
    | secrets_name   | secret/testsecret2          |
    Then the step should fail
    And the output should match:
    | .*default_test.* not found|

