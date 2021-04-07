Feature: FibreChannel specific scenarios on dedicated servers
  # @author lxia@redhat.com
  # @case_id OCP-12664
  @admin
  Scenario: FibreChannel volume plugin with ROX access mode and Retain policy
    Given I have a project
    Given I obtain test data file "storage/fc/pv-retain-rwx.json"
    When admin creates a PV from "pv-retain-rwx.json" where:
      | ["metadata"]["name"]       | pv-<%= project.name %> |
      | ["spec"]["accessModes"][0] | ReadOnlyMany           |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a manual pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]       | mypvc        |
      | ["spec"]["accessModes"][0] | ReadOnlyMany |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
      | ["metadata"]["name"]                                         | mypod |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | mountpoint | -d | /mnt/ocp_pv |
    Then the step should succeed
    When I execute on the pod:
      | cp | /proc/cpuinfo | /mnt/ocp_pv/ |
    Then the step should succeed

  # @author chaoyang@redhat.com
  # @case_id OCP-15499
  # This test case depends on specific env which contains nodes with fibre channel volume
  @admin
  @destructive
  Scenario: Drain a node that is filled with fibre channel volume mounts
    Given I have a project

    Given I obtain test data file "storage/fc/storageclass.yaml"
    When admin creates a StorageClass from "storageclass.yaml" where:
      | ["metadata"]["name"]  | sc-<%= project.name %> |
    Then the step should succeed

    Given I obtain test data file "storage/fc/pv1.yaml"
    And admin creates a PV from "pv1.yaml" where:
      | ["metadata"]["name"]         | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> | 
    Then the step should succeed

    Given I obtain test data file "storage/misc/pvc-with-storageClassName.json"
    When I create a dynamic pvc from "pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
      | ["spec"]["volumeName"]       | pv-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

    Given I obtain test data file "storage/fc/dc1.yaml"
    When I run oc create over "dc1.yaml" replacing paths:
      | ["spec"]["template"]["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> | 
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=hello-storage | 
    
    #Saved the node which pod scheduled to
    And evaluation of `pod.node_name` is stored in the :node_beforedrain clipboard

    #1.mpathconf should be enabled before this testcase.This is executed in the postaction_hp_workers.sh
    Given I use the "<%= cb.node_beforedrain %>" node
    And I run commands on the host:
      | multipath -ll |
    Then the output should contain:
      | dm-0 |
      | dm-1 |
    Then the step should succeed

    Given node schedulable status should be restored after scenario
    When I run the :oadm_drain admin command with:
      | node_name    | <%= cb.node_beforedrain %> |
      | pod-selector | app=hello-storage         | 
      | force        | true                      |
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=hello-storage |

    Given I use the "<%= cb.node_beforedrain %>" node
    When I run commands on the host:
      | dmesg |
    Then the output should not contain:
      | I/O error |	
    Then the step should succeed
    When I run commands on the host:
      | multipath -ll |  
    Then the output should contain 1 times:
      | dm | 
    Then the step should succeed

