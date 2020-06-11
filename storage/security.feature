Feature: storage security check
  # @author lxia@redhat.com
  @admin
  Scenario Outline: Run pod with specific user/group by using securityContext
    Given I have a project
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    Given I obtain test data file "storage/misc/pod-with-security-context.yaml"
    When I run oc create over "pod-with-security-context.yaml" replacing paths:
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
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    Given I obtain test data file "storage/misc/pod-with-security-context.yaml"
    When I run oc create over "pod-with-security-context.yaml" replacing paths:
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
  # @case_id OCP-14139
  @admin
  Scenario: downwardapi using a volume plugin with security testing
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    Given I obtain test data file "downwardapi/pod-dapi-security.yaml"
    When I run the :create client command with:
      | filename | pod-dapi-security.yaml |
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
    Given I obtain test data file "configmap/configmap.yaml"
    When I run the :create client command with:
      | f | configmap.yaml |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    Given I obtain test data file "configmap/pod-configmap-security.yaml"
    When I run the :create client command with:
      | filename | pod-configmap-security.yaml |
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

  # @author wehe@redhat.com
  # @author chaoyang@redhat.com
  # @case_id OCP-9698
  @admin
  Scenario: emptyDir volume security testing
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    #Create pods for selinux testing
    Given I obtain test data file "storage/security/emptydir_selinux.json"
    When I run the :create client command with:
      | f | emptydir_selinux.json |
    Then the step should succeed
    Given the pod named "emptydir" becomes ready

    #Verify the seLinux options
    When I execute on the pod:
      | id |
    Then the output should match:
      | uid=1000160000.*groups=.*123456,654321 |
    When I execute on the pod:
      | ls | -lZd | /tmp |
    Then the output should match:
      | 123456                                   |
      | s0:c2,c13                                |
      | (svirt_sandbox_file_t\|container_file_t) |
    When I execute on the pod:
      |  touch | /tmp/file1 |
    Then the step should succeed
    When I execute on the pod:
      | ls | -lZ | /tmp/file1 |
    Then the output should match:
      | 1000160000 123456                        |
      | s0:c2,c13                                |
      | (svirt_sandbox_file_t\|container_file_t) |
    Then the step should succeed
    When I execute on the pod:
      | cp | /hello | /tmp/hello |
    Then the step should succeed
    When I execute on the pod:
      | /tmp/hello |
    And the output should contain "Hello OpenShift Storage"

