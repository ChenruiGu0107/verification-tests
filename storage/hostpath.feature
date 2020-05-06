Feature: Storage of Hostpath plugin testing

  # @author chaoyang@redhat.com
  # @case_id OCP-9704
  @admin
  Scenario: Hostpath volume security checking
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>                |
      | node_selector | <%= cb.proj_name %>=testfor510646  |
      | admin         | <%= user.name %>                   |
    Then the step should succeed

    #Add label to the first node "<%= cb.proj_name %>=testfor510646"
    Given I store the ready and schedulable workers in the :nodes clipboard
    And label "<%= cb.proj_name %>=testfor510646" is added to the "<%= cb.nodes[0].name %>" node

    #Create a dir on the first node
    Given I use the "<%= cb.nodes[0].name %>" node
    Given a 5 characters random string of type :dns is stored into the :hostpath clipboard
    Given the "/etc/origin/<%= cb.hostpath %>" path is recursively removed on the host after scenario
    Given I run commands on the host:
      | mkdir -p /etc/origin/<%= cb.hostpath %>                         |
      | chmod -R 777 /etc/origin/<%= cb.hostpath %>                     |
      | chown -R root:123456 /etc/origin/<%= cb.hostpath %>             |
      | chcon -R -t svirt_sandbox_file_t /etc/origin/<%= cb.hostpath %> |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project
    Then I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/hostpath/security/hostpath.yaml" replacing paths:
      | ["metadata"]["name"]                                      | localpd-<%= cb.proj_name %>    |
      | ["spec"]["volumes"][0]["hostPath"]["path"]                | /etc/origin/<%= cb.hostpath %> |
      | ["spec"]["containers"][0]["securityContext"]["runAsUser"] | 22222                          |
    Then the step should succeed
    And the pod named "localpd-<%= project.name %>" becomes ready

    When I execute on the pod:
      | id |
    Then the output should contain:
      | 22222  |
      | 123456 |
    When I execute on the pod:
      | ls | -ld | /example/hostpath |
    Then the step should succeed
    And the output should contain:
      | 123456 |
    When I execute on the pod:
      | touch | /example/hostpath/testfilea |
    Then the step should succeed
    When I execute on the pod:
      | ls | -l | /example/hostpath/testfilea |
    Then the step should succeed
      And the output should contain:
      | 22222 |
    When I execute on the pod:
      | cp | /hello | /example/hostpath |
    Then the step should succeed
    When I execute on the pod:
      | /example/hostpath/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"


  # @author jhou@redhat.com
  # @case_id OCP-13676
  @admin
  Scenario: Setting mount options for volume plugins that doesn't support it
    Given I switch to cluster admin pseudo user
    When I run the :create client command with:
        | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/hostpath/hostpath_invalid_mount_options.yaml |
    Then the step should fail
    And the output should contain:
      | may not specify mount options for this volume type |

  # @author wehe@redhat.com
  # @case_id OCP-14665
  @admin
  Scenario: Mount propagation test of HostToContainer and Bidirectional
    Given admin creates a project with a random schedulable node selector
    And I use the "<%= node.name %>" node
    And the "/mnt/disk" path is recursively removed on the host after scenario
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/hostpath/propashare.yaml |
      | n | <%= project.name %>                                                                                            |
    Then the step should succeed
    Given the pod named "propashare" becomes ready
    When I execute on the pod:
      | mkdir | -p | /mnt/local/master |
    Then the step should succeed
    When I execute on the pod:
      | mount | -t | tmpfs | master | /mnt/local/master |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/local/master/masterdata |
    Then the step should succeed
    When I run commands on the host:
      | ls /mnt/disk/master |
    Then the output should contain:
      | masterdata |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/hostpath/propaslave.yaml |
      | n | <%= project.name %>                                                                                            |
    Then the step should succeed
    Given the pod named "propaslave" becomes ready
    When I execute on the pod:
      | mkdir | -p | /mnt/local/slave |
    Then the step should succeed
    When I execute on the pod:
      | mount | -t | tmpfs | slave | /mnt/local/slave |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/local/slave/slavedata |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/local/master/ |
    Then the output should contain:
      | masterdata |
    When I execute on the "propashare" pod:
      | ls | /mnt/local/slave/ |
    Then the output should not contain:
      | slavedata |
    When I run commands on the host:
      | mkdir -p /mnt/disk/slave1                       |
      | mount -t tmpfs HostToContainer /mnt/disk/slave1 |
      | touch /mnt/disk/slave1/slavedata                |
    Then the step should succeed
    When I execute on the "propaslave" pod:
      | ls | /mnt/local/slave1 |
    Then the output should contain:
      | slavedata |
    When I run commands on the host:
      | umount master          |
      | umount slave           |
      | umount HostToContainer |
    Then the step should succeed

  # @author wehe@redhat.com
  # @case_id OCP-14673
  @admin
  Scenario: Bidirectional and HostoContainer mount propagation with unpriviledged pod
    Given admin creates a project with a random schedulable node selector
    And I use the "<%= node.name %>" node
    And the "/mnt/<%= project.name %>" path is recursively removed on the host after scenario
    And I run commands on the host:
      | mkdir -p /mnt/<%= project.name %>                         |
      | chcon -R -t svirt_sandbox_file_t /mnt/<%= project.name %> |
    Then the step should succeed
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/hostpath/propashare.yaml" replacing paths:
      | ["spec"]["containers"][0]["securityContext"]["privileged"] | false |
    Then the step should fail
    And the output should contain:
      | Bidirectional mount propagation is available only to privileged containers |
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/hostpath/propaslave.yaml" replacing paths:
      | ["spec"]["containers"][0]["securityContext"]["privileged"] | false                    |
      | ["spec"]["volumes"][0]["hostPath"]["path"]                 | /mnt/<%= project.name %> |
    Then the step should succeed
    Given the pod named "propaslave" becomes ready
    When I run commands on the host:
      | mkdir -p /mnt/<%= project.name %>/slave                         |
      | mount -t tmpfs HostToContainer /mnt/<%= project.name %>/slave   |
      | chcon -R -t svirt_sandbox_file_t /mnt/<%= project.name %>/slave |
      | touch /mnt/<%= project.name %>/slave/slavedata                  |
    Then the step should succeed
    When I execute on the "propaslave" pod:
      | ls | /mnt/local/slave |
    Then the output should contain:
      | slavedata |
    When I run commands on the host:
      | umount master          |
      | umount slave           |
      | umount HostToContainer |
    Then the step should succeed
