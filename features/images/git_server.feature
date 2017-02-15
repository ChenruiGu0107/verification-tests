Feature: git server related scenarios
  # @author xiuwang@redhat.com
  # @case_id OCP-10678
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

  # @author shiywang@redhat.com
  # @case_id OCP-11166
  Scenario: Do automatic build and deployment using private gitserver
    Given I have a project
    Given I have an http-git service in the project
    Given I have a git client pod in the project
    When I execute on the pod:
      | bash |
      | -c   |
      | cd /tmp/; git clone https://github.com/openshift/ruby-hello-world.git |
    Then the step should succeed
    When I execute on the pod:
      | bash |
      | -c   |
      | cd /tmp/ruby-hello-world/; git remote add openshift http://<%= cb.git_svc_ip %>:8080/ruby-hello-world.git; git push openshift master |
    Then the step should succeed
    Then the output should contain:
      | master -> master |
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json"
    Then the step should succeed
    And I replace lines in "ruby20rhel7-template-sti.json":
      | https://github.com/openshift/ruby-hello-world.git | http://<%= cb.git_svc_ip %>:8080/ruby-hello-world.git |
    Then the step should succeed
    When I run the :new_app client command with:
      | file  | ruby20rhel7-template-sti.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    Then I run the :delete client command with:
      | object_type       | build              |
      | object_name_or_id | ruby-hello-world-1 |
    Then the step should succeed
    When I execute on the pod:
      | bash |
      | -c   |
      | cd /tmp/ruby-hello-world/; touch testfile; git add testfile; git commit -m "change: add testfile"; git push openshift master |
    Then the step should succeed
    And the output should contain:
      | master -> master |
    And the "ruby-hello-world-2" build was created
    And the "ruby-hello-world-2" build completed
    And a pod becomes ready with labels:
      | deployment=git-1 |
    Then I run the :delete client command with:
      | object_type       | pod             |
      | object_name_or_id | <%= pod.name %> |
    Then the step should succeed
    And I execute on the "git-client" pod:
      | bash |
      | -c   |
      | cd /tmp/ruby-hello-world/; touch testfile1; git add testfile1; git commit -m "change: add testfile1"; git push openshift master |
    Then the step should fail
    And I run the :get client command with:
      | resource      | build              |
      | resource_name | ruby-hello-world-3 |
    Then the step should fail