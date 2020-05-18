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
 
