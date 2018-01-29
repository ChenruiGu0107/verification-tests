Feature: PVC resizing Test

  # @author piqin@redhat.com
  # @case_id OCP-16613
  @admin
  Scenario: Resize PVC online and with data
    Given I check feature gate "ExpandPersistentVolumes" with admission "PersistentVolumeClaimResize" is enabled

    Given I have a StorageClass named "glusterprovisioner"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "glusterprovisioner" with volume expansion enabled

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>   |
    Then the step should succeed
    And the pod named "mypod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | cp | /hello | /mnt/gluster |
    Then the step should succeed

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}}  |
    Then the step should succeed
    And I wait up to 500 seconds for the steps to pass:
    """
    Given the expression should be true> pvc("pvc-#{project.name}").capacity(cached: false) == "2Gi"
    """

    When I execute on the pod:
      | /mnt/gluster/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"
    When I execute on the pod:
      | /bin/dd | if=/dev/zero | of=/mnt/gluster/1 | bs=1M | count=1500 |
    Then the step should succeed
    And the output should not contain:
      | No space left on device |


  # @author piqin@redhat.com
  # @case_id OCP-16614
  @admin
  Scenario: Resize PVC offline and no data on it
    Given I check feature gate "ExpandPersistentVolumes" with admission "PersistentVolumeClaimResize" is enabled

    Given I have a StorageClass named "glusterprovisioner"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "glusterprovisioner" with volume expansion enabled

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}}  |
    Then the step should succeed
    And I wait up to 500 seconds for the steps to pass:
    """
    Given the expression should be true> pvc("pvc-#{project.name}").capacity(cached: false) == "2Gi"
    """

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>   |
    Then the step should succeed
    And the pod named "mypod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | /bin/dd | if=/dev/zero | of=/mnt/gluster/1 | bs=1M | count=1500 |
    Then the step should succeed
    And the output should not contain:
      | No space left on device |


  # @author piqin@redhat.com
  # @case_id OCP-16615
  @admin
  Scenario: Resize PVC offline and with data on it
    Given I check feature gate "ExpandPersistentVolumes" with admission "PersistentVolumeClaimResize" is enabled

    Given I have a StorageClass named "glusterprovisioner"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "glusterprovisioner" with volume expansion enabled

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>   |
    Then the step should succeed
    And the pod named "mypod-<%= project.name %>" becomes ready

    When I execute on the pod:
      | cp | /hello | /mnt/gluster |
    Then the step should succeed
    And I ensure "mypod-<%= project.name %>" pod is deleted

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}}  |
    Then the step should succeed
    And I wait up to 500 seconds for the steps to pass:
    """
    Given the expression should be true> pvc("pvc-#{project.name}").capacity(cached: false) == "2Gi"
    """

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod-1-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>     |
    Then the step should succeed
    And the pod named "mypod-1-<%= project.name %>" becomes ready

    When I execute on the pod:
      | /mnt/gluster/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"
    When I execute on the pod:
      | /bin/dd | if=/dev/zero | of=/mnt/gluster/1 | bs=1M | count=1500 |
    Then the step should succeed
    And the output should not contain:
      | No space left on device |


  # @author piqin@redhat.com
  # @case_id OCP-16616
  @admin
  @destructive
  Scenario: Resize PVC when glusterfs outage
    Given I check feature gate "ExpandPersistentVolumes" with admission "PersistentVolumeClaimResize" is enabled
    And I have a StorageClass named "glusterprovisioner"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "glusterprovisioner" with volume expansion enabled

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When admin recreate storage class "sc-<%= project.name %>" with:
      | ["parameters"]["resturl"] | http://error.address.com |
    Then the step should succeed

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}}  |
    Then the step should succeed
    And I wait up to 500 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc                     |
      | name     | pvc-<%= project.name %> |
    Then the output should contain:
      | Error expanding volume |
    """

  # @author piqin@redhat.com
  @admin
  Scenario Outline: Resize PVC using StorageClass without allowVolumeExpansion enable
    Given I check feature gate "ExpandPersistentVolumes" with admission "PersistentVolumeClaimResize" is enabled
    And I have a StorageClass named "<sc_name>"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "<sc_name>" with volume expansion disabled

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}}  |
    Then the step should fail
    And the output should contain "storageclass that provisions the pvc must support resize"

    Examples:
      | volume_type | sc_name            |
      | glusterfs   | glusterprovisioner | # @case_id OCP-16617
      | cinder      | standard           | # @case_id OCP-18379

  # @author piqin@redhat.com
  @admin
  Scenario Outline: Resize PVC to a size less than the current size
    Given I check feature gate "ExpandPersistentVolumes" with admission "PersistentVolumeClaimResize" is enabled
    And I have a StorageClass named "<sc_name>"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "<sc_name>" with volume expansion enabled

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"1Gi"}}}}  |
    Then the step should fail
    And the output should contain "field can not be less than previous value"

    Examples:
      | volume_type | sc_name            |
      | glusterfs   | glusterprovisioner | # @case_id OCP-16619
      | cinder      | standard           | # @case_id OCP-18381

  # @author piqin@redhat.com
  @admin
  Scenario Outline: Resize PVC to a size is the same with current size
    Given I check feature gate "ExpandPersistentVolumes" with admission "PersistentVolumeClaimResize" is enabled
    And I have a StorageClass named "<sc_name>"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "<sc_name>" with volume expansion enabled

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When I run the :patch client command with:
      | resource      | pvc                                                   |
      | resource_name | pvc-<%= project.name %>                               |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}} |
    Then the step should fail
    And the output should contain "not patched"

    Examples:
      | volumetype | sc_name            |
      | glusterfs  | glusterprovisioner | # @case_id OCP-16620
      | cinder     | standard           | # @case_id OCP-18382

  # @author piqin@redhat.com
  @admin
  Scenario Outline: Modify PVC other field than Spec.Resources.Requests.storage
    Given I check feature gate "ExpandPersistentVolumes" with admission "PersistentVolumeClaimResize" is enabled
    And I have a StorageClass named "<sc_name>"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "<sc_name>" with volume expansion enabled

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When I run the :patch client command with:
      | resource      | pvc                                        |
      | resource_name | pvc-<%= project.name %>                    |
      | p             | {"spec":{"accessModes":["ReadWriteMany"]}} |
    Then the step should fail
    And the output should contain "is immutable"

    Examples:
      | volumetype | sc_name            |
      | glusterfs  | glusterprovisioner | # @case_id OCP-16621
      | cinder     | standard           | # @case_id OCP-18383

  # @author piqin@redhat.com
  @admin
  Scenario Outline: Resize PVC when it's PV was deleted
    Given I check feature gate "ExpandPersistentVolumes" with admission "PersistentVolumeClaimResize" is enabled
    And I have a StorageClass named "<sc_name>"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "<sc_name>" with volume expansion enabled

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds
    And admin ensures "<%= pvc.volume_name %>" pv is deleted

    When I run the :patch client command with:
      | resource      | pvc                                                   |
      | resource_name | pvc-<%= project.name %>                               |
      | p             | {"spec":{"resources":{"requests":{"storage":"3Gi"}}}} |
    Then the step should fail
    And the output should contain "except resources.requests for bound claims"

    Examples:
      | volumetype | sc_name            |
      | glusterfs  | glusterprovisioner | # @case_id OCP-16634
      | cinder     | standard           | # @case_id OCP-18395
