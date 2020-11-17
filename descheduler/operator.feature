Feature: Descheduler related scenarios

  # @author knarra@redhat.com
  # @case_id OCP-21481
  @admin
  Scenario: Install descheduler operator via olm
    Given the master version >= "4.4"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-kube-descheduler-operator" project
    And all existing pods are ready with labels:
      | name=descheduler-operator |
      | app=descheduler           |
    And status becomes :running of exactly 1 pods labeled:
      | app=descheduler |
    Given evaluation of `pod.name` is stored in the :pod_name clipboard
    When I run the :logs client command with:
      | resource_name | pod/<%= cb.pod_name %> |
    And the output should contain:
      | duplicates.go         |
      | lownodeutilization.go |
      | pod_antiaffinity.go   |
      | node_affinity.go      |
      | node_taint.go         |

  # @author knarra@redhat.com
  # @case_id OCP-17202
  @admin
  @destructive
  Scenario: Basic Descheduler - Descheduler should not violate PodDisruptionBudget
    Given the master version >= "4.4"
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given I store the schedulable workers in the :nodes clipboard
    Given I switch to cluster admin pseudo user
    And I use the "openshift-kube-descheduler-operator" project
    When I run the :patch admin command with:
      | resource      | kubedescheduler                                                                     |
      | resource_name | cluster                                                                             |
      | p             | [{"op": "replace", "path": "/spec/strategies/0/name", "value": "RemoveDuplicates"}] |
      | type          | json                                                                                |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    Given a pod becomes ready with labels:
      | app=descheduler |
    And evaluation of `pod.name` is stored in the :pod_name clipboard
    When I run the :logs client command with:
      | resource_name | pod/<%= cb.pod_name %> |
    Then the step should succeed
    And the output should contain:
      | duplicates.go |
    """
    And I use the "<%= cb.proj_name %>" project
    When I run the :create_deployment client command with:
      | name  | hello                                                                                                         |
      | image | quay.io/openshifttest/hello-openshift@sha256:424e57db1f2e8e8ac9087d2f5e8faea6d73811f0b6f96301bc94293680897073 |
    Then the step should succeed
    And the output should match "deployment.apps/hello created"
    Given a pod becomes ready with labels:
      | app=hello |
    Given I successfully patch resource "deployment/hello" with:
      | {"spec":{"replicas": 12}} |
    Then the step should succeed
    And I wait until number of replicas match "12" for deployment "hello"
    When I run the :create_poddisruptionbudget client command with:
      | name          | pdbocp17202 |
      | min_available | 11          |
      | selector      | app=hello   |
    Then the step should succeed
    Given I wait up to 80 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | pod/<%= cb.pod_name %>              |
      | n             | openshift-kube-descheduler-operator |
    Then the step should succeed
    And the output should contain:
      | Cannot evict pod as it would violate the pod's disruption budget. |
    """
    Given I ensure "pdbocp17202" poddisruptionbudget is deleted
    When I run the :create_poddisruptionbudget client command with:
      | name            | pdbocp17202_1 |
      | max_unavailable | 11            |
      | selector        | app=hello     |
    Then the step should succeed
    Given I wait up to 80 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | pod/<%= cb.pod_name %>              |
      | n             | openshift-kube-descheduler-operator |
    Then the step should succeed
    And the output should contain:
      | Cannot evict pod as it would violate the pod's disruption budget. |
    """

   # @author knarra@redhat.com
   # @case_id OCP-35000
   @admin
   @destructive
   Scenario: Basic Descheduler - validate if given priorityclass is not present descheduler does not create it
     Given the "cluster" descheduler CR is restored from the "openshift-kube-descheduler-operator" after scenario
     Given I switch to cluster admin pseudo user
     And I use the "openshift-kube-descheduler-operator" project
     When I run the :patch admin command with:
       | resource      | kubedescheduler                                                                                        |
       | resource_name | cluster                                                                                                |
       | p             | [{"op": "replace", "path": "/spec/strategies/0/params/1/name", "value": "thresholdPriorityClassName"}] |
       | type          | json                                                                                                   |
     Then the step should succeed
     When I run the :patch admin command with:
       | resource      | kubedescheduler                                                                             |
       | resource_name | cluster                                                                                     |
       | p             | [{"op": "replace", "path": "/spec/strategies/0/params/1/value", "value": "priorityclass1"}] |
       | type          | json                                                                                        |
     Then the step should succeed
     Given 60 seconds have passed
     Given a pod becomes ready with labels:
       | app=descheduler |
     When I run the :logs client command with:
       | resource_name | <%= pod.name %> |
     Then the step should succeed
     And the output should contain:
       | err="priorityclasses.scheduling.k8s.io \"priorityclass1\" not found |
