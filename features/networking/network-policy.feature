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

  #author bmeng@redhat.com
  #case_id OCP-12876
  @admin
  Scenario: Use podSelector to control access for pods with network policy - allow from
    Given the env is using networkpolicy plugin
    # create project and pods and add label to 1 pod
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 3 |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).ip` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(1).ip` is stored in the :p1pod2ip clipboard
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
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
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
    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj1 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-from-label.yaml |
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/aosqe-pod-for-ping.json |
    Then the step should succeed
    And the pod named "hello-pod" becomes ready
    When I run the :label client command with:
      | resource  | pod |
      | name      | <%= cb.p1pod3 %> |
      | name      | hello-pod |
      | key_val   | type=red |
    Then the step should succeed
    Given I use the "<%= cb.proj2 %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/aosqe-pod-for-ping.json |
    Then the step should succeed
    And the pod named "hello-pod" becomes ready
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

  #author bmeng@redhat.com
  #case_id OCP-12877
  @admin
  Scenario: Use podSelector to control access for pods with network policy - allow to
    Given the env is using networkpolicy plugin
    # create project and pods and add label to 1 pod
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 3 |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(1).ip` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(2).ip` is stored in the :p1pod3ip clipboard
    And evaluation of `pod(2).name` is stored in the :p1pod3 clipboard
    When I run the :label client command with:
      | resource | pod |
      | name     | <%= cb.p1pod2 %> |
      | key_val  | type=blue |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(3).name` is stored in the :p2pod1 clipboard

    # add annotation and apply network policy to the project1
    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj1 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-to-label.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # access the labeled pod and un-labeled pod in project 1 via pods in both projects
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
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod3ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

    # Add label to an existing pod and a new pod in project1
    Given I use the "<%= cb.proj1 %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/aosqe-pod-for-ping.json |
    Then the step should succeed
    And the pod named "hello-pod" becomes ready
    And evaluation of `pod.ip` is stored in the :p1pod4ip clipboard
    When I run the :label client command with:
      | resource  | pod |
      | name      | <%= cb.p1pod3 %> |
      | name      | hello-pod |
      | key_val   | type=blue |
    Then the step should succeed

    # access the label new added pods
    Given I use the "<%= cb.proj1 %>" project
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

    # remove the label from pod and access again
    Given I use the "<%= cb.proj1 %>" project
    When I run the :label client command with:
      | resource  | pod |
      | name      | <%= cb.p1pod2 %> |
      | key_val   | type- |
    Then the step should succeed
    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"

  #author bmeng@redhat.com
  #case_id OCP-12945
  @admin
  Scenario: Use podSelector to control access for pods with network policy - allow from red to blue
    Given the env is using networkpolicy plugin
    # create project and pods and add label to 1 pod
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 3 |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(1).ip` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(2).ip` is stored in the :p1pod3ip clipboard
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
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(3).name` is stored in the :p2pod1 clipboard
    And evaluation of `pod(4).name` is stored in the :p2pod2 clipboard

    # add annotation and apply network policy to the project1
    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj1 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-from-red-to-blue.yaml |
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


  #author bmeng@redhat.com
  #case_id OCP-12807
  @admin
  Scenario: Multiple networkpolicys can work together on a single project
    Given the env is using networkpolicy plugin
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(1).ip` is stored in the :p1pod2ip clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).name` is stored in the :p2pod1 clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(3).name` is stored in the :p3pod1 clipboard

    # add annotation to project 1 and apply the network policies to project 1
    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj1 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-local.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-project.yaml |
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


  #author bmeng@redhat.com
  #case_id OCP-13304
  @admin
  Scenario: podSelector allow-to and allow-from can work together
    Given the env is using networkpolicy plugin
    # create project and pods with label added
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 4 |
    Then the step should succeed
    Given 4 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(1).ip` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    And evaluation of `pod(2).name` is stored in the :p1pod3 clipboard
    And evaluation of `pod(3).ip` is stored in the :p1pod4ip clipboard
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
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
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
    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj1 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-from-label.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-to-label.yaml |
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


  #author bmeng@redhat.com
  #case_id OCP-12851
  @admin
  Scenario: Allow the specific ports to be accessible via network policy
    Given the env is using networkpolicy plugin
    # create project and pods for tcp and udp
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).ip` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/udp8888-pod.json |
    Then the step should succeed
    And the pod named "udp-pod" becomes ready
    And evaluation of `pod.ip` is stored in the :p1udppodip clipboard

    # create another project and pod
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p2pod1 clipboard

    # add annotation to project 1 and apply the network policy for pod to project 1
    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj1 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-port.yaml |
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
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/networkpolicy/allow-project.yaml |
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


  #author bmeng@redhat.com
  #case_id OCP-12800
  @admin
  Scenario: The network policy will also restrict the connection between node and pod
    Given the env is using networkpolicy plugin
    And environment has at least 2 nodes
    And I store the nodes in the :nodes clipboard
    # create project and pod 
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/pod_with_nodename.json" replacing paths:
      | ["spec"]["nodeName"] | <%= cb.nodes[0].name %> |
    Then the step should succeed
    Given all pods in the project are ready
    And evaluation of `pod.ip` is stored in the :p1pod1ip clipboard
    # create another project and pod 
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :p2pod1ip clipboard

    # add defaultdeny annotation to the project1
    When I run the :annotate admin command with:
      | resource  | namespace/<%= cb.proj1 %>                                                     |
      | overwrite | true                                                                          |
      | keyval    | net.beta.kubernetes.io/network-policy={"ingress":{"isolation":"DefaultDeny"}} |
    Then the step should succeed

    # try to access the pod in both project on different nodes
    Given I use the "<%= cb.nodes[0].name %>" node
    When I run commands on the host:
      | curl -sS --connect-timeout 5 http://<%= cb.p1pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    When I run commands on the host:
      | curl -sS --connect-timeout 5 http://<%= cb.p2pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.nodes[1].name %>" node
    When I run commands on the host:
      | curl -sS --connect-timeout 5 http://<%= cb.p1pod1ip %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I run commands on the host:
      | curl -sS --connect-timeout 5 http://<%= cb.p2pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
