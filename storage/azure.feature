Feature: Azure disk and Azure file specific scenarios

  # @author wehe@redhat.com
  # @author wduan@redhat.com
  @admin
  Scenario Outline: azureDisk volume with readwrite/readonly cachingmode and xfs fstype
    Given I have a project
    When admin clones storage class "sc-<%= project.name %>" from ":default" with:
      | ["parameters"]["cachingMode"] | <cachingMode> |
      | ["parameters"]["fsType"]      | xfs           |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc-storageClass.json"
    When I create a dynamic pvc from "pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc                   |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod      |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc      |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/azure |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound within 120 seconds
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | rm | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    # Verify PV with correct cachingMode and fsType
    When I run the :get admin command with:
      | resource      | pv                     |
      | resource_name | <%= pvc.volume_name %> |
      | o             | yaml                   |
    Then the output should contain:
      | cachingMode: <cachingMode>             |
      | fsType: xfs                            |

    Examples:
      | cachingMode |
      | ReadOnly    | # @case_id OCP-10204
      | ReadWrite   | # @case_id OCP-10205

  # @author wduan@redhat.com
  # @case_id OCP-10200
  @admin
  Scenario: azureDisk volume with RWO access mode and Delete policy
    Given I have a project
    Given I obtain test data file "storage/azure/azsc-NOPAR.yaml"
    When admin creates a StorageClass from "azsc-NOPAR.yaml" where:
      | ["metadata"]["name"]  | sc-<%= project.name %> |
      | ["volumeBindingMode"] | WaitForFirstConsumer   |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod      |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc      |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/azure |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound within 120 seconds
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | rm | /mnt/azure/ad-<%= project.name %> |
    Given I ensure "mypod" pod is deleted
    And I ensure "mypvc" pvc is deleted
    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 1200 seconds


  # @author wduan@redhat.com
  # @case_id OCP-16498
  @admin
  Scenario: Azure file persistent volume parameters negative test
    Given I have a project
    And azure file dynamic provisioning is enabled in the project
    And the azure file secret name and key are stored to the clipboard
    Given I obtain test data file "storage/azure-file/azf-pv.yml"
    When admin creates a PV from "azf-pv.yml" where:
      | ["metadata"]["name"]                | pv-<%= project.name %> |
      | ["spec"]["azureFile"]["secretName"] | <%= cb.secretName %>   |
      | ["spec"]["azureFile"]["shareName"]  | noexist                |
      | ["spec"]["storageClassName"]        | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["accessModes"][0]   | ReadWriteMany          |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod      |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc      |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/azure |
    Then the step should succeed
    And the pod named "mypod" status becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod   |
      | name     | mypod |
    Then the output should contain:
      | FailedMount               |
      | No such file or directory |
    """

  # @author wduan@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-10174
  @admin
  Scenario: Azure file with secretNamespace parameter of different project
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    And azure file dynamic provisioning is enabled in the project
    And the azure file secret name and key are stored to the clipboard
    Given I create a new project
    Given I obtain test data file "storage/azure-file/azf-pv.yml"
    When admin creates a PV from "azf-pv.yml" where:
      | ["metadata"]["name"]                     | pv-<%= project.name %> |
      | ["spec"]["azureFile"]["secretName"]      | <%= cb.secretName %>   |
      | ["spec"]["azureFile"]["shareName"]       | <%= cb.shareName %>    |
      | ["spec"]["storageClassName"]             | sc-<%= project.name %> |
      | ["spec"]["azureFile"]["secretNamespace"] | <%= cb.proj1 %>        |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["accessModes"][0]   | ReadWriteMany          |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod      |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc      |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/azure |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/af-<%= project.name %> |
    Then the step should succeed

  # @author wduan@redhat.com
  # @author lxia@redhat.com
  # @case_id OCP-14526
  @admin
  Scenario: Azure file with secretNamespace parameter of current project
    Given I have a project
    And azure file dynamic provisioning is enabled in the project
    And the azure file secret name and key are stored to the clipboard
    Given I obtain test data file "storage/azure-file/azf-pv.yml"
    When admin creates a PV from "azf-pv.yml" where:
      | ["metadata"]["name"]                | pv-<%= project.name %> |
      | ["spec"]["azureFile"]["secretName"] | <%= cb.secretName %>   |
      | ["spec"]["azureFile"]["shareName"]  | <%= cb.shareName %>    |
      | ["spec"]["storageClassName"]        | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["accessModes"][0]   | ReadWriteMany          |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod      |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc      |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/azure |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/af-<%= project.name %> |
    Then the step should succeed

  # @author wduan@redhat.com
  @admin
  Scenario Outline: azureFile dynamic provisioning with storage class
    Given I have a project
    And azure file dynamic provisioning is enabled in the project
    Given I obtain test data file "storage/azure-file/azfsc-<sctype>.yaml"
    When admin creates a StorageClass from "azfsc-<sctype>.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I run oc create over "pvc.json" replacing paths:
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["accessModes"][0]   | ReadWriteMany          |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound within 120 seconds
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod      |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc      |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/azure |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound within 120 seconds
    Given the pod named "mypod" becomes ready
    When admin executes on the pod:
      | touch | /mnt/azure/af-<%= project.name %> |
    Then the step should succeed
    When admin executes on the pod:
      | ls | /mnt/azure/af-<%= project.name %> |
    Then the step should succeed
    When admin executes on the pod:
      | rm | /mnt/azure/af-<%= project.name %> |
    Then the step should succeed

    Examples:
      | sctype |
      | NOPAR  | # @case_id OCP-10203
      | MODIR  | # @case_id OCP-13689
      | MOUID  | # @case_id OCP-15852


  # @author wduan@redhat.com
  @admin
  Scenario Outline: AzureDisk dynamic provisioning with managed storage class for storageaccounttype in OCP4.x
    Given I have a project
    Given I obtain test data file "storage/azure/azsc-MANAGED.yaml"
    When admin creates a StorageClass from "azsc-MANAGED.yaml" where:
      | ["metadata"]["name"]                 | sc-<%= project.name %> |
      | ["parameters"]["storageaccounttype"] | <storageaccounttype>   |
      | ["volumeBindingMode"]                | WaitForFirstConsumer   |
      | ["reclaimPolicy"]                    | Delete                 |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc-storageClass.json"
    When I create a dynamic pvc from "pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi   |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/azure |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound within 120 seconds
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | rm | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    Given I ensure "mypod" pod is deleted
    And I ensure "mypvc" pvc is deleted
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 300 seconds

    Examples:
      | storageaccounttype |
      | Standard_LRS       |    # @case_id OCP-26094
      | Premium_LRS        |    # @case_id OCP-26095
      | StandardSSD_LRS    |    # @case_id OCP-26096


  # @author wduan@redhat.com
  # @case_id OCP-26172
  @admin
  Scenario: AzureDisk dynamic provisioning with managed storage class for resourceGroup
    Given I have a project
    And I have a 1 GB volume from provisioner "azure-disk" and save volume id in the :vid clipboard
    Given I obtain test data file "storage/azure/azsc-MANAGED.yaml"
    When admin creates a StorageClass from "azsc-MANAGED.yaml" where:
      | ["metadata"]["name"]            | sc-<%= project.name %>      |
      | ["parameters"]["resourceGroup"] | <%= cb.vid.split("/")[4] %> |
      | ["volumeBindingMode"]           | WaitForFirstConsumer        |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]            | mypvc                  |
      | ["spec"]["storageClassName"]    | sc-<%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod      |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc      |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/azure |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound within 120 seconds
    Given the pod named "mypod" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | rm | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed

  # @author wduan@redhat.com
  # @case_id OCP-26173
  @admin
  Scenario: AzureDisk dynamic provisioning with managed storage class for invalid resourceGroup
    Given I have a project
    Given I obtain test data file "storage/azure/azsc-MANAGED.yaml"
    When admin creates a StorageClass from "azsc-MANAGED.yaml" where:
      | ["metadata"]["name"]            | sc-<%= project.name %> |
      | ["parameters"]["resourceGroup"] | invalid                |
      | ["volumeBindingMode"]           | Immediate              |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pvc   |
      | name     | mypvc |
    Then the output should match:
      | ProvisioningFailed  |
      | AuthorizationFailed |
    And the "mypvc" PVC status is :pending

  # @author wduan@redhat.com
  # @case_id OCP-26785
  @admin
  Scenario: Check azure-file dependencies cifs-utils on the node
    Given I store the schedulable nodes in the :nodes clipboard
    Given I repeat the following steps for each :node in cb.nodes:
    """
    And I use the "#{cb.node.name}" node
    When I run commands on the host:
      | rpm -qa \| grep -i cifs-utils |
    Then the step should succeed
    And the output should contain "cifs-utils"
    """

  # @author wduan@redhat.com
  # @case_id OCP-19192
  @admin
  Scenario: Azure file can not dynamic provision block volume
    Given I have a project
    And azure file dynamic provisioning is enabled in the project
    Given I obtain test data file "storage/azure-file/azfsc-NOPAR.yaml"
    When admin creates a StorageClass from "azfsc-NOPAR.yaml" where:
      | ["metadata"]["name"]  | sc-<%= project.name %> |
      | ["volumeBindingMode"] | Immediate              |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc.json"
    When I run oc create over "pvc.json" replacing paths:
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["volumeMode"]       | Block                  |
    Then the step should succeed
    And the "mypvc" PVC becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc   |
      | name     | mypvc |
    Then the output should match:
      | ProvisioningFailed                                                    |
      | Failed to provision volume with StorageClass "sc-<%= project.name %>" |
      | does not support block volume provisioning                            |
    """

