Feature: Cluster Autoscaler Tests

  # @author zhsun@redhat.com
  # @case_id OCP-20108
  @admin
  @destructive
  Scenario: Cluster-autoscaler should balance similiar node groups between zones
    Given I have an IPI deployment
    And I switch to cluster admin pseudo user

    Given I store the number of machines in the :num_to_restore clipboard
    And admin ensures node number is restored to "<%= cb.num_to_restore %>" after scenario

    Given I clone a machineset named "machineset-clone-20108"
    Given I clone a machineset named "machineset-clone-20108-2"
    
    # Create clusterautoscaler
    Given I use the "openshift-machine-api" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cloud/cluster-autoscaler.yml" replacing paths:
      | ["spec"]["balanceSimilarNodeGroups"] | true |
    Then the step should succeed
    And admin ensures "default" clusterautoscaler is deleted after scenario
    And 1 pods become ready with labels:
      | cluster-autoscaler=default,k8s-app=cluster-autoscaler |

    # Create machineautoscaler
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cloud/machine-autoscaler.yml" replacing paths:
      | ["metadata"]["name"]               | maotest                |
      | ["spec"]["minReplicas"]            | 1                      |
      | ["spec"]["maxReplicas"]            | 3                      |
      | ["spec"]["scaleTargetRef"]["name"] | machineset-clone-20108 |
    Then the step should succeed
    And admin ensures "maotest" machineautoscaler is deleted after scenario
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cloud/machine-autoscaler.yml" replacing paths:
      | ["metadata"]["name"]               | maotest1                 |
      | ["spec"]["minReplicas"]            | 1                        |
      | ["spec"]["maxReplicas"]            | 3                        |
      | ["spec"]["scaleTargetRef"]["name"] | machineset-clone-20108-2 |
    Then the step should succeed
    And admin ensures "maotest1" machineautoscaler is deleted after scenario

    # Create workload
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cloud/autoscaler-auto-tmpl.yml |
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

    Given I store the number of machines in the :num_to_restore clipboard
    And admin ensures node number is restored to "<%= cb.num_to_restore %>" after scenario

    Given I clone a machineset named "machineset-clone-24715"
    
    # Create clusterautoscaler
    Given I use the "openshift-machine-api" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cloud/cluster-autoscaler.yml" replacing paths:
      | ["spec"]["skipNodesWithLocalStorage"] | true |
    Then the step should succeed
    And admin ensures "default" clusterautoscaler is deleted after scenario
    And 1 pods become ready with labels:
      | cluster-autoscaler=default,k8s-app=cluster-autoscaler |

    # Create machineautoscaler
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cloud/machine-autoscaler.yml" replacing paths:
      | ["metadata"]["name"]               | maotest                |
      | ["spec"]["minReplicas"]            | 1                      |
      | ["spec"]["maxReplicas"]            | 3                      |
      | ["spec"]["scaleTargetRef"]["name"] | machineset-clone-24715 |
    Then the step should succeed
    And admin ensures "maotest" machineautoscaler is deleted after scenario

    # Create workload
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cloud/autoscaler-auto-tmpl.yml |
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
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cloud/local-storage-pod.yml" replacing paths:
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

    Given I store the number of machines in the :num_to_restore clipboard
    And admin ensures node number is restored to "<%= cb.num_to_restore %>" after scenario

    Given I clone a machineset named "machineset-clone-20787"
    
    # Create clusterautoscaler
    Given I use the "openshift-machine-api" project
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cloud/cluster-autoscaler.yml |
    Then the step should succeed
    And admin ensures "default" clusterautoscaler is deleted after scenario
    And 1 pods become ready with labels:
      | cluster-autoscaler=default,k8s-app=cluster-autoscaler |

    # Create machineautoscaler
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cloud/machine-autoscaler.yml" replacing paths:
      | ["metadata"]["name"]               | maotest                |
      | ["spec"]["minReplicas"]            | 1                      |
      | ["spec"]["maxReplicas"]            | 3                      |
      | ["spec"]["scaleTargetRef"]["name"] | machineset-clone-20787 |
    Then the step should succeed
    And admin ensures "maotest" machineautoscaler is deleted after scenario

    # Create workload
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/cloud/autoscaler-auto-tmpl.yml |
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

