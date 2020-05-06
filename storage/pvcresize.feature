Feature: PVC resizing Test

  # @author piqin@redhat.com
  # @case_id OCP-19331
  @admin
  Scenario: Resize PVC online and with data on it
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "glusterprovisioner" with:
      | ["allowVolumeExpansion"]        | true                     |

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pod.json" replacing paths:
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

  # @author piqin@redhat.com
  # @case_id OCP-16614
  @admin
  Scenario: Resize PVC offline and no data on it
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "glusterprovisioner" with:
      | ["allowVolumeExpansion"]        | true                     |

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
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

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>   |
    Then the step should succeed
    And the pod named "mypod-<%= project.name %>" becomes ready

  # @author piqin@redhat.com
  # @case_id OCP-16615
  @admin
  Scenario: Resize PVC offline and with data on it
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "glusterprovisioner" with:
      | ["allowVolumeExpansion"]        | true                     |

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pod.json" replacing paths:
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

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pod.json" replacing paths:
      | ["metadata"]["name"]                                         | mypod-1-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>     |
    Then the step should succeed
    And the pod named "mypod-1-<%= project.name %>" becomes ready

    When I execute on the pod:
      | /mnt/gluster/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

  # @author piqin@redhat.com
  # @case_id OCP-19332
  @admin
  @destructive
  Scenario: Resize PVC when glusterfs outage
    Given I have a StorageClass named "glusterprovisioner"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "glusterprovisioner" with volume expansion enabled

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
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
  # @case_id OCP-16619
  @admin
  Scenario: Resize PVC to a size less than the current size
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
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

  # @author piqin@redhat.com
  # @case_id OCP-16620
  @admin
  Scenario: Resize PVC to a size is the same with current size
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
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

  # @author piqin@redhat.com
  # @case_id OCP-16621
  @admin
  Scenario: Modify PVC other field than Spec.Resources.Requests.storage
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
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

  # @author piqin@redhat.com
  # @case_id OCP-16634
  @admin
  Scenario: Resize PVC when it's PV was deleted
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
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

  # @author chaoyang@redhat.com
  @admin
  Scenario Outline: Check volumes could resize
    Given I have a StorageClass named "<sc_name>"
    And I have a project
    And admin clones storage class "sc-<%= project.name %>" from "<sc_name>" with volume expansion enabled

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>   |
    Then the step should succeed
    And the pod named "mypod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | cp | /hello | /mnt/ocp_pv |
    Then the step should succeed

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}}  |
    Then the step should succeed
    And I wait up to 800 seconds for the steps to pass:
    """
    Given the expression should be true> pv(pvc("pvc-<%= project.name %>").volume_name).capacity_raw(cached: false) == "2Gi"
    """

    # re-create the pod
    Given I ensures "mypod-<%= project.name %>" pod is deleted

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %>   |
    And the pod named "mypod-<%= project.name %>" status becomes :running

    And the expression should be true> pvc.capacity(cached: false) == "2Gi"

    When I execute on the pod:
      | /mnt/ocp_pv/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"

    When I execute on the pod:
      | /bin/dd | if=/dev/zero | of=/mnt/ocp_pv/1 | bs=1M | count=1500 |
    Then the step should succeed
    And the output should not contain:
      | No space left on device |

    Examples:
      | sc_name  |
      | gp2      |  # @case_id OCP-17487
      | standard |  # @case_id OCP-18395


  # @author jhou@redhat.com
  # @case_id OCP-16655
  @admin
  Scenario: Resize PVC will fail when PVC size exceed namespace storage quota
    # Admin could create ResourceQuata
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/quota-pvc-storage.yaml" replacing paths:
      | ["spec"]["hard"]["persistentvolumeclaims"] | 5   |
      | ["spec"]["hard"]["requests.storage"]       | 1Gi |
    Then the step should succeed

    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod                   |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/pvcresize          |
    Then the step should succeed
    And the pod named "mypod" becomes ready

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}}  |
    Then the step should fail
    And the output should contain:
      | exceeded quota |

  # @author jhou@redhat.com
  # @case_id OCP-16657
  @admin
  Scenario: Resize PVC will fail when PVC size exceed storageclass storage quota
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/quota_for_storageclass.yml" replacing paths:
      | ["spec"]["hard"]["sc-<%= project.name %>.storageclass.storage.k8s.io/requests.storage"]       | 1Gi |
      | ["spec"]["hard"]["sc-<%= project.name %>.storageclass.storage.k8s.io/persistentvolumeclaims"] | 1   |
    Then the step should succeed

    Given admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
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
    And the output should contain:
      | exceeded quota |

  # @author jhou@redhat.com
  # @case_id OCP-16618
  @admin
  Scenario: Resize a static PVC
    Given I have a project

    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pv-retain-rwo.json" where:
      | ["metadata"]["name"] | gluster-<%= project.name %> |
    Then the step should succeed
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/claim-rwo.json" replacing paths:
      | ["metadata"]["name"] | glusterc |
    Then the step should succeed
    And the PV becomes :bound

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | glusterc                                               |
      | p             | {"spec":{"resources":{"requests":{"storage":"20Gi"}}}} |
    Then the step should fail
    And the output should contain "storageclass that provisions the pvc must support resize"

  # @author jhou@redhat.com
  # @case_id OCP-16622
  @admin
  Scenario: Resize a pending PVC
    Given I have a project

    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/claim-rwo.json" replacing paths:
      | ["metadata"]["name"] | glusterc |
    Then the step should succeed

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | glusterc                                               |
      | p             | {"spec":{"resources":{"requests":{"storage":"20Gi"}}}} |
    Then the step should fail
    And the output should contain:
      | immutable |
      | bound     |

  # @author piqin@redhat.com
  # @case_id OCP-16623
  @admin
  Scenario: Resize PVC to a very large size
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    When I run the :patch client command with:
      | resource      | pvc                                                              |
      | resource_name | pvc-<%= project.name %>                                          |
      | p             | {"spec":{"resources":{"requests":{"storage":"100000000000Gi"}}}} |
    Then the step should succeed
    When I get project events
    Then the output should match:
      | VolumeSizeExceedsAvailableQuota |

  # @author jhou@redhat.com
  # @case_id OCP-16633
  @admin
  @destructive
  Scenario: Resize PVC should be successful after node service restart
    Given I have a StorageClass named "glusterprovisioner"
    And admin creates a project with a random schedulable node selector

    Given admin clones storage class "sc-<%= project.name %>" from "glusterprovisioner" with volume expansion enabled
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds

    # Resize PVC
    Given I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}}  |
    And I use the "<%= node.name %>" node
    And the node service is restarted on the host
    And I wait up to 120 seconds for the steps to pass:
    """
    Given the expression should be true> pv(pvc.volume_name).capacity_raw(cached: false) == "2Gi"
    """

  # @author piqin@redhat.com
  # @case_id OCP-16654
  @admin
  Scenario: namespace quota can handle pvc resize
    # Admin could create ResourceQuata
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/quota-pvc-storage.yaml" replacing paths:
      | ["metadata"]["name"]                       | project-quota |
      | ["spec"]["hard"]["persistentvolumeclaims"] | 5             |
      | ["spec"]["hard"]["requests.storage"]       | 10Gi          |
    Then the step should succeed

    Given I run the steps 3 times:
    """
    Given I ensure "pvc-<%= project.name %>" pvc is deleted
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds
    And the expression should be true> resource_quota("project-quota").total_used(cached: false).storage_requests_raw == "1Gi"

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}}  |
    Then the step should succeed
    And the expression should be true> resource_quota("project-quota").total_used(cached: false).storage_requests_raw == "2Gi"
    """

  # @author piqin@redhat.com
  # @case_id OCP-16656
  @admin
  Scenario: StorageClass quota can handle pvc resize
    # Admin could create ResourceQuata
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/quota_for_storageclass.yml" replacing paths:
      | ["metadata"]["name"]                                                                         | sc-quota |
      | ["spec"]["hard"]["sc-<%= project.name%>.storageclass.storage.k8s.io/persistentvolumeclaims"] | 5        |
      | ["spec"]["hard"]["sc-<%= project.name%>.storageclass.storage.k8s.io/requests.storage"]       | 10Gi     |
      | ["spec"]["hard"]["persistentvolumeclaims"]                                                   | 10       |
      | ["spec"]["hard"]["requests.storage"]                                                         | 20Gi     |
    Then the step should succeed

    Given I run the steps 3 times:
    """
    Given I ensure "pvc-<%= project.name %>" pvc is deleted
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds
    And the expression should be true> resource_quota("sc-quota").sc_used(name: "sc-<%= project.name %>", cached: false).storage_requests_raw == "1Gi"

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}}  |
    Then the step should succeed
    And the expression should be true> resource_quota("sc-quota").sc_used(name: "sc-<%= project.name %>", cached: false).storage_requests_raw == "2Gi"
    """

  # @author piqin@redhat.com
  # @case_id OCP-16659
  @admin
  Scenario: namespace quota can handle multi times pvc resize
    # Admin could create ResourceQuata
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/quota-pvc-storage.yaml" replacing paths:
      | ["metadata"]["name"]                       | project-quota |
      | ["spec"]["hard"]["persistentvolumeclaims"] | 5             |
      | ["spec"]["hard"]["requests.storage"]       | 10Gi          |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds
    And the expression should be true> resource_quota("project-quota").total_used(cached: false).storage_requests_raw == "1Gi"

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}}  |
    Then the step should succeed
    And the expression should be true> resource_quota("project-quota").total_used(cached: false).storage_requests_raw == "2Gi"

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"5Gi"}}}}  |
    Then the step should succeed
    And the expression should be true> resource_quota("project-quota").total_used(cached: false).storage_requests_raw == "5Gi"

  # @author piqin@redhat.com
  # @case_id OCP-16676
  @admin
  Scenario: namespace quota can handle pvc resize failed
    # Admin could create ResourceQuata
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/quota-pvc-storage.yaml" replacing paths:
      | ["metadata"]["name"]                       | project-quota |
      | ["spec"]["hard"]["persistentvolumeclaims"] | 5             |
      | ["spec"]["hard"]["requests.storage"]       | 10Gi          |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 240 seconds
    And the expression should be true> resource_quota("project-quota").total_used(cached: false).storage_requests_raw == "2Gi"

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"1Gi"}}}}  |
    Then the step should fail
    And the expression should be true> resource_quota("project-quota").total_used(cached: false).storage_requests_raw == "2Gi"

    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"spec":{"resources":{"requests":{"storage":"15Gi"}}}}  |
    Then the step should fail
    And the expression should be true> resource_quota("project-quota").total_used(cached: false).storage_requests_raw == "2Gi"


  # @author piqin@redhat.com
  # @case_id OCP-16627
  @admin
  Scenario: Resize many PVCs in the same time
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled

    And I run the steps 5 times:
    """
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-#{cb.i}            |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                    |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %> |
    Then the step should succeed
    """
    And I run the steps 5 times:
    """
    And the "pvc-#{cb.i}" PVC becomes :bound within 240 seconds
    """

    When I run the :patch client command with:
      | resource      | pvc                                                   |
      | resource_name | pvc-1                                                 |
      | resource_name | pvc-2                                                 |
      | resource_name | pvc-3                                                 |
      | resource_name | pvc-4                                                 |
      | resource_name | pvc-5                                                 |
      | p             | {"spec":{"resources":{"requests":{"storage":"3Gi"}}}} |
    Then the step should succeed

    Given 30 seconds have passed
    And I run the steps 5 times:
    """
    And the expression should be true> pv(pvc("pvc-#{cb.i}").volume_name).capacity_raw(cached: false) == "3Gi"
    """

    When I run the :patch client command with:
      | resource      | pvc                                                   |
      | resource_name | pvc-1                                                 |
      | resource_name | pvc-2                                                 |
      | resource_name | pvc-3                                                 |
      | resource_name | pvc-4                                                 |
      | resource_name | pvc-5                                                 |
      | p             | {"spec":{"resources":{"requests":{"storage":"5Gi"}}}} |
    Then the step should succeed

    Given 30 seconds have passed
    And I run the steps 5 times:
    """
    And the expression should be true> pv(pvc("pvc-#{cb.i}").volume_name).capacity_raw(cached: false) == "5Gi"
    """

  # @author piqin@redhat.com
  # @case_id OCP-19333
  @admin
  Scenario: Resize PVC using StorageClass with allowVolumeExpansion set to false
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["allowVolumeExpansion"] | false     |
      | ["volumeBindingMode"]    | Immediate |

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound

    When I run the :patch client command with:
      | resource      | pvc                                                   |
      | resource_name | mypvc                                                 |
      | p             | {"spec":{"resources":{"requests":{"storage":"2Gi"}}}} |
    Then the step should fail
    And the output should contain "storageclass that provisions the pvc must support resize"

  # @author piqin@redhat.com
  # @case_id OCP-16630
  @admin
  @destructive
  Scenario: After master restart PVCs resizing can be finished as well
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with volume expansion enabled

    And I run the steps 5 times:
    """
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-#{cb.i}            |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                    |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %> |
    Then the step should succeed
    """
    And I run the steps 5 times:
    """
    And the "pvc-#{cb.i}" PVC becomes :bound within 240 seconds
    """

    When I run the :patch client command with:
      | resource      | pvc                                                   |
      | resource_name | pvc-1                                                 |
      | resource_name | pvc-2                                                 |
      | resource_name | pvc-3                                                 |
      | resource_name | pvc-4                                                 |
      | resource_name | pvc-5                                                 |
      | p             | {"spec":{"resources":{"requests":{"storage":"3Gi"}}}} |
    Then the step should succeed

    Given the master service is restarted on all master nodes
    And 30 seconds have passed

    When I run the steps 5 times:
    """
    And the expression should be true> pv(pvc("pvc-#{cb.i}").volume_name).capacity_raw(cached: false) == "3Gi"
    """
