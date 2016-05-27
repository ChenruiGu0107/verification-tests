Feature: git server related scenarios
  # @author xiuwang@redhat.com
  # @case_id 500998
  Scenario: Config REQUIRE_SERVER_AUTH and REQUIRE_GIT_AUTH for git server
    Given I have a project
    And I have an http-git service in the project 
    When I run the :run client command with:
      | name  | gitserver                  |
      | image | openshift/origin-gitserver |
      | env   | GIT_HOME=/var/lib/git      |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role          | edit             |
      | serviceaccount| default          |
    Then the step should succeed
    When I run the :env client command with:
      | resource | dc/git |
      | e        | ALLOW_ANON_GIT_PULL=false |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deploymentconfig=git |
      | deployment=git-2     |

    And a pod becomes ready with labels:
      | run=gitserver |
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      |bash|
      |-c  |
      |sed -i '1,2d' /var/lib/gitconfig/.gitconfig|
    Then the step should succeed
    """
    When I execute on the pod:
      |bash|
      |-c  |
      |git config --global credential.http://<%= cb.git_route%>.helper '!f() { echo "username=<%= @user.name %>"; echo "password=<%= user.get_bearer_token.token %>"; }; f'|
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/ ;git clone http://<%= cb.git_route%>/ruby-hello-world.git|
    Then the step should succeed
    Then the output should contain:
      |You appear to have cloned an empty repository|

    When I run the :env client command with:
      | resource | dc/git |
      | e        | REQUIRE_SERVER_AUTH= |
      | e        | REQUIRE_GIT_AUTH=openshift:redhat |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deploymentconfig=git|
      | deployment=git-3|
    And a pod becomes ready with labels:
      | run=gitserver|
    When I execute on the pod:
      |bash|
      |-c  |
      |git config --global credential.http://<%= cb.git_route%>.helper '!f() { echo "username=openshift"; echo "password=redhat"; }; f'|
    Then the step should succeed
    When I execute on the pod:
      |bash|
      |-c  |
      |cd /tmp/; rm -rf ruby-hello-world;git clone http://<%= cb.git_route%>/ruby-hello-world.git|
    Then the step should succeed
    Then the output should contain:
      |You appear to have cloned an empty repository|

    When I run the :env client command with:
      | resource | dc/git                |
      | e        | REQUIRE_SERVER_AUTH=- |
    Then the step should succeed
    And I wait until number of replicas match "1" for replicationController "git-4"
    Given I store in the clipboard the pods labeled:
     | deployment=git-4 |
    When I run the :logs client command with:
      | resource_name| pods/<%= cb.pods[0].name%> |
    Then the output should contain:
      |error: only one of REQUIRE_SERVER_AUTH or REQUIRE_GIT_AUTH may be specified|
