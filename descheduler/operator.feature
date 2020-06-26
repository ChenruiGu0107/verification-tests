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

   # @author knarra@redhat.com
   # @case_id OCP-34999
   @admin
   @destructive
   Scenario: validate that descheduler does not allow to configure both thresholdPriority & thresholdPriorityClassName
     Given admin ensures "priorityl" priority_class is deleted after scenario
     # Create priority class
     Given I obtain test data file "scheduler/priority-preemptionscheduling/priorityl.yaml"
     When I run the :create admin command with:
       | f | priorityl.yaml |
     Then the step should succeed
     Given the "cluster" descheduler CR is restored from the "openshift-kube-descheduler-operator" after scenario
     Given I switch to cluster admin pseudo user
     And I use the "openshift-kube-descheduler-operator" project
     When I run the :patch admin command with:
       | resource      | kubedescheduler                                                                                                               |
       | resource_name | cluster                                                                                                                       |
       | p             | [{"op": "add", "path": "/spec/strategies/0/params/2", "value": {"name": "thresholdPriorityClassName", "value": "priorityl"}}] |
       | type          | json                                                                                                                          |
     Then the step should succeed
     Given a pod becomes ready with labels:
       | name=descheduler-operator |
     When I run the :logs admin command with:
       | resource_name | <%= pod.name %> |
     Then the step should succeed
     And the output should contain:
       | cannot set both thresholdPriorityClassName and thresholdPriority |

   # @author knarra@redhat.com
   # @case_id OCP-21842
   @admin
   @destructive
   Scenario: Basic descheduler - NodeAffinity strategy
     Given the master version >= "4.4"
     Given I store the schedulable workers in the :nodes clipboard
     Given node schedulable status should be restored after scenario
     Given the "<%= cb.nodes[0].name %>" node labels are restored after scenario
     Given the "cluster" descheduler CR is restored from the "openshift-kube-descheduler-operator" after scenario
     Given I switch to cluster admin pseudo user
     And I use the "openshift-kube-descheduler-operator" project
     Given a pod becomes ready with labels:
       | app=descheduler |
     When I run the :patch admin command with:
       | resource      | kubedescheduler                                                               |
       | resource_name | cluster                                                                       |
       | p             | [{"op": "replace", "path": "/spec/deschedulingIntervalSeconds", "value": 60}] |
       | type          | json                                                                          |
     Then the step should succeed
     Given I wait for the resource "pod" named "<%= pod.name %>" to disappear
     Given a pod becomes ready with labels:
       | app=descheduler |
     And evaluation of `pod.name` is stored in the :pod_name clipboard
     When I run the :oadm_cordon_node admin command with:
       | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
     Then the step should succeed
     When I run the :oadm_uncordon_node admin command with:
       | node_name | <%= cb.nodes[0].name %> |
     Then the step should succeed
     Given I switch to the first user
     And I have a project
     And evaluation of `project.name` is stored in the :proj_name clipboard
     When I run the :create_deployment client command with:
       | name  | hello                                                                                                         |
       | image | quay.io/openshifttest/hello-openshift@sha256:424e57db1f2e8e8ac9087d2f5e8faea6d73811f0b6f96301bc94293680897073 |
     Then the step should succeed
     Given a pod becomes ready with labels:
       | app=hello |
     When I run the :oadm_uncordon_node admin command with:
       | node_name | <%= cb.nodes[1].name %> |
     Then the step should succeed
     When I run the :patch client command with:
       | resource      | deployment                                                                                                                                                                                                                                                                       |
       | resource_name | hello                                                                                                                                                                                                                                                                            |
       | p             | [{"op": "add", "path": "/spec/template/spec/affinity", "value": {"nodeAffinity": {"requiredDuringSchedulingIgnoredDuringExecution": {"nodeSelectorTerms": [{"matchExpressions": [{"key": "e2e-az-NorthSouth","operator": "In","values": ["e2e-az-North","e2e-az-South"]}]}]}}}}] |
       | type          | json                                                                                                                                                                                                                                                                             |
     Then the step should succeed
     And label "e2e-az-NorthSouth=e2e-az-North" is added to the "<%= cb.nodes[1].name %>" node
     Given I wait up to 10 seconds for the steps to pass:
     """
     And a pod becomes ready with labels:
       | app=hello |
     And evaluation of `pod.name` is stored in the :testpod_name clipboard
     Then the expression should be true> pod.node_name == cb.nodes[1].name
     """
     When I run the :label admin command with:
       | resource | node                    |
       | name     | <%= cb.nodes[1].name %> |
       | key_val  | e2e-az-NorthSouth-      |
     Then the step should succeed
     And label "e2e-az-NorthSouth=e2e-az-North" is added to the "<%= cb.nodes[0].name %>" node
     And I wait up to 80 seconds for the steps to pass:
     """
     Given a pod becomes ready with labels:
       | app=hello |
     Then the expression should be true> pod.node_name == cb.nodes[0].name
     """
     When I run the :logs admin command with:
       | resource_name | pod/<%= cb.pod_name %>              |
       | n             | openshift-kube-descheduler-operator |
     And the output should contain:
       | Evicted 1 pods                                                           |
       | Evicted pod: "<%= cb.testpod_name %>" in namespace "<%= cb.proj_name %>" |
