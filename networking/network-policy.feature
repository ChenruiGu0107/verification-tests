Feature: Network policy plugin scenarios

  # @author bmeng@redhat.com
  # @case_id OCP-12801
  @admin
  Scenario: The network between projects are flat and can be managed by admin when using networkpolicy plugin
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).ip_url` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
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
  # @case_id OCP-12804
  @admin
  Scenario: Use networkpolicy plugin with "allow local connections" policy
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
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
    Given I obtain test data file "networking/networkpolicy/allow-local.yaml"
    When I run the :create admin command with:
      | f | allow-local.yaml |
      | n | <%= cb.proj1 %>                                                                                              |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
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
    Given I obtain test data file "networking/networkpolicy/allow-project.yaml"
    When I run the :create admin command with:
      | f | allow-project.yaml |
      | n | <%= cb.proj1 %>                                                                                              |
    Then the step should succeed

    # create another project and pods with label blue
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
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
    Given I obtain test data file "networking/networkpolicy/allow-all.yaml"
    When I run the :create admin command with:
      | f | allow-all.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
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
    Given I obtain test data file "networking/networkpolicy/allow-from-label.yaml"
    When I run the :create admin command with:
      | f | allow-from-label.yaml |
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod(3).name` is stored in the :p2pod1 clipboard

    # add annotation and apply network policy to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    Given I obtain test data file "networking/networkpolicy/allow-to-label.yaml"
    When I run the :create admin command with:
      | f | allow-to-label.yaml |
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
    And evaluation of `pod.ip_url` is stored in the :p1pod4ip clipboard
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(3).name` is stored in the :p2pod1 clipboard
    And evaluation of `pod(4).name` is stored in the :p2pod2 clipboard

    # add annotation and apply network policy to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    Given I obtain test data file "networking/networkpolicy/allow-from-red-to-blue.yaml"
    When I run the :create admin command with:
      | f | allow-from-red-to-blue.yaml |
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).name` is stored in the :p2pod1 clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod(3).name` is stored in the :p3pod1 clipboard

    # add annotation to project 1 and apply the network policies to project 1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    Given I obtain test data file "networking/networkpolicy/allow-local.yaml"
    When I run the :create admin command with:
      | f | allow-local.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed
    Given I obtain test data file "networking/networkpolicy/allow-project.yaml"
    When I run the :create admin command with:
      | f | allow-project.yaml |
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
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
    Given I obtain test data file "networking/networkpolicy/allow-from-label.yaml"
    When I run the :create admin command with:
      | f | allow-from-label.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed
    Given I obtain test data file "networking/networkpolicy/allow-to-label.yaml"
    When I run the :create admin command with:
      | f | allow-to-label.yaml |
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).ip_url` is stored in the :p1pod1ip clipboard
    And evaluation of `pod(1).name` is stored in the :p1pod2 clipboard
    Given I obtain test data file "networking/networkpolicy/udp8888-pod.json"
    When I run the :create client command with:
      | f | udp8888-pod.json |
    Then the step should succeed
    And the pod named "udp-pod" becomes ready
    And evaluation of `pod.ip` is stored in the :p1udppodip clipboard

    # create another project and pod
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p2pod1 clipboard

    # add annotation to project 1 and apply the network policy for pod to project 1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    Given I obtain test data file "networking/networkpolicy/allow-port.yaml"
    When I run the :create admin command with:
      | f | allow-port.yaml |
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
    Given I obtain test data file "networking/networkpolicy/allow-project.yaml"
    When I run the :create admin command with:
      | f | allow-project.yaml |
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
    And evaluation of `pod.ip_url` is stored in the :p1pod1ip clipboard
    And evaluation of `pod.node_name` is stored in the :podnodename clipboard
    # create another project and pod
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip_url` is stored in the :p2pod1ip clipboard

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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `service("test-service").url` is stored in the :p1svc1url clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p2pod1 clipboard
    And evaluation of `service("test-service").url` is stored in the :p2svc1url clipboard

    # and annotation to both project 1 2, apply network policy to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    Given the DefaultDeny policy is applied to the "<%= cb.proj2 %>" namespace
    Then the step should succeed
    Given I obtain test data file "networking/networkpolicy/allow-local.yaml"
    When I run the :create admin command with:
      | f | allow-local.yaml |
      | n | <%= cb.proj1 %>                                                                                              |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
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
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
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
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"


  # @author bmeng@redhat.com
  # @case_id OCP-14669
  @admin
  Scenario: Use networkpolicy plugin with "allow connections from specific project" policy for service
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `service("test-service").url` is stored in the :p1svc1url clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p2pod1 clipboard
    And evaluation of `service("test-service").url` is stored in the :p2svc1url clipboard

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
    Given I obtain test data file "networking/networkpolicy/allow-project.yaml"
    When I run the :create admin command with:
      | f | allow-project.yaml |
      | n | <%= cb.proj1 %>                                                                                              |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p3pod1 clipboard
    And evaluation of `service("test-service").url` is stored in the :p3svc1url clipboard
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
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p3svc1url %> |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1url %> |
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
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p3svc1url %> |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"

  # @author bmeng@redhat.com
  # @case_id OCP-14671
  @admin
  Scenario: Use networkpolicy plugin with "allow all connections" policy for service
    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `service("test-service").url` is stored in the :p1svc1url clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p2pod1 clipboard
    And evaluation of `service("test-service").url` is stored in the :p2svc1url clipboard

    # and annotation to both project 1 2, apply network policy to the project1
    Given the DefaultDeny policy is applied to the "<%= cb.proj1 %>" namespace
    Then the step should succeed
    Given the DefaultDeny policy is applied to the "<%= cb.proj2 %>" namespace
    Then the step should succeed
    Given I obtain test data file "networking/networkpolicy/allow-all.yaml"
    When I run the :create admin command with:
      | f | allow-all.yaml |
      | n | <%= cb.proj1 %>                                                                                            |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given 1 pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :p3pod1 clipboard
    And evaluation of `service("test-service").url` is stored in the :p3svc1url clipboard

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
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p3svc1url %> |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should succeed
    And the output should contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
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
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "hello-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.p2svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.p2pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.p3pod1 %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.p1svc1url %> |
    Then the step should fail
    And the output should not contain "Hello"

  # @author hongli@redhat.com
  # @case_id OCP-14981
  Scenario: Project admins can create and delete networkpolicies in their own project
    Given the master version >= "3.6"

    # create project and networkpolicy
    Given I have a project
    Given I obtain test data file "networking/networkpolicy/defaultdeny-v1-semantic.yaml"
    When I run the :create client command with:
      | f | defaultdeny-v1-semantic.yaml |
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
    Given I obtain test data file "networking/networkpolicy/defaultdeny-v1-semantic.yaml"
    When I run the :create client command with:
      | f | defaultdeny-v1-semantic.yaml |
      | namespace | <%= cb.proj1 %> |
    Then the step should fail
    And the output should match "User "<%= user.name %>" cannot create"

  # @author bmeng@redhat.com
  # @case_id OCP-19399
  @admin
  Scenario: If only egress type of rule appears in the networkpolicy then the networkpolicy will not take effect
    Given the master version >= "3.9"

    # create project and pods
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(1).ip_url` is stored in the :p1pod2ip clipboard
    And evaluation of `pod(0).name` is stored in the :p1pod1 clipboard

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(2).ip_url` is stored in the :p2pod1ip clipboard
    And evaluation of `pod(2).name` is stored in the :p2pod1 clipboard

    # create network policy with only egress policy in project 1
    Given I obtain test data file "networking/networkpolicy/egress-default-deny.yaml"
    When I run the :create admin command with:
      | f | egress-default-deny.yaml |
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
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
    Given I obtain test data file "networking/networkpolicy/ipblock.yaml"
    When I run the :create admin command with:
      | f | ipblock.yaml |
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
    Given I obtain test data file "networking/networkpolicy/incorrect-structure.yaml"
    When I run the :create client command with:
      | f | incorrect-structure.yaml |
    Then the step should succeed
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :p1podip clipboard
    #Add the namespace and pod policy for project1 to make the matched namespaces and matched pods can access project1 pod
    Given I obtain test data file "networking/networkpolicy/allow-namespace-and-pod.yaml"
    When I run the :create client command with:
      | f | allow-namespace-and-pod.yaml |
    Then the step should succeed

    # create another project and pods
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
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
    #Add one policy to make sure the pod can ping each other

    Given I use the "<%= cb.proj1 %>" project
    Given I obtain test data file "networking/networkpolicy/allow-all.yaml"
    When I run the :create client command with:
      | f | allow-all.yaml |
    Then the step should succeed

    When I execute on the "<%= cb.p1pod1 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod2ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"

    When I execute on the "<%= cb.p1pod2 %>" pod:
      | curl | -s | --connect-timeout | 5 | <%= cb.p1pod1ip %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"

    Given I obtain test data file "networking/networkpolicy/allow-all.yaml"
    When I run the :delete client command with:
      | f | allow-all.yaml |
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 3 |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :pod0_name clipboard
    And evaluation of `pod(1).name` is stored in the :pod1_name clipboard
    # pod0 we need the raw ip
    And evaluation of `pod(0).ip` is stored in the :pod0_ip clipboard
    And evaluation of `pod(2).ip_url` is stored in the :pod2_ip clipboard

    #Apply networpolicy with ipBlock as pod0 ip
    When I obtain test data file "networking/networkpolicy/nw_ipblock.yaml"
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(3).name` is stored in the :pod3_name clipboard
    # pod3 we need the raw ip
    And evaluation of `pod(3).ip` is stored in the :pod3_ip clipboard
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
    Given I obtain test data file "networking/networkpolicy/allow-from-label.yaml"
    When I run the :create admin command with:
      | f | allow-from-label.yaml |
      | n | <%= project.name %>                                                                            |
    Then the step should succeed

    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
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
    Given I obtain test data file "networking/list_for_pods.json"
    When I run oc create over "list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 3 |
    Then the step should succeed
    Given 3 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).name` is stored in the :pod0_name clipboard
    And evaluation of `pod(1).name` is stored in the :pod1_name clipboard
    # pod0 we need the raw ip
    And evaluation of `pod(0).ip` is stored in the :pod0_ip clipboard
    And evaluation of `pod(2).ip_url` is stored in the :pod2_ip clipboard

    #Apply network policy
    Given I obtain test data file "networking/networkpolicy/nw_ipblock_except.yaml"
    When I run oc create over "nw_ipblock_except.yaml" replacing paths:
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

  # @author anusaxen@redhat.com
  # @case_id OCP-29337
  @admin
  Scenario: [Bug 1816394] Pod IP rules should be accurately populated when multiple network policies gets triggered at a time
    Given I have a project
    Given I obtain test data file "networking/list_for_pods.json"
    When I run the :create client command with:
      | f | list_for_pods.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `pod(0).ip_url` is stored in the :test_pod1_ip clipboard
    And evaluation of `pod(1).ip_url` is stored in the :test_pod2_ip clipboard
    Given the DefaultDeny policy is applied to the "<%= project.name %>" namespace
    Then the step should succeed
    #Add more network policies
    Given I obtain test data file "networking/networkpolicy/allow-testpods-from-blue-black-Bug1816394.yaml"
    When I run the :create client command with:
      | f | allow-testpods-from-blue-black-Bug1816394.yaml|
    Then the step should succeed
    Given I obtain test data file "networking/networkpolicy/allow-black-from-blue-Bug1816394.yaml"
    When I run the :create client command with:
      | f | allow-black-from-blue-Bug1816394.yaml|
    Then the step should succeed
    Given I obtain test data file "networking/networkpolicy/allow-from-all-pods-Bug1816394.yaml"
    When I run the :create client command with:
      | f | allow-from-all-pods-Bug1816394.yaml|
    Then the step should succeed
    #Creating other pods in loop
    Given evaluation of `%w{black allowall blue}` is stored in the :pods clipboard
    And I run the steps 3 times:
    """
    Given I obtain test data file "networking/pod-for-ping.json"
    When I run oc create over "pod-for-ping.json" replacing paths:
      | ["metadata"]["name"]           | #{cb.pods[cb.i-1]}-pod |
      | ["metadata"]["labels"]["name"] | #{cb.pods[cb.i-1]}     |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=#{cb.pods[cb.i-1]} |
    And evaluation of `pod.ip_url` is stored in the :<%=cb.pods[cb.i-1]%>_ip clipboard
    """
    #As Blue-pod is the pod which will refresh all network policies created above we need to make sure every other pod is curl'able via it which proves that ovs rules are populated correct
    #5-10 seconds are more than enough to make sure rules to get populated in OVS table post above pods creation
    Given 10 seconds have passed
    When I execute on the "blue-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.test_pod1_ip %>:8080 |
    Then the step should succeed
    When I execute on the "blue-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.test_pod2_ip %>:8080 |
    Then the step should succeed
    When I execute on the "blue-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.black_ip %>:8080     |
    Then the step should succeed
    When I execute on the "blue-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.allowall_ip %>:8080  |
    Then the step should succeed
    When I execute on the "black-pod" pod:
      | curl | --connect-timeout | 5 | <%= cb.blue_ip %>:8080      |
    Then the step should fail
	
  # @author anusaxen@redhat.com
  # @case_id OCP-30881
  @admin
  Scenario: Repeatability testing - Create various Network Policies and confirm their recreation in NB db post db crash too
    Given the env is using "OVNKubernetes" networkType
    And I have a project
    #Creating Policies in loop
    Given I obtain test data file "networking/networkpolicy/allow-project.yaml"
    Given I run the steps 10 times:
    """
    When I run oc create over "allow-project.yaml" replacing paths:
      | ["metadata"]["name"] | allow-from-blue-#{cb.i} |
    Then the step should succeed
    """
    Given I store the ovnkube-master "north" leader pod in the clipboard
    And evaluation of `pod.node_name` is stored in the :ovn_nb_leader_node clipboard
    Given I use the "<%= cb.ovn_nb_leader_node %>" node
    And I run commands on the host:
      | pkill -f OVN_Northbound |
    And admin waits for all pods in the "openshift-ovn-kubernetes" project to become ready up to 120 seconds
    #Making sure the policy entries are synced again when NB db is re-created
    Given I store the ovnkube-master "north" leader pod in the clipboard
    And evaluation of `pod.ip_url` is stored in the :new_ovn_nb_leader_ip clipboard
    Given admin executes on the pod:
      | bash | -c | ovn-nbctl list ACL |
    Then the step should succeed
    And the output should contain 10 times:
      | allow-from-blue |
    
    Given I have a project
    #Creating Policies in loop again
    Given I obtain test data file "networking/networkpolicy/allow-project.yaml"
    And I run the steps 10 times:
    """
    When I run oc create over "allow-project.yaml" replacing paths:
      | ["metadata"]["name"] | allow-from-red-#{cb.i} |
    Then the step should succeed
    """
    Given I store the ovnkube-master "north" leader pod in the clipboard
    And evaluation of `pod.node_name` is stored in the :ovn_nb_leader_node clipboard
    Given I use the "<%= cb.ovn_nb_leader_node %>" node
    And I run commands on the host:
      | pkill -f OVN_Northbound |
    And admin waits for all pods in the "openshift-ovn-kubernetes" project to become ready up to 120 seconds
    #Making sure the policy entries are synced again when NB db is re-created
    Given I store the ovnkube-master "north" leader pod in the clipboard
    And evaluation of `pod.ip_url` is stored in the :new_ovn_nb_leader_ip clipboard
    Given admin executes on the pod:
      | bash | -c | ovn-nbctl list ACL |
    Then the step should succeed
    And the output should contain 10 times:
      | allow-from-red  |
      | allow-from-blue |
