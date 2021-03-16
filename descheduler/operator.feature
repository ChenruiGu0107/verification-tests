Feature: Descheduler related scenarios

  # @author knarra@redhat.com
  # @case_id OCP-21481
  @admin
  Scenario: Install descheduler operator via olm
    Given the master version == "4.4"
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
  # @case_id OCP-40065
  @admin
  Scenario: Install & validate descheduler for 4.5
    Given the master version == "4.5"
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
      | toomanyrestarts.go    |

  # @author knarra@redhat.com
  # @case_id OCP-40072
  @admin
  Scenario: validate & install descheduler for 4.6
    Given the master version == "4.6"
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
      | toomanyrestarts.go    |
      | pod_lifetime.go       |

  # @author knarra@redhat.com
  # @case_id 40170
  @admin
  Scenario: Install & validate descheduler for 4.7 & above
    Given the master version >= "4.7"
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
      | duplicates.go               |
      | lownodeutilization.go       |
      | pod_antiaffinity.go         |
      | node_affinity.go            |
      | node_taint.go               |
      | toomanyrestarts.go          |
      | pod_lifetime.go             |
      | topologyspreadconstraint.go |

  # @author knarra@redhat.com
  # @case_id OCP-17202
  @admin
  @destructive
  Scenario: Basic Descheduler - Descheduler should not violate PodDisruptionBudget
    Given the master version >= "4.4"
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
    Given I switch to the first user
    And I have a project
    When I run the :create_deployment client command with:
      | name  | hello                                                                                                         |
      | image | quay.io/openshifttest/hello-openshift@sha256:424e57db1f2e8e8ac9087d2f5e8faea6d73811f0b6f96301bc94293680897073 |
    Then the step should succeed
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
    When I run the :logs admin command with:
      | resource_name | <%= cb.pod_name %>                  |
      | n             | openshift-kube-descheduler-operator |
    Then the step should succeed
    And the output should contain:
      | Cannot evict pod as it would violate the pod's disruption budget. |
    """
    Given I ensure "pdbocp17202" pod_disruption_budget is deleted
    When I run the :create_poddisruptionbudget client command with:
      | name            | pdbocp17202 |
      | max_unavailable | 1           |
      | selector        | app=hello   |
    Then the step should succeed
    Given I wait up to 80 seconds for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | <%= cb.pod_name %>                  |
      | since         | 10s                                 |
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
     And the output should match:
       | Evict.*<%= cb.testpod_name %>\|"<%= cb.testpod_name %>" |

   # @author knarra@redhat.com
   # @case_id OCP-34944
   @admin
   @destructive
   Scenario: Validate PodLifeTime Strategy
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
     Then the step should succeed
     Given I switch to the first user
     When I run the :new_project client command with:
       | project_name | ocp34944 |
     Then the step should succeed
     And I use the "ocp34944" project
     When I run the :create_deploymentconfig client command with:
       | image | quay.io/openshifttest/hello-openshift@sha256:aaea76ff622d2f8bcb32e538e7b3cd0ef6d291953f3e7c9f556c1ba5baf47e2e |
       | name  | hello-openshift                                                                                               |
     Then the step should succeed
     Given a pod becomes ready with labels:
       | deploymentconfig=hello-openshift |
     And I wait up to 80 seconds for the steps to pass:
     """
     When I run the :logs admin command with:
       | resource_name | pod/<%= cb.pod_name %>              |
       | n             | openshift-kube-descheduler-operator |
     And the output should contain:
       | Evicted pod: "<%= pod.name %>" in namespace "ocp34944" (PodLifeTime) |
     """

   # @author knarra@redhat.com
   @admin
   @destructive
   Scenario Outline: Basic descheduler - RemovePodsHavingTooManyRestarts
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
     Then the step should succeed
     Given I obtain test data file "descheduler/<podfilename>"
     Given I switch to the first user
     When I run the :new_project client command with:
       | project_name | <project_name> |
     Then the step should succeed
     And I use the "<project_name>" project
     When I run the :create client command with:
       | f | "<podfilename>" |
     Then the step should succeed
     Given a pod is present with labels:
       | app=hello |
     Given evaluation of `pod.name` is stored in the :testpodname clipboard
     And I wait up to 300 seconds for the steps to pass:
     """
       When I get project pod named "<%= cb.testpodname %>" as JSON
       Then the expression should be true> @result[:parsed]['status']['<statuses>'][0]['restartCount'] == 3
     """
     And I wait up to 80 seconds for the steps to pass:
     """
     When I run the :logs admin command with:
       | resource_name | pod/<%= cb.pod_name %>              |
       | n             | openshift-kube-descheduler-operator |
     And the output should contain:
       | Evicted pod: "<%= cb.testpodname %>" in namespace "<project_name>" |
     """
     Examples:
       | podfilename   | statuses              | project_name |
       | ocp30710.yaml | containerStatuses     | ocp30710     | # @case_id OCP-30710
       | ocp37032.yaml | initContainerStatuses | ocp37032     | # @case_id OCP-37032

   # @author knarra@redhat.com
   # @case_id OCP-34998
   @admin
   @destructive
   Scenario:  Verify that user is not able to set both included & Excluded Namespaces
     Given the "cluster" descheduler CR is restored from the "openshift-kube-descheduler-operator" after scenario
     Given I switch to cluster admin pseudo user
     And I use the "openshift-kube-descheduler-operator" project
     When I run the :patch admin command with:
       | resource      | kubedescheduler                                                                                                       |
       | resource_name | cluster                                                                                                               |
       | p             | [{"op": "add", "path": "/spec/strategies/4/params/3", "value": {"name": "excludeNamespaces", "value": "my-project"}}] |
       | type          | json                                                                                                                  |
     Then the step should succeed
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
     And I wait up to 80 seconds for the steps to pass:
     """
     When I run the :logs admin command with:
       | resource_name | pod/<%= cb.pod_name %>              |
       | n             | openshift-kube-descheduler-operator |
     And the output should contain:
       | only one of Include/Exclude namespaces can be set |
     """

   # @author knarra@redhat.com
   # @case_id OCP-34956
   @admin
   @destructive
   Scenario: Basic descheduler - validate excludeOwnerKinds param of RemoveDuplicates strategy
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
     Then the step should succeed
     Given I obtain test data file "replicaSet/rs.yaml"
     Given I switch to the first user
     And I have a project
     And evaluation of `project.name` is stored in the :proj_name clipboard
     When I run the :create client command with:
       | f | rs.yaml |
     Then the step should succeed
     And I run the :scale client command with:
       | resource | replicaset |
       | name     | frontend   |
       | replicas | 12         |
     Then the step should succeed
     And I wait until number of replicas match "12" for replicaSet "frontend"
     Given 80 seconds have passed
     When I run the :logs admin command with:
       | resource_name | pod/<%= cb.pod_name %>              |
       | n             | openshift-kube-descheduler-operator |
     And the output should not contain:
       | in namespace "<%= cb.proj_name %>" (RemoveDuplicates) |

   # @author knarra@redhat.com
   # @case_id OCP-17095
   @admin
   @destructive
   Scenario: Basic descheduler - RemovePodsViolatingInterPodAntiAffinity strategy
     Given the CR "descheduler" named "cluster" is restored from the "openshift-kube-descheduler-operator" after scenario
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
     Given I obtain test data file "descheduler/ocp17095.yaml"
     Given I switch to first user
     Given I have a project
     And evaluation of `project.name` is stored in the :proj_name clipboard
     When I run the :create client command with:
      | f | ocp17095.yaml |
     Then the step should succeed
     Given a pod becomes ready with labels:
       | app=testone |
     Given evaluation of `pod.name` is stored in the :podonename clipboard
     Given evaluation of `pod.node_name` is stored in the :nodename clipboard
     Given I obtain test data file "descheduler/ocp170951.yaml"
     When I run the :create client command with:
       | f | ocp170951.yaml |
     Then the step should succeed
     When I run the :get client command with:
       | resource | pod      |
       | l        | app=test |
       | o        | wide     |
     Then the step should succeed
     And the output should contain "<%= cb.nodename %>"
     When I run the :label client command with:
       | resource | pod                    |
       | name     | <%= cb.podonename %>   |
       | key_val  | key17095=value17095    |
     Then the step should succeed
     Given I wait up to 80 seconds for the steps to pass:
     """
     When I run the :logs admin command with:
       | resource_name | pod/<%= cb.pod_name %>              |
       | n             | openshift-kube-descheduler-operator |
     Then the step should succeed
     And the output should match:
       | Evicted pod.*test.*in namespace "<%= cb.proj_name %>" |
     """
     Given I wait up to 80 seconds for the steps to pass:
     """
     When I run the :get client command with:
       | resource | pod      |
       | l        | app=test |
       | o        | wide     |
     Then the step should succeed
     And the output should not contain "<%= cb.nodename %>"
     """

   # @author knarra@redhat.com
   # @case_id OCP-37441
   @admin
   @destructive
   Scenario: Validate TopologyAndDuplicates descheduler profile
     Given the "cluster" descheduler CR is restored from the "openshift-kube-descheduler-operator" after scenario
     Given I store the schedulable workers in the :nodes clipboard
     Given node schedulable status should be restored after scenario
     When I run the :oadm_cordon_node admin command with:
       | node_name | noescape: <%= cb.nodes.map(&:name).join(" ") %> |
     Then the step should succeed
     When I run the :oadm_uncordon_node admin command with:
       | node_name | <%= cb.nodes[0].name %> |
     Then the step should succeed
     When I run the :oadm_uncordon_node admin command with:
       | node_name | <%= cb.nodes[1].name %> |
     Then the step should succeed
     Given the "<%= cb.nodes[0].name %>" node labels are restored after scenario
     Given the "<%= cb.nodes[1].name %>" node labels are restored after scenario
     And label "ocp37441-zone=ocp37441zoneA" is added to the "<%= cb.nodes[0].name %>" node
     And label "ocp37441-zone=ocp37441zoneB" is added to the "<%= cb.nodes[1].name %>" node
     When I run the :oadm_cordon_node admin command with:
       | node_name | <%= cb.nodes[1].name %> |
     Then the step should succeed
     Given I obtain test data file "descheduler/ocp37441.yaml"
     Given I switch to first user
     Given I have a project
     And evaluation of `project.name` is stored in the :proj_name clipboard
     When I run the :create client command with:
       | f | ocp37441.yaml |
     Then the step should succeed
     Given I obtain test data file "descheduler/ocp37441one.yaml"
     When I run the :create client command with:
       | f | ocp37441one.yaml |
     Then the step should succeed
     When I run the :create client command with:
       | f | ocp37441one.yaml |
     Then the step should succeed
     When I run the :oadm_cordon_node admin command with:
       | node_name | <%= cb.nodes[0].name %> |
     Then the step should succeed
     When I run the :oadm_uncordon_node admin command with:
       | node_name | <%= cb.nodes[1].name %> |
     Then the step should succeed
     When I run the :create client command with:
       | f | ocp37441one.yaml |
     Then the step should succeed
     Given 4 pod becomes ready with labels:
       | ocp37441=ocp37441 |
     When I run the :oadm_uncordon_node admin command with:
       | node_name | <%= cb.nodes[0].name %> |
     Then the step should succeed
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
     When I run the :logs admin command with:
       | resource_name | pod/<%= cb.pod_name %>              |
       | n             | openshift-kube-descheduler-operator |
     Then the step should succeed
     And the output should match:
       | \"Evicted pod\" pod\=\"<%= cb.proj_name %>.*\" reason\=\" \(PodTopologySpread\)\" |
