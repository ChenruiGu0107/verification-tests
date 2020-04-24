Feature: git server related scenarios
  # @author shiywang@redhat.com
  # @case_id OCP-11166
  @smoke
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
    And I obtain test data file "build/ruby20rhel7-template-sti.json"
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
