Feature: storageClass related feature
  # @author lxia@redhat.com
  @admin
  Scenario Outline: pre-bound still works with storage class
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/<path_to_file>" where:
      | ["metadata"]["name"]                        | pv-<%= project.name %> |
      | ["spec"]["capacity"]["storage"]             | 1Gi                    |
      | ["spec"]["accessModes"][0]                  | ReadWriteOnce          |
      | ["spec"]["<storage_type>"]["<volume_name>"] | <%= cb.vid %>          |
      | ["spec"]["persistentVolumeReclaimPolicy"]   | Retain                 |
      | ["spec"]["storageClassName"]                | sc-<%= project.name %> |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["volumeName"]       | pv-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV

    Examples:
      | provisioner | storage_type         | volume_name | path_to_file               |
      | gce-pd      | gcePersistentDisk    | pdName      | gce/pv-default-rwo.json    | # @case_id OCP-10470
      | aws-ebs     | awsElasticBlockStore | volumeID    | ebs/pv-rwo.yaml            | # @case_id OCP-10473
      | cinder      | cinder               | volumeID    | cinder/pv-rwx-default.json | # @case_id OCP-10474

  # @author lxia@redhat.com
  # @case_id OCP-10469
  @admin
  Scenario: storage class creation negative testing
    Given I have a project
    Given admin ensures "slow-<%= project.name %>" storage_class is deleted after scenario
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-invalidAPI.yaml |
    Then the step should fail
    And the output should match:
      | no (matches for )?kind "StorageClass" (is registered for \|in )version "storage.k8s.io/invalid" |

    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-emptyName.yaml |
    Then the step should fail
    And the output should contain:
      | name or generateName is required |

    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-invalidName.yaml |
    Then the step should fail
    And the output should contain:
      | Invalid value: "@test@" |

    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-noProvisioner.yaml |
    Then the step should fail
    And the output should contain:
      | provisioner: Required value |

  # @author lxia@redhat.com
  # @case_id OCP-12299
  @admin
  Scenario: Do not allow creation of GCE PDs in unmanaged zones
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["parameters"]["zone"] | europe-west1-d |
      | ["volumeBindingMode"]  | Immediate      |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/mypvc |
    Then the output should match:
      | ProvisioningFailed                                                    |
      | Failed to provision volume with StorageClass "sc-<%= project.name %>" |
      | does not .*zone "europe-west1-d"                                      |
    """

  # @author lxia@redhat.com
  @admin
  Scenario Outline: PVC request storage class with specific provisioner
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["provisioner"]       | <provisioner> |
      | ["volumeBindingMode"] | Immediate     |
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "mypvc" PVC becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/mypvc |
    Then the output should contain:
      | <%= "<provisioner>"=="manual" ? "ExternalProvisioning" : "ProvisioningFailed" %>                     |
      | <%= "<provisioner>"=="manual" ? "waiting for a volume to be created" : "no volume plugin matched" %> |
    """
    And the "mypvc" PVC status is :pending

    Examples:
      | provisioner           |
      | manual                | # @case_id OCP-12326
      | kubernetes.io/unknown | # @case_id OCP-12348

  # @author chaoyang@redhat.com
  # @case_id OCP-10163
  @admin
  Scenario: PVC with storage class will not provision io1 pv with wrong parameters for aws ebs volume
    Given I have a project
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/dynamic-provisioning/storageclass-io1.yaml" where:
      | ["metadata"]["name"]        | sc1-<%=project.name%> |
      | ["parameters"]["iopsPerGB"] | 400000                |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc1-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce            |
      | ["spec"]["resources"]["requests"]["storage"] | 4Gi                      |
      | ["spec"]["storageClassName"]                 | sc1-<%= project.name %>  |
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

    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/dynamic-provisioning/storageclass-io1.yaml" where:
      | ["metadata"]["name"]        | sc2-<%=project.name%> |
      | ["parameters"]["iopsPerGB"] | 40                    |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc2-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce            |
      | ["spec"]["resources"]["requests"]["storage"] | 3Gi                      |
      | ["spec"]["storageClassName"]                 | sc2-<%= project.name %>  |
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

  # @author lxia@redhat.com
  @admin
  @destructive
  Scenario Outline: dynamic provision with storage class in multi-zones
    Given I have a project
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gce/storageClass.yaml" where:
      | ["metadata"]["name"]   | sc1-<%= project.name %>     |
      | ["provisioner"]        | kubernetes.io/<provisioner> |
      | ["parameters"]["zone"] | <region1_zone1>             |
    Then the step should succeed
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gce/storageClass.yaml" where:
      | ["metadata"]["name"]   | sc2-<%= project.name %>     |
      | ["provisioner"]        | kubernetes.io/<provisioner> |
      | ["parameters"]["zone"] | <region1_zone2>             |
    Then the step should succeed
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gce/storageClass.yaml" where:
      | ["metadata"]["name"]   | sc3-<%= project.name %>     |
      | ["provisioner"]        | kubernetes.io/<provisioner> |
      | ["parameters"]["zone"] | <region2_zone1>             |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | pvc1-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc1-<%= project.name %>  |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | pvc2-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc2-<%= project.name %>  |
    Then the step should succeed
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | pvc3-<%= project.name %> |
      | ["spec"]["storageClassName"] | sc3-<%= project.name %>  |
    Then the step should succeed
    And the "pvc1-<%= project.name %>" PVC becomes :bound
    And the "pvc2-<%= project.name %>" PVC becomes :bound
    And the "pvc3-<%= project.name %>" PVC becomes :pending
    When I run the :describe client command with:
      | resource | pvc/pvc3-<%= project.name %> |
    Then the step should succeed
    And the output should match:
      | ProvisioningFailed                                       |
      | does not (manage\|have a node in) zone "<region2_zone1>" |

    Examples:
      | provisioner | region1_zone1 | region1_zone2 | region2_zone1  |
      | gce-pd      | us-central1-a | us-central1-b | europe-west1-d | # @case_id OCP-11830

  # @author lxia@redhat.com
  @admin
  Scenario Outline: Create storageclass with specific api
    Given a 5 characters random string of type :dns is stored into the :sc_name clipboard
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-with-beta-annotations.yaml" where:
      | ["apiVersion"]                                                                  | storage.k8s.io/<version> |
      | ["metadata"]["name"]                                                            | sc1-<%= cb.sc_name %>    |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | false                    |
      | ["provisioner"]                                                                 | kubernetes.io/manual     |
    Then the step should succeed
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-with-stable-annotations.yaml" where:
      | ["apiVersion"]                                                             | storage.k8s.io/<version> |
      | ["metadata"]["name"]                                                       | sc2-<%= cb.sc_name %>    |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"] | false                    |
      | ["provisioner"]                                                            | kubernetes.io/manual     |
    Then the step should succeed

    When I run the :describe admin command with:
      | resource | storageclass          |
      | name     | sc1-<%= cb.sc_name %> |
      | name     | sc2-<%= cb.sc_name %> |
    Then the step should succeed
    And the output by order should match:
      | sc1-<%= cb.sc_name %>                                  |
      | IsDefaultClass:\s+No                                   |
      | storageclass.beta.kubernetes.io/is-default-class=false |
      | sc2-<%= cb.sc_name %>                                  |
      | IsDefaultClass:\s+No                                   |
      | storageclass.kubernetes.io/is-default-class=false      |

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
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-without-annotations.yaml" where:
      | ["apiVersion"]       | storage.k8s.io/v1beta1 |
      | ["metadata"]["name"] | sc1-<%= cb.sc_name %>  |
      | ["provisioner"]      | kubernetes.io/manual   |
    Then the step should succeed
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-without-annotations.yaml" where:
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
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-with-beta-annotations.yaml" where:
      | ["apiVersion"]                                                                  | storage.k8s.io/v1beta1 |
      | ["metadata"]["name"]                                                            | sc1-<%= cb.sc_name %>  |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | false                  |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"]      | false                  |
      | ["provisioner"]                                                                 | kubernetes.io/manual   |
    Then the step should succeed
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-with-beta-annotations.yaml" where:
      | ["apiVersion"]                                                                  | storage.k8s.io/v1     |
      | ["metadata"]["name"]                                                            | sc2-<%= cb.sc_name %> |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                  |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"]      | true                  |
      | ["provisioner"]                                                                 | kubernetes.io/manual  |
    Then the step should succeed
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-with-stable-annotations.yaml" where:
      | ["apiVersion"]                                                                  | storage.k8s.io/v1beta1 |
      | ["metadata"]["name"]                                                            | sc3-<%= cb.sc_name %>  |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | false                  |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"]      | true                   |
      | ["provisioner"]                                                                 | kubernetes.io/manual   |
    Then the step should succeed
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-with-stable-annotations.yaml" where:
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
    Given I have a project
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=mysql |

    Given the "mysql" PVC becomes :bound
    When I run the :describe client command with:
      | resource | pvc   |
      | name     | mysql |
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
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-without-annotations.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | kubernetes.io/gce-pd   |
    Then the step should succeed
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
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
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-without-annotations.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | kubernetes.io/gce-pd   |
    Then the step should succeed
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-with-storageClassName.json" replacing paths:
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
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-without-annotations.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
      | ["provisioner"]      | kubernetes.io/gce-pd   |
    Then the step should succeed
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
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
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-without-annotations.yaml" where:
      | ["metadata"]["name"] | sc1-<%= project.name %> |
      | ["provisioner"]      | kubernetes.io/gce-pd    |
    Then the step should succeed
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-without-annotations.yaml" where:
      | ["metadata"]["name"] | sc2-<%= project.name %> |
      | ["provisioner"]      | kubernetes.io/gce-pd    |
    Then the step should succeed
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-storageClass.json" replacing paths:
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
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
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
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/dynamic-provisioning/storageclass.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/dynamic-provisioning/pvc.yaml" replacing paths:
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
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gce/storageClass.yaml" where:
      | ["metadata"]["name"]                                                       | sc-<%= project.name %>  |
      | ["provisioner"]                                                            | kubernetes.io/aws-ebs   |
      | ["parameters"]["type"]                                                     | gp2                     |
      | ["parameters"]["zone"]                                                     | us-east-1d              |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"] | true                    |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc-without-annotations.json" replacing paths:
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

    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/pv-rwo.yaml" where:
      | ["metadata"]["name"]                         | pv-<%= project.name %> |
      | ["spec"]["awsElasticBlockStore"]["volumeID"] | <%= cb.vid %>          |
    Then the step should succeed
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/ebs/pvc-retain.json" replacing paths:
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
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                       | sc-<%= project.name %>  |
      | ["provisioner"]                                                            | kubernetes.io/aws-ebs   |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"] | true                    |
    Then the step should succeed

    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                                                    | pvc-<%= project.name %> |
      | ["metadata"]["annotations"]["volume.alpha.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound
    And the expression should be true> pvc.storage_class == "sc-<%= project.name %>"
    And the expression should be true> pv(pvc.volume_name).storage_class_name == "sc-<%= project.name %>"

  # @author jhou@redhat.com
  @admin
  Scenario Outline: Configure 'Retain' reclaim policy for StorageClass
    Given I have a project
    And azure file dynamic provisioning is enabled in the project
    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-reclaim-policy.yaml" where:
      | ["metadata"]["name"]                                                       | sc-<%= project.name %>      |
      | ["provisioner"]                                                            | kubernetes.io/<provisioner> |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"] | false                       |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
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
      | azure-file     | # @case_id OCP-17276

  # @author jhou@redhat.com
  @admin
  Scenario Outline: Setting mountOptions for StorageClass
    Given I have a project
    And admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["mountOptions"] | ["discard"] |
    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod       |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc       |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/mypath |
    Then the step should succeed
    Given the pod named "mypod" becomes ready

    When I execute on the pod:
      | sh | -c | mount \| grep /mnt/mypath |
    Then the step should succeed
    And the output should contain:
      | discard |

    Examples:
      | keyword |
      | vsphere | # @case_id OCP-17224
      | gce     | # @case_id OCP-17259
      | ebs     | # @case_id OCP-17260
      | cinder  | # @case_id OCP-17258
      | azure   | # @case_id OCP-17490

  # @author chaoyang@redhat.com
  # @case_id OCP-17272
  @admin
  Scenario: Configure Retain reclaim policy for aws-efs
    Given I have a project
    And I have a efs-provisioner in the project

    When admin creates a StorageClass from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/storageClass-reclaim-policy.yaml" where:
      | ["apiVersion"]                                                             | storage.k8s.io/v1      |
      | ["metadata"]["name"]                                                       | sc-<%= project.name %> |
      | ["provisioner"]                                                            | openshift.org/aws-efs  |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"] | false                  |
    Then the step should succeed

    When I create a dynamic pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce           |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound within 120 seconds
    And the expression should be true> pv(pvc.volume_name).reclaim_policy == "Retain"

    When I ensure "pvc-<%= project.name %>" pvc is deleted
    Then the PV becomes :released
    And admin ensures "<%= pvc.volume_name %>" pv is deleted

  # @author lxia@redhat.com
  # @case_id OCP-18650
  Scenario: Make sure storage.k8s.io/v1beta1 API is enabled in 3.10
    When I perform the HTTP request:
    """
    :url: <%= env.api_endpoint_url %>/apis/storage.k8s.io
    :method: GET
    """
    Then the step should succeed
    And the output should contain:
      | storage.k8s.io/v1beta1 |

  # @author lxia@redhat.com
  # @case_id OCP-19886
  @admin
  Scenario: Display allowVolumeExpansion field in oc describe storage class
    Given the master version >= "3.11"
    Given a 5 characters random string of type :dns is stored into the :sc_name clipboard
    And admin clones storage class "sc1-<%= cb.sc_name %>" from ":default" with:
      | ["allowVolumeExpansion"] | false |
    And admin clones storage class "sc2-<%= cb.sc_name %>" from ":default" with:
      | ["allowVolumeExpansion"] | true |
    And admin clones storage class "sc3-<%= cb.sc_name %>" from ":default" with:
      | | |
    When I run the :describe client command with:
      | resource | storageclass          |
      | name     | sc1-<%= cb.sc_name %> |
      | name     | sc2-<%= cb.sc_name %> |
      | name     | sc3-<%= cb.sc_name %> |
    Then the step should succeed
    And the output by order should match:
      | sc1-<%= cb.sc_name %>         |
      | AllowVolumeExpansion:\s+False |
      | sc2-<%= cb.sc_name %>         |
      | AllowVolumeExpansion:\s+True  |
      | sc3-<%= cb.sc_name %>         |
      | AllowVolumeExpansion:\s+      |


  # @author lxia@redhat.com
  # @case_id OCP-23987
  Scenario: Check the detail of default storage class
    When I run the :get client command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should contain:
      #| mountOptions:               |
      #| parameters:                 |
      | provisioner: kubernetes.io/ |
      | reclaimPolicy: Delete       |
    And the output should match:
      | kubernetes.io/(aws-ebs\|gce-pd\|vsphere-volume\|cinder\|azure-disk) |
      | volumeBindingMode:\s+(Immediate\|WaitForFirstConsumer)              |
    When I run the :describe client command with:
      | resource | storageclass |
    Then the step should succeed
    And the output should contain:
      | MountOptions: |
      | Parameters:   |
      | Provisioner:  |
    And the output should match:
      | AllowVolumeExpansion:                                               |
      | IsDefaultClass:\s+(Yes\|No)                                         |
      | kubernetes.io/(aws-ebs\|gce-pd\|vsphere-volume\|cinder\|azure-disk) |
      | ReclaimPolicy:\s+Delete                                             |
      | VolumeBindingMode:\s+(Immediate\|WaitForFirstConsumer)              |

  # @author lxia@redhat.com
  # @case_id OCP-22018
  @admin
  @destructive
  Scenario: Admin can change default storage class to non-default
    When I run the :get client command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should contain 1 times:
      | is-default-class: "true" |
    Given default storage class is patched to non-default
    When I run the :get client command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should not contain:
      | is-default-class: "true" |
