Feature: Storage of Hostpath plugin testing

  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  @admin
  Scenario Outline: Create hostpath pv with access mode and reclaim policy
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>          |
      | node_selector | <%= cb.proj_name %>=hostpath |
      | admin         | <%= user.name %>             |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project

    #Add label to the first node "<%= cb.proj_name %>=hostpath"
    Given I store the schedulable nodes in the :nodes clipboard
    And label "<%= cb.proj_name %>=hostpath" is added to the "<%= cb.nodes[0].name %>" node

    #Create a dir on the first node
    Given I use the "<%= cb.nodes[0].name %>" node
    Given a 5 characters random string of type :dns is stored into the :hostpath clipboard
    Given the "/etc/origin/<%= cb.hostpath %>" path is recursively removed on the host after scenario
    Given I run commands on the host:
      | mkdir -p /etc/origin/<%= cb.hostpath %>     |
      | chmod -R 777 /etc/origin/<%= cb.hostpath %> |
    Then the step should succeed

    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/local.yaml" where:
      | ["metadata"]["name"]         | local-<%= cb.proj_name %>      |
      | ["spec"]["hostPath"]["path"] | /etc/origin/<%= cb.hostpath %> |
      | ["spec"]["accessModes"][0]   | <access_mode>                  |
      | ["spec"]["persistentVolumeReclaimPolicy"] | <reclaim_policy>  |
    Then the step should succeed

    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/claim.yaml" replacing paths:
      | ["metadata"]["name"]       | localc-<%= cb.proj_name %> |
      | ["spec"]["volumeName"]     | local-<%= cb.proj_name %>  |
      | ["spec"]["accessModes"][0] | <access_mode>              |
    Then the step should succeed
    And the "localc-<%= cb.proj_name %>" PVC becomes bound to the "local-<%= cb.proj_name %>" PV

    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | localpd-<%= cb.proj_name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | localc-<%= cb.proj_name %>  |
    Then the step should succeed

    Given the pod named "localpd-<%= cb.proj_name %>" becomes ready
    When I execute on the pod:
      | touch | /mnt/local/test |
    Then the step should succeed

    Given I ensure "localpd-<%= cb.proj_name %>" pod is deleted
    And I ensure "localc-<%= cb.proj_name %>" pvc is deleted
    And the PV becomes :<pv_status> within 300 seconds

    Given I use the "<%= cb.nodes[0].name %>" node
    When I run commands on the host:
      | ls /etc/origin/<%= cb.hostpath %>/test |
    Then the step should <step_status>

    Examples:
      | access_mode   | reclaim_policy | pv_status | step_status |
      | ReadWriteOnce | Retain         | released  | succeed     | # @case_id OCP-9639
      | ReadOnlyMany  | Default        | released  | succeed     | # @case_id OCP-11726
      | ReadWriteMany | Recycle        | available | fail        | # @case_id OCP-9640

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
    Given I store the schedulable nodes in the :nodes clipboard
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
    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/security/hostpath.yaml" replacing paths:
      | ["metadata"]["name"]                       | localpd-<%= cb.proj_name %>    |
      | ["spec"]["volumes"][0]["hostPath"]["path"] | /etc/origin/<%= cb.hostpath %> |
    Then the step should succeed
    And the pod named "localpd-<%= project.name %>" becomes ready

    When I run the :exec client command with:
      | pod          | localpd-<%= cb.proj_name %> |
      | container    | a                           |
      | exec_command | id                          |
    Then the output should contain:
      | 1000130001 |
      | 123456     |
    When I run the :exec client command with:
      | pod              | localpd-<%= cb.proj_name %> |
      | container        | a                           |
      | oc_opts_end      |                             |
      | exec_command     | ls                          |
      | exec_command_arg | -lZd                        |
      | exec_command_arg | /example/hostpath/a         |
    Then the step should succeed
    And the output should contain:
      | 123456 |
    When I run the :exec client command with:
      | pod              | localpd-<%= cb.proj_name %>   |
      | container        | a                             |
      | oc_opts_end      |                               |
      | exec_command     | touch                         |
      | exec_command_arg | /example/hostpath/a/testfilea |
    Then the step should succeed
    When I run the :exec client command with:
      | pod              | localpd-<%= cb.proj_name %>   |
      | container        | a                             |
      | oc_opts_end      |                               |
      | exec_command     | ls                            |
      | exec_command_arg | -lZ                           |
      | exec_command_arg | /example/hostpath/a/testfilea |
    Then the step should succeed
    And the output should contain:
      | 1000130001 |
    When I run the :exec client command with:
      | pod              | localpd-<%= cb.proj_name %> |
      | container        | a                           |
      | oc_opts_end      |                             |
      | exec_command     | cp                          |
      | exec_command_arg | /hello                      |
      | exec_command_arg | /example/hostpath/a         |
    Then the step should succeed
    When I run the :exec client command with:
      | pod          | localpd-<%= cb.proj_name %> |
      | container    | a                           |
      | oc_opts_end  |                             |
      | exec_command | /example/hostpath/a/hello   |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

    When I run the :exec client command with:
      | pod          | localpd-<%= cb.proj_name %> |
      | container    | b                           |
      | exec_command | id                          |
    Then the output should contain:
      | 1000130002 |
      | 123456     |
    When I run the :exec client command with:
      | pod              | localpd-<%= cb.proj_name %> |
      | container        | b                           |
      | oc_opts_end      |                             |
      | exec_command     | ls                          |
      | exec_command_arg | -lZd                        |
      | exec_command_arg | /example/hostpath/b         |
    Then the step should succeed
    And the output should contain:
      | 123456 |
    When I run the :exec client command with:
      | pod              | localpd-<%= cb.proj_name %>   |
      | container        | b                             |
      | oc_opts_end      |                               |
      | exec_command     | touch                         |
      | exec_command_arg | /example/hostpath/b/testfileb |
    Then the step should succeed
    When I run the :exec client command with:
      | pod              | localpd-<%= cb.proj_name %>   |
      | container        | b                             |
      | oc_opts_end      |                               |
      | exec_command     | ls                            |
      | exec_command_arg | -lZ                           |
      | exec_command_arg | /example/hostpath/b/testfileb |
    Then the step should succeed
    And the output should contain:
      | 1000130002 |

  # @author jhou@redhat.com
  # @case_id OCP-13676
  @admin
  Scenario: Setting mount options for volume plugins that doesn't support it
    Given I switch to cluster admin pseudo user
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/hostpath_invalid_mount_options.yaml |
    Then the step should fail
    And the output should contain:
      | may not specify mount options for this volume type |

  # @author wehe@redhat.com
  # @case_id OCP-14665
  @admin
  @destructive
  Scenario: Mount propagation test of HostToContainer and Bidirectional 
    Given feature gate "MountPropagation" is enabled
    And admin creates a project with a random schedulable node selector
    And I use the "<%= node.name %>" node
    And the "/mnt/disk" path is recursively removed on the host after scenario
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/propashare.yaml | 
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
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/propaslave.yaml |
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
  @destructive
  Scenario: Bidirectional and HostoContainer mount propagation with unpriviledged pod 
    Given feature gate "MountPropagation" is enabled
    And admin creates a project with a random schedulable node selector
    And I use the "<%= node.name %>" node
    And the "/mnt/<%= project.name %>" path is recursively removed on the host after scenario
    And I run commands on the host:
      | mkdir -p /mnt/<%= project.name %>                         |
      | chcon -R -t svirt_sandbox_file_t /mnt/<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/propashare.yaml" replacing paths:
      | ["spec"]["containers"][0]["securityContext"]["privileged"] | false |
    Then the step should fail 
    And the output should contain:
      | Bidirectional mount propagation is available only to privileged containers |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/propaslave.yaml" replacing paths:
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

