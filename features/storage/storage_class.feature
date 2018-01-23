Feature: storageClass related feature
  # @author lxia@redhat.com
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
    Given default storage class is deleted
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc-<%= project.name %>      |
      | ["provisioner"]                                                                 | kubernetes.io/<provisioner> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                        |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | pv-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV

    Examples:
      | provisioner | storage_type         | volume_name | path_to_file               |
      | gce-pd      | gcePersistentDisk    | pdName      | gce/pv-default-rwo.json    | # @case_id OCP-10470
      | aws-ebs     | awsElasticBlockStore | volumeID    | ebs/pv-rwo.yaml            | # @case_id OCP-10473
      | cinder      | cinder               | volumeID    | cinder/pv-rwx-default.json | # @case_id OCP-10474

  # @author lxia@redhat.com
  # @case_id OCP-10469
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

    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-noProvisioner.yaml |
    Then the step should fail
    And the output should contain:
      | provisioner: Required value |

  # @author lxia@redhat.com
  @admin
  @destructive
  Scenario Outline: PVC modification after creating storage class
    Given I have a project
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-without-annotations.json" replacing paths:
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
    Then the expression should be true> @result[:success] == env.version_le("3.5", user: user)

    Examples:
      | provisioner |
      | gce-pd      | # @case_id OCP-12089
      | aws-ebs     | # @case_id OCP-12269
      | cinder      | # @case_id OCP-12272
      | azure-disk  | # @case_id OCP-13488

  # @author lxia@redhat.com
  @admin
  @destructive
  Scenario Outline: No dynamic provision when no default storage class
    Given I have a project
    And default storage class is deleted
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %>      |
      | ["provisioner"]      | kubernetes.io/<provisioner> |
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
      | gce-pd      | # @case_id OCP-12090
      | aws-ebs     | # @case_id OCP-12096
      | cinder      | # @case_id OCP-12097
      | azure-disk  | # @case_id OCP-13489

  # @author lxia@redhat.com
  # @author chaoyang@redhat.com
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

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"]                           | <size>                  |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And the expression should be true> pvc.capacity == "<size>"
    And the expression should be true> pvc.access_modes[0] == "ReadWriteOnce"
    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Delete"
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
    Given the pod named "pod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | ls | -ld | /mnt/iaas/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/iaas/testfile |
    Then the step should succeed
    Given I ensure "pod-<%= project.name %>" pod is deleted
    Given I ensure "pvc-<%= project.name %>" pvc is deleted
    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear

    Examples:
      | provisioner | type        | zone          | is-default | size  |
      | gce-pd      | pd-ssd      | us-central1-a | false      | 1Gi   | # @case_id OCP-11359
      | gce-pd      | pd-standard | us-central1-a | false      | 2Gi   | # @case_id OCP-11640
      | aws-ebs     | gp2         | us-east-1d    | false      | 1Gi   | # @case_id OCP-10160
      | aws-ebs     | sc1         | us-east-1d    | false      | 500Gi | # @case_id OCP-10161
      | aws-ebs     | st1         | us-east-1d    | false      | 500Gi | # @case_id OCP-10424

  # @author lxia@redhat.com
  # @case_id OCP-12299
  @admin
  @destructive
  Scenario: Do not allow creation of GCE PDs in unmanaged zones
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/storageClass.yaml" where:
      | ["metadata"]["name"]   | sc-<%= project.name %> |
      | ["parameters"]["zone"] | europe-west1-d         |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/pvc-<%= project.name %> |
    Then the output should match:
      | ProvisioningFailed                                                    |
      | Failed to provision volume with StorageClass "sc-<%= project.name %>" |
      | does not .*zone "europe-west1-d"                                      |
    """

  # @author lxia@redhat.com
  @admin
  @destructive
  Scenario Outline: PVC request storage class with specific provisioner
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | <provisioner>          |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/pvc-<%= project.name %> |
    Then the output should contain:
      | <%= "<provisioner>"=="manual" ? "ExternalProvisioning" : "ProvisioningFailed" %>                                                                                                                    |
      | <%= "<provisioner>"=="manual" ? (env.version_lt("3.7", user: user) ? "provisioned either manually or via external software" : "waiting for a volume to be created") : "no volume plugin matched" %> |
    """
    And the "pvc-<%= project.name %>" PVC status is :pending

    Examples:
      | provisioner           |
      | manual                | # @case_id OCP-12326
      | kubernetes.io/unknown | # @case_id OCP-12348

  # @author lxia@redhat.com
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
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc1-<%= project.name %>  |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc2-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc2-<%= project.name %>  |
    Then the step should succeed
    And the "pvc1-<%= project.name %>" PVC becomes :bound within 120 seconds
    And the "pvc2-<%= project.name %>" PVC becomes :bound within 120 seconds

    Examples:
      | provisioner |
      | gce-pd      | # @case_id OCP-12223
      | aws-ebs     | # @case_id OCP-12226
      | cinder      | # @case_id OCP-12227
      | azure-disk  | # @case_id OCP-13490

  # @author lxia@redhat.com
  @admin
  @destructive
  Scenario Outline: New created PVC without specifying storage class use default class when only one class is marked as default
    Given default storage class is deleted
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
      | gce-pd      | # @case_id OCP-12171
      | aws-ebs     | # @case_id OCP-12176
      | cinder      | # @case_id OCP-12177
      | azure-disk  | # @case_id OCP-13492

  # @author wehe@redhat.com
  # @case_id OCP-10218
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
      | Annotations.*.kubernetes.io/is-default-class=true |
      | Provisioner.*kubernetes.io/gce-pd |
    When I run the :describe admin command with:
      | resource | storageclass/sc-<%= project.name %> |
    Then the output should match:
      | IsDefaultClass.*No |
      | Annotations.*.kubernetes.io/is-default-class=false |
      | Parameters.*type=pd-ssd,zone=us-central1-b |

  # @author chaoyang@redhat.com
  @admin
  Scenario Outline: PVC with storage class will provision pv with io1 type and 100/20000 iops ebs volume
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/dynamic-provisioning/storageclass-io1.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"]                           | <size>                  |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And the expression should be true> pvc.capacity == "<size>"
    And the expression should be true> pvc.access_modes[0] == "ReadWriteOnce"
    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Delete"

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | pod-<%= project.name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-<%= project.name %> |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/iaas               |
    Then the step should succeed
    Given the pod named "pod-<%= project.name %>" becomes ready
    When I execute on the pod:
      | ls | -ld | /mnt/iaas/ |
    Then the step should succeed
    When I execute on the pod:
      | touch | /mnt/iaas/testfile |
    Then the step should succeed
    Given I ensure "pod-<%= project.name %>" pod is deleted
    Given I ensure "pvc-<%= project.name %>" pvc is deleted
    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 300 seconds

    Examples:
      | size  |
      | 4Gi   | # @case_id OCP-10158
      | 800Gi | # @case_id OCP-10162

  # @author jhou@redhat.com
  # @case_id OCP-10325
  @admin
  Scenario: Error messaging for failed provision via StorageClass
    Given I have a project
    # Scenario when StorageClass's rest url can't be reached
    Given admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/storageclass_using_key.yaml" where:
      | ["metadata"]["name"]      | sc-<%= project.name %> |
      | ["parameters"]["resturl"] | http://foo.com/        |
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gluster/dynamic-provisioning/claim.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | invalid                |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %> |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/invalid |
    Then the output should contain:
      | error creating volume |
    """

  # @author lxia@redhat.com
  # @case_id OCP-10459
  Scenario: Using both alpha and beta annotation in PVC
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                    | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.alpha.kubernetes.io/storage-class"] | sc1-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"]  | sc2-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :pending
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/pvc-<%= project.name %> |
    Then the output should contain:
      | <%= env.version_lt("3.7", user: user) ? "ProvisioningIgnoreAlpha" : "ProvisioningFailed" %>                     |
      | <%= env.version_lt("3.7", user: user) ? "" : "storageclass.storage.k8s.io \"sc2-#{project.name}\" not found" %> |
    """

  # @author chaoyang@redhat.com
  @admin
  Scenario Outline: PVC with storage class will not provision pv with st1/sc1 type ebs volume if request size is wrong
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/dynamic-provisioning/storageclass.yaml" where:
      | ["metadata"]["name"]   | sc-<%= project.name %> |
      | ["provisioner"]        | kubernetes.io/aws-ebs  |
      | ["parameters"]["type"] | <type>                 |
      | ["parameters"]["zone"] | us-east-1d             |
    Then the step should succeed

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"]                           | <size>                  |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/pvc-<%= project.name %> |
    Then the output should contain:
      | ProvisioningFailed    |
      | InvalidParameterValue |
      | <errorMessage>        |
    """

    Examples:
      | type | size | errorMessage                  |
      | sc1  | 5Gi  | at least 500 GiB              | # @case_id OCP-10164
      | st1  | 17Ti | too large for volume type st1 | # @case_id OCP-10425

  # @author chaoyang@redhat.com
  # @case_id OCP-10163
  @admin
  Scenario: PVC with storage class will not provision io1 pv with wrong parameters for aws ebs volume
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/dynamic-provisioning/storageclass-io1.yaml" where:
      | ["metadata"]["name"]        | sc1-<%=project.name%> |
      | ["parameters"]["iopsPerGB"] | 400000                |
    Then the step should succeed

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1-<%= project.name %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce            |
      | ["spec"]["resources"]["requests"]["storage"]                           | 4Gi                      |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc1-<%= project.name %>  |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/pvc1-<%= project.name %> |
    And the output should contain:
      | Pending               |
      | ProvisioningFailed    |
      | InvalidParameterValue |
      | maximum is 50         |
    """

    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/dynamic-provisioning/storageclass-io1.yaml" where:
      | ["metadata"]["name"]        | sc2-<%=project.name%> |
      | ["parameters"]["iopsPerGB"] | 40                    |
    Then the step should succeed

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc2-<%= project.name %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce            |
      | ["spec"]["resources"]["requests"]["storage"]                           | 3Gi                      |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc2-<%= project.name %>  |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/pvc2-<%= project.name %> |
    And the output should contain:
      | Pending                |
      | ProvisioningFailed     |
      | InvalidParameterValue  |
      | at least 4 GiB in size |
    """

  # @author chaoyang@redhat.com
  # @case_id OCP-10159
  @admin
  Scenario: PVC with storage class won't provisioned pv if no storage class or wrong storage class object
    Given I have a project
    # No sc exists
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1-<%= project.name %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce            |
      | ["spec"]["resources"]["requests"]["storage"]                           | 1Gi                      |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc1-<%= project.name %>  |
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/pvc1-<%= project.name %> |
    And the output should contain:
      | ProvisioningFailed                  |
      | "sc1-<%= project.name %>" not found |
    """

  # @author lxia@redhat.com
  @admin
  @destructive
  Scenario Outline: dynamic provision with storage class in multi-zones
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/storageClass.yaml" where:
      | ["metadata"]["name"]   | sc1-<%= project.name %>     |
      | ["provisioner"]        | kubernetes.io/<provisioner> |
      | ["parameters"]["zone"] | <region1_zone1>             |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/storageClass.yaml" where:
      | ["metadata"]["name"]   | sc2-<%= project.name %>     |
      | ["provisioner"]        | kubernetes.io/<provisioner> |
      | ["parameters"]["zone"] | <region1_zone2>             |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/storageClass.yaml" where:
      | ["metadata"]["name"]   | sc3-<%= project.name %>     |
      | ["provisioner"]        | kubernetes.io/<provisioner> |
      | ["parameters"]["zone"] | <region2_zone1>             |
    Then the step should succeed

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc1-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc1-<%= project.name %>  |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc2-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc2-<%= project.name %>  |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc3-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc3-<%= project.name %>  |
    Then the step should succeed
    And the "pvc1-<%= project.name %>" PVC becomes :bound
    And the "pvc2-<%= project.name %>" PVC becomes :bound
    And the "pvc3-<%= project.name %>" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc/pvc3-<%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | ProvisioningFailed                     |
      | does not manage zone "<region2_zone1>" |

    Examples:
      | provisioner | region1_zone1 | region1_zone2 | region2_zone1  |
      | gce-pd      | us-central1-a | us-central1-b | europe-west1-d | # @case_id OCP-11830

  # @author lxia@redhat.com
  @admin
  @destructive
  Scenario Outline: Create storageclass with specific api
    Given a 5 characters random string of type :dns is stored into the :sc_name clipboard
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-with-beta-annotations.yaml" where:
      | ["apiVersion"]                                                                  | storage.k8s.io/<version> |
      | ["metadata"]["name"]                                                            | sc1-<%= cb.sc_name %>    |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | false                    |
      | ["provisioner"]                                                                 | kubernetes.io/manual     |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-with-beta-annotations.yaml" where:
      | ["apiVersion"]                                                                  | storage.k8s.io/<version> |
      | ["metadata"]["name"]                                                            | sc2-<%= cb.sc_name %>    |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                     |
      | ["provisioner"]                                                                 | kubernetes.io/manual     |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-with-stable-annotations.yaml" where:
      | ["apiVersion"]                                                             | storage.k8s.io/<version> |
      | ["metadata"]["name"]                                                       | sc3-<%= cb.sc_name %>    |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"] | false                    |
      | ["provisioner"]                                                            | kubernetes.io/manual     |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-with-stable-annotations.yaml" where:
      | ["apiVersion"]                                                             | storage.k8s.io/<version> |
      | ["metadata"]["name"]                                                       | sc4-<%= cb.sc_name %>    |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"] | true                     |
      | ["provisioner"]                                                            | kubernetes.io/manual     |
    Then the step should succeed

    When I run the :describe admin command with:
      | resource | storageclass          |
      | name     | sc1-<%= cb.sc_name %> |
      | name     | sc2-<%= cb.sc_name %> |
      | name     | sc3-<%= cb.sc_name %> |
      | name     | sc4-<%= cb.sc_name %> |
    Then the step should succeed
    And the output by order should match:
      | sc1-<%= cb.sc_name %>                                  |
      | IsDefaultClass:\s+No                                   |
      | storageclass.beta.kubernetes.io/is-default-class=false |
      | sc2-<%= cb.sc_name %>                                  |
      | IsDefaultClass:\s+Yes                                  |
      | storageclass.beta.kubernetes.io/is-default-class=true  |
      | sc3-<%= cb.sc_name %>                                  |
      | IsDefaultClass:\s+No                                   |
      | storageclass.kubernetes.io/is-default-class=false      |
      | sc4-<%= cb.sc_name %>                                  |
      | IsDefaultClass:\s+Yes                                  |
      | storageclass.kubernetes.io/is-default-class=true       |

    Examples:
      | version |
      | v1beta1 | # @case_id OCP-13352
      | v1      | # @case_id OCP-13353

  # @author lxia@redhat.com
  # @case_id OCP-13664
  @admin
  Scenario: Create storageclass without annotations
    Given the master version >= "3.6"
    Given a 5 characters random string of type :dns is stored into the :sc_name clipboard
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-without-annotations.yaml" where:
      | ["apiVersion"]       | storage.k8s.io/v1beta1 |
      | ["metadata"]["name"] | sc1-<%= cb.sc_name %>  |
      | ["provisioner"]      | kubernetes.io/manual   |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-without-annotations.yaml" where:
      | ["apiVersion"]       | storage.k8s.io/v1     |
      | ["metadata"]["name"] | sc2-<%= cb.sc_name %> |
      | ["provisioner"]      | kubernetes.io/manual  |
    Then the step should succeed

    When I run the :describe admin command with:
      | resource | storageclass          |
      | name     | sc1-<%= cb.sc_name %> |
      | name     | sc2-<%= cb.sc_name %> |
    Then the step should succeed
    And the output by order should match:
      | sc1-<%= cb.sc_name %> |
      | IsDefaultClass:\s+No  |
      | sc2-<%= cb.sc_name %> |
      | IsDefaultClass:\s+No  |

  # @author lxia@redhat.com
  # @case_id OCP-13665
  @admin
  @destructive
  Scenario: Create storageclass with both beta and stable annotations
    Given the master version >= "3.6"
    Given a 5 characters random string of type :dns is stored into the :sc_name clipboard
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-with-beta-annotations.yaml" where:
      | ["apiVersion"]                                                                  | storage.k8s.io/v1beta1 |
      | ["metadata"]["name"]                                                            | sc1-<%= cb.sc_name %>  |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | false                  |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"]      | false                  |
      | ["provisioner"]                                                                 | kubernetes.io/manual   |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-with-beta-annotations.yaml" where:
      | ["apiVersion"]                                                                  | storage.k8s.io/v1     |
      | ["metadata"]["name"]                                                            | sc2-<%= cb.sc_name %> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                  |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"]      | true                  |
      | ["provisioner"]                                                                 | kubernetes.io/manual  |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-with-stable-annotations.yaml" where:
      | ["apiVersion"]                                                                  | storage.k8s.io/v1beta1 |
      | ["metadata"]["name"]                                                            | sc3-<%= cb.sc_name %>  |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | false                  |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"]      | true                   |
      | ["provisioner"]                                                                 | kubernetes.io/manual   |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-with-stable-annotations.yaml" where:
      | ["apiVersion"]                                                                  | storage.k8s.io/v1     |
      | ["metadata"]["name"]                                                            | sc4-<%= cb.sc_name %> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                  |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"]      | false                 |
      | ["provisioner"]                                                                 | kubernetes.io/manual  |
    Then the step should succeed

    When I run the :describe admin command with:
      | resource | storageclass          |
      | name     | sc1-<%= cb.sc_name %> |
      | name     | sc2-<%= cb.sc_name %> |
      | name     | sc3-<%= cb.sc_name %> |
      | name     | sc4-<%= cb.sc_name %> |
    Then the step should succeed
    And the output by order should match:
      | sc1-<%= cb.sc_name %>                                  |
      | IsDefaultClass:\s+No                                   |
      | storageclass.beta.kubernetes.io/is-default-class=false |
      | storageclass.kubernetes.io/is-default-class=false      |
      | sc2-<%= cb.sc_name %>                                  |
      | IsDefaultClass:\s+Yes                                  |
      | storageclass.beta.kubernetes.io/is-default-class=true  |
      | storageclass.kubernetes.io/is-default-class=true       |
      | sc3-<%= cb.sc_name %>                                  |
      | IsDefaultClass:\s+Yes                                  |
      | storageclass.beta.kubernetes.io/is-default-class=false |
      | storageclass.kubernetes.io/is-default-class=true       |
      | sc4-<%= cb.sc_name %>                                  |
      | IsDefaultClass:\s+Yes                                  |
      | storageclass.beta.kubernetes.io/is-default-class=true  |
      | storageclass.kubernetes.io/is-default-class=false      |

  # @author lxia@redhat.com
  # @case_id OCP-13666
  @admin
  Scenario: Dynamic provisioning using default storageclass
    Given the master version >= "3.6"
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-without-annotations.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    When I run the :describe client command with:
      | resource | pvc                     |
      | name     | pvc-<%= project.name %> |
    Then the step should succeed
    And the output should match "StorageClass:\s+[a-z]+"
    When I run the :describe admin command with:
      | resource | pv                     |
      | name     | <%= pvc.volume_name %> |
    Then the step should succeed
    And the output should match "StorageClass:\s+[a-z]+"

  # @author lxia@redhat.com
  # @case_id OCP-13667
  @admin
  Scenario: Dynamic provisioning using non-default storageclass by annotations
    Given the master version >= "3.6"
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-without-annotations.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | kubernetes.io/gce-pd   |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    And the expression should be true> pvc.storage_class == "sc-<%= project.name %>"
    And the expression should be true> pv(pvc.volume_name).storage_class_name == "sc-<%= project.name %>"

  # @author lxia@redhat.com
  # @case_id OCP-13668
  @admin
  Scenario: Dynamic provisioning using non-default storageclass by attribute storageClassName
    Given the master version >= "3.6"
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-without-annotations.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | kubernetes.io/gce-pd   |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    And the expression should be true> pvc.storage_class == "sc-<%= project.name %>"
    And the expression should be true> pv(pvc.volume_name).storage_class_name == "sc-<%= project.name %>"

  # @author lxia@redhat.com
  # @case_id OCP-13669
  @admin
  Scenario: Dynamic provisioning with both annotations and atrribute storageClassName, reference the same storageclass
    Given the master version >= "3.6"
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-without-annotations.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | kubernetes.io/gce-pd   |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
      | ["spec"]["storageClassName"]                                           | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    And the expression should be true> pvc.storage_class == "sc-<%= project.name %>"
    And the expression should be true> pv(pvc.volume_name).storage_class_name == "sc-<%= project.name %>"

  # @author lxia@redhat.com
  # @case_id OCP-13670
  @admin
  Scenario: Dynamic provisioning with both annotations and atrribute storageClassName, reference different storageclass, annotation wins
    Given the master version >= "3.6"
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-without-annotations.yaml" where:
      | ["metadata"]["name"] | sc1-<%= project.name %> |
      | ["provisioner"]      | kubernetes.io/gce-pd    |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-without-annotations.yaml" where:
      | ["metadata"]["name"] | sc2-<%= project.name %> |
      | ["provisioner"]      | kubernetes.io/gce-pd    |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc1-<%= project.name %> |
      | ["spec"]["storageClassName"]                                           | sc2-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    And the expression should be true> pvc.storage_class == "sc1-<%= project.name %>"
    And the expression should be true> pv(pvc.volume_name).storage_class_name == "sc1-<%= project.name %>"

  # @author chaoyang@redhat.com
  # @case_id OCP-12872
  @admin
  @destructive
  Scenario: Check storageclass info pv and pvc requested when pvc is using alpha annotation and no default storageclass
    Given I have a project
    Given default storage class is deleted
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                    | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.alpha.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    And the expression should be true> pvc.storage_class == nil
    And the expression should be true> pv(pvc.volume_name).storage_class_name == nil

  # @author chaoyang@redhat.com
  # @case_id OCP-12873
  @admin
  Scenario: Check storageclass info pv and pvc requested when pvc is using beta annotation
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/dynamic-provisioning/storageclass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/dynamic-provisioning/pvc.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    And the expression should be true> pvc.storage_class == "sc-<%= project.name %>"
    And the expression should be true> pv(pvc.volume_name).storage_class_name == "sc-<%= project.name %>"

  # @author chaoyang@redhat.com
  # @case_id OCP-12874
  @admin
  @destructive
  Scenario: Check storageclass info when pvc using default storageclass
    Given I have a project
    Given default storage class is deleted
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc-<%= project.name %>  |
      | ["provisioner"]                                                                 | kubernetes.io/aws-ebs   |
      | ["parameters"]["type"]                                                          | gp2                     |
      | ["parameters"]["zone"]                                                          | us-east-1d              |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                    |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-without-annotations.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    And the expression should be true> pvc.storage_class == "sc-<%= project.name %>"
    And the expression should be true> pv(pvc.volume_name).storage_class_name == "sc-<%= project.name %>"

  # @author chaoyang@redhat.com
  # @case_id OCP-12875
  @admin
  @destructive
  Scenario: Check storageclass is none when pv and pvc does not use storageclass
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard

    Given default storage class is deleted
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pv-rwo.yaml" where:
      | ["metadata"]["name"]                         | pv-<%= project.name %> |
      | ["spec"]["awsElasticBlockStore"]["volumeID"] | <%= cb.vid %>          |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pvc-retain.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes bound to the "pv-<%= project.name %>" PV

    And the expression should be true> env.version_ge("3.7", user: user)? pvc.storage_class == "":pvc.storage_class == nil
    And the expression should be true> pv(pvc.volume_name).storage_class_name == nil

  # @author chaoyang@redhat.com
  # @case_id OCP-14160
  @admin
  @destructive
  Scenario: Check storageclass info pv and pvc requested when pvc is using alpha annotation
    Given I have a project
    Given default storage class is deleted
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc-<%= project.name %>  |
      | ["provisioner"]                                                                 | kubernetes.io/aws-ebs   |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                    |
    Then the step should succeed

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                    | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.alpha.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    And the expression should be true> pvc.storage_class == "sc-<%= project.name %>"
    And the expression should be true> pv(pvc.volume_name).storage_class_name == "sc-<%= project.name %>"

  # @author chaoyang@redhat.com
  # @case_id OCP-10228
  Scenario: AWS ebs volume is dynamic provisioned with default storageclass
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pvc-retain.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound


  # @author jhou@redhat.com
  @admin
  Scenario Outline: Configure 'Retain' reclaim policy for StorageClass
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass-reclaim-policy.yaml" where:
      | ["metadata"]["name"]                                                            | sc-<%= project.name %>      |
      | ["provisioner"]                                                                 | kubernetes.io/<provisioner> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | false                       |
    Then the step should succeed

    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                   | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"]                           | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Retain"

    When I ensure "pvc-<%= project.name %>" pvc is deleted
    Then the PV becomes :released
    And admin ensures "<%= pvc.volume_name %>" pv is deleted

    Examples:
      | provisioner    |
      | vsphere-volume | # @case_id OCP-17269
      | gce-pd         | # @case_id OCP-17273
      | aws-ebs        | # @case_id OCP-17271
      | cinder         | # @case_id OCP-17270
      | azure-disk     | # @case_id OCP-17274
