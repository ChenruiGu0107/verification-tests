Feature: Features of seccomp

  # @author chezhang@redhat.com
  # @case_id OCP-10921
  @admin
  @destructive
  Scenario: container use container level seccomp profile when both container level and pod level profiles given
    Given I store the schedulable nodes in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
      | key_val   | size=large:NoSchedule                           |
    Then the step should succeed
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %> |
      | key_val   | size-                   |
    Then the step should succeed
    Given I use the "<%= cb.nodes[0].name %>" node
    And the "/etc/origin/node/profile1.json" path is removed on the host after scenario
    And node config is merged with the following hash:
    """
    kubeletArguments:
      seccomp-profile-root:
      - "/etc/origin/node"
    """
    When I try to restart the node service on node
    Then the step should succeed
    When I run commands on the host:
      | touch /etc/origin/node/profile1.json |
      | echo -e "{\n     \"defaultAction\": \"SCMP_ACT_ALLOW\",\n     \"syscalls\": [\n        {\n             \"name\": \"chmod\",\n             \"action\": \"SCMP_ACT_ERRNO\"\n        }\n    ]\n}" > /etc/origin/node/profile1.json |
    Then the step should succeed
    Given scc policy "restricted" is restored after scenario
    When I run the :patch admin command with:
      | resource      | scc                                                       |
      | resource_name | restricted                                                |
      | p             | seccompProfiles:\n- unconfined\n- localhost/profile1.json |
    Then the step should succeed
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/seccomp/pod-sec-two-cont-1.yaml |
    Then the step should succeed
    Given the pod named "pod-sec-two-cont" becomes ready
    When I run the :rsh client command with:
      | c       | hello2            |
      | pod     | pod-sec-two-cont  |
      | command | grep              |
      | command | ecc               |
      | command | /proc/self/status |
    Then the step should succeed
    And the output should match:
      | Seccomp:\\s+0 |
    When I run the :rsh client command with:
      | c       | hello1            |
      | pod     | pod-sec-two-cont  |
      | command | grep              |
      | command | ecc               |
      | command | /proc/self/status |
    Then the step should succeed
    And the output should match:
      | Seccomp:\\s+2 |

  # @author chezhang@redhat.com
  # @case_id OCP-11331
  @admin
  @destructive
  Scenario: containers in a pod can use their own seccomp profiles
    Given I store the schedulable nodes in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
      | key_val   | size=large:NoSchedule                           |
    Then the step should succeed
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %> |
      | key_val   | size-                   |
    Then the step should succeed
    Given I use the "<%= cb.nodes[0].name %>" node
    And the "/etc/origin/node/profile1.json" path is removed on the host after scenario
    And node config is merged with the following hash:
    """
    kubeletArguments:
      seccomp-profile-root:
      - "/etc/origin/node"
    """
    And I try to restart the node service on node
    Then the step should succeed
    When I run commands on the host:
      | touch /etc/origin/node/profile1.json |
      | echo -e "{\n     \"defaultAction\": \"SCMP_ACT_ALLOW\",\n     \"syscalls\": [\n        {\n             \"name\": \"chmod\",\n             \"action\": \"SCMP_ACT_ERRNO\"\n        }\n    ]\n}" > /etc/origin/node/profile1.json |
    Then the step should succeed
    Given scc policy "restricted" is restored after scenario
    When I run the :patch admin command with:
      | resource      | scc                                                       |
      | resource_name | restricted                                                |
      | p             | seccompProfiles:\n- unconfined\n- localhost/profile1.json |
    Then the step should succeed
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/seccomp/pod-sec-two-cont-2.yaml |
    Then the step should succeed
    Given the pod named "pod-sec-two-cont" becomes ready
    When I run the :rsh client command with:
      | c       | hello2            |
      | pod     | pod-sec-two-cont  |
      | command | grep              |
      | command | ecc               |
      | command | /proc/self/status |
    Then the step should succeed
    And the output should match:
      | Seccomp:\\s+0 |
    When I run the :rsh client command with:
      | c       | hello1            |
      | pod     | pod-sec-two-cont  |
      | command | grep              |
      | command | ecc               |
      | command | /proc/self/status |
    Then the step should succeed
    And the output should match:
      | Seccomp:\\s+2 |

  # @author chezhang@redhat.com
  # @case_id OCP-11622
  @admin
  @destructive
  Scenario: containers use pod level seccomp
    Given I store the schedulable nodes in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
      | key_val   | size=large:NoSchedule                           |
    Then the step should succeed
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %> |
      | key_val   | size-                   |
    Then the step should succeed
    Given I use the "<%= cb.nodes[0].name %>" node
    And the "/etc/origin/node/profile1.json" path is removed on the host after scenario
    And node config is merged with the following hash:
    """
    kubeletArguments:
      seccomp-profile-root:
      - "/etc/origin/node"
    """
    And I try to restart the node service on node
    Then the step should succeed
    When I run commands on the host:
      | touch /etc/origin/node/profile1.json |
      | echo -e "{\n     \"defaultAction\": \"SCMP_ACT_ALLOW\",\n     \"syscalls\": [\n        {\n             \"name\": \"chmod\",\n             \"action\": \"SCMP_ACT_ERRNO\"\n        }\n    ]\n}" > /etc/origin/node/profile1.json |
    Then the step should succeed
    Given scc policy "restricted" is restored after scenario
    When I run the :patch admin command with:
      | resource      | scc                                                       |
      | resource_name | restricted                                                |
      | p             | seccompProfiles:\n- unconfined\n- localhost/profile1.json |
    Then the step should succeed
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/seccomp/pod-sec-two-cont-3.yaml |
    Then the step should succeed
    Given the pod named "pod-sec-two-cont" becomes ready
    When I run the :rsh client command with:
      | c       | hello2            |
      | pod     | pod-sec-two-cont  |
      | command | grep              |
      | command | ecc               |
      | command | /proc/self/status |
    Then the step should succeed
    And the output should match:
      | Seccomp:\\s+2 |
    When I run the :rsh client command with:
      | c       | hello1            |
      | pod     | pod-sec-two-cont  |
      | command | grep              |
      | command | ecc               |
      | command | /proc/self/status |
    Then the step should succeed
    And the output should match:
      | Seccomp:\\s+2 |

  # @author chezhang@redhat.com
  # @case_id OCP-11818
  @admin
  @destructive
  Scenario: meaningful error if seccomp profile not found
    Given I store the schedulable nodes in the :nodes clipboard
    Given the taints of the nodes in the clipboard are restored after scenario
    When I run the :oadm_taint_nodes admin command with:
      | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
      | key_val   | size=large:NoSchedule                           |
    Then the step should succeed
    When I run the :oadm_taint_nodes admin command with:
      | node_name | <%= cb.nodes[0].name %> |
      | key_val   | size-                   |
    Then the step should succeed
    Given I use the "<%= cb.nodes[0].name %>" node
    And node config is merged with the following hash:
    """
    kubeletArguments:
      seccomp-profile-root:
      - "/etc/origin/node"
    """
    And I try to restart the node service on node
    Then the step should succeed
    Given scc policy "restricted" is restored after scenario
    When I run the :patch admin command with:
      | resource      | scc                     |
      | resource_name | restricted              |
      | p             | seccompProfiles:\n- '*' |
    Then the step should succeed
    Given I have a project
    Given I run the :patch admin command with:
      | resource | namespace |
      | resource_name | <%=project.name%> |
      | p | {"metadata":{"annotations": {"openshift.io/node-selector": ""}}}|
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/seccomp/pod-sec-two-cont-1.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod              |
      | name     | pod-sec-two-cont |
    And the output should match:
      | Warning\\s+(FailedSync\|FailedCreatePodSandBox) |
    """

  # @author chezhang@redhat.com
  # @case_id OCP-10492
  @admin
  @destructive
  Scenario: OpenShift SCC seccomp check, the first non-wildcard profile is used as the default
    Given scc policy "restricted" is restored after scenario
    When I run the :patch admin command with:
      | resource      | scc                                                                                         |
      | resource_name | restricted                                                                                  |
      | p             | seccompProfiles:\n- '*'\n- localhost/profile2.json\n- localhost/profile8.json\n- unconfined |
    Then the step should succeed
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/pod-pull-by-tag.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod             |
      | name     | pod-pull-by-tag |
    And the output should match:
      | seccomp.security.alpha.kubernetes.io/pod.*localhost/profile2.json |

  # @author chezhang@redhat.com
  # @case_id OCP-10183
  @admin
  @destructive
  Scenario: OpenShift SCC check, specific seccomp allowed
    Given scc policy "restricted" is restored after scenario
    When I run the :patch admin command with:
      | resource      | scc                                         |
      | resource_name | restricted                                  |
      | p             | seccompProfiles:\n- localhost/profile1.json |
    Then the step should succeed
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/seccomp/pod-sec-pod-prof2.yaml |
    Then the step should fail
    And the output should contain:
      | localhost/profile2.json is not a valid seccomp profile |

  # @author chezhang@redhat.com
  # @case_id OCP-10493
  @admin
  @destructive
  Scenario: Seccomp profile default directory should exist
    Given scc policy "restricted" is restored after scenario
    When I run the :patch admin command with:
      | resource      | scc                     |
      | resource_name | restricted              |
      | p             | seccompProfiles:\n- '*' |
    Then the step should succeed
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/seccomp/pod-sec-pod-prof1.yaml |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod                   |
      | name     | pod-seccomp-prof1-pod |
    And the output should match:
      | Warning\\s+(FailedSync\|FailedCreatePodSandBox) |
    """
