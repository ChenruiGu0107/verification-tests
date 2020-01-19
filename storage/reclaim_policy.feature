Feature: Persistent Volume reclaim policy tests
  # @author jhou@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-10638
  @admin
  Scenario: Recycle reclaim policy for persistent volumes
    Given I have a project
    And I have a NFS service in the project
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/nfs/auto/pv.json" where:
      | ["metadata"]["name"]                      | pv-<%= project.name %>           |
      | ["spec"]["storageClassName"]              | sc-<%= project.name %>           |
      | ["spec"]["nfs"]["server"]                 | <%= service("nfs-service").ip %> |
      | ["spec"]["persistentVolumeReclaimPolicy"] | Recycle                          |
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["volumeName"]       | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
      | ["metadata"]["name"]                                         | mypod |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    Given I ensure "mypod" pod is deleted
    And I ensure "mypvc" pvc is deleted
    And the PV becomes :available within 300 seconds


  # @author lxia@redhat.com
  # @case_id OCP-12836
  @admin
  Scenario: Change dynamic provisioned PV's reclaim policy
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/storageClass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | kubernetes.io/gce-pd   |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Delete"
    When I run the :patch admin command with:
      | resource      | pv                                                  |
      | resource_name | <%= pvc.volume_name %>                  |
      | p             | {"spec":{"persistentVolumeReclaimPolicy":"Retain"}} |
    Then the step should succeed

    Given I ensure "pvc-<%= project.name %>" pvc is deleted
    Given I switch to cluster admin pseudo user
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | pv                                 |
      | resource_name | <%= pvc.volume_name %> |
    Then the step should succeed
    And the output should contain:
      | Retain   |
      | Released |
    And the output should not contain:
      | Delete |
    """
