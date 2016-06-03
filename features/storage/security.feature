Feature: storage security check
  # @author chaoyang@redhat.com
  # @case_id 510760
  @admin
  @destructive
  Scenario: secret volume security check
    Given I have a project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/secret/secret.yaml |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/secret/secret-pod-test.json |
    Then the step should succeed

    Given the pod named "secretpd" becomes ready
    When I execute on the pod:
      | id | -G |
    Then the step should succeed
    And the outputs should contain "123456"
    When I execute on the pod:
      | ls | -lZd | /mnt/secret/ |
    Then the step should succeed
    And the outputs should contain:
      | 123456 |
      | system_u:object_r:svirt_sandbox_file_t:s0 |
    When I execute on the pod:
      | touch | /mnt/secret/file |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /mnt/secret/file |
    Then the step should succeed
    And the outputs should contain:
      | 123456 |
      | system_u:object_r:svirt_sandbox_file_t:s0 |

  # @author chaoyang@redhat.com
  # @author wehe@redhat.com
  # @case_id 510759
  @admin
  @destructive
  Scenario: gitRepo volume security testing
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    #Create two pods for selinux testing
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gitrepo/gitrepo-selinux-fsgroup-auto510759.json |
    Then the step should succeed
    Given the pod named "gitrepo" becomes ready

    #Verify the security testing
    When I execute on the pod:
      | id |
    Then the outputs should contain:
      | uid=1000130000 |
      | groups=123456 |
    When I execute on the pod:
      | ls | -lZd | /mnt/git |
    Then the outputs should contain:
      | system_u:object_r:svirt_sandbox_file_t:s0 |
    When I execute on the pod:
      | touch |
      | /mnt/git/gitrepoVolume/file1 |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /mnt/git/gitrepoVolume/file1 |
    Then the outputs should contain:
      | 1000130000 123456 |
      | system_u:object_r:svirt_sandbox_file_t:s0 |
      | file1 |

  # @author wehe@redhat.com
  # @case_id 510562
  @admin
  @destructive
  Scenario: emptyDir volume security testing
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    #Create two pods for selinux testing
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/emptydir/emptydir_pod_selinux_test.json |
    Then the step should succeed
    Given the pod named "emptydir" becomes ready

    #Verify the seLinux options
    When I run the :exec client command with:
      | pod | <%= pod.name %> |
      | c | c1 |
      | exec_command | id |
    Then the output should contain:
      | uid=1000160000 |
      | groups=123456,654321 |
    When I run the :exec client command with:
      | pod | <%= pod.name %> |
      | c | c1 |
      | exec_command | -- |
      | exec_command | ls |
      | exec_command_arg | -lZd |
      | exec_command_arg | /tmp/ |
    Then the output should contain:
      | 123456 |
      | svirt_sandbox_file_t:s0:c2,c13 |
    When I run the :exec client command with:
      | pod | <%= pod.name %> |
      | c | c1 |
      | exec_command | touch |
      | exec_command_arg | /tmp/file1 |
    Then the step should succeed
    When I run the :exec client command with:
      | pod | <%= pod.name %> |
      | c | c1 |
      | exec_command | -- |
      | exec_command | ls |
      | exec_command_arg | -lZ |
      | exec_command_arg | /tmp/ |
    Then the output should contain:
      | 1000160000 123456 |
      | svirt_sandbox_file_t:s0:c2,c13 file1 |
    When I run the :exec client command with:
      | pod | <%= pod.name %> |
      | c | c2 |
      | exec_command | id |
    Then the output should contain:
      | uid=1000160200 |
      | groups=0(root),123456,654321 |
    When I run the :exec client command with:
      | pod | <%= pod.name %> |
      | c | c2 |
      | exec_command | -- |
      | exec_command | ls |
      | exec_command_arg | -lZd |
      | exec_command_arg | /tmp/ |
    Then the output should contain:
      | 123456 |
      | svirt_sandbox_file_t:s0:c2,c13 |
    When I run the :exec client command with:
      | pod | <%= pod.name %> |
      | c | c2 |
      | exec_command | touch |
      | exec_command_arg | /tmp/file2 |
    Then the step should succeed
    When I run the :exec client command with:
      | pod | <%= pod.name %> |
      | c | c2 |
      | exec_command | -- |
      | exec_command | ls |
      | exec_command_arg | -lZ |
      | exec_command_arg | /tmp/ |
    Then the output should contain:
      | 1000160200 123456 |
      | svirt_sandbox_file_t:s0:c2,c13 |
      | file2 |

