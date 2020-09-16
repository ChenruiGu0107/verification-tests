Feature: testing multicast scenarios

  # @author hongli@redhat.com
  # @case_id OCP-12928
  @admin
  Scenario: pods should be able to join multiple multicast groups at same time
    Given the env is using multitenant or networkpolicy network

    # create some multicast testing pods in the project
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I obtain test data file "networking/multicast-rc.json"
    When I run oc create over "multicast-rc.json" replacing paths:
      | ["spec"]["replicas"] | 2 |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=mcast-pods |
    And evaluation of `pod(0).ip` is stored in the :pod1ip clipboard
    And evaluation of `pod(0).name` is stored in the :pod1 clipboard
    And evaluation of `pod(1).ip` is stored in the :pod2ip clipboard
    And evaluation of `pod(1).name` is stored in the :pod2 clipboard

    # enable multicast for the netnamespace
    When I run the :annotate admin command with:
      | resource     | netnamespace    |
      | resourcename | <%= cb.proj1 %> |
      | overwrite    | true            |
      | keyval       | netnamespace.network.openshift.io/multicast-enabled=true |
    Then the step should succeed

    # run omping with default group (232.43.211.234) on first pod
    When I run the :exec background client command with:
      | pod              | <%= cb.pod1 %>   |
      | oc_opts_end      |                  |
      | exec_command     | omping           |
      | exec_command_arg | -c               |
      | exec_command_arg | 5                |
      | exec_command_arg | -T               |
      | exec_command_arg | 15               |
      | exec_command_arg | <%= cb.pod1ip %> |
      | exec_command_arg | <%= cb.pod2ip %> |
    Then the step should succeed

    # run omping with another group 232.43.211.235 on first pod
    When I run the :exec background client command with:
      | pod              | <%= cb.pod1 %>   |
      | oc_opts_end      |                  |
      | exec_command     | omping           |
      | exec_command_arg | -c               |
      | exec_command_arg | 5                |
      | exec_command_arg | -T               |
      | exec_command_arg | 15               |
      | exec_command_arg | -m               |
      | exec_command_arg | 232.43.211.235   |
      | exec_command_arg | -p               |
      | exec_command_arg | 4322             |
      | exec_command_arg | <%= cb.pod1ip %> |
      | exec_command_arg | <%= cb.pod2ip %> |
    Then the step should succeed

    # run omping on second pod
    When I run the :exec background client command with:
      | pod              | <%= cb.pod2 %> |
      | oc_opts_end      |                |
      | exec_command     | sh             |
      | exec_command_arg | -c             |
      | exec_command_arg | omping -c 5 -T 10 <%= cb.pod1ip %> <%= cb.pod2ip %> > /tmp/p2g1.log |
    Then the step should succeed
    When I run the :exec background client command with:
      | pod              | <%= cb.pod2 %> |
      | oc_opts_end      |                |
      | exec_command     | sh             |
      | exec_command_arg | -c             |
      | exec_command_arg | omping -c 5 -T 10 -m 232.43.211.235 -p 4322 <%= cb.pod1ip %> <%= cb.pod2ip %> > /tmp/p2g2.log |
    Then the step should succeed

    # ensure pod joined both multicast groups
    When I execute on the "<%= cb.pod2 %>" pod:
      | netstat | -ng |
    Then the step should succeed
    And the output should match:
      | eth0\s+1\s+232.43.211.234 |
      | eth0\s+1\s+232.43.211.235 |

    Given 10 seconds have passed
    When I execute on the "<%= cb.pod2 %>" pod:
      | cat | /tmp/p2g1.log |
    Then the step should succeed
    And the output should contain:
      | <%= cb.pod1ip %> : joined (S,G) = (*, 232.43.211.234), pinging |
      | <%= cb.pod1ip %> : multicast, xmt/rcv/%loss = 5/5/0% |
    When I execute on the "<%= cb.pod2 %>" pod:
      | cat | /tmp/p2g2.log |
    Then the step should succeed
    And the output should contain:
      | <%= cb.pod1ip %> : joined (S,G) = (*, 232.43.211.235), pinging |
      | <%= cb.pod1ip %> : multicast, xmt/rcv/%loss = 5/5/0% |

  # @author hongli@redhat.com
  # @case_id OCP-12929
  @admin
  Scenario: pods should not be able to receive multicast traffic from other pods in different tenant
    Given the env is using multitenant or networkpolicy network

    # create some multicast testing pods in one project
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I obtain test data file "networking/multicast-rc.json"
    When I run oc create over "multicast-rc.json" replacing paths:
      | ["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=mcast-pods |
    And evaluation of `pod.ip` is stored in the :proj1_podip clipboard
    And evaluation of `pod.name` is stored in the :proj1_pod clipboard

    # enable multicast for the netnamespace
    When I run the :annotate admin command with:
      | resource     | netnamespace    |
      | resourcename | <%= cb.proj1 %> |
      | overwrite    | true            |
      | keyval       | netnamespace.network.openshift.io/multicast-enabled=true |
    Then the step should succeed

    # create some multicast testing pods in another project
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/multicast-rc.json"
    When I run oc create over "multicast-rc.json" replacing paths:
      | ["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=mcast-pods |
    And evaluation of `pod.ip` is stored in the :proj2_podip clipboard
    And evaluation of `pod.name` is stored in the :proj2_pod clipboard

    # enable multicast for the netnamespace
    When I run the :annotate admin command with:
      | resource     | netnamespace    |
      | resourcename | <%= cb.proj2 %> |
      | overwrite    | true            |
      | keyval       | netnamespace.network.openshift.io/multicast-enabled=true |

    # run omping on pod in first project
    Given I use the "<%= cb.proj1 %>" project
    When I run the :exec background client command with:
      | pod              | <%= cb.proj1_pod %>   |
      | oc_opts_end      |                       |
      | exec_command     | omping                |
      | exec_command_arg | -c                    |
      | exec_command_arg | 5                     |
      | exec_command_arg | -T                    |
      | exec_command_arg | 15                    |
      | exec_command_arg | <%= cb.proj1_podip %> |
      | exec_command_arg | <%= cb.proj2_podip %> |
    Then the step should succeed

    # check the omping result on pod in second project
    Given I use the "<%= cb.proj2 %>" project
    When I run the :exec background client command with:
      | pod              | <%= cb.proj2_pod %> |
      | oc_opts_end      |                     |
      | exec_command     | sh                  |
      | exec_command_arg | -c                  |
      | exec_command_arg | omping -c 5 -T 10 <%= cb.proj1_podip %> <%= cb.proj2_podip %> > /tmp/p2.log |
    Then the step should succeed

    When I execute on the "<%= cb.proj2_pod %>" pod:
      | netstat | -ng |
    Then the step should succeed
    And the output should match:
      | eth0\s+1\s+232.43.211.234 |

    Given 10 seconds have passed
    When I execute on the "<%= cb.proj2_pod %>" pod:
      | cat | /tmp/p2.log |
    Then the step should succeed
    And the output should not contain:
      | multicast, xmt/rcv/%loss = 5/5/0%" |

  # @author hongli@redhat.com
  # @case_id OCP-12931
  @admin
  @destructive
  Scenario: pods in default project should not be able to receive multicast traffic from other tenants
    Given the env is using multitenant or networkpolicy network

    # create multicast testing pod in one project
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I obtain test data file "networking/multicast-rc.json"
    When I run oc create over "multicast-rc.json" replacing paths:
      | ["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=mcast-pods |
    And evaluation of `pod.ip` is stored in the :proj1_podip clipboard
    And evaluation of `pod.name` is stored in the :proj1_pod clipboard

    # enable multicast for the netnamespace
    When I run the :annotate admin command with:
      | resource     | netnamespace    |
      | resourcename | <%= cb.proj1 %> |
      | overwrite    | true            |
      | keyval       | netnamespace.network.openshift.io/multicast-enabled=true |
    Then the step should succeed

    # enable multicast and create testing pods in default project
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    Given admin adds and overwrites following annotations to the "default" netnamespace:
      | netnamespace.network.openshift.io/multicast-enabled=true |
    Then the step should succeed

    Given admin ensures "mcast-rc" rc is deleted after scenario
    Given I obtain test data file "networking/multicast-rc.json"
    When I run oc create over "multicast-rc.json" replacing paths:
      | ["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=mcast-pods |
    And evaluation of `pod.ip` is stored in the :proj2_podip clipboard
    And evaluation of `pod.name` is stored in the :proj2_pod clipboard

    # run omping on the pod in first project
    Given I use the "<%= cb.proj1 %>" project
    When I run the :exec background client command with:
      | pod              | <%= cb.proj1_pod %>   |
      | oc_opts_end      |                       |
      | exec_command     | sh                  |
      | exec_command_arg | -c                  |
      | exec_command_arg | omping -c 5 -T 15 <%= cb.proj1_podip %> <%= cb.proj2_podip %> > /tmp/p1.log |
    Then the step should succeed

    # run omping on the pod in default project
    Given I use the "default" project
    When I run the :exec background client command with:
      | pod              | <%= cb.proj2_pod %> |
      | oc_opts_end      |                     |
      | exec_command     | sh                  |
      | exec_command_arg | -c                  |
      | exec_command_arg | omping -c 5 -T 10 <%= cb.proj1_podip %> <%= cb.proj2_podip %> > /tmp/p2.log |
    Then the step should succeed

    # check the result and should receive 0 multicast packet
    Given 10 seconds have passed
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.proj1_pod %>" pod:
      | cat | /tmp/p1.log |
    Then the step should succeed
    And the output should contain:
      | joined (S,G) = (*, 232.43.211.234), pinging |
      | multicast, xmt/rcv/%loss = 5/0/100%         |

    Given I use the "default" project
    When I execute on the "<%= cb.proj2_pod %>" pod:
      | cat | /tmp/p2.log |
    Then the step should succeed
    And the output should contain:
      | joined (S,G) = (*, 232.43.211.234), pinging |
      | multicast, xmt/rcv/%loss = 5/0/100%         |

  # @author hongli@redhat.com
  # @case_id OCP-12966
  @admin
  @destructive
  Scenario: pods in default project should be able to receive multicast traffic from other default project pods
    Given the env is using multitenant or networkpolicy network

    # enable multicast and create testing pods
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    Given admin adds and overwrites following annotations to the "default" netnamespace:
      | netnamespace.network.openshift.io/multicast-enabled=true |
    Then the step should succeed

    Given admin ensures "mcast-rc" rc is deleted after scenario
    Given I obtain test data file "networking/multicast-rc.json"
    When I run the :create client command with:
      | f | multicast-rc.json |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=mcast-pods |
    And evaluation of `pod(0).ip` is stored in the :pod1ip clipboard
    And evaluation of `pod(0).name` is stored in the :pod1 clipboard
    And evaluation of `pod(1).ip` is stored in the :pod2ip clipboard
    And evaluation of `pod(1).name` is stored in the :pod2 clipboard
    And evaluation of `pod(2).ip` is stored in the :pod3ip clipboard
    And evaluation of `pod(2).name` is stored in the :pod3 clipboard

    # run omping as background on the pods
    When I run the :exec background client command with:
      | pod              | <%= cb.pod1 %>   |
      | oc_opts_end      |                  |
      | exec_command     | omping           |
      | exec_command_arg | -c               |
      | exec_command_arg | 5                |
      | exec_command_arg | -T               |
      | exec_command_arg | 15               |
      | exec_command_arg | <%= cb.pod1ip %> |
      | exec_command_arg | <%= cb.pod2ip %> |
      | exec_command_arg | <%= cb.pod3ip %> |
    Then the step should succeed

    When I run the :exec background client command with:
      | pod              | <%= cb.pod2 %>   |
      | oc_opts_end      |                  |
      | exec_command     | omping           |
      | exec_command_arg | -c               |
      | exec_command_arg | 5                |
      | exec_command_arg | -T               |
      | exec_command_arg | 15               |
      | exec_command_arg | <%= cb.pod1ip %> |
      | exec_command_arg | <%= cb.pod2ip %> |
      | exec_command_arg | <%= cb.pod3ip %> |
    Then the step should succeed

    When I run the :exec background client command with:
      | pod              | <%= cb.pod3 %> |
      | oc_opts_end      |                |
      | exec_command     | sh             |
      | exec_command_arg | -c             |
      | exec_command_arg | omping -c 5 -T 10 <%= cb.pod1ip %> <%= cb.pod2ip %> <%= cb.pod3ip %> > /tmp/p3.log |
    Then the step should succeed

    # ensure interface join to the multicast group
    When I execute on the "<%= cb.pod3 %>" pod:
      | netstat | -ng |
    Then the step should succeed
    And the output should match:
      | eth0\s+1\s+232.43.211.234 |

    # check the result on third pod and should received 5 multicast packets from other pods
    Given 10 seconds have passed
    When I execute on the "<%= cb.pod3 %>" pod:
      | cat | /tmp/p3.log |
    Then the step should succeed
    And the output should match:
      | <%= cb.pod1ip %>.*joined \(S,G\) = \(\*, 232.43.211.234\), pinging |
      | <%= cb.pod2ip %>.*joined \(S,G\) = \(\*, 232.43.211.234\), pinging |
      | <%= cb.pod1ip %>.*multicast, xmt/rcv/%loss = 5/5/0% |
      | <%= cb.pod2ip %>.*multicast, xmt/rcv/%loss = 5/5/0% |

