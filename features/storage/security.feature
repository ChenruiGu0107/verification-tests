Feature: storage security check
  # @author lxia@redhat.com
  # @case_id OCP-9700 OCP-9699 OCP-9721
  @admin
  Scenario Outline: [origin_infra_20] volume security testing
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/<type>/security/<type>-selinux-fsgroup-test.json" replacing paths:
      | ["metadata"]["name"]                                      | pod-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"] | /mnt                    |
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"]    | s0:c13,c2               |
      | ["spec"]["securityContext"]["fsGroup"]                    | 24680                   |
      | ["spec"]["securityContext"]["runAsUser"]                  | 1000160000              |
      | ["spec"]["volumes"][0]["<storage_type>"]["<volume_name>"] | <%= cb.vid %>           |
    Then the step should succeed
    And the pod named "pod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | id | -u |
    Then the step should succeed
    And the output should contain:
      | 1000160000 |
    When I execute on the pod:
      | id | -G |
    Then the step should succeed
    And the output should contain:
      | 24680 |
    When I execute on the pod:
      | ls | -lZd | /mnt |
    Then the step should succeed
    And the output should contain:
      | 24680                |
      | svirt_sandbox_file_t |
      | s0:c2,c13            |
    When I execute on the pod:
      | touch | /mnt/testfile |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /mnt/testfile |
    Then the step should succeed
    And the output should contain:
      | 24680 |
    Given I ensure "pod-<%= project.name %>" pod is deleted

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/<type>/security/<type>-privileged-test.json" replacing paths:
      | ["metadata"]["name"]                                      | pod2-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"] | /mnt                     |
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"]    | s0:c13,c2                |
      | ["spec"]["securityContext"]["fsGroup"]                    | 24680                    |
      | ["spec"]["volumes"][0]["<storage_type>"]["<volume_name>"] | <%= cb.vid %>            |
    Then the step should succeed
    And the pod named "pod2-<%= project.name %>" becomes ready
    When I execute on the pod:
      | id |
    Then the step should succeed
    And the output should contain:
      | uid=0 |
    When I execute on the pod:
      | id | -G |
    Then the step should succeed
    And the output should contain:
      | 24680 |
    When I execute on the pod:
      | ls | -lZd | /mnt |
    Then the step should succeed
    And the output should contain:
      | 24680 |
    When I execute on the pod:
      | touch | /mnt/testfile |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /mnt/testfile |
    Then the step should succeed
    And the output should contain:
      | 24680                |
      | svirt_sandbox_file_t |
      | s0:c2,c13            |

    Examples:
      | storage_type         | volume_name | type   |
      | gcePersistentDisk    | pdName      | gce    |
      | awsElasticBlockStore | volumeID    | ebs    |
      | cinder               | volumeID    | cinder |

  # @author chaoyang@redhat.com
  # @case_id OCP-9709
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
  # @case_id OCP-9708
  @admin
  @destructive
  Scenario: gitRepo volume security testing
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    When I run the :create client command with:
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
  # @case_id OCP-9698
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
