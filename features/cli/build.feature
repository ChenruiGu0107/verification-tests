Feature: build 'apps' with CLI

  # @author xxing@redhat.com
  # @case_id 489753
  Scenario: Create a build config from a remote repository using branch
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world#beta2 |
      | l        | app=test |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc |
      | name     | ruby-hello-world |
    Then the output should match:
      | URL:\s+https://github.com/openshift/ruby-hello-world|
      | Ref:\s+beta2                                        |
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed  
    When I run the :get client command with:
      | resource | builds |
    Then the output should contain:
      | NAME                |
      | ruby-hello-world-1  |
    When I run the :get client command with:
      |resource| is |
    Then the output should contain:
      | ruby-20-centos7  |
      | ruby-hello-world |
