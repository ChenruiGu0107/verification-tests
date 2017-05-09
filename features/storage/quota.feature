Feature: ResourceQuata for storage
  # @author jhou@redhat.com
  # @case_id OCP-14173
  @admin
  Scenario: Requested storage can not exceed the namespace's storage quota
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project

    # Admin could create ResourceQuata
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/quota-pvc-storage.yaml" replacing paths:
      | ["spec"]["hard"]["persistentvolumeclaims"] | 5    |
      | ["spec"]["hard"]["requests.storage"]       | 12Gi |
    Then the step should succeed

    # Consume 9Gi storage in the namespace
    And I run the steps 3 times:
    """
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                    | pvc-#{ cb.i } |
      | ["metadata"]["annotations"]["volume.alpha.kubernetes.io/storage-class"] | foo           |
      | ["spec"]["resources"]["requests"]["storage"]                            | 3Gi           |
    Then the step should succeed
    And the "pvc-#{ cb.i }" PVC becomes :bound
    """

    # Try to exceed the 12Gi storage
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                    | pvc-<% project.name %> |
      | ["metadata"]["annotations"]["volume.alpha.kubernetes.io/storage-class"] | foo                    |
      | ["spec"]["resources"]["requests"]["storage"]                            | 4Gi                    |
    Then the step should fail
    And the output should contain:
      | exceeded quota                 |
      | requests.storage=4Gi           |
      | used: requests.storage=9Gi     |
      | limited: requests.storage=12Gi |

    # Try to exceed total number of PVCs
    And I run the steps 2 times:
    """
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                    | pvci-#{ cb.i } |
      | ["metadata"]["annotations"]["volume.alpha.kubernetes.io/storage-class"] | foo            |
      | ["spec"]["resources"]["requests"]["storage"]                            | 1Gi            |
    Then the step should succeed
    And the "pvc-#{ cb.i }" PVC becomes :bound
    """

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                    | pvc-<% project.name %> |
      | ["metadata"]["annotations"]["volume.alpha.kubernetes.io/storage-class"] | foo                    |
      | ["spec"]["resources"]["requests"]["storage"]                            | 1Gi                    |
    Then the step should fail
    And the output should contain:
      | exceeded quota                      |
      | requested: persistentvolumeclaims=1 |
      | used: persistentvolumeclaims=5      |
      | limited: persistentvolumeclaims=5   |
