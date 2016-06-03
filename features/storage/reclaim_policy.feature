Feature: Persistent Volume reclaim policy tests
  # @author jhou@redhat.com
  # @case_id 488979
  @admin
  Scenario: Recycle reclaim policy for persistent volumes
    # Preparations
    Given I have a project
    And I have a NFS service in the project
    # Creating PV and PVC
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pv.json" where:
      | ["metadata"]["name"]      | pv-nfs-<%= project.name %>       |
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
      | ["spec"]["persistentVolumeReclaimPolicy"]| Recycle           |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/pvc.json" replacing paths:
      | ["metadata"]["name"]   | pvc-nfs-<%= project.name %> |
      | ["spec"]["volumeName"] | pv-nfs-<%= project.name %>  |
    Then the step should succeed
    And the PV becomes :bound
    And the "pvc-nfs-<%= project.name %>" PVC becomes :bound

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/auto/web-pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-nfs-<%= project.name %>   |
      | ["metadata"]["name"]                                         | pod488979-<%= project.name %> |
    Then the step should succeed
    Given the pod named "pod488979-<%= project.name %>" becomes ready
    When I run the :delete client command with:
      | object_type       | pod                           |
      | object_name_or_id | pod488979-<%= project.name %> |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | pvc                         |
      | object_name_or_id | pvc-nfs-<%= project.name %> |
    Then the step should succeed
    And the PV becomes :available within 300 seconds
