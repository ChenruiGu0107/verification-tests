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
