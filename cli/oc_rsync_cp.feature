Feature: oc_rsync.feature

  # @author cryan@redhat.com
  Scenario Outline: Copying files from container to host using oc rsync
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | aosqe/scratch:tarrsync |
    Given a pod becomes ready with labels:
      | deployment=scratch-1 |
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
      | tar          | # @case_id OCP-11538
      | rsync-daemon | # @case_id OCP-11204

  # @author cryan@redhat.com
  Scenario Outline: Copying files from host to container using oc rsync
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | aosqe/scratch:tarrsync |
    Given a pod becomes ready with labels:
      | deploymentconfig=scratch |
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
      | tar          | # @case_id OCP-12054
      | rsync        | # @case_id OCP-11763
      | rsync-daemon | # @case_id OCP-11934

  # @author cryan@redhat.com
  Scenario Outline: oc rsync with --delete option
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | aosqe/scratch:tarrsync |
    Given a pod becomes ready with labels:
      | deploymentconfig=scratch |
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
      | tar          | # @case_id OCP-12320
      | rsync        | # @case_id OCP-12257
      | rsync-daemon | # @case_id OCP-12293

  # @author cryan@redhat.com
  # @case_id OCP-12208
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
      | deployment=scratch-1 |
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
  # @case_id OCP-10833
  Scenario: Copying files from host to container using oc rsync command with --watch
    Given I have a project
    Given I create the "test" directory
    When I run the :new_app client command with:
      | docker_image | aosqe/scratch:tarrsync       |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | deployment=scratch-1 |
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
    Then the step should succeed
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

  # @author cryan@redhat.com
  # @case_id OCP-10221
  # @bug_id 1314817
  Scenario: oc rsync commands with not exited container
    Given I have a project
    And a "test/test.txt" file is created with the following lines:
    """
    test
    """
    When I run the :rsync client command with:
      | source      | test/                 |
      | destination | podnotexist:/tmp/test |
    Then the step should fail
    And the output should contain ""podnotexist" not found"
    And the output should not contain:
      | cannot use rsync |
      | cannot use tar   |

  # @author xxia@redhat.com
  Scenario Outline: Copy files and directories to and from containers via oc cp
    Given I have a project
    When I run the :new_app client command with:
      | app_repo   | openshift/mysql-55-centos7   |
      | env        | MYSQL_USER=user              |
      | env        | MYSQL_PASSWORD=pass          |
      | env        | MYSQL_DATABASE=db            |
      | name       | myapp                        |
    Then the step should succeed
    Given I create the "local/foo_dir" directory
    Given a pod becomes ready with labels:
      | app=myapp |
    # File
    When I run the :cp client command with:
      | _tool  | <tool>                      |
      | source | <%= pod.name %>:/etc/hosts  |
      | dest   | local/foo_dir               |
    Then the step should succeed
    When I read the "local/foo_dir/hosts" file
    Then the step should succeed
    And the output should contain "localhost"
    # Directory
    When I run the :cp client command with:
      | _tool  | <tool>                          |
      | source | <%= pod.name %>:/etc/sysconfig  |
      | dest   | local/foo_dir                   |
    Then the step should succeed
    And the "local/foo_dir/network" file is present

    # From local to pod. Cover project/ and -c usage as well
    When I run the :cp client command with:
      | _tool    | <tool>                                    |
      | source   | local/foo_dir                             |
      | dest     | <%= project.name %>/<%= pod.name %>:/tmp  |
      | c        | myapp                                     |
    Then the step should succeed
    When I execute on the pod:
      | cat  | /tmp/foo_dir/hosts |
    Then the step should succeed
    And the output should contain "localhost"

    Examples:
      | tool     |
      | oc       | # @case_id OCP-15029
      | kubectl  | # @case_id OCP-21021
