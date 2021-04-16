Feature: Cluster Autoscaler Tests

  # @author zhsun@redhat.com
  # @case_id OCP-20854
  @admin
  @destructive
  Scenario: Some special pods can prevent CA from removing a node
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario

    Given I clone a machineset and name it "machineset-clone-20854"

    # Create clusterautoscaler
    Given I obtain test data file "cloud/cluster-autoscaler.yml"
    When I run the :create admin command with:
      | f | cluster-autoscaler.yml |
    Then the step should succeed
    And admin ensures "default" clusterautoscaler is deleted after scenario

    # Create machineautoscaler
    Given I obtain test data file "cloud/machine-autoscaler.yml"
    When I run oc create over "machine-autoscaler.yml" replacing paths:
      | ["metadata"]["name"]               | maotest                |
      | ["spec"]["minReplicas"]            | 1                      |
      | ["spec"]["maxReplicas"]            | 3                      |
      | ["spec"]["scaleTargetRef"]["name"] | machineset-clone-20854 |
    Then the step should succeed
    And admin ensures "maotest" machineautoscaler is deleted after scenario

    # Create workload
    Given I obtain test data file "cloud/autoscaler-auto-tmpl.yml"
    When I run the :create admin command with:
      | f | autoscaler-auto-tmpl.yml |
    Then the step should succeed
    And admin ensures "workload" job is deleted after scenario

    # Verify machineset has scaled
    Given I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set("machineset-clone-20854").desired_replicas(cached: false) == 3
    """
    Then the machineset should have expected number of running machines

    # Create workload with "safe-to-evict" annotation
    Given I store the last provisioned machine in the :machine clipboard
    And evaluation of `machine(cb.machine).node_name` is stored in the :noderef_name clipboard
    Given I obtain test data file "cloud/safe-to-evict-pod.yml"
    When I run oc create over "safe-to-evict-pod.yml" replacing paths:
      | ["spec"]["nodeName"] | <%= cb.noderef_name %> |
    Then the step should succeed
    And admin ensures "safe-to-evict" pod is deleted after scenario

    # Delete workload manually to scale down the cluster
    Given admin ensures "workload" job is deleted from the "openshift-machine-api" project

    Given 1 pods become ready with labels:
      | cluster-autoscaler=default,k8s-app=cluster-autoscaler |
    And I wait for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | <%= pod.name %> |
    Then the step should succeed
    And the output should match:
      | 1 nodes found to be unremovable in simulation                         |
      | Scale-down calculation: ignoring 1 nodes unremovable in the last 5m0s |
    """

    # Check cluster auto scales down
    And I wait up to 600 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set("machineset-clone-20854").desired_replicas(cached: false) == 1
    """
    Then the machineset should have expected number of running machines

    # Check special pods can prevent CA from removing a node
    And I check that the "<%= cb.noderef_name %>" node exists

  # @author zhsun@redhat.com
  # @case_id OCP-20108
  @admin
  @destructive
  Scenario: Cluster-autoscaler should balance similiar node groups between zones
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario

    Given I clone a machineset and name it "machineset-clone-20108"
    Given I clone a machineset and name it "machineset-clone-20108-2"

    # Create clusterautoscaler
    Given I obtain test data file "cloud/cluster-autoscaler.yml"
    When I run oc create over "cluster-autoscaler.yml" replacing paths:
      | ["spec"]["balanceSimilarNodeGroups"] | true |
    Then the step should succeed
    And admin ensures "default" clusterautoscaler is deleted after scenario
    And 1 pod becomes ready with labels:
      | cluster-autoscaler=default,k8s-app=cluster-autoscaler |

    # Create machineautoscaler
    Given I obtain test data file "cloud/machine-autoscaler.yml"
    When I run oc create over "machine-autoscaler.yml" replacing paths:
      | ["metadata"]["name"]               | maotest                |
      | ["spec"]["minReplicas"]            | 1                      |
      | ["spec"]["maxReplicas"]            | 3                      |
      | ["spec"]["scaleTargetRef"]["name"] | machineset-clone-20108 |
    Then the step should succeed
    And admin ensures "maotest" machineautoscaler is deleted after scenario
    Given I obtain test data file "cloud/machine-autoscaler.yml"
    When I run oc create over "machine-autoscaler.yml" replacing paths:
      | ["metadata"]["name"]               | maotest1                 |
      | ["spec"]["minReplicas"]            | 1                        |
      | ["spec"]["maxReplicas"]            | 3                        |
      | ["spec"]["scaleTargetRef"]["name"] | machineset-clone-20108-2 |
    Then the step should succeed
    And admin ensures "maotest1" machineautoscaler is deleted after scenario

    # Create workload
    Given I obtain test data file "cloud/autoscaler-auto-tmpl.yml"
    When I run the :create admin command with:
      | f | autoscaler-auto-tmpl.yml |
    Then the step should succeed
    And admin ensures "workload" job is deleted after scenario

    # Verify machineset has scaled
    Given I wait for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | <%= pod.name %> |
    Then the step should succeed
    And the output should contain:
      | Splitting scale-up between 2 similar node groups |
    """

    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set("machineset-clone-20108").desired_replicas(cached: false) == 3
    """
    Then the machineset should have expected number of running machines
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set("machineset-clone-20108-2").desired_replicas(cached: false) == 3
    """
    Then the machineset should have expected number of running machines

    # Delete workload
    Given admin ensures "workload" job is deleted from the "openshift-machine-api" project

    # Check cluster auto scales down
    And I wait up to 600 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set("machineset-clone-20108").desired_replicas(cached: false) == 1
    """
    Then the machineset should have expected number of running machines
    And I wait up to 600 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set("machineset-clone-20108-2").desired_replicas(cached: false) == 1
    """
    Then the machineset should have expected number of running machines

  # @author zhsun@redhat.com
  # @case_id OCP-24715
  @admin
  @destructive
  Scenario: Cluster-autoscaler should never delete nodes with pods with local storage
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario

    Given I clone a machineset and name it "machineset-clone-24715"

    # Create clusterautoscaler
    Given I use the "openshift-machine-api" project
    Given I obtain test data file "cloud/cluster-autoscaler.yml"
    When I run oc create over "cluster-autoscaler.yml" replacing paths:
      | ["spec"]["skipNodesWithLocalStorage"] | true |
    Then the step should succeed
    And admin ensures "default" clusterautoscaler is deleted after scenario
    And 1 pod becomes ready with labels:
      | cluster-autoscaler=default,k8s-app=cluster-autoscaler |

    # Create machineautoscaler
    Given I obtain test data file "cloud/machine-autoscaler.yml"
    When I run oc create over "machine-autoscaler.yml" replacing paths:
      | ["metadata"]["name"]               | maotest                |
      | ["spec"]["minReplicas"]            | 1                      |
      | ["spec"]["maxReplicas"]            | 3                      |
      | ["spec"]["scaleTargetRef"]["name"] | machineset-clone-24715 |
    Then the step should succeed
    And admin ensures "maotest" machineautoscaler is deleted after scenario

    # Create workload
    Given I obtain test data file "cloud/autoscaler-auto-tmpl.yml"
    When I run the :create admin command with:
      | f | autoscaler-auto-tmpl.yml |
    Then the step should succeed
    And admin ensures "workload" job is deleted after scenario

    # Verify machineset has scaled
    Given I wait for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | <%= pod.name %> |
    Then the step should succeed
    And the output should contain:
      | Final scale-up plan |
    """

    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set.desired_replicas(cached: false) == 3
    """
    Then the machineset should have expected number of running machines

    #Create a pod with local storage
    Given I store the last provisioned machine in the :machine clipboard
    And evaluation of `machine(cb.machine).node_name` is stored in the :noderef_name clipboard
    Given I obtain test data file "cloud/local-storage-pod.yml"
    When I run oc create over "local-storage-pod.yml" replacing paths:
      | ["spec"]["nodeName"]               | <%= cb.noderef_name %> |
    Then the step should succeed
    And admin ensures "localstorage" pod is deleted after scenario

    # Delete workload
    Given admin ensures "workload" job is deleted from the "openshift-machine-api" project

    # Check cluster auto scales down
    And I wait up to 600 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set.desired_replicas(cached: false) == 1
    """
    Then the machineset should have expected number of running machines

    # Check node with pod with local storage is not deleted
    When I run the :get admin command with:
      | resource      | node           |
      | resource_name | <%= cb.noderef_name %> |
    Then the step succeeded

  # @author zhsun@redhat.com
  # @case_id OCP-20787
  @admin
  @destructive
  Scenario: Use annotation to prevent cluster autoscaler from scaling down a node
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario

    Given I clone a machineset and name it "machineset-clone-20787"

    # Create clusterautoscaler
    Given I use the "openshift-machine-api" project
    Given I obtain test data file "cloud/cluster-autoscaler.yml"
    When I run the :create admin command with:
      | f | cluster-autoscaler.yml |
    Then the step should succeed
    And admin ensures "default" clusterautoscaler is deleted after scenario
    And 1 pod becomes ready with labels:
      | cluster-autoscaler=default,k8s-app=cluster-autoscaler |

    # Create machineautoscaler
    Given I obtain test data file "cloud/machine-autoscaler.yml"
    When I run oc create over "machine-autoscaler.yml" replacing paths:
      | ["metadata"]["name"]               | maotest                |
      | ["spec"]["minReplicas"]            | 1                      |
      | ["spec"]["maxReplicas"]            | 3                      |
      | ["spec"]["scaleTargetRef"]["name"] | machineset-clone-20787 |
    Then the step should succeed
    And admin ensures "maotest" machineautoscaler is deleted after scenario

    # Create workload
    Given I obtain test data file "cloud/autoscaler-auto-tmpl.yml"
    When I run the :create admin command with:
      | f | autoscaler-auto-tmpl.yml |
    Then the step should succeed
    And admin ensures "workload" job is deleted after scenario

    # Verify machineset has scaled
    Given I wait for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | <%= pod.name %> |
    Then the step should succeed
    And the output should contain:
      | Final scale-up plan |
    """

    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set.desired_replicas(cached: false) == 3
    """
    Then the machineset should have expected number of running machines

    # Add annotation to a node
    Given I store the last provisioned machine in the :machine clipboard
    And evaluation of `machine(cb.machine).node_name` is stored in the :noderef_name clipboard
    When I run the :annotate admin command with:
      | resource     | node                                                      |
      | resourcename | <%= cb.noderef_name %>                                    |
      | keyval       | cluster-autoscaler.kubernetes.io/scale-down-disabled=true |
    Then the step should succeed

    # Delete workload
    Given admin ensures "workload" job is deleted from the "openshift-machine-api" project

    # Check cluster auto scales down
    And I wait up to 600 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set.desired_replicas(cached: false) == 1
    """
    Then the machineset should have expected number of running machines
    # Check node with pod with local storage is not deleted
    When I run the :get admin command with:
      | resource      | node                   |
      | resource_name | <%= cb.noderef_name %> |
    Then the step succeeded
    And I wait for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | <%= pod.name %> |
    Then the step should succeed
    And the output should contain:
      | Skipping <%= cb.noderef_name %> from delete consideration - the node is marked as no scale down |
    """

  # @author zhsun@redhat.com
  # @case_id OCP-19898
  @admin
  @destructive
  Scenario: Cluster-autoscaler should work with Pod Priority and Preemption
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario

    Given I clone a machineset and name it "machineset-clone-19898"

    # Create clusterautoscaler,podPriorityThreshold is -10 by default
    Given I use the "openshift-machine-api" project
    Given I obtain test data file "cloud/cluster-autoscaler.yml"
    When I run the :create admin command with:
      | f | cluster-autoscaler.yml |
    Then the step should succeed
    And admin ensures "default" clusterautoscaler is deleted after scenario
    And 1 pod becomes ready with labels:
      | cluster-autoscaler=default,k8s-app=cluster-autoscaler |

    # Create machineautoscaler
    Given I obtain test data file "cloud/machine-autoscaler.yml"
    When I run oc create over "machine-autoscaler.yml" replacing paths:
      | ["metadata"]["name"]               | maotest                |
      | ["spec"]["minReplicas"]            | 1                      |
      | ["spec"]["maxReplicas"]            | 3                      |
      | ["spec"]["scaleTargetRef"]["name"] | machineset-clone-19898 |
    Then the step should succeed
    And admin ensures "maotest" machineautoscaler is deleted after scenario

    # Create priorityclass
    Given I obtain test data file "cloud/priority-class-low.yml"
    When I run the :create admin command with:
      | f | priority-class-low.yml |
    Then the step should succeed
    And admin ensures "low" priorityclass is deleted after scenario
    Given I obtain test data file "cloud/priority-class-high.yml"
    When I run the :create admin command with:
      | f | priority-class-high.yml |
    Then the step should succeed
    And admin ensures "high" priorityclass is deleted after scenario

    # Create workload,priority is 1
    Given I obtain test data file "cloud/autoscaler-auto-tmpl.yml"
    When I run oc create over "autoscaler-auto-tmpl.yml" replacing paths:
      | ["spec"]["template"]["spec"]["priorityClassName"] | low |
    Then the step should succeed
    And admin ensures "workload" job is deleted after scenario

    # Verify machineset has scaled, workload priority is 1,podPriorityThreshold is -10
    Given I wait for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | <%= pod.name %> |
    Then the step should succeed
    And the output should contain:
      | Final scale-up plan |
    """

    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set.desired_replicas(cached: false) == 3
    """
    Then the machineset should have expected number of running machines

    # 1)Verify pods with priority lower than this cutoff don't prevent scale-downs
    # workload priority is 1,podPriorityThreshold is 10
    Given as admin I successfully merge patch resource "clusterautoscaler/default" with:
      | {"spec":{"podPriorityThreshold":10}} |
    And I wait for the pod to die regardless of current status
    And a pod becomes ready with labels:
      | cluster-autoscaler=default,k8s-app=cluster-autoscaler |

    # Check cluster auto scales down
    And I wait up to 600 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set.desired_replicas(cached: false) == 1
    """
    Then the machineset should have expected number of running machines

    # 2)Verify pods with priority lower than this cutoff don't trigger scale-ups
    # workload priority is 1,podPriorityThreshold is 10
    Given 120 seconds have passed
    When I run the :logs admin command with:
      | resource_name | <%= pod.name %> |
    Then the step should succeed
    And the output should not contain:
      | Final scale-up plan |
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set.desired_replicas(cached: false) == 1
    """
    Then the machineset should have expected number of running machines

    # Delete workload
    Given admin ensures "workload" job is deleted from the "openshift-machine-api" project

    # 3)Verifify nothing changes for pods with priority greater or equal to cutoff
    # workload priority is 100,podPriorityThreshold is 10
    Given I obtain test data file "cloud/autoscaler-auto-tmpl.yml"
    When I run oc create over "autoscaler-auto-tmpl.yml" replacing paths:
      | ["spec"]["template"]["spec"]["priorityClassName"] | high |
    Then the step should succeed
    And admin ensures "workload" job is deleted after scenario

    # Verify machineset has scaled
    Given I wait for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | <%= pod.name %> |
    Then the step should succeed
    And the output should contain:
      | Final scale-up plan |
    """

    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set.desired_replicas(cached: false) == 3
    """
    Then the machineset should have expected number of running machines

    # Delete workload
    Given admin ensures "workload" job is deleted from the "openshift-machine-api" project

    # Check cluster auto scales down
    And I wait up to 600 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set.desired_replicas(cached: false) == 1
    """
    Then the machineset should have expected number of running machines

  # @author zhsun@redhat.com
  @admin
  @destructive
  Scenario Outline: Machineset should have relevant annotations to support scale from/to zero
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario

    And I use the "openshift-machine-api" project
    And I pick a random machineset to scale

    When I get project machineset named "<%= machine_set.name %>" as YAML
    And I save the output to file> machineset.yaml

    # Create a machineset with a valid instanceType
    And I replace content in "machineset.yaml":
      | <%= machine_set.name %> | <machineset_name>-valid |
      | <re_type_field>         | <valid_value>           |
      | /replicas:.*/           | replicas: 1             |

    When I run the :create admin command with:
      | f | machineset.yaml |
    Then the step should succeed
    And admin ensures "<machineset_name>-valid" machineset is deleted after scenario

    When I run the :annotate admin command with:
      | resource     | machineset               |
      | resourcename | <machineset_name>-valid  |
      | overwrite    | true                     |
      | keyval       | new=new                  |
    Then the step should succeed

    When I run the :describe admin command with:
      | resource | machineset              |
      | name     | <machineset_name>-valid |
    Then the step should succeed
    And the output should contain:
      | machine.openshift.io/memoryMb: |
      | machine.openshift.io/vCPU:     |
      | new:                           |

    # Create a machineset with an invalid instanceType
    And I replace content in "machineset.yaml":
      | <%= machine_set.name %> | <machineset_name>-invalid |
      | <re_type_field>         | <invalid_value>           |
      | /replicas:.*/           | replicas: 1               |

    When I run the :create admin command with:
      | f | machineset.yaml |
    Then the step should succeed
    And admin ensures "<machineset_name>-invalid" machineset is deleted after scenario

    Given 1 pod becomes ready with labels:
      | api=clusterapi,k8s-app=controller |
    And I wait for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | <%= pod.name %>    |
      | c             | machine-controller |
    Then the step should succeed
    And the output should match:
      | <Output> |
    """

    Examples:
      | re_type_field     | valid_value                | invalid_value         | no_value      | machineset_name  | Output                                                                   |
      | /machineType:.*/  | machineType: n1-standard-2 | machineType: invalid  | machineType:  | machineset-28778 | <machineset_name>-invalid.*ReconcileError                                | # @case_id OCP-28778
      | /vmSize:.*/       | vmSize: Standard_D2s_v3    | vmSize: invalid       | vmSize:       | machineset-28876 | <machineset_name>-invalid.*ReconcileError                                | # @case_id OCP-28876
      | /instanceType:.*/ | instanceType: m4.large     | instanceType: invalid | instanceType: | machineset-28875 | <machineset_name>-invalid.*ReconcileError                                | # @case_id OCP-28875
      | /diskGiB:.*/      | diskGiB: 120               | diskGiB: 0            | diskGiB:      | machineset-41039 | error getting disk spec                                                  | # @case_id OCP-41039
      | /instanceType:.*/ | instanceType: m4.large     | instanceType: invalid | instanceType: | machineset-41146 | Failed to set autoscaling from zero annotations, instance type unknown   | # @case_id OCP-41146
      | /vmSize:.*/       | vmSize: Standard_D2s_v3    | vmSize: invalid       | vmSize:       | machineset-41150 | Failed to set autoscaling from zero annotations, instance type unknown   | # @case_id OCP-41150
      | /machineType:.*/  | machineType: n1-standard-2 | machineType: invalid  | machineType:  | machineset-41151 | To fix this, manually populate machine annotations for your instance type| # @case_id OCP-41151

  # @author zhsun@redhat.com
  @admin
  @destructive
  Scenario Outline: Autoscaler will scale down the nodegroup that has Failed machine when maxNodeProvisionTime is reached
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario

    #Create an invalid machineset with replicas=0
    Given I pick a random machineset to scale
    Given I get project machineset named "<%= machine_set.name %>" as YAML
    And I save the output to file> <machineset_name>.yaml
    And I replace content in "<machineset_name>.yaml":
      | <%= machine_set.name %> | <machineset_name> |
      | /replicas.*/            | replicas: 0       |

    When I run the :create admin command with:
      | f | <machineset_name>.yaml |
    Then the step should succeed
    And admin ensures "<machineset_name>" machineset is deleted after scenario

    Given as admin I successfully merge patch resource "machineset/<machineset_name>" with:
      | {"spec":{"template":{"spec":{"providerSpec":{"value":{<invalid_value>}}}}}} |

    # Create clusterautoscaler
    Given I use the "openshift-machine-api" project
    Given I obtain test data file "cloud/cluster-autoscaler.yml"
    When I run the :create admin command with:
      | f | cluster-autoscaler.yml |
    Then the step should succeed
    And admin ensures "default" clusterautoscaler is deleted after scenario
    And 1 pod becomes ready with labels:
      | cluster-autoscaler=default,k8s-app=cluster-autoscaler |

    # Create machineautoscaler
    Given I obtain test data file "cloud/machine-autoscaler.yml"
    When I run oc create over "machine-autoscaler.yml" replacing paths:
      | ["metadata"]["name"]               | maotest           |
      | ["spec"]["minReplicas"]            | 0                 |
      | ["spec"]["maxReplicas"]            | 2                 |
      | ["spec"]["scaleTargetRef"]["name"] | <machineset_name> |
    Then the step should succeed
    And admin ensures "maotest" machineautoscaler is deleted after scenario

    # Create workload
    Given I obtain test data file "cloud/autoscaler-auto-tmpl.yml"
    When I run the :create admin command with:
      | f | autoscaler-auto-tmpl.yml |
    Then the step should succeed
    And admin ensures "workload" job is deleted after scenario

    # Check new created machine has 'Failed' phase
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given I store the last provisioned machine in the :failed_machine clipboard
    Then the expression should be true> machine(cb.failed_machine).phase(cached: false) == "Failed"
    """
    # Check cluster auto scales down and node group will be marked as backoff
    And I wait up to 1000 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set("<machineset_name>").desired_replicas(cached: false) == 0
    When I run the :logs admin command with:
      | resource_name | <%= pod.name %> |
    Then the step should succeed
    And the output should match:
      | Scale-up timed out for node group .*openshift-machine-api/<machineset_name>             |
      | Disabling scale-up for node group .*openshift-machine-api/<machineset_name>             |
      | Removing unregistered node failed-machine-openshift-machine-api_                        |
      | Node group .*openshift-machine-api/<machineset_name> is not ready for scaleup - backoff |
    """
    # Node group could be re-enabled scale up
    And I wait up to 360 seconds for the steps to pass:
    """
    When I run the :logs admin command with:
      | resource_name | <%= pod.name %> |
    Then the step should succeed
    And the output should contain:
      | Final scale-up plan |
    """

    Examples:
      | invalid_value               | machineset_name        |
      | "instanceType": "invalid"   | machineset-clone-30377 | # @case_id OCP-30377
      | "machineType": "invalid"    | machineset-clone-37854 | # @case_id OCP-37854
      | "vmSize": "invalid"         | machineset-clone-37855 | # @case_id OCP-37855
      | "flavor": "invalid"         | machineset-clone-37856 | # @case_id OCP-37856
      | "folder": "/dc1/vm/invalid" | machineset-clone-37857 | # @case_id OCP-37857

  # @author zhsun@redhat.com
  # @case_id OCP-30387
  @admin
  @destructive
  Scenario: Autoscaler should work even machinesets miss replicas
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user
    And I use the "openshift-machine-api" project
    And admin ensures machine number is restored after scenario

    And I pick a random machineset to scale
    When I get project machineset named "<%= machine_set.name %>" as YAML
    And I save the output to file> machineset.yaml

    # Create a machineset with replicas is nil
    And I replace content in "machineset.yaml":
      | <%= machine_set.name %> | machineset-clone-30387 |
      | /replicas.*/            |                        |
    When I run the :create admin command with:
      | f | machineset.yaml |
    Then the step should succeed
    And admin ensures "machineset-clone-30387" machineset is deleted after scenario

    # Create clusterautoscaler
    Given I obtain test data file "cloud/cluster-autoscaler.yml"
    When I run the :create admin command with:
      | f | cluster-autoscaler.yml |
    Then the step should succeed
    And admin ensures "default" clusterautoscaler is deleted after scenario
    And 1 pod becomes ready with labels:
      | cluster-autoscaler=default,k8s-app=cluster-autoscaler |

    # Create machineautoscaler
    Given I obtain test data file "cloud/machine-autoscaler.yml"
    When I run oc create over "machine-autoscaler.yml" replacing paths:
      | ["metadata"]["name"]               | maotest                |
      | ["spec"]["minReplicas"]            | 0                      |
      | ["spec"]["maxReplicas"]            | 2                      |
      | ["spec"]["scaleTargetRef"]["name"] | machineset-clone-30387 |
    Then the step should succeed
    And admin ensures "maotest" machineautoscaler is deleted after scenario

    # Create workload
    Given I obtain test data file "cloud/autoscaler-auto-tmpl.yml"
    When I run the :create admin command with:
      | f | autoscaler-auto-tmpl.yml |
    Then the step should succeed
    And admin ensures "workload" job is deleted after scenario

    # Verify machineset has scaled
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set.desired_replicas(cached: false) == 2
    """
    Then the machineset should have expected number of running machines

    # Delete workload
    Given admin ensures "workload" job is deleted from the "openshift-machine-api" project

    # Check cluster auto scales down
    And I wait up to 600 seconds for the steps to pass:
    """
    Then the expression should be true> machine_set.desired_replicas(cached: false) == 0
    """
    Then the machineset should have expected number of running machines

