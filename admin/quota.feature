Feature: Quota related scenarios

  # @author xiaocwan@redhat.com
  # @case_id OCP-9778
  @admin
  Scenario: when the deployment can not be created due to a quota limit will get event from original report
    Given I have a project
    Given I obtain test data file "quota/quota.yaml"
    When I run oc create as admin over "quota.yaml" replacing paths:
      | ["spec"]["hard"]["memory"] | 20Mi                |
      | ["metadata"]["namespace"]  | <%= project.name %> |
    Then the step should succeed

    Given I obtain test data file "deployment/dc-with-two-containers.yaml"
    When I run the :create client command with:
      | f |  dc-with-two-containers.yaml |
    Then the step should succeed
    And the output should match:
      | eployment.*onfig.*reated |

    When I get project pods
    Then the output should match:
      | No resources found |
    When I get project events
    Then the output should match:
      | ailed quota: quota: must specify cpu,memory |

  # @author xiaocwan@redhat.com
  # @case_id OCP-11475
  @admin
  Scenario: DeploymentConfig should not allow the specification(which exceed resource quota) of resource requirements
    Given I have a project
    Given I obtain test data file "quota/quota.yaml"
    Given I obtain test data file "quota/limits.yaml"
    When I run the :create admin command with:
      | f     | quota.yaml  |
      | f     | limits.yaml |
      | n     | <%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "deployment/deployment-with-resources.json"
    When I run the :create client command with:
      | f | deployment-with-resources.json |
    Then the step should succeed

    # update dc to be exceeded and triggered deployment
    Given I replace resource "dc" named "hooks":
      | cpu: 30m      | cpu:    1020m |
      | memory: 150Mi | memory: 760Mi |

    # trigger deployment manually according to the case step
    Given I wait until the status of deployment "hooks" becomes :complete
    When I run the :rollout_latest client command with:
      | resource | dc/hooks |
    Then the step should succeed
    When I get project pods
    Then the output should not contain:
      | hooks-2-deploy |

    When I run the :describe client command with:
      | resource | dc      |
      | name     | hooks   |
    Then the output should match:
      | pods "hooks-\\d+-deploy" is forbidden |
      | aximum memory usage.*is 750Mi.*limit is 796917760 |
      | aximum cpu usage.*is 500m.*limit is 1020m |

    When I get project events
    # here comes a bug which fail the last step - 1317783
    Then the output should match:
      | pods "hooks-\\d+-deploy" is forbidden |
      | aximum memory usage.*is 750Mi.*limit is 796917760 |
      | aximum cpu usage.*is 500m.*limit is 1020m |

  # @author xiaocwan@redhat.com
  # @case_id OCP-11881
  @admin
  Scenario: [origin_platformexp_372][origin_platformexp_334] Resource quota can be set for project
    Given I have a project
    Given I obtain test data file "quota/quota.yaml"
    When I run oc create as admin over "quota.yaml" replacing paths:
      | ["spec"]["hard"]["memory"] | 110Mi               |
      | namespace                  | <%= project.name %> |
    Then the step should succeed

    Given I obtain test data file "pods/hello-pod.json"
    When I run the :create client command with:
      | f | hello-pod.json |
    Then the step should fail
    And the output should match:
      | specify.*memory |

    Given I obtain test data file "quota/limits.yaml"
    When I run the :create admin command with:
      | f | limits.yaml |
      | n | <%= project.name %>                                                     |
    Then the step should succeed
    Given I obtain test data file "pods/hello-pod.json"
    When I run the :create client command with:
      | f | hello-pod.json |
    Then the step should succeed
    When I get project pod as YAML
    Then the output should match:
      | cpu:\\s*100m     |
      | memory:\\s*100Mi |
    When I run the :describe admin command with:
      | resource | quota               |
      | name     | quota               |
      | n        | <%= project.name %> |
    Then the output should match:
      | cpu\\s*100m      |
      | memory\\s*100Mi  |
    Given I obtain test data file "pods/hello-pod.json"
    When I run the :create client command with:
      | f | hello-pod.json |
    Then the step should fail
    And the output should match:
      | xceeded quota |
    When I run the :delete client command with:
      | object_type | pods |
      | all         |      |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :describe admin command with:
      | resource | quota               |
      | name     | quota               |
      | n        | <%= project.name %> |
    Then the output should not match:
      | cpu\\s*100m      |
      | memory\\s*100Mi  |
    """

  # @author xiaocwan@redhat.com
  # @case_id OCP-11111
  @admin
  Scenario: Buildconfig should support providing cpu and memory usage
    Given I have a project
    Given I obtain test data file "quota/quota.yaml"
    When I run the :create admin command with:
      | f     | quota.yaml  |
      | n     | <%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "quota/limits.yaml"
    When I run the :create admin command with:
      | f     | limits.yaml |
      | n     | <%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "quota/application-template-with-resources.json"
    When I run the :create client command with:
      | f | application-template-with-resources.json |
    And I run the :new_app client command with:
      | template | ruby-helloworld-sample-with-resources |
    Then the step should succeed
    And the output should match:
      | "ruby-sample-build"\\s+created |
    Given the pod named "database-1-deploy" becomes present
    And the pod named "ruby-sample-build-1-build" becomes present
    When I get project pod as YAML
    Then the output should match:
      |   cpu:\\s+120m     |
      |   memory:\\s+256Mi |
      |   cpu:\\s+120m     |
      |   memory:\\s+256Mi |
    When I run the :delete client command with:
      | object_type       | build               |
      | all               | |
    Then the step should succeed
    When I replace resource "bc" named "ruby-sample-build" saving edit to "ruby-sample-build2.yaml":
      | cpu: 120m          | cpu:    1020m       |
      | memory: 256Mi      | memory: 760Mi       |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I get project builds
    Then the step should succeed
    And the output should match:
      | ruby-sample-build-[23].*[Nn]ew.*[Cc]annotCreateBuildPod |
    """
    When I run the :describe client command with:
      | resource | build                |
    Then the output should match:
      | pods.*ruby-sample-build-[23].*forbidden |
      | aximum memory usage.*is 750Mi.*limit is 796917760 |
      | aximum cpu usage.*is 500m.*limit is 1020m |

  # @author chezhang@redhat.com
  # @case_id OCP-10912
  @admin
  Scenario: Admin can restrict the ability to use services.nodeports
    Given I have a project
    Given I obtain test data file "quota/quota-service.yaml"
    When I run the :create admin command with:
      | f | quota-service.yaml |
      | n | <%= project.name %>  |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+0\\s+5           |
      | services.nodeports\\s+0\\s+2 |
    Given I obtain test data file "quota/nodeport-svc1.json"
    When I run the :create client command with:
      | f | nodeport-svc1.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+1\\s+5           |
      | services.nodeports\\s+1\\s+2 |
    Given I obtain test data file "quota/nodeport-svc2.json"
    When I run the :create client command with:
      | f | nodeport-svc2.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+2\\s+5           |
      | services.nodeports\\s+2\\s+2 |
    Given I obtain test data file "quota/nodeport-svc3.json"
    When I run the :create client command with:
      | f | nodeport-svc3.json |
    Then the step should fail
    And the output should match:
      | xceeded quota: quota-service.*limited: services.nodeports=2 |
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+2\\s+5           |
      | services.nodeports\\s+2\\s+2 |
    When I run the :delete client command with:
      | object_type       | svc           |
      | object_name_or_id | nodeport-svc1 |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+1\\s+5           |
      | services.nodeports\\s+1\\s+2 |
    Given I obtain test data file "quota/nodeport-svc3.json"
    When I run the :create client command with:
      | f | nodeport-svc3.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+2\\s+5           |
      | services.nodeports\\s+2\\s+2 |

  # @author chezhang@redhat.com
  # @case_id OCP-11322
  @admin
  Scenario: Service with multi nodeports should be charged properly in the quota system
    Given I have a project
    Given I obtain test data file "quota/quota-service.yaml"
    When I run the :create admin command with:
      | f | quota-service.yaml |
      | n | <%= project.name %>  |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+0\\s+5           |
      | services.nodeports\\s+0\\s+2 |
    Given I obtain test data file "quota/ocp11322/multi-nodeports-svc.json"
    When I run the :create client command with:
      | f | multi-nodeports-svc.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+1\\s+5           |
      | services.nodeports\\s+2\\s+2 |
    When I run the :delete client command with:
      | object_type       | svc                 |
      | object_name_or_id | multi-nodeports-svc |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+0\\s+5           |
      | services.nodeports\\s+0\\s+2 |

  # @author chezhang@redhat.com
  # @case_id OCP-11616
  @admin
  Scenario: services.nodeports in quota system work well when change service type
    Given I have a project
    Given I obtain test data file "quota/quota-service.yaml"
    When I run the :create admin command with:
      | f | quota-service.yaml |
      | n | <%= project.name %>  |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+0\\s+5           |
      | services.nodeports\\s+0\\s+2 |
    Given I obtain test data file "quota/nodeport-svc1.json"
    When I run the :create client command with:
      | f | nodeport-svc1.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+1\\s+5           |
      | services.nodeports\\s+1\\s+2 |
    When I run the :patch client command with:
      | resource      | svc           |
      | resource_name | nodeport-svc1 |
      | type          | json          |
      | p             | [{"op": "remove", "path": "/spec/ports/0/nodePort"},{"op": "replace", "path": "/spec/type", "value": ClusterIP}] |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+1\\s+5           |
      | services.nodeports\\s+0\\s+2 |
    When I run the :patch client command with:
      | resource      | svc           |
      | resource_name | nodeport-svc1 |
      | type          | json          |
      | p             | [{"op": "replace", "path": "/spec/type", "value": NodePort}] |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | quota-service |
    Then the output should match:
      | services\\s+1\\s+5           |
      | services.nodeports\\s+1\\s+2 |

  # @author wmeng@redhat.com
  # @case_id OCP-10278
  Scenario: check QoS Tier BestEffort
    Given I have a project
    Given I obtain test data file "quota/pod-besteffort.yaml"
    When I run the :create client command with:
      | f | pod-besteffort.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod            |
      | name     | pod-besteffort |
    Then the step should succeed
    And the output should not match:
      | Burstable  |
      | Guaranteed |
    And the output should match:
      | BestEffort |

  # @author wmeng@redhat.com
  # @case_id OCP-10279
  Scenario: check QoS Tier Burstable
    Given I have a project
    Given I obtain test data file "quota/pod-burstable.yaml"
    When I run the :create client command with:
      | f | pod-burstable.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod            |
      | name     | pod-burstable |
    Then the step should succeed
    And the output should not match:
      | Guaranteed |
      | BestEffort |
    And the output should match:
      | Burstable  |

  # @author wmeng@redhat.com
  # @case_id OCP-10280
  Scenario: check QoS Tier Guaranteed
    Given I have a project
    Given I obtain test data file "quota/pod-guaranteed.yaml"
    When I run the :create client command with:
      | f | pod-guaranteed.yaml |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod            |
      | name     | pod-guaranteed |
    Then the step should succeed
    And the output should not match:
      | BestEffort |
      | Burstable  |
    And the output should match:
      | Guaranteed |

  # @author cryan@redhat.com
  # @case_id OCP-11187
  # @bug_id 1293836
  @admin
  Scenario: Resource quota value should not be fractional value
    Given I have a project
    Given I obtain test data file "quota/ocp11187/quota-1.yaml"
    When I run the :create admin command with:
      | f | quota-1.yaml |
      | n | <%= project.name %>                                                                            |
    Then the step should fail
    And the output should contain 6 times:
      | must be an integer |
    When I run the :describe admin command with:
      | resource | quota   |
      | name     | quota-1 |
    Then the step should fail
    And the output should contain "not found"
    Given I obtain test data file "quota/ocp11187/quota-2.yaml"
    When I run the :create admin command with:
      | f | quota-2.yaml |
      | n | <%= project.name %>                                                                            |
    Then the step should fail
    And the output should contain "quantities must match the regular expression"
    When I run the :describe admin command with:
      | resource | quota   |
      | name     | quota-2 |
    Then the step should fail
    And the output should contain "not found"

  # @author cryan@redhat.com
  # @case_id OCP-11528
  @admin
  Scenario: Resource quota value should not be negative
    Given I have a project
    Given I obtain test data file "quota/ocp11528/negquota.yaml"
    When I run the :create admin command with:
      | f | negquota.yaml |
      | n | <%= project.name %>                                                                             |
    Then the step should fail
    And the output should match 8 times:
      | must be greater than or equal to 0 |
    When I run the :describe client command with:
      | resource | quota    |
      | name     | negquota |
    Then the step should fail
    And the output should contain "not found"

  # @author qwang@redhat.com
  # @case_id OCP-12827
  @admin
  Scenario: Precious resources should be restrained if they are covered in quota and not configured on the master
    Given I have a project
    Given I obtain test data file "quota/quota-precious-resource.yaml"
    When I run the :create admin command with:
      | f | quota-precious-resource.yaml |
      | n | <%= project.name %>                                                                      |
    Then the step should succeed
    Given I obtain test data file "quota/pvc-storage-class.json"
    When I run the :create client command with:
      | f | pvc-storage-class.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota                   |
      | name     | quota-precious-resource |
    Then the output should match:
      | requests.storage\\s+2Gi\\s+50Gi                                 |
      | persistentvolumeclaims\\s+1\\s+10                               |
      | gold.storageclass.storage.k8s.io/requests.storage\\s+2Gi\\s+3Gi |
    Given I obtain test data file "quota/pvc-storage-class.json"
    When I create a dynamic pvc from "pvc-storage-class.json" replacing paths:
      | ["metadata"]["name"] | pvc-storage-class-1 |
    Then the step should fail
    And the output should contain:
      | exceeded quota: quota-precious-resource, requested: gold.storageclass.storage.k8s.io/requests.storage=2Gi, used: gold.storageclass.storage.k8s.io/requests.storage=2Gi, limited: gold.storageclass.storage.k8s.io/requests.storage=3Gi |
    When I run the :describe client command with:
      | resource | quota                   |
      | name     | quota-precious-resource |
    Then the output should match:
      | requests.storage\\s+2Gi\\s+50Gi                                 |
      | persistentvolumeclaims\\s+1\\s+10                               |
      | gold.storageclass.storage.k8s.io/requests.storage\\s+2Gi\\s+3Gi |


  # @author qwang@redhat.com
  # @case_id OCP-12826
  Scenario: Precious resources should be consumed without constraint in the absence of a covering quota if they are not configured on the master
    Given I have a project
    And evaluation of `%w{2Gi 20Gi 30Gi}` is stored in the :sizes clipboard
    And I run the steps 3 times:
    """
    Given I obtain test data file "quota/pvc-storage-class.json"
    When I create a dynamic pvc from "pvc-storage-class.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc#{cb.i}        |
      | ["spec"]["resources"]["requests"]["storage"] | #{cb.sizes[cb.i-1]} |
    Then the step should succeed
    """


  # @author qwang@redhat.com
  # @case_id OCP-11427
  @admin
  Scenario: Only PVC matches a suffix name of storage class can consume its corresponding specified quota
    Given I have a project
    When I run the :create_quota admin command with:
      | name | storage-quota                                                                                                     |
      | n    | <%= project.name %>                                                                                               |
      | hard | slow.storageclass.storage.k8s.io/requests.storage=20Gi,slow.storageclass.storage.k8s.io/persistentvolumeclaims=15 |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-storage-class |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi               |
      | ["spec"]["storageClassName"]                 | slow              |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | storage-quota |
    Then the step should succeed
    And the output should match:
      | slow.storageclass.storage.k8s.io/persistentvolumeclaims\\s+1\\s+15 |
      | slow.storageclass.storage.k8s.io/requests.storage\\s+2Gi\\s+20Gi   |
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-storage-class-iamnotslow |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                          |
      | ["spec"]["storageClassName"]                 | iamnotslow                   |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | storage-quota |
    Then the step should succeed
    And the output should match:
      | slow.storageclass.storage.k8s.io/persistentvolumeclaims\\s+1\\s+15 |
      | slow.storageclass.storage.k8s.io/requests.storage\\s+2Gi\\s+20Gi   |
    Given I ensure "pvc-storage-class" pvc is deleted
    When I run the :describe client command with:
      | resource | quota         |
      | name     | storage-quota |
    Then the step should succeed
    And the output should match:
      | slow.storageclass.storage.k8s.io/persistentvolumeclaims\\s+0\\s+15 |
      | slow.storageclass.storage.k8s.io/requests.storage\\s+0\\s+20Gi     |
    Given I ensure "pvc-storage-class-iamnotslow" pvc is deleted
    When I run the :describe client command with:
      | resource | quota         |
      | name     | storage-quota |
    Then the step should succeed
    And the output should match:
      | slow.storageclass.storage.k8s.io/persistentvolumeclaims\\s+0\\s+15 |
      | slow.storageclass.storage.k8s.io/requests.storage\\s+0\\s+20Gi     |


  # @author qwang@redhat.com
  # @case_id OCP-11056
  @admin
  Scenario: Multi-quota ability to scope PVC quotas by Storage Class
    Given I have a project
    When I run the :create_quota admin command with:
      | name | my-quota            |
      | n    | <%= project.name %> |
      | hard | slow.storageclass.storage.k8s.io/requests.storage=20Gi,slow.storageclass.storage.k8s.io/persistentvolumeclaims=15,persistentvolumeclaims=2,requests.storage=5Gi |
    Then the step should succeed
    When I run the :create_quota admin command with:
      | name | my-quota-1          |
      | n    | <%= project.name %> |
      | hard | persistentvolumeclaims=10,requests.storage=50Gi,gold.storageclass.storage.k8s.io/requests.storage=10Gi,bronze.storageclass.storage.k8s.io/requests.storage=20Gi |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-storage-class-slow |
      | ["spec"]["resources"]["requests"]["storage"] | 2Gi                    |
      | ["spec"]["storageClassName"]                 | slow                   |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota |
    Then the step should succeed
    And the output should match:
      | persistentvolumeclaims\\s+1\\s+2                                   |
      | requests.storage\\s+2Gi\\s+5Gi                                     |
      | slow.storageclass.storage.k8s.io/persistentvolumeclaims\\s+1\\s+15 |
      | slow.storageclass.storage.k8s.io/requests.storage\\s+2Gi\\s+20Gi   |
      | persistentvolumeclaims\\s+1\\s+10                                  |
      | requests.storage\\s+2Gi\\s+50Gi                                    |
      | bronze.storageclass.storage.k8s.io/requests.storage\\s+0\\s+20Gi   |
      | gold.storageclass.storage.k8s.io/requests.storage\\s+0\\s+10Gi     |
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-storage-class-bronze |
      | ["spec"]["resources"]["requests"]["storage"] | 3Gi                      |
      | ["spec"]["storageClassName"]                 | bronze                   |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota |
    Then the step should succeed
    And the output should match:
      | persistentvolumeclaims\\s+2\\s+2                                   |
      | requests.storage\\s+5Gi\\s+5Gi                                     |
      | slow.storageclass.storage.k8s.io/persistentvolumeclaims\\s+1\\s+15 |
      | slow.storageclass.storage.k8s.io/requests.storage\\s+2Gi\\s+20Gi   |
      | persistentvolumeclaims\\s+2\\s+10                                  |
      | requests.storage\\s+5Gi\\s+50Gi                                    |
      | bronze.storageclass.storage.k8s.io/requests.storage\\s+3Gi\\s+20Gi |
      | gold.storageclass.storage.k8s.io/requests.storage\\s+0\\s+10Gi     |
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-storage-class-gold |
      | ["spec"]["resources"]["requests"]["storage"] | 4Gi                    |
      | ["spec"]["storageClassName"]                 | gold                   |
    Then the step should fail
    And the output should contain:
      | persistentvolumeclaims "pvc-storage-class-gold" is forbidden: exceeded quota: my-quota, requested: persistentvolumeclaims=1,requests.storage=4Gi, used: persistentvolumeclaims=2,requests.storage=5Gi, limited: persistentvolumeclaims=2,requests.storage=5Gi |
    When I run the :describe client command with:
      | resource | quota |
    Then the step should succeed
    And the output should match:
      | persistentvolumeclaims\\s+2\\s+2                                   |
      | requests.storage\\s+5Gi\\s+5Gi                                     |
      | slow.storageclass.storage.k8s.io/persistentvolumeclaims\\s+1\\s+15 |
      | slow.storageclass.storage.k8s.io/requests.storage\\s+2Gi\\s+20Gi   |
      | persistentvolumeclaims\\s+2\\s+10                                  |
      | requests.storage\\s+5Gi\\s+50Gi                                    |
      | bronze.storageclass.storage.k8s.io/requests.storage\\s+3Gi\\s+20Gi |
      | gold.storageclass.storage.k8s.io/requests.storage\\s+0\\s+10Gi     |


  # @author qwang@redhat.com
  # @case_id OCP-11685
  @admin
  Scenario: Quota ability to scope PVC quotas by Storage Class
    Given I have a project
    When I run the :create_quota admin command with:
      | name | storage-quota       |
      | n    | <%= project.name %> |
      | hard | persistentvolumeclaims=10,requests.storage=50Gi,gold.storageclass.storage.k8s.io/requests.storage=10Gi,bronze.storageclass.storage.k8s.io/requests.storage=20Gi |
    Then the step should succeed
    Given I obtain test data file "quota/pvc-storage-class.json"
    When I run the :create client command with:
      | f | pvc-storage-class.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | storage-quota |
    Then the step should succeed
    And the output should match:
      | requests.storage\\s+2Gi\\s+50Gi                                  |
      | persistentvolumeclaims\\s+1\\s+10                                |
      | gold.storageclass.storage.k8s.io/requests.storage\\s+2Gi\\s+10Gi |
      | bronze.storageclass.storage.k8s.io/requests.storage\\s+0\\s+20Gi |
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-storage-class-bronze |
      | ["spec"]["resources"]["requests"]["storage"] | 3Gi                      |
      | ["spec"]["storageClassName"]                 | bronze                   |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | quota         |
      | name     | storage-quota |
    Then the step should succeed
    And the output should match:
      | requests.storage\\s+5Gi\\s+50Gi                                    |
      | persistentvolumeclaims\\s+2\\s+10                                  |
      | gold.storageclass.storage.k8s.io/requests.storage\\s+2Gi\\s+10Gi   |
      | bronze.storageclass.storage.k8s.io/requests.storage\\s+3Gi\\s+20Gi |
    Given I ensure "pvc-storage-class" pvc is deleted
    When I run the :describe client command with:
      | resource | quota         |
      | name     | storage-quota |
    Then the step should succeed
    And the output should match:
      | requests.storage\\s+3Gi\\s+50Gi                                    |
      | persistentvolumeclaims\\s+1\\s+10                                  |
      | gold.storageclass.storage.k8s.io/requests.storage\\s+0\\s+10Gi     |
      | bronze.storageclass.storage.k8s.io/requests.storage\\s+3Gi\\s+20Gi |
    Given I ensure "pvc-storage-class-bronze" pvc is deleted
    When I run the :describe client command with:
      | resource | quota         |
      | name     | storage-quota |
    Then the step should succeed
    And the output should match:
      | requests.storage\\s+0\\s+50Gi                                    |
      | persistentvolumeclaims\\s+0\\s+10                                |
      | gold.storageclass.storage.k8s.io/requests.storage\\s+0\\s+10Gi   |
      | bronze.storageclass.storage.k8s.io/requests.storage\\s+0\\s+20Gi |

  # @author yinzhou@redhat.com
  @admin
  Scenario Outline: Image with multiple layers and sumed up size slightly exceed the openshift.io/image-size will push failed
    Given I have a project
    And I have a skopeo pod in the project
    Given admin uses the "<%= project.name %>" project
    Given I obtain test data file "quota/image-limit-range.yaml"
    When I run oc create as admin over "image-limit-range.yaml" replacing paths:
      | ["spec"]["limits"][0]["max"]["storage"] | "100Mi" |
    Then the step should succeed
    And default registry service ip is stored in the :integrated_reg_ip clipboard
    When I execute on the pod:
      | skopeo                                                                    |
      | --debug                                                                   |
      | --insecure-policy                                                         |
      | copy                                                                      |
      | --dest-tls-verify=false                                                   |
      | --dcreds                                                                  |
      | dnm:<%= user.cached_tokens.first %>                                       |
      | docker://docker.io/<image>                                                |
      | docker://<%= cb.integrated_reg_ip %>/<%= project.name %>/mystream:latest  |
    Then the step should fail
    And the output should contain "denied"

    Examples:
      | image                       |
      | aosqe/fedora_base:latest    | # @case_id OCP-11797
      | aosqe/singlelayer:latest    | # @case_id OCP-11963

  # @author weinliu@redhat.com
  # @case_id OCP-15821
  @admin
  @destructive
  Scenario: Release quota for a pod if its terminating and exceeded grace period
    Given I have a project
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    Given I obtain test data file "quota/ocp15821/quota.yaml"
    When I run the :create client command with:
       | f | quota.yaml |
       | n | <%= project.name %>                                                                         |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | pods\\s+0\\s+10          |
      | resourcequotas\\s+1\\s+1 |
    """
    Given I obtain test data file "infrastructure/podpreset/hello-pod.yaml"
    When I run the :create admin command with:
      | f | hello-pod.yaml |
      | n | <%= project.name %>                                                                                        |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    And evaluation of `pod.node_name` is stored in the :pod_node clipboard
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | pods\\s+1\\s+10          |
      | resourcequotas\\s+1\\s+1 |
    """
    Given I use the "<%= cb.pod_node %>" node
    Given the node service is restarted on the host after scenario
    When the node service is stopped
    Then I wait up to 500 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | po |
    Then the output should match:
      | hello-pod\\s+1/1\\s+Unknown |
    """

    Then I wait up to 500 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota   |
      | name     | myquota |
    Then the output should match:
      | pods\\s+0\\s+10          |
      | resourcequotas\\s+1\\s+1 |
    """
    And I check that the "hello-pod" pod exists in the project
