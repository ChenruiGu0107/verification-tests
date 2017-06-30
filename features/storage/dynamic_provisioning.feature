Feature: Dynamic provisioning
  # @author lxia@redhat.com
  # @case_id OCP-12665 OCP-9656 OCP-9685
  @admin
  Scenario Outline: dynamic provisioning
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>         |
      | node_selector | <%= cb.proj_name %>=dynamic |
      | admin         | <%= user.name %>            |
    Then the step should succeed

    Given I store the schedulable nodes in the :nodes clipboard
    And label "<%= cb.proj_name %>=dynamic" is added to the "<%= cb.nodes[0].name %>" node

    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | dynamic-pvc1-<%= project.name %> |
    Then the step should succeed
    And the "dynamic-pvc1-<%= project.name %>" PVC becomes :bound

    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain:
      | dynamic-pvc1-<%= project.name %> |

    When I get project pvc named "dynamic-pvc1-<%= project.name %>" as JSON
    Then the step should succeed
    And evaluation of `@result[:parsed]['spec']['volumeName']` is stored in the :pv_name1 clipboard

    And I save volume id from PV named "<%= cb.pv_name1 %>" in the :volumeID1 clipboard

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc1-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod1                           |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/<cloud_provider>            |
    Then the step should succeed
    And the pod named "mypod1" becomes ready
    When I execute on the pod:
      | touch | /mnt/<cloud_provider>/testfile_1 |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type | pod |
      | all         |     |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type | pvc |
      | all         |     |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    Then I wait for the resource "pv" named "<%= cb.pv_name1 %>" to disappear within 1200 seconds

    Given I use the "<%= cb.nodes[0].name %>" node
    When I run commands on the host:
      | mount |
    Then the step should succeed
    And the output should not contain:
      | <%= cb.pv_name1 %> |
      | <%= cb.volumeID1 %> |
    And I verify that the IAAS volume with id "<%= cb.volumeID1 %>" was deleted

    Examples:
      | cloud_provider |
      | cinder         |
      | ebs            |
      | gce            |

  # @author wehe@redhat.com
  # @case_id OCP-13787
  @admin
  Scenario: azure disk dynamic provisioning
    Given admin creates a project with a random schedulable node selector
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azsc-NOPAR.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed
    Given evaluation of `%w{ReadWriteOnce ReadWriteOnce ReadWriteOnce}` is stored in the :accessmodes clipboard
    And I run the steps 1 times:
    """
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc-sc.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | dpvc-#{cb.i}              |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>    |
      | ["spec"]["accessModes"][0]                                             | #{cb.accessmodes[cb.i-1]} |
      | ["spec"]["resources"]["requests"]["storage"]                           | #{cb.i}Gi                 |
    Then the step should succeed
    And the "dpvc-#{cb.i}" PVC becomes :bound within 120 seconds
    And I save volume id from PV named "#{ pvc.volume_name }" in the :disk clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvcpod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dpvc-#{cb.i} |
      | ["metadata"]["name"]                                         | mypod#{cb.i} |
    Then the step should succeed
    And the pod named "mypod#{cb.i}" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/testfile_#{cb.i} |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | pod |
      | all         |     |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | pvc |
      | all         |     |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    Then I wait for the resource "pv" named "#{ pvc.volume_name }" to disappear within 1200 seconds
    Given I use the "<%= node.name %>" node
    And I run commands on the host:
      | mount |
    And the output should not contain:
      | #{ pvc.volume_name }       |
      | #{cb.disk.split("/").last} |
    """

  # @author lxia@redhat.com
  # @case_id OCP-12667
  @admin
  Scenario: dynamic provisioning with multiple access modes
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | dynamic-pvc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                   | ReadWriteOnce                   |
      | ["spec"]["accessModes"][1]                   | ReadWriteMany                   |
      | ["spec"]["accessModes"][2]                   | ReadOnlyMany                    |
      | ["spec"]["resources"]["requests"]["storage"] | 1                               |
    Then the step should succeed
    And the "dynamic-pvc-<%= project.name %>" PVC becomes :bound

    When I run the :get admin command with:
      | resource      | pv                                                |
      | resource_name | <%= pvc.volume_name(user: admin, cached: true) %> |
    Then the step should succeed
    And the output should contain:
      | dynamic-pvc-<%= project.name %> |
      | Bound |
      | RWO |
      | ROX |
      | RWX |

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/gce/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | dynamic-pvc-<%= project.name %> |
      | ["metadata"]["name"]                                         | mypod-<%= project.name %>       |
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=frontendhttp |

    When I execute on the pod:
      | touch | /mnt/gce/testfile |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type | pod |
      | all         |     |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | pvc |
      | all         |     |
    Then the step should succeed

    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: admin, cached: true) %>" to disappear within 1200 seconds

  # @author wehe@redhat.com
  # @case_id OCP-13889
  @admin
  Scenario: azure disk dynamic provisioning with multiple access modes
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azsc-NOPAR.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc-sc.yaml" replacing paths:
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %> |
      | ["spec"]["accessModes"][0]                                             | ReadWriteOnce          |
      | ["spec"]["accessModes"][1]                                             | ReadWriteMany          |
      | ["spec"]["accessModes"][2]                                             | ReadOnlyMany           |
    Then the step should succeed
    And the "azpvc" PVC becomes :bound within 120 seconds
    When I run the :get admin command with:
      | resource      | pv                     |
      | resource_name | <%= pvc.volume_name %> |
    Then the step should succeed
    And the output should contain:
      | azpvc |
      | Bound |
      | RWO |
      | ROX |
      | RWX |
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvcpod.yaml |
      | n | <%= project.name %>                                                                                       |
    Then the step should succeed
    Given the pod named "azpvcpo" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/testfile |
    When I run the :delete client command with:
      | object_type | pod |
      | all         |     |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | pvc |
      | all         |     |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 1200 seconds

  # @author lxia@redhat.com
  # @case_id OCP-10790
  @admin
  Scenario: Check only one pv created for one pvc for dynamic provisioner
    Given I have a project
    And I run the steps 30 times:
    """
    When I run oc create over ERB URL: https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc-ERB.json
    Then the step should succeed
    """
    Given 30 PVCs become :bound within 600 seconds with labels:
      | name=dynamic-pvc-<%= project.name %> |
    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain 30 times:
      | <%= project.name %> |

  # @author wehe@redhat.com
  # @case_id OCP-10137 OCP-10138 OCP-10139
  @admin
  Scenario Outline: dynamic pvc shows lost after pv is deleted
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | dynamic-pvc1-<%= project.name %> |
    Then the step should succeed
    And the "dynamic-pvc1-<%= project.name %>" PVC becomes :bound

    When I run the :get admin command with:
      | resource | pv |
    Then the output should contain:
      | dynamic-pvc1-<%= project.name %> |

    When I get project pvc named "dynamic-pvc1-<%= project.name %>" as JSON
    Then the step should succeed

    Given admin ensures "<%= pvc("dynamic-pvc1-#{project.name}").volume_name(user: admin) %>" pv is deleted

    Then the "dynamic-pvc1-<%= project.name %>" PVC becomes :lost within 300 seconds

    Examples:
      | cloud_provider |
      | cinder         |
      | ebs            |
      | gce            |

  # @author wehe@redhat.com
  # @case_id OCP-13902
  @admin
  Scenario: azure disk dynamic pvc shows lost after pv is deleted
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azsc-NOPAR.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed
    Given evaluation of `%w{ReadWriteOnce ReadWriteOnce ReadWriteOnce}` is stored in the :accessmodes clipboard
    And I run the steps 1 times:
    """
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc-sc.yaml" replacing paths:
      | ["metadata"]["name"]                                                   | dpvc-#{cb.i}              |
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>    |
      | ["spec"]["accessModes"][0]                                             | #{cb.accessmodes[cb.i-1]} |
      | ["spec"]["resources"]["requests"]["storage"]                           | #{cb.i}Gi                 |
    Then the step should succeed
    And the "dpvc-#{cb.i}" PVC becomes :bound within 120 seconds
    Given admin ensures "#{ pvc.volume_name }" pv is deleted
    And the "dpvc-#{cb.i}" PVC becomes :lost within 300 seconds
    """

  # @author jhou@redhat.com
  @admin
  @destructive
  Scenario Outline: No volume and PV provisioned when provisioner is disabled
    Given I have a project
    And master config is merged with the following hash:
    """
    volumeConfig:
      dynamicProvisioningEnabled: False
    """
    And the master service is restarted on all master nodes
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | dynamic-pvc-<%= project.name %> |
    Then the step should succeed
    When 30 seconds have passed
    Then the "dynamic-pvc-<%= project.name %>" PVC status is :pending

    Examples:
      | provisioner |
      | aws-ebs     | # @case_id OCP-10360
      | gce-pd      | # @case_id OCP-10361
      | cinder      | # @case_id OCP-10362
      | azure-disk  | # @case_id OCP-13903

  # @author chaoyang@redhat.com
  # case_id OCP-13943
  @smoke
  Scenario: Dynamic provision smoke test
    Given I have a project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"] | pvc-<%= project.name %> |
    Then the step should succeed
    And the "pvc-<%= project.name %>" PVC becomes :bound

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
    When I execute on the pod:
      | cp | /hello | /mnt/iaas/ |
    Then the step should succeed
    When I execute on the pod:
      | /mnt/iaas/hello |
    Then the step should succeed
    And the output should contain "Hello OpenShift Storage"
