Feature: oc_rsync.feature

  # @author cryan@redhat.com
  # @case_id 510657 510658 510659
  Scenario Outline: Copying files from container to host using oc rsync
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | aosqe/scratch:tarrsync |
    Given a pod becomes ready with labels:
      | app=scratch |
    When I execute on the pod:
      | touch | /tmp/test1 |
    Then the step should succeed
    Given I create the "rsync_folder" directory
    When I run the :rsync client command with:
      | source      | <%= pod.name %>:/tmp/test1                  |
      | destination | <%= localhost.absolutize("rsync_folder") %> |
      | loglevel    | 5                                           |
      | strategy    | <strategy>                                  |
    Given the "rsync_folder/test1" file is present
    When I run the :rsync client command with:
      | source      | <%= pod.name %>:/root/notexisted/ |
      | destination | <%= localhost.workdir %>          |
      | loglevel    | 5                                 |
      | strategy    | <strategy>                        |
    Then the step should fail
    And the output should contain "No such file or directory"
    When I run the :rsync client command with:
      | source      | <%= pod.name %>:/tmp/test1 |
      | destination | ./nonexisted               |
      | loglevel    | 5                          |
      | strategy    | <strategy>                 |
    Then the step should fail
    And the output should contain "invalid path"
    Given I create the "rsync_folder/lvl2" directory
    When I run the :rsync client command with:
      | source      | <%= pod.name %>:/tmp/test1 |
      | destination | ./rsync_folder/lvl2        |
      | loglevel    | 5                          |
      | strategy    | <strategy>                 |
    Then the step should succeed
    Given the "rsync_folder/lvl2/test1" file is present
    Examples:
      | strategy     |
      | tar          |
      | rsync        |
      | rsync-daemon |

  # @author cryan@redhat.com
  # @case_id 510660 510661 510662
  Scenario Outline: Copying files from host to container using oc rsync
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | aosqe/scratch:tarrsync |
    Given a pod becomes ready with labels:
      | app=scratch |
    Given I create the "test1" directory
    Given a "test1/testfile1" file is created with the following lines:
    """
    test1
    """
    When I run the :rsync client command with:
      | source      | <%= localhost.absolutize("test1") %> |
      | destination | <%= pod.name %>:/tmp                 |
      | loglevel    | 5                                    |
      | strategy    | <strategy>                           |
    Then the step should succeed
    When I execute on the pod:
      | ls | -ltr | /tmp/test1 |
    Then the step should succeed
    And the output should contain "testfile1"
    When I run the :rsync client command with:
      | source      | ./test1              |
      | destination | <%= pod.name %>:/tmp |
      | loglevel    | 5                    |
      | strategy    | <strategy>           |
    Then the step should succeed
    When I execute on the pod:
      | ls | -ltr | /tmp/test1 |
    Then the step should succeed
    When I execute on the pod:
      | cat | /tmp/test1/testfile1 |
    Then the step should succeed
    And the output should contain "test1"
    Examples:
      | strategy     |
      | tar          |
      | rsync        |
      | rsync-daemon |

  # @author cryan@redhat.com
  # @case_id 510665 510666 510667
  Scenario Outline: oc rsync with --delete option
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | aosqe/scratch:tarrsync |
    Given a pod becomes ready with labels:
      | app=scratch |
    Given I create the "test" directory
    Given the "test/testfile1" file is created with the following lines:
    """
    testfile1
    """
    When I run the :rsync client command with:
      | source      | ./test               |
      | destination | <%= pod.name %>:/tmp |
      | strategy    | <strategy>           |
    Then the step should succeed
    When I execute on the pod:
      | ls | -ltr | /tmp/test |
    Then the step should succeed
    And the output should contain "testfile1"
    Given the "test/testfile1" file is deleted
    Given the "test/testfile2" file is created with the following lines:
    """
    testfile2
    """
    When I run the :rsync client command with:
      | source      | ./test                    |
      | destination | <%= pod.name %>:/tmp      |
      | delete      | true                      |
      | strategy    | <strategy>                |
    Then the step should succeed
    When I execute on the pod:
      | ls | -ltr | /tmp/test |
    Then the step should succeed
    And the output should contain "testfile2"
    And the output should not contain "testfile1"
    Given the "test/testfile3" file is created with the following lines:
    """
    testfile3
    """
    When I run the :rsync client command with:
      | source      | <%= pod.name %>:/tmp/test |
      | destination | <%= localhost.workdir %>  |
      | delete      | true                      |
      | strategy    | <strategy>                |
    Then the step should succeed
    Given the "test/testfile3" file is not present
    Examples:
      | strategy     |
      | tar          |
      | rsync        |
      | rsync-daemon |

  # @author cryan@redhat.com
  # @case_id 510664
  Scenario: Copying files from host to one of multi-containers using oc rsync comand --container option
    Given I have a project
    Given I create the "test" directory
    Given a "test/testfile1" file is created with the following lines:
    """
    Hello, World! 1
    """
    And a "test/testfile2" file is created with the following lines:
    """
    Hello, World! 2
    """
    When I run the :new_app client command with:
      | docker_image | aosqe/scratch:tarrsync                      |
      | docker_image | aosqe/scratch:latest                        |
      | group        | aosqe/scratch:tarrsync+aosqe/scratch:latest |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | app=scratch |
    When I run the :rsync client command with:
      | source      | <%= localhost.workdir %>/test |
      | destination | <%= pod.name %>:/tmp          |
      | c           | scratch                       |
    Then the step should succeed
    When I execute on the pod:
      | ls | -ltr | /tmp/test |
    Then the step should succeed
    And the output should contain:
      | testfile1 |
      | testfile2 |
    When I execute on the pod:
      | cat | /tmp/test/testfile1 | /tmp/test/testfile2 |
    Then the step should succeed
    And the output should contain:
      | Hello, World! 1 |
      | Hello, World! 2 |

  # @author wewang@redhat.com
  # @case_id 525986
  Scenario: Copying files from host to container using oc rsync command with --watch
    Given I have a project
    Given I create the "test" directory
    When I run the :new_app client command with:
      | docker_image | aosqe/scratch:tarrsync       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | app=scratch |
    When I run the :rsync background client command with:
      | source      | <%= localhost.workdir %>/test |
      | destination | <%= pod.name %>:/tmp |
      | w           | true |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I execute on the pod:
      | ls | /tmp |
    Then the step should succeed
    And the output should contain "test"
    """
    Given I create the "test/test1" directory
    Given I wait for the steps to pass:
    """
    When I execute on the pod:
      | ls | -ltr | /tmp/test |
    Then the step should succeed
    And the output should contain:
      | test1 |
    """
    Given a "test/test1/testfile1" file is created with the following lines:
    """
    testfile1 
    """
    And a "test/test1/testfile2" file is created with the following lines:
    """
    testfile2
    """
    Given I wait for the steps to pass:
    """
    When I execute on the pod:
      | cat | /tmp/test/test1/testfile1 | /tmp/test/test1/testfile2 |
    Then the step should succeed
    And the output should contain:
      | testfile1 |
      | testfile2 |
    """
    Given I replace lines in "test/test1/testfile1":
      | testfile1 | Hello world |
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | cat | /tmp/test/test1/testfile1 |
    Then the step should succeed
    And the output should contain:
      | Hello world |
    """
    And I terminate last background process
    Given the "test/test1/testfile1" file is deleted
    And the "test/test1/testfile2" file is deleted
    When I run the :rsync background client command with:
      | source      | <%= localhost.workdir %>/test |
      | destination | <%= pod.name %>:/tmp |
      | w           | true |
      | delete      | true |
    Given I wait for the steps to pass:
    """
    When I execute on the pod:
      | ls | -ltr | /tmp/test/test1/ |
    Then the step should succeed
    And the output should not contain:
      | testfile1 |
      | testfile2 |
    """
    And I terminate last background process
    When I run the :rsync client command with:
      | source      | <%= pod.name %>:/tmp/test |
      | destination | <%= localhost.workdir %>  |
      | w           | true                      |
    Then the step should fail
    And the output should contain ""--watch" can only be used with a local source directory"
