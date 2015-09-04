Feature: build 'apps' with CLI

  #@author xxing@redhat.com
  #@case_id 489753
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

  # @author cryan@redhat.com
  # @case_id 489741
  Scenario: Create a build config based on the provided image and source code
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-centos7.json |
    Then the step should succeed
    When I run the :new_build client command with:
      | code  | https://github.com/openshift/ruby-hello-world |
      | image | ruby                                          |
      | l     | app=rubytest                                  |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc               |
      | name     | ruby-hello-world |
    Then the output should match:
      | URL:\s+https://github.com/openshift/ruby-hello-world|
    Given the pod named "ruby-hello-world-1-build" becomes ready
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
    When I run the :new_build client command with:
      | app_repo |  openshift/ruby-20-centos7~https://github.com/openshift/ruby-hello-world.git |
      | strategy | docker                                                                       |
      | name     | n1                                                                           |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | bc               |
      | name     | ruby-hello-world |
    Then the output should match:
      | URL:\s+https://github.com/openshift/ruby-hello-world|
    Given the pod named "ruby-hello-world-1-build" becomes ready
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
