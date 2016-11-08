Feature: storageClass related feature
  # @author lxia@redhat.com
  # @case_id 538932 538962 538963
  @admin
  @destructive
  Scenario Outline: pre-bound still works with storage class
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/<path_to_file>" where:
      | ["metadata"]["name"]                        | pv-<%= project.name %> |
      | ["spec"]["capacity"]["storage"]             | 1Gi                    |
      | ["spec"]["accessModes"][0]                  | ReadWriteOnce          |
      | ["spec"]["<storage_type>"]["<volume_name>"] | <%= cb.vid %>          |
      | ["spec"]["persistentVolumeReclaimPolicy"]   | Retain                 |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc-<%= project.name %>      |
      | ["provisioner"]                                                                 | kubernetes.io/<provisioner> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                        |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/claim-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | pv-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV

    Examples:
      | provisioner | storage_type         | volume_name | path_to_file               |
      | gce-pd      | gcePersistentDisk    | pdName      | gce/pv-default-rwo.json    |
      | aws-ebs     | awsElasticBlockStore | volumeID    | ebs/pv-rwo.yaml            |
      | cinder      | cinder               | volumeID    | cinder/pv-rwx-default.json |

  # @author lxia@redhat.com
  # @case_id 538926
  @admin
  @destructive
  Scenario: storage class creation negative testing
    Given admin ensures "slow" storage_class is deleted after scenario
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-invalidAPI.yaml |
    Then the step should fail
    And the output should contain:
      | StorageClass in version "invalid" cannot be handled                       |
      | no kind "StorageClass" is registered for version "storage.k8s.io/invalid" |

    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-emptyName.yaml |
    Then the step should fail
    And the output should contain:
      | name or generateName is required |

    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-invalidName.yaml |
    Then the step should fail
    And the output should contain:
      | Invalid value: "@test@" |

  # @author lxia@redhat.com
  # @case_id 534820 534823 536564
  @admin
  @destructive
  Scenario Outline: PVC modification after creating storage class
    Given I have a project
    # "oc get storageclass -o yaml"
    # should not contain string 'kind: StorageClass' when there are no storageclass
    When I run the :get admin command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should not contain "kind: StorageClass"
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-without-annotations.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    Given 30 seconds have passed
    And the "pvc-<%= project.name %>" PVC status is :pending

    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc-<%= project.name %>      |
      | ["provisioner"]                                                                 | kubernetes.io/<provisioner> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                        |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | pvc                                                    |
      | resource_name | pvc-<%= project.name %>                                |
      | p             | {"metadata":{"labels":{"<%= project.name %>":"test"}}} |
    Then the step should succeed
    Given 30 seconds have passed
    And the "pvc-<%= project.name %>" PVC status is :pending
    When I run the :patch client command with:
      | resource      | pvc                                                                                               |
      | resource_name | pvc-<%= project.name %>                                                                           |
      | p             | {"metadata":{"annotations":{"volume.beta.kubernetes.io/storage-class":"sc-<%= project.name %>"}}} |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

    Examples:
      | provisioner |
      | gce-pd      |
      | aws-ebs     |
      | cinder      |

  # @author lxia@redhat.com
  # @case_id 535042 536528 536529
  @admin
  @destructive
  Scenario Outline: No dynamic provision when no default storage class
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc-<%= project.name %>      |
      | ["provisioner"]                                                                 | kubernetes.io/<provisioner> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | "false"                     |
    Then the step should succeed
    # "oc get storageclass -o yaml"
    # should contain string 'kind: StorageClass' when there are storageclass
    # should not contain string 'is-default-class: "true"' when there are no default storageclass
    When I run the :get admin command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should contain "kind: StorageClass"
    And the output should not contain:
      | is-default-class: "true" |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-without-annotations.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    Given 30 seconds have passed
    And the "pvc-<%= project.name %>" PVC status is :pending

    Examples:
      | provisioner |
      | gce-pd      |
      | aws-ebs     |
      | cinder      |

  # @author lxia@redhat.com
  # @case_id 534816 534817
  @admin
  @destructive
  Scenario Outline: storage class provisioner
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc-<%= project.name %>      |
      | ["provisioner"]                                                                 | kubernetes.io/<provisioner> |
      | ["parameters"]["type"]                                                          | <type>                      |
      | ["parameters"]["zone"]                                                          | <zone>                      |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | <is-default>                |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"]                           | <size>                  |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And the expression should be true> pvc.capacity(user: user) == "<size>"
    And the expression should be true> pvc.access_modes(user: user)[0] == "ReadWriteOnce"
    And the expression should be true> pv(pvc.volume_name(user: user)).reclaim_policy(user: admin) == "Delete"
    # ToDo
    # check storage size info
    # check storage type info
    # check storage zone info
    # gcloud compute disks describe --zone <zone> diskNameViaPvInfo

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/iaas               |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=frontendhttp |
    When I execute on the pod:
      | ls | -ld | /mnt/iaas/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/iaas/testfile |
    Then the step should succeed
    Given I ensure "pod-<%= project.name %>" pod is deleted
    Given I ensure "pvc-<%= project.name %>" pvc is deleted
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: user) %>" to disappear within 300 seconds

    Examples:
      | provisioner | type        | zone          | is-default | size |
      | gce-pd      | pd-ssd      | us-central1-a | false      | 1Gi  |
      | gce-pd      | pd-standard | us-central1-a | false      | 2Gi  |

  # @author lxia@redhat.com
  # @case_id 534824
  @admin
  @destructive
  Scenario: Do not allow creation of GCE PDs in unmanaged zones
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/storageClass.yaml" where:
      | ["metadata"]["name"]   | sc-<%= project.name %> |
      | ["parameters"]["zone"] | europe-west1-d         |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/pvc-<%= project.name %> |
    Then the output should contain:
      | ProvisioningFailed |
      | Failed to provision volume with StorageClass "sc-<%= project.name %>" |
      | does not manage zone "europe-west1-d" |
    """

  # @author lxia@redhat.com
  # @case_id 534825 534826
  @admin
  @destructive
  Scenario Outline: PVC request storage class with specific provisioner
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | <provisioner>          |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/pvc-<%= project.name %> |
    Then the output should contain:
      | <str1> |
      | <str2> |
    """
    And the "pvc-<%= project.name %>" PVC status is :pending

    Examples:
      | provisioner           | str1                 | str2 |
      | manual                | ExternalProvisioning | provisioned either manually or via external software |
      | kubernetes.io/unknown | ProvisioningFailed   | no volume plugin matched                             |

  # @author lxia@redhat.com
  # @case_id 534822 536520 536521
  @admin
  @destructive
  Scenario Outline: New creation PVC failed when multiple classes are set as default
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc1-<%= project.name %>     |
      | ["provisioner"]                                                                 | kubernetes.io/<provisioner> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                        |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc2-<%= project.name %>     |
      | ["provisioner"]                                                                 | kubernetes.io/<provisioner> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                        |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-without-annotations.json" replacing paths:
      | ["metadata"]["name"] | should-fail-<%= project.name %> |
    Then the step should fail
    And the output should match:
      | Internal error occurred |
      | ([2-9]\|[1-9][0-9]+) default StorageClasses were found |
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc1-<%= project.name %>  |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc2-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc2-<%= project.name %>  |
    Then the step should succeed
    And the "pvc1-<%= project.name %>" PVC becomes :bound within 120 seconds
    And the "pvc2-<%= project.name %>" PVC becomes :bound within 120 seconds

    Examples:
      | provisioner |
      | gce-pd      |
      | aws-ebs     |
      | cinder      |

  # @author lxia@redhat.com
  # @case_id 534821 536531 536532
  @admin
  @destructive
  Scenario Outline: New created PVC without specifying storage class use default class when only one class is marked as default
    # check there are no default StorageClass
    When I run the :get admin command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should not contain:
      | is-default-class: "true" |
    Given I have a project
    # create one as default StorageClass
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc-<%= project.name %>      |
      | ["provisioner"]                                                                 | kubernetes.io/<provisioner> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                        |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-without-annotations.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds

    Examples:
      | provisioner |
      | gce-pd      |
      | aws-ebs     |
      | cinder      |

  # @author wehe@redhat.com
  # @case_id 534488
  @admin
  @destructive
  Scenario: Check the storage class detail by oc describe
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc1-<%= project.name %> |
      | ["provisioner"]                                                                 | kubernetes.io/gce-pd    |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                    |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/storageClass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run the :describe admin command with:
      | resource | storageclass/sc1-<%= project.name %> |
    Then the output should match:
      | IsDefaultClass.*Yes |
      | Annotations.*storageclass.beta.kubernetes.io/is-default-class=true | 
      | Provisioner.*kubernetes.io/gce-pd | 
    When I run the :describe admin command with:
      | resource | storageclass/sc-<%= project.name %> |
    Then the output should match:
      | IsDefaultClass.*No |
      | Annotations.*storageclass.beta.kubernetes.io/is-default-class=false | 
      | Parameters.*type=pd-ssd,zone=us-central1-b |

