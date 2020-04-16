Feature: Network policy plugin scenarios

  # @author bmeng@redhat.com
  # @case_id OCP-12801
  @admin
  Scenario: The network between projects are flat and can be managed by admin when using networkpolicy plugin
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).ip_url` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).ip_url` is stored in the :p2pod1ip clipboard
    And evaluation of `pod(3).ip_url` is stored in the :p2pod2ip clipboard
    And evaluation of `pod(2).name` is stored in the :p2pod2 clipboard

    # make sure the network is flat
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"

    # the network is managed by network policy
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed

    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"


  # @author bmeng@redhat.com
  # @case_id OCP-12803
  @admin
  @destructive
  Scenario: Set networkpolicy to project which does not have the annoation will not take effect
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # check the openflow rules
    Given I select a random node's host
    When I run the ovs commands on the host:
      | ovs-ofctl -O OpenFlow13 dump-flows br0 \| grep priority=100.*actions=output:NXM_NX_REG2 |
    Then the step should succeed
    And the output should not contain "reg0=0x"

    # apply network policy to project which does not have the annotation
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-local.yaml |
      | n | <%= cb.proj1 %> |
    Then the step should succeed

    # check the openflow rules
    Given I select a random node's host
    When I run the ovs commands on the host:
      | ovs-ofctl -O OpenFlow13 dump-flows br0 \| grep priority=100.*actions=output:NXM_NX_REG2 |
    Then the step should succeed
    And the output should not contain "reg0=0x"

    # apply network policy to project which does not have the annotation
    Given the DefaultDeny policy is applied to the "<%= cb.proj2 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-local.yaml |
      | n | <%= cb.proj2 %> |
    Then the step should succeed

    # check the openflow rules
    Given I select a random node's host
    When I run the ovs commands on the host:
      | ovs-ofctl -O OpenFlow13 dump-flows br0 \| grep priority=100.*actions=output:NXM_NX_REG2 |
    Then the step should succeed
    And the output should contain "reg0=0x"

  # @author bmeng@redhat.com
  # @case_id OCP-12804
  @admin
  Scenario: Use networkpolicy plugin with "allow local connections" policy
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).ip_url` is stored in the :p2pod1ip clipboard
    And evaluation of `pod(3).name` is stored in the :p2pod2 clipboard

    # and annotation to both project 1 2, apply network policy to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    Given the DefaultDeny policy is applied to the "<%= cb.proj2 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-local.yaml |
      | n | <%= cb.proj1 %>                                                                                              |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(4).name` is stored in the :p3pod1 clipboard
    And evaluation of `pod(5).ip_url` is stored in the :p3pod2ip clipboard

    # scale up the pod in project1
    Given I use the "<%= cb.proj1 %>" project
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc                |
      | replicas | 3                      |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(-3).ip_url` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(-3).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(-2).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(-2).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(-1).ip_url` is stored in the :p1pod3ip clipboard

    # access the pods cross project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p3pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

    # delete the network policy and access again
    When I run the :delete admin command with:
      | object_type       | networkpolicy   |
      | object_name_or_id | allow-local     |
      | n                 | <%= cb.proj1 %> |
    Then the step should succeed
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p3pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"


  # @author bmeng@redhat.com
  # @case_id OCP-12805
  @admin
  Scenario: Use networkpolicy plugin with "allow connections from specific project" policy
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).ip_url` is stored in the :p2pod1ip clipboard
    And evaluation of `pod(3).name` is stored in the :p2pod2 clipboard

    # add annotation to both projects and apply network policy to the project1
    When I run the :label admin command with:
      | resource | namespace |
      | name     | <%= cb.proj1 %> |
      | key_val  | team=red |
    Then the step should succeed
    When I run the :label admin command with:
      | resource | namespace |
      | name     | <%= cb.proj2 %> |
      | key_val  | team=blue |
    Then the step should succeed

    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    Given the DefaultDeny policy is applied to the "<%= cb.proj2 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-project.yaml |
      | n | <%= cb.proj1 %>                                                                                              |
    Then the step should succeed

    # create another project and pods with label blue
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(4).name` is stored in the :p3pod1 clipboard
    And evaluation of `pod(5).ip_url` is stored in the :p3pod2ip clipboard
    When I run the :label admin command with:
      | resource | namespace |
      | name     | <%= cb.proj3 %> |
      | key_val  | team=blue |
    Then the step should succeed

    # scale up the pod in project1
    Given I use the "<%= cb.proj1 %>" project
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc                |
      | replicas | 3                      |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(-3).ip_url` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(-3).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(-2).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(-2).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(-1).ip_url` is stored in the :p1pod3ip clipboard

    # access pod across the projects
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p3pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"

    # delete the network policy and access across the projects
    When I run the :delete admin command with:
      | object_type       | networkpolicy   |
      | object_name_or_id | allow-from-blue     |
      | n                 | <%= cb.proj1 %> |
    Then the step should succeed
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p3pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"


  # @author bmeng@redhat.com
  # @case_id OCP-12806
  @admin
  Scenario: Use networkpolicy plugin with "allow all connections" policy
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).ip_url` is stored in the :p2pod1ip clipboard
    And evaluation of `pod(3).name` is stored in the :p2pod2 clipboard

    # and annotation to both project 1 2, apply network policy to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    Given the DefaultDeny policy is applied to the "<%= cb.proj2 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-all.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(4).name` is stored in the :p3pod1 clipboard
    And evaluation of `pod(5).ip_url` is stored in the :p3pod2ip clipboard

    # scale up the pod in project1
    Given I use the "<%= cb.proj1 %>" project
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc                |
      | replicas | 3                      |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(-3).ip_url` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(-3).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(-2).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(-2).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(-1).ip_url` is stored in the :p1pod3ip clipboard

    # access pods across projects
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p3pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"

    # delete networkpolicy and access again
    When I run the :delete admin command with:
      | object_type       | networkpolicy |
      | object_name_or_id | allow-all |
      | n                 | <%= cb.proj1 %> |
    Then the step should succeed
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p3pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

  # @author bmeng@redhat.com
  # @case_id OCP-12876
  @admin
  Scenario: Use podSelector to control access for pods with network policy - allow from
    # create project and pods and add label to 1 pod
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 3 |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).ip_url` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(2).name` is stored in the :p1pod3 clipboard
    When I run the :label client command with:
      | resource | pod |
      | name     | <%= cb.p1pod2 %> |
      | key_val  | type=red |
    Then the step should succeed

    # create another project and pods and add label to 1 pod
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 3 |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(3).name` is stored in the :p2pod1 clipboard
    And evaluation of `pod(4).name` is stored in the :p2pod2 clipboard
    And evaluation of `pod(5).name` is stored in the :p2pod3 clipboard
    When I run the :label client command with:
      | resource | pod |
      | name     | <%= cb.p2pod2 %> |
      | key_val  | type=red |
    Then the step should succeed

    # add annotation and apply network policy to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-from-label.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # access the pods in project 1
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod3 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod3 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

    # Add label to an existing pod and a new pod in each project
    Given I use the "<%= cb.proj1 %>" project
    And I have a pod-for-ping in the project
    When I run the :label client command with:
      | resource  | pod |
      | name      | <%= cb.p1pod3 %> |
      | name      | hello-pod |
      | key_val   | type=red |
    Then the step should succeed
    Given I use the "<%= cb.proj2 %>" project
    And I have a pod-for-ping in the project
    When I run the :label client command with:
      | resource  | pod |
      | name      | <%= cb.p2pod3 %> |
      | name      | hello-pod |
      | key_val   | type=red |
    Then the step should succeed

    # access pod in project 1 via the label new added pods
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod3 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod3 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

    # remove the label from pod and access again
    Given I use the "<%= cb.proj1 %>" project
    When I run the :label client command with:
      | resource  | pod |
      | name      | <%= cb.p1pod2 %> |
      | key_val   | type- |
    Then the step should succeed
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I run the :label client command with:
      | resource  | pod |
      | name      | <%= cb.p2pod2 %> |
      | key_val   | type- |
    Then the step should succeed
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

  # @author bmeng@redhat.com
  # @case_id OCP-12877
  @admin
  Scenario: Use podSelector to control access for pods with network policy - allow to
    # create project and pods and add label to 1 pod
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 3 |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(2).ip_url` is stored in the :p1pod3ip clipboard
    And evaluation of `pod(2).name` is stored in the :p1pod3 clipboard
    When I run the :label client command with:
      | resource | pod |
      | name     | <%= cb.p1pod2 %> |
      | key_val  | type=blue |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(3).name` is stored in the :p2pod1 clipboard

    # add annotation and apply network policy to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-to-label.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # access the labeled pod and un-labeled pod in project 1 via pods in both projects
    Given I use the "<%= cb.proj1 %>" project
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    """

    # Add label to an existing pod and a new pod in project1
    Given I use the "<%= cb.proj1 %>" project
    And I have a pod-for-ping in the project
    And evaluation of `pod.ip` is stored in the :p1pod4ip clipboard
    When I run the :label client command with:
      | resource  | pod |
      | name      | <%= cb.p1pod3 %> |
      | name      | hello-pod |
      | key_val   | type=blue |
    Then the step should succeed

    # access the label new added pods
    Given I use the "<%= cb.proj1 %>" project
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod4ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod4ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    """

    # remove the label from pod and access again
    Given I use the "<%= cb.proj1 %>" project
    When I run the :label client command with:
      | resource  | pod |
      | name      | <%= cb.p1pod2 %> |
      | key_val   | type- |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    """

  # @author bmeng@redhat.com
  # @case_id OCP-12945
  @admin
  Scenario: Use podSelector to control access for pods with network policy - allow from red to blue
    # create project and pods and add label to 1 pod
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 3 |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(2).ip_url` is stored in the :p1pod3ip clipboard
    When I run the :label client command with:
      | resource | pod |
      | name     | <%= cb.p1pod1 %> |
      | key_val  | type=red |
    Then the step should succeed
    When I run the :label client command with:
      | resource | pod |
      | name     | <%= cb.p1pod2 %> |
      | key_val  | type=blue |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(3).name` is stored in the :p2pod1 clipboard
    And evaluation of `pod(4).name` is stored in the :p2pod2 clipboard

    # add annotation and apply network policy to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-from-red-to-blue.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # Access the pods across the projects
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"


  # @author bmeng@redhat.com
  # @case_id OCP-12807
  @admin
  Scenario: Multiple networkpolicys can work together on a single project
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).name` is stored in the :p2pod1 clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(3).name` is stored in the :p3pod1 clipboard

    # add annotation to project 1 and apply the network policies to project 1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-local.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-project.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed
    # add team=blue label to project 2
    When I run the :label admin command with:
      | resource | namespace |
      | name     | <%= cb.proj2 %> |
      | key_val  | team=blue |
    Then the step should succeed

    # try to access the pod in project 1 from each project
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"


  # @author bmeng@redhat.com
  # @case_id OCP-13304
  @admin
  Scenario: podSelector allow-to and allow-from can work together
    # create project and pods with label added
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 4 |
    Then the step should succeed
    Given 4 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(2).name` is stored in the :p1pod3 clipboard
    And evaluation of `pod(3).ip_url` is stored in the :p1pod4ip clipboard
    When I run the :label client command with:
      | resource | pod |
      | name     | <%= cb.p1pod1 %> |
      | key_val  | type=red |
    Then the step should succeed
    When I run the :label client command with:
      | resource | pod |
      | name     | <%= cb.p1pod2 %> |
      | key_val  | type=blue |
    Then the step should succeed

    # create another project and pods with label added
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 2 |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(4).name` is stored in the :p2pod1 clipboard
    And evaluation of `pod(5).name` is stored in the :p2pod2 clipboard
    When I run the :label client command with:
      | resource | pod |
      | name     | <%= cb.p2pod1 %> |
      | key_val  | type=red |
    Then the step should succeed

    # add annotation to project 1 and apply the network policies to project 1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-from-label.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-to-label.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # try to access the pod in project 1 from each pod
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod4ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod3 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod3 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod4ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod4ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod4ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"


  # @author bmeng@redhat.com
  # @case_id OCP-12851
  @admin
  Scenario: Allow the specific ports to be accessible via network policy
    # create project and pods for tcp and udp
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).ip_url` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/udp8888-pod.json |
    Then the step should succeed
    And the pod named "udp-pod" becomes ready
    And evaluation of `pod.ip` is stored in the :p1udppodip clipboard

    # create another project and pod
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p2pod1 clipboard

    # add annotation to project 1 and apply the network policy for pod to project 1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-port.yaml |
      | n | <%= cb.proj1 %>                                                                                             |
    Then the step should succeed

    # access the pod in project 1 via tcp and udp port 8888 in each project
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8888 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | bash | -c | (echo UDP-TEST-1) \| ncat -u <%= cb.p1udppodip %> 8888 |
    Then the step should succeed
    When I run the :logs client command with:
      | resource_name | udp-pod |
      | n | <%= cb.proj1 %> |
    Then the step should succeed
    And the output should not contain "UDP-TEST-1"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8888 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | bash | -c | (echo UDP-TEST-2) \| ncat -u <%= cb.p1udppodip %> 8888 |
    Then the step should succeed
    When I run the :logs client command with:
      | resource_name | udp-pod |
      | n | <%= cb.proj1 %> |
    Then the step should succeed
    And the output should not contain "UDP-TEST-2"

    # add another network policy to allow project 2
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-project.yaml |
      | n | <%= cb.proj1 %>                                                                                                |
    Then the step should succeed
    When I run the :label admin command with:
      | resource | namespace |
      | name     | <%= cb.proj2 %> |
      | key_val  | team=blue |
    Then the step should succeed

    # access the pod in project 1 via tcp and udp port 8888 in each project
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8888 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | bash | -c | (echo UDP-TEST-3) \| ncat -u <%= cb.p1udppodip %> 8888 |
    Then the step should succeed
    When I run the :logs client command with:
      | resource_name | udp-pod |
      | n | <%= cb.proj1 %> |
    Then the step should succeed
    And the output should not contain "UDP-TEST-3"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8888 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | bash | -c | (echo UDP-TEST-4) \| ncat -u <%= cb.p1udppodip %> 8888 |
    Then the step should succeed
    When I run the :logs client command with:
      | resource_name | udp-pod |
      | n | <%= cb.proj1 %> |
    Then the step should succeed
    And the output should contain "UDP-TEST-4"


  # @author bmeng@redhat.com
  # @case_id OCP-12800
  @admin
  Scenario: The network policy will also restrict the connection between node and pod
    Given environment has at least 2 nodes
    And I store the nodes in the :nodes clipboard
    # create project and pod
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I have a pod-for-ping in the project
    And evaluation of `pod.ip` is stored in the :p1pod1ip clipboard
    And evaluation of `pod.node_name` is stored in the :podnodename clipboard
    # create another project and pod
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :p2pod1ip clipboard

    # add defaultdeny annotation to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed

    # try to access the pod in both project on different nodes
    Given I use the "<%= cb.podnodename %>" node
    When I run commands on the host:
      | curl -sS --connect-timeout 5 http://<%= cb.p1pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I run commands on the host:
      | curl -sS --connect-timeout 5 http://<%= cb.p2pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= node(-2).name %>" node
    When I run commands on the host:
      | curl -sS --connect-timeout 5 http://<%= cb.p1pod1ip %>:8080 |
    Then the output should contain "Connection timed out"
    And the output should not contain "Hello"
    When I run commands on the host:
      | curl -sS --connect-timeout 5 http://<%= cb.p2pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"

  # @author bmeng@redhat.com
  # @case_id OCP-14668
  @admin
  Scenario: Use networkpolicy plugin with "allow local connections" policy for service
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `service("test-service").ip(user: user)` is stored in the :p1svc1ip clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p2pod1 clipboard
    And evaluation of `service("test-service").ip(user: user)` is stored in the :p2svc1ip clipboard

    # and annotation to both project 1 2, apply network policy to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    Given the DefaultDeny policy is applied to the "<%= cb.proj2 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-local.yaml |
      | n | <%= cb.proj1 %>                                                                                              |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p3pod1 clipboard

    # scale up the pod in project1
    Given I use the "<%= cb.proj1 %>" project
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc                |
      | replicas | 2                      |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    # have a pod-for-ping to access the svc in case the pod access to the svc which endpoint is itself
    Given I have a pod-for-ping in the project

    # access the svc cross project
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"

    # delete the network policy and access again
    When I run the :delete admin command with:
      | object_type       | networkpolicy   |
      | object_name_or_id | allow-local     |
      | n                 | <%= cb.proj1 %> |
    Then the step should succeed
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"


  # @author bmeng@redhat.com
  # @case_id OCP-14669
  @admin
  Scenario: Use networkpolicy plugin with "allow connections from specific project" policy for service
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `service("test-service").ip(user: user)` is stored in the :p1svc1ip clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p2pod1 clipboard
    And evaluation of `service("test-service").ip(user: user)` is stored in the :p2svc1ip clipboard

    # add annotation to both projects and apply network policy to the project1
    When I run the :label admin command with:
      | resource | namespace |
      | name     | <%= cb.proj1 %> |
      | key_val  | team=red |
    Then the step should succeed
    When I run the :label admin command with:
      | resource | namespace |
      | name     | <%= cb.proj2 %> |
      | key_val  | team=blue |
    Then the step should succeed
    # and annotation to both project 1 2, apply network policy to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    Given the DefaultDeny policy is applied to the "<%= cb.proj2 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-project.yaml |
      | n | <%= cb.proj1 %>                                                                                              |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p3pod1 clipboard
    And evaluation of `service("test-service").ip(user: user)` is stored in the :p3svc1ip clipboard
    When I run the :label admin command with:
      | resource | namespace |
      | name     | <%= cb.proj3 %> |
      | key_val  | team=blue |
    Then the step should succeed

    # scale up the pod in project1
    Given I use the "<%= cb.proj1 %>" project
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc                |
      | replicas | 2                      |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    # have a pod-for-ping to access the svc in case the pod access to the svc which endpoint is itself
    Given I have a pod-for-ping in the project

    # access the svc cross project
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p3svc1ip %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"

    # delete the network policy and access again
    When I run the :delete admin command with:
      | object_type       | networkpolicy   |
      | object_name_or_id | allow-from-blue |
      | n                 | <%= cb.proj1 %> |
    Then the step should succeed
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p3svc1ip %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"

  # @author bmeng@redhat.com
  # @case_id OCP-14671
  @admin
  Scenario: Use networkpolicy plugin with "allow all connections" policy for service
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `service("test-service").ip(user: user)` is stored in the :p1svc1ip clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p2pod1 clipboard
    And evaluation of `service("test-service").ip(user: user)` is stored in the :p2svc1ip clipboard

    # and annotation to both project 1 2, apply network policy to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    Given the DefaultDeny policy is applied to the "<%= cb.proj2 %>" namespace
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-all.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p3pod1 clipboard
    And evaluation of `service("test-service").ip(user: user)` is stored in the :p3svc1ip clipboard

    # scale up the pod in project1
    Given I use the "<%= cb.proj1 %>" project
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc                |
      | replicas | 2                      |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    # have a pod-for-ping to access the svc in case the pod access to the svc which endpoint is itself
    Given I have a pod-for-ping in the project

    # access the svc cross project
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p3svc1ip %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"

    # delete the network policy and access again
    When I run the :delete admin command with:
      | object_type       | networkpolicy   |
      | object_name_or_id | allow-all       |
      | n                 | <%= cb.proj1 %> |
    Then the step should succeed
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1ip %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"

  # @author hongli@redhat.com
  # @case_id OCP-14981
  Scenario: Project admins can create and delete networkpolicies in their own project
    Given the master version >= "3.6"

    # create project and networkpolicy
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/defaultdeny-v1-semantic.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | resource | networkpolicy |
    Then the step should succeed
    And the output should contain "default-deny"

    # delete the networkpolicy
    When I run the :delete client command with:
      | object_type       | networkpolicy |
      | object_name_or_id | default-deny  |
    Then the step should succeed
    And I ensure "default-deny" networkpolicies is deleted

  # @author hongli@redhat.com
  # @case_id OCP-15024
  Scenario: Project admin cannot create networkpolicy in other's project
    Given the master version >= "3.6"

    # first user create project
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard

    # second user try to create networkpolicy in first user's project
    Given I switch to the second user
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/defaultdeny-v1-semantic.yaml |
      | namespace | <%= cb.proj1 %> |
    Then the step should fail
    And the output should match "User "<%= user.name %>" cannot create"

  # @author bmeng@redhat.com
  # @case_id OCP-19397
  @admin
  Scenario: Egress type rule in network policy should not affect the policy function
    Given the master version >= "3.9"

    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).ip_url` is stored in the :p2pod1ip clipboard
    And evaluation of `pod(2).name` is stored in the :p2pod1 clipboard

    # create network policy with both ingress and egress field in project 1
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/ignore-egress-policy.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # access the pod via port 8080 in project 1 from project 1
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    # access the pod via other port in project 1 from project 1
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8888 |
    Then the step should fail
    And the output should not contain "Hello"
    # access the pod via port 8080 in project 2 from project 1, the egress rule will be ignored
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    # access the pod via other port in project 2 from project 1, the egress rule will be ignored
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8888 |
    Then the step should succeed
    And the output should contain "Hello"
    # access the pod via port 8080 in project 1 from project 2
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    # access the pod via other port in project 1 from project 2
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8888 |
    Then the step should fail
    And the output should not contain "Hello"


  # @author bmeng@redhat.com
  # @case_id OCP-19399
  @admin
  Scenario: If only egress type of rule appears in the networkpolicy then the networkpolicy will not take effect
    Given the master version >= "3.9"

    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).ip_url` is stored in the :p2pod1ip clipboard
    And evaluation of `pod(2).name` is stored in the :p2pod1 clipboard

    # create network policy with only egress policy in project 1
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/egress-default-deny.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # access pod in project 1 from project 1
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    # access pod in project 2 from project 1
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    # access pod in project 1 from project 2
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"


  # @author bmeng@redhat.com
  # @case_id OCP-19400
  @admin
  Scenario: A policy with an ingress rule with an ipBlock element behaves like it would if that rule was removed
    Given the master version >= "3.9"

    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).ip_url` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    When I run the :label client command with:
      | resource | pod |
      | name     | <%= cb.p1pod1 %> |
      | key_val  | type=red |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).ip_url` is stored in the :p2pod1ip clipboard
    And evaluation of `pod(2).name` is stored in the :p2pod1 clipboard
    And evaluation of `pod(3).name` is stored in the :p2pod2 clipboard
    When I run the :label client command with:
      | resource | pod |
      | name     | <%= cb.p2pod2 %> |
      | key_val  | type=red |
    Then the step should succeed

    # create network policy with ingress.from.ipBlock element in project 1
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/ipblock.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # access the pod in project 1 from pod with label in project1
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    # access the pod in project 1 from pod without label in project1
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    # access the pod in project 2 from pod in project1
    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p2pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    # access the pod in project 1 from pod with label in project2
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    # access the pod in project 1 from pod without label in project2
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"


  # @author bmeng@redhat.com
  # @case_id OCP-19552
  @admin
  Scenario: Should not break the cluster when creating network policy with incorrect json structure
    Given the master version >= "4.1"

    Given I store the masters in the :masters clipboard
    # Create project via user and create invalid networkpolicy in it
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/incorrect-structure.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # Check if there is core dump generated on master nodes
    Given I run commands on the nodes in the :masters clipboard:
      | coredumpctl list |
    Then all outputs should contain:
      | No coredumps found. |

  # @author zzhao@redhat.com
  # @case_id OCP-21219
  @admin
  Scenario: Use networkpolicy plugin with allow connections from specific project and pod at same policy for service
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :p1podip clipboard
    #Add the namespace and pod policy for project1 to make the matched namespaces and matched pods can access project1 pod
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-namespace-and-pod.yaml |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(1).name` is stored in the :p2pod1 clipboard
    And evaluation of `pod(2).name` is stored in the :p2pod2 clipboard

    #try to ping proj1 pod from proj2 pod, it cannot be accessed since the proj2 label do not match team=operations
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1podip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

    #add label for proj2 with team=operations
    When I run the :label admin command with:
      | resource | namespace       |
      | name     | <%= cb.proj2 %> |
      | key_val  | team=operations |
    Then the step should succeed

    #try to ping proj1 pod from proj2 pod, it can be accessed since the policy match the namespace and pod
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1podip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1podip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"

    #change the label do not match the policy for p2pod2
    When I run the :label client command with:
      | resource | pod              |
      | name     | <%= cb.p2pod2 %> |
      | key_val  | name=blue        |
      | overwrite| true             |
    Then the step should succeed

    #try to ping proj1 pod from p2pod2 pod, it cannot be accessed since the pod label do not match name=test-pods
    When I execute on the "<%= cb.p2pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1podip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

  # @author zzhao@redhat.com
  # @case_id OCP-23680
  @admin
  Scenario: Both namespace openshift-ingress and openshift-monitoring should have the default label for networkpolicy
    Given I switch to cluster admin pseudo user
    And the expression should be true> namespace('openshift-ingress').labels['network.openshift.io/policy-group'] == 'ingress'
    And the expression should be true> namespace('openshift-monitoring').labels['network.openshift.io/policy-group'] == 'monitoring'

  # @author zzhao@redhat.com
  # @case_id OCP-22659
  @admin
  @destructive
  Scenario: The old and new created networkpolicy should work well when the sdn pod is recreated
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).ip_url` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(0).node_name` is stored in the :node_name clipboard
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed

    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

    Given I use the "<%= cb.node_name %>" node
    And I restart the network components on the node
    Given I wait for the networking components of the node to become ready
    #Add one policy to make sure the pod can ping each other

    Given I use the "<%= cb.proj1 %>" project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-all.yaml |
    Then the step should succeed

    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"

    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"

    When I run the :delete client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-all.yaml |
    Then the step should succeed

    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

  # @author huirwang@redhat.com
  # @case_id OCP-26207
  @admin
  @destructive
  Scenario: A network policy with ingress rule with "ipBlock"
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 3 |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :pod0_name clipboard
    And evaluation of `pod(1).name` is stored in the :pod1_name clipboard
    And evaluation of `pod(0).ip_url` is stored in the :pod0_ip clipboard
    And evaluation of `pod(2).ip_url` is stored in the :pod2_ip clipboard

    #Apply networpolicy with ipBlock as pod0 ip
    When I download a file from "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/nw_ipblock.yaml"
    And I replace lines in "nw_ipblock.yaml":
      | 10.131.0.25/32 | <%= cb.pod0_ip %>/32 |
    And I run the :create admin command with:
      | f | nw_ipblock.yaml |
      | n | <%= cb.proj1 %> |
    Then the step should succeed

    #From pod0 access pod2 success, from pod1 access pod2 fail
    When I execute on the "<%= cb.pod0_name %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.pod2_ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.pod1_name %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.pod2_ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

    #delete network policy
    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj1 %>" project
    And admin ensures "test-podselector-and-ipblock" network_policy is deleted

    # from pod0 and pod1 access pod2 success
    When I execute on the "<%= cb.pod0_name %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.pod2_ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.pod1_name %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.pod2_ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"


    # create another project and pods
    Given I switch to the first user
    And I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(3).name` is stored in the :pod3_name clipboard
    And evaluation of `pod(3).ip_url` is stored in the :pod3_ip clipboard
    And evaluation of `pod(4).name` is stored in the :pod4_name clipboard

    #Apply networkpoicy to project 1 with ipBlock is pod3 ip
    When I replace lines in "nw_ipblock.yaml":
      | <%= cb.pod0_ip %>/32 | <%= cb.pod3_ip %>/32 |
    And I run the :create admin command with:
      | f | nw_ipblock.yaml |
      | n | <%= cb.proj1 %> |
    Then the step should succeed

    #From pod3 in project 2 access pod2 success, from pod4 in project2 access pod2 fail
    When I execute on the "<%= cb.pod3_name %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.pod2_ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.pod4_name %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.pod2_ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

    #Delete networkpolicy
    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj1 %>" project
    And admin ensures "test-podselector-and-ipblock" networkpolicies is deleted

    # From pod3 and pod4 access pod2 success.
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.pod3_name %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.pod2_ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.pod4_name %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.pod2_ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"

  # @author huirwang@redhat.com
  # @case_id OCP-28723
  # @bug_id 1813846
  @admin
  Scenario: Network policy should work for newly created pods
    Given I have a project
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/allow-from-label.yaml |
      | n | <%= project.name %>                                                                            |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 3 |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).ip_url` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(2).name` is stored in the :p1pod3 clipboard
    When I run the :label client command with:
      | resource | pod              |
      | name     | <%= cb.p1pod2 %> |
      | key_val  | type=red         |
    Then the step should succeed

    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p1pod3 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.p1pod3 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

  # @author huirwang@redhat.com
  # @case_id OCP-26325
  @admin
  Scenario: A network policy with an ipBlock and an except clause, ipBlock will be ignored
    Given I have a project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 3 |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :pod0_name clipboard
    And evaluation of `pod(1).name` is stored in the :pod1_name clipboard
    And evaluation of `pod(0).ip_url` is stored in the :pod0_ip clipboard
    And evaluation of `pod(2).ip_url` is stored in the :pod2_ip clipboard

    #Apply network policy
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/networking/networkpolicy/nw_ipblock_except.yaml" replacing paths:
      | ["spec"]["ingress"][0]["from"][0]["ipBlock"]["cidr"]      | 10.128.0.0/14         |
      | ["spec"]["ingress"][0]["from"][0]["ipBlock"]["except"][0] | <%= cb.pod0_ip %>/32  |
    Then the step should succeed

    #From pod0 and pod1 access pod2 fail
    When I execute on the "<%= cb.pod0_name %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.pod2_ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.pod1_name %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.pod2_ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

    #Check sdn logs, should show IPBlock except not support
    Given I select a random node's host
    And I get the networking components logs of the node since "120s" ago
    Then the output should contain "IPBlocks with except rules are not supported"
