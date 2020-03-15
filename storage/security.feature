Feature: storage security check
  # @author lxia@redhat.com
  @admin
  Scenario Outline: Run pod with specific user/group by using securityContext
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod-with-security-context.yaml" replacing paths:
      | ["spec"]["securityContext"]["<key>"] | 135246 |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    When I execute on the pod:
      | id |
    Then the step should succeed
    And the output should contain:
      | 135246 |
    When I execute on the pod:
      | cp | /hello | /mnt/storage/hello |
    Then the step should succeed
    When I execute on the pod:
      | ls | -l | /mnt/storage/hello |
    Then the step should succeed
    And the output should contain:
      | 135246 |
    When I execute on the pod:
      | /mnt/storage/hello |
    Then the step should succeed

    Examples:
      | key       |
      | runAsUser | # @case_id OCP-28093
      | fsGroup   | # @case_id OCP-28095

  # @author lxia@redhat.com
  # @case_id OCP-28097
  @admin
  Scenario: Run pod with specific SELinux by using seLinuxOptions in securityContext
    Given I have a project
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod-with-security-context.yaml" replacing paths:
      | ["spec"]["securityContext"]["seLinuxOptions"] | {"level":"s0:c13,c2"} |
    Then the step should succeed
    And the pod named "mypod" becomes ready
    When I execute on the pod:
      | ls | -lZd | /mnt/storage |
    Then the step should succeed
    And the output should match:
      | s0:c2,c13 |
    When I execute on the pod:
      | cp | /hello | /mnt/storage/hello |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /mnt/storage/hello |
    Then the step should succeed
    And the output should contain:
      | s0:c2,c13 |
    When I execute on the pod:
      | /mnt/storage/hello |
    Then the step should succeed

  # @author wehe@redhat.com
  # @case_id OCP-13915
  @admin
  Scenario: azure disk volume security testing
    Given I have a project
    And I have a 1 GB volume from provisioner "azure-disk" and save volume id in the :vid clipboard
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/security/azure-selinux-fsgroup-test.yml" replacing paths:
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"] | s0:c13,c2                     |
      | ["spec"]["securityContext"]["fsGroup"]                 | 24680                         |
      | ["spec"]["securityContext"]["runAsUser"]               | 1000160000                    |
      | ["spec"]["volumes"][0]["azureDisk"]["diskName"]        | <%= cb.vid.split("/").last %> |
      | ["spec"]["volumes"][0]["azureDisk"]["diskURI"]         | <%= cb.vid %>                 |
    Then the step should succeed
    And the pod named "azdsecurity" becomes ready
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
      | ls | -lZd | /mnt/azure |
    Then the step should succeed
    And the output should match:
      | 24680                                    |
      | (svirt_sandbox_file_t\|container_file_t) |
      | s0:c2,c13                                |
    When I execute on the pod:
      | touch | /mnt/azure/testfile |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /mnt/azure/testfile |
    Then the step should succeed
    And the output should contain:
      | 24680 |
    When I execute on the pod:
      | cp | /hello | /mnt/azure |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/azure/hello |
    Then the step should succeed
    Given I ensure "azdsecurity" pod is deleted
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/security/azure-privileged-test.yml" replacing paths:
      | ["spec"]["securityContext"]["seLinuxOptions"]["level"] | s0:c13,c2                     |
      | ["spec"]["securityContext"]["fsGroup"]                 | 24680                         |
      | ["spec"]["volumes"][0]["azureDisk"]["diskName"]        | <%= cb.vid.split("/").last %> |
      | ["spec"]["volumes"][0]["azureDisk"]["diskURI"]         | <%= cb.vid %>                 |
    Then the step should succeed
    And the pod named "azdsecprv" becomes ready
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
      | ls | -lZd | /mnt/azure |
    Then the step should succeed
    And the output should contain:
      | 24680 |
    When I execute on the pod:
      | touch | /mnt/azure/testfile |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /mnt/azure/testfile |
    Then the step should succeed
    And the output should match:
      | 24680                                    |
      | (svirt_sandbox_file_t\|container_file_t) |
      | s0:c2,c13                                |
    When I execute on the pod:
      | cp | /hello | /mnt/azure |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/azure/hello |
    Then the step should succeed

  # @author wehe@redhat.com
  # @case_id OCP-14139
  @admin
  Scenario: downwardapi using a volume plugin with security testing
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/downwardapi/pod-dapi-security.yaml |
    Then the step should succeed
    Given the pod named "dapisec" becomes ready
    When I execute on the pod:
      | id | -G |
    Then the step should succeed
    And the outputs should contain "123456"
    When I execute on the pod:
      | ls | -lZd | /mnt/dapi/ |
    Then the step should succeed
    And the outputs should match:
      | 123456                                                        |
      | system_u:object_r:(svirt_sandbox_file_t\|container_file_t):s0 |
    When I execute on the pod:
      | touch | /mnt/dapi/file |
    Then the step should fail 
    And the outputs should contain "Read-only file system"

  # @author wehe@redhat.com
  # @case_id OCP-14138
  @admin
  Scenario: Consume ConfigMap via volume plugin with security testing
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run the :create client command with:
      | filename | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-security.yaml |
    Then the step should succeed
    Given the pod named "configsec" becomes ready
    When I execute on the pod:
      | id | -G |
    Then the step should succeed
    And the outputs should contain "123456"
    When I execute on the pod:
      | ls | -lZd | /mnt/configmap/ |
    Then the step should succeed
    And the outputs should match:
      | 123456                                                        |
      | system_u:object_r:(svirt_sandbox_file_t\|container_file_t):s0 |
    When I execute on the pod:
      | touch | /mnt/configmap/file |
    Then the step should fail 
    And the outputs should contain "Read-only file system"

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
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/gitrepo/gitrepo-selinux-fsgroup-auto510759.json |
    Then the step should succeed
    Given the pod named "gitrepo" becomes ready

    #Verify the security testing
    When I execute on the pod:
      | id |
    Then the outputs should contain:
      | uid=1000130000 |
    When I execute on the pod:
      | id | -G |
    Then the step should succeed
    And the output should contain "123456"
    When I execute on the pod:
      | ls | -lZd | /mnt/git |
    Then the outputs should match:
      | system_u:object_r                        |
      | (svirt_sandbox_file_t\|container_file_t) |
      | s0                                       |
    When I execute on the pod:
      | touch | /mnt/git/gitrepoVolume/file1 |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /mnt/git/gitrepoVolume/file1 |
    Then the outputs should match:
      | 1000130000 123456                        |
      | system_u:object_r                        |
      | (svirt_sandbox_file_t\|container_file_t) |
      | s0                                       |

  # @author wehe@redhat.com
  # @author chaoyang@redhat.com
  # @case_id OCP-9698
  @admin
  @destructive
  Scenario: emptyDir volume security testing
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    #Create two pods for selinux testing
    And I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/emptydir/emptydir_pod_selinux_test.json |
    Then the step should succeed
    Given the pod named "emptydir" becomes ready

    #Verify the seLinux options
    When I run the :exec client command with:
      | pod          | <%= pod.name %> |
      | c            | c1              |
      | exec_command | id              |
    Then the output should match:
      | uid=1000160000.*groups=.*123456,654321 |
    When I run the :exec client command with:
      | pod              | <%= pod.name %> |
      | c                | c1              |
      | exec_command     | --              |
      | exec_command     | ls              |
      | exec_command_arg | -lZd            |
      | exec_command_arg | /tmp/           |
    Then the output should match:
      | 123456                                   |
      | s0:c2,c13                                |
      | (svirt_sandbox_file_t\|container_file_t) |
    When I run the :exec client command with:
      | pod              | <%= pod.name %> |
      | c                | c1              |
      | exec_command     | touch           |
      | exec_command_arg | /tmp/file1      |
    Then the step should succeed
    When I run the :exec client command with:
      | pod              | <%= pod.name %> |
      | c                | c1              |
      | exec_command     | --              |
      | exec_command     | ls              |
      | exec_command_arg | -lZ             |
      | exec_command_arg | /tmp/           |
    Then the output should match:
      | 1000160000 123456                        |
      | s0:c2,c13                                |
      | (svirt_sandbox_file_t\|container_file_t) |
   When I run the :exec client command with:
      | pod              | <%= pod.name %> |
      | c                | c1              |
      | exec_command     | --              |
      | exec_command     | cp              |
      | exec_command_arg | /hello          |
      | exec_command_arg | /tmp            |
    Then the step should succeed
    When I run the :exec client command with:
      | pod          | <%= pod.name %> |
      | c            | c1              |
      | exec_command | --              |
      | exec_command | /tmp/hello      |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

    When I run the :exec client command with:
      | pod          | <%= pod.name %> |
      | c            | c2              |
      | exec_command | id              |
    Then the output should contain:
      | uid=1000160200               |
      | groups=0(root),123456,654321 |
    When I run the :exec client command with:
      | pod              | <%= pod.name %> |
      | c                | c2              |
      | exec_command     | --              |
      | exec_command     | ls              |
      | exec_command_arg | -lZd            |
      | exec_command_arg | /tmp/           |
    Then the output should match:
      | 123456                                   |
      | s0:c2,c13                                |
      | (svirt_sandbox_file_t\|container_file_t) |
    When I run the :exec client command with:
      | pod              | <%= pod.name %> |
      | c                | c2              |
      | exec_command     | touch           |
      | exec_command_arg | /tmp/file2      |
    Then the step should succeed
    When I run the :exec client command with:
      | pod              | <%= pod.name %> |
      | c                | c2              |
      | exec_command     | --              |
      | exec_command     | ls              |
      | exec_command_arg | -lZ             |
      | exec_command_arg | /tmp/           |
    Then the output should match:
      | 1000160200 123456                        |
      | s0:c2,c13                                |
      | (svirt_sandbox_file_t\|container_file_t) |
      | file2                                    |
