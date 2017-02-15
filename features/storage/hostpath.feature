Feature: Storage of Hostpath plugin testing

  # @author chaoyang@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-9639 OCP-11726 OCP-9640
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

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/claim.yaml" replacing paths:
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
      | ReadWriteOnce | Retain         | released  | succeed     |
      | ReadOnlyMany  | Default        | released  | succeed     |
      | ReadWriteMany | Recycle        | available | fail        |

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
