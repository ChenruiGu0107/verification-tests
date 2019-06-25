Feature: cluster storage operator related scenarios
  # @author lxia@redhat.com
  # @case_id OCP-24110
  @admin
  Scenario: Cluster storage operator pod is using terminationMessagePolicy FallbackToLogsOnError
    #Given the master version >= "4.2"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-cluster-storage-operator" project
    And a pod becomes ready with labels:
      | name=cluster-storage-operator |
    And the expression should be true> pod.container(name: 'cluster-storage-operator').spec.termination_message_policy == 'FallbackToLogsOnError'
