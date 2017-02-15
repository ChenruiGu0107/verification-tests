Feature: Network policy plugin scenarios

  #author bmeng@redhat.com
  #case_id OCP-12801
  @admin
  Scenario: The network between projects are flat and can be managed by admin when using networkpolicy plugin
    Given the env is using networkpolicy plugin
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).ip` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(1).ip` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).ip` is stored in the :p2pod1ip clipboard
    And evaluation of `pod(3).ip` is stored in the :p2pod2ip clipboard
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
    When I run the :annotate admin command with:
      | resource     | namespace/<%= cb.proj1 %> |
      | overwrite    | true |
      | keyval       | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
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


  #author bmeng@redhat.com
  #case_id OCP-12803
  @admin
  @destructive
  Scenario: Set networkpolicy to project which does not have the annoation will not take effect
    Given the env is using networkpolicy plugin
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # check the openflow rules
    Given I select a random node's host
    When I run commands on the host:
      | ovs-ofctl -O OpenFlow13 dump-flows br0 \| grep priority=100.*actions=output:NXM_NX_REG2 \|\| docker exec openvswitch ovs-ofctl -O OpenFlow13 dump-flows br0 \| grep priority=100.*actions=output:NXM_NX_REG2 |
    Then the step should succeed
    And the output should not contain "reg0=0x"

    # apply network policy to project which does not have the annotation
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-local.yaml |
      | n | <%= cb.proj1 %> |
    Then the step should succeed

    # check the openflow rules
    Given I select a random node's host
    When I run commands on the host:
      | ovs-ofctl -O OpenFlow13 dump-flows br0 \| grep priority=100.*actions=output:NXM_NX_REG2 \|\| docker exec openvswitch ovs-ofctl -O OpenFlow13 dump-flows br0 \| grep priority=100.*actions=output:NXM_NX_REG2 |
    Then the step should succeed
    And the output should not contain "reg0=0x"

    # apply network policy to project which does not have the annotation
    When I run the :annotate admin command with:
      | resource     | namespace/<%= cb.proj2 %> |
      | overwrite    | true |
      | keyval       | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-local.yaml |
      | n | <%= cb.proj2 %> |
    Then the step should succeed

    # check the openflow rules
    Given I select a random node's host
    When I run commands on the host:
      | ovs-ofctl -O OpenFlow13 dump-flows br0 \| grep priority=100.*actions=output:NXM_NX_REG2 \|\| docker exec openvswitch ovs-ofctl -O OpenFlow13 dump-flows br0 \| grep priority=100.*actions=output:NXM_NX_REG2 |
    Then the step should succeed
    And the output should contain "reg0=0x"

  #author bmeng@redhat.com
  #case_id OCP-12804
  @admin
  Scenario: Use networkpolicy plugin with "allow local connections" policy
    Given the env is using networkpolicy plugin
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).ip` is stored in the :p2pod1ip clipboard
    And evaluation of `pod(3).name` is stored in the :p2pod2 clipboard

    # and annotation to both project 1 2, apply network policy to the project1
    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj1 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj2 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-local.yaml |
      | n | <%= cb.proj1 %>                                                                                              |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(4).name` is stored in the :p3pod1 clipboard
    And evaluation of `pod(5).ip` is stored in the :p3pod2ip clipboard

    # scale up the pod in project1
    Given I use the "<%= cb.proj1 %>" project
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc                |
      | replicas | 3                      |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(-3).ip` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(-3).ip` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(-2).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(-2).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(-1).ip` is stored in the :p1pod3ip clipboard

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


  #author bmeng@redhat.com
  #case_id OCP-12805
  @admin
  Scenario: Use networkpolicy plugin with "allow connections from specific project" policy
    Given the env is using networkpolicy plugin
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).ip` is stored in the :p2pod1ip clipboard
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

    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj1 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj2 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-project.yaml |
      | n | <%= cb.proj1 %>                                                                                              |
    Then the step should succeed

    # create another project and pods with label blue
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(4).name` is stored in the :p3pod1 clipboard
    And evaluation of `pod(5).ip` is stored in the :p3pod2ip clipboard
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
    And evaluation of `pod(-3).ip` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(-3).ip` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(-2).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(-2).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(-1).ip` is stored in the :p1pod3ip clipboard

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


  #author bmeng@redhat.com
  #case_id OCP-12806
  @admin
  Scenario: Use networkpolicy plugin with "allow all connections" policy
    Given the env is using networkpolicy plugin
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).ip` is stored in the :p2pod1ip clipboard
    And evaluation of `pod(3).name` is stored in the :p2pod2 clipboard

    # and annotation to both project 1 2, apply network policy to the project1
    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj1 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj2 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-all.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(4).name` is stored in the :p3pod1 clipboard
    And evaluation of `pod(5).ip` is stored in the :p3pod2ip clipboard

    # scale up the pod in project1
    Given I use the "<%= cb.proj1 %>" project
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | test-rc                |
      | replicas | 3                      |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(-3).ip` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(-3).ip` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(-2).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(-2).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(-1).ip` is stored in the :p1pod3ip clipboard

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
