Feature: etcd related features
	
  # @author geliu@redhat.com
  # @case_id OCP-24280
  @admin
  Scenario: Etcd basic verification
    Given I switch to cluster admin pseudo user
    When I use the "openshift-etcd" project
    Given 3 pods become ready with labels:
      | k8s-app=etcd |
    Given evaluation of `@pods[0].name` is stored in the :etcdpod clipboard
    When I execute on the pod:
      | bash| -c | etcdctl member list |
    Then the output should contain 3 times:
      | , started, |

  # @author geliu@redhat.com
  # @case_id OCP-19980
  @admin
  @destructive
  Scenario: etcd operator subscription and destroy
    Given I switch to cluster admin pseudo user
    Given admin ensures "etcd-9.2-test" subscriptions is deleted from the "openshift-operators" project after scenario
    Given admin ensures "etcdoperator.v0.9.4-clusterwide" csv is deleted from the "openshift-operators" project after scenario
    And I obtain test data file "admin/subscription.yaml"
    When I run the :create client command with:
      | f | subscription.yaml |
    When I use the "openshift-operators" project
    And status becomes :running of 1 pods labeled:
      | name=etcd-operator-alm-owned |
    When I obtain test data file "admin/etcd-cluster.yaml"
    And I replace lines in "etcd-cluster.yaml":
      | namespace: default | namespace: openshift-operators |
    Given admin ensures "example" etcd_cluster is deleted from the "openshift-operators" project after scenario
    When I run the :create client command with:
      | f | etcd-cluster.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | etcd_cluster=example |
    And status becomes :running of 3 pods labeled:
      | app=etcd | 

  # @author geliu@redhat.com
  # @case_id OCP-19981
  @admin
  @destructive
  Scenario: Resize an etcd cluster
    Given I switch to cluster admin pseudo user
    Given admin ensures "etcd-9.2-test" subscriptions is deleted from the "openshift-operators" project after scenario
    Given admin ensures "etcdoperator.v0.9.4-clusterwide" csv is deleted from the "default" project after scenario 
    And I obtain test data file "admin/subscription.yaml"
    When I run the :create client command with:
      | f | subscription.yaml |
    When I use the "openshift-operators" project
    And status becomes :running of 1 pods labeled:
      | name=etcd-operator-alm-owned |
    Given admin ensures "example" etcd_cluster is deleted from the "openshift-operators" project after scenario
    When I use the "default" project
    When I obtain test data file "admin/etcd-cluster.yaml"
    When I run the :create client command with:
      | f | etcd-cluster.yaml | 
    Given a pod becomes ready with labels:
      | etcd_cluster=example |
    And status becomes :running of 3 pods labeled:
      | app=etcd |
    When I replace lines in "etcd-cluster.yaml":
      | size: 3 | size: 4 |
    Then I run the :apply client command with:
      | f | etcd-cluster.yaml |
    Then the step should succeed
    And status becomes :running of 4 pods labeled:
      | app=etcd |

  # @author geliu@redhat.com
  # @case_id OCP-19982
  @admin
  @destructive
  Scenario: etcd operator automatically recover failure
    Given I switch to cluster admin pseudo user
    Given admin ensures "etcd-9.2-test" subscriptions is deleted from the "openshift-operators" project after scenario
    Given admin ensures "etcdoperator.v0.9.4-clusterwide" csv is deleted from the "default" project after scenario
    And I obtain test data file "admin/subscription.yaml"
    When I run the :create client command with:
      | f | subscription.yaml |
    When I use the "openshift-operators" project
    And status becomes :running of 1 pods labeled:
      | name=etcd-operator-alm-owned |
    Given admin ensures "example" etcd_cluster is deleted from the "openshift-operators" project after scenario
    When I use the "default" project
    When I obtain test data file "admin/etcd-cluster.yaml"
    When I run the :create client command with:
      | f | etcd-cluster.yaml |
    Given a pod becomes ready with labels:
      | etcd_cluster=example |
    And evaluation of `pod.name` is stored in the :pod1 clipboard
    And status becomes :running of 3 pods labeled:
      | app=etcd |
    Given I ensure "<%= cb.pod1 %>" pod is deleted
    And status becomes :running of 3 pods labeled:
      | app=etcd |

  # @author geliu@redhat.com
  # @case_id OCP-19986
  @admin
  @destructive
  Scenario: upgrade an etcd cluster
    Given I switch to cluster admin pseudo user
    Given admin ensures "etcd-9.2-test" subscriptions is deleted from the "openshift-operators" project after scenario
    Given admin ensures "etcdoperator.v0.9.4-clusterwide" csv is deleted from the "default" project after scenario 
    And I obtain test data file "admin/subscription.yaml"
    When I run the :create client command with:
      | f | subscription.yaml | 
    When I use the "openshift-operators" project
    And status becomes :running of 1 pods labeled:
      | name=etcd-operator-alm-owned |
    Given admin ensures "example" etcd_cluster is deleted from the "openshift-operators" project after scenario
    When I use the "default" project
    When I obtain test data file "admin/etcd-cluster.yaml"
    When I run the :create client command with:
      | f | etcd-cluster.yaml |
    Given a pod becomes ready with labels:
      | etcd_cluster=example |
    And status becomes :running of 3 pods labeled:
      | app=etcd |
    When I replace lines in "etcd-cluster.yaml":
      | 3.2.13 | 3.2.3 |
    Then I run the :apply client command with:
      | f | etcd-cluster.yaml |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe client command with:	    
      | resource | po       |
      | l        | app=etcd |
    Then the output should match:
      | etcd.version: 3.2.3 |
    """

  # @author geliu@redhat.com
  # @case_id OCP-20141
  @admin
  @destructive
  Scenario: etcd clusters could be managed in all namespaces
    Given I switch to cluster admin pseudo user
    Given admin ensures "etcd-9.2-test" subscriptions is deleted from the "openshift-operators" project after scenario
    Given admin ensures "etcdoperator.v0.9.4-clusterwide" csv is deleted from the "default" project after scenario
    And I obtain test data file "admin/subscription.yaml"
    When I run the :create client command with:
      | f | subscription.yaml |
    When I use the "openshift-operators" project
    And status becomes :running of 1 pods labeled:
      | name=etcd-operator-alm-owned |
    Given admin ensures "example" etcd_cluster is deleted from the "openshift-operators" project after scenario
    When I use the "default" project
    When I obtain test data file "admin/etcd-cluster.yaml"
    When I run the :create client command with:
      | f | etcd-cluster.yaml |
    Given a pod becomes ready with labels:
      | etcd_cluster=example |
    And status becomes :running of 3 pods labeled:
      | app=etcd |

  # @author knarra@redhat.com
  # @case_id OCP-32124
  @admin
  Scenario: etcd-memeber-pod should have working etcdctl
    Given the master version >= "4.4"
    Given I switch to cluster admin pseudo user
    When I use the "openshift-etcd" project
    And status becomes :running of 3 pods labeled:
      | app=etcd |
    When I execute on the pod:
      | bash | -c | etcdctl |
    Then the output should contain:
      | NAME:                                             |
      | etcdctl - A simple command line client for etcd3. |
      | USAGE:                                            |
      | VERSION:                                          |
      | API VERSION:                                      |
      | COMMANDS:                                         |
      | OPTIONS:                                          |
