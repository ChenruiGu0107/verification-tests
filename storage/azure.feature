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
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc                   |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
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

  # @author wehe@redhat.com
  # @case_id OCP-10206
  @admin
  Scenario: azureDisk volume with readwrite cachingmode and readonly filesystem
    Given I have a project
    And I have a 1 GB volume from provisioner "azure-disk" and save volume id in the :vid clipboard
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azrwro-pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["azureDisk"]["diskName"] | <%= cb.vid.split("/").last %> |
      | ["spec"]["volumes"][0]["azureDisk"]["diskURI"]  | <%= cb.vid %>                 |
    Then the step should succeed
    Given the pod named "azrwro" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should fail
    When I execute on the pod:
      | ls | /mnt/azure/ |
    Then the output should not contain "ad-<%= project.name %>"

  # @author wehe@redhat.com
  # @case_id OCP-10198
  @admin
  @destructive
  Scenario: Persistent Volume with azureDisk volume plugin
    Given I have a project
    And I have a 1 GB volume from provisioner "azure-disk" and save volume id in the :vid clipboard
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azpv.yaml" where:
      | ["metadata"]["name"]              | ad-<%= project.name %>        |
      | ["spec"]["azureDisk"]["diskName"] | <%= cb.vid.split("/").last %> |
      | ["spec"]["azureDisk"]["diskURI"]  | <%= cb.vid %>                 |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azpvc.yaml" replacing paths:
      | ["metadata"]["name"] | azpvc |
    Then the step should succeed
    Given the "azpvc" PVC becomes bound to the "ad-<%= project.name %>" PV
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | azpvcpo    |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | azpvc      |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/azure |
    Then the step should succeed
    Given the pod named "azpvcpo" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | rm | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed

  # @author wehe@redhat.com
  @admin
  Scenario Outline: azureDisk dynamic provisioning with storage class
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azsc-<sctype>.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azpvc-sc.yaml" replacing paths:
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "azpvc" PVC becomes :bound within 120 seconds
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | azpvcpo    |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | azpvc      |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/azure |
    Then the step should succeed
    Given the pod named "azpvcpo" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | rm | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    Given I ensure "azpvcpo" pod is deleted
    And I ensure "azpvc" pvc is deleted
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 300 seconds

    Examples:
      | sctype   |
      | LRS      | # @case_id OCP-10254
      | GRS      | # @case_id OCP-10256 
      | RAGRS    | # @case_id OCP-10257
      | PLRS     | # @case_id OCP-10255
      | NOPAR    | # @case_id OCP-10413
      | COMBSL   | # @case_id OCP-10258
      | IGNOR    | # @case_id OCP-10262
      | LCONLY   | # @case_id OCP-10259
      | ACONLY   | # @case_id OCP-13330
      | DEACCT   | # @case_id OCP-14681
      | DEDICATE | # @case_id OCP-13785
      | SKUACCT  | # @case_id OCP-14675
      | DESKU    | # @case_id OCP-18293


  # @author wduan@redhat.com
  # @case_id OCP-10200
  @admin
  Scenario: azureDisk volume with RWO access mode and Delete policy
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azsc-NOPAR.yaml" where:
      | ["metadata"]["name"]  | sc-<%= project.name %> |
      | ["volumeBindingMode"] | WaitForFirstConsumer   |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
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


  # @author wehe@redhat.com
  @admin
  Scenario Outline: Negative test of azureDisk with storage class
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azsc-<sctype>.yaml" where:
      | ["metadata"]["name"]   | sc-<%= project.name %> |
      | ["parameters"]["kind"] | Dedicated              |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azpvc-sc.yaml" replacing paths:
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "azpvc" PVC becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/azpvc |
    Then the output should contain:
      | ProvisioningFailed |
      | Failed to provision volume with StorageClass "sc-<%= project.name %>" |
      | could not get storage key for storage account |
    """

    Examples:
      | sctype  |
      | invalid | # @case_id OCP-10260 
      | noext   | # @case_id OCP-10407 

  # @author wehe@redhat.com
  # @case_id OCP-13486
  @admin
  @destructive
  Scenario: pre-bound still works with storage class on Azure
    Given I have a project
    And I have a 1 GB volume from provisioner "azure-disk" and save volume id in the :vid clipboard
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azpv.yaml" where:
      | ["metadata"]["name"]              | pv-<%= project.name %>        |
      | ["spec"]["azureDisk"]["diskName"] | <%= cb.vid.split("/").last %> |
      | ["spec"]["azureDisk"]["diskURI"]  | <%= cb.vid %>                 |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                       | sc-<%= project.name %>   |
      | ["provisioner"]                                                            | kubernetes.io/azure-disk |
      | ["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"] | true                     |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azpvc.yaml" replacing paths:
      | ["spec"]["volumeName"] | pv-<%= project.name %>  |
    Then the step should succeed
    And the "azpvc" PVC becomes bound to the "pv-<%= project.name %>" PV

  # @author wehe@redhat.com
  # @case_id OCP-13981
  @admin
  @destructive
  Scenario: Azure disk should be detached and attached again for scale down and up
    Given I have a project
    And environment has at least 2 schedulable nodes
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azsc-NOPAR.yaml" where:
      | ["metadata"]["name"]      | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azpvc-sc.yaml" replacing paths:
      | ["spec"]["storageClassName"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "azpvc" PVC becomes :bound within 120 seconds
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/dc.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=hello-openshift |
    And evaluation of `pod.node_name` is stored in the :pod_node clipboard
    When I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | hello-openshift  |
      | replicas | 0                |
    Then the step should succeed
    Given all existing pods die with labels:
      | run=hello-openshift |
    Given node schedulable status should be restored after scenario
    When I run the :oadm_cordon_node admin command with:
      | node_name | <%= pod.node_name %> |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | deploymentconfig |
      | name     | hello-openshift  |
      | replicas | 1                |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=hello-openshift |
    And the expression should be true> pod.node_name != cb.pod_node

  # @author wehe@redhat.com
  # @case_id OCP-13942
  @admin
  Scenario: Azure disk should work after a bad disk is requested
    Given I have a project
    And I have a 1 GB volume from provisioner "azure-disk" and save volume id in the :vid clipboard
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azcaro-pod.yaml" replacing paths:
      | ["metadata"]["name"]                            | baddiskpod                                             |
      | ["spec"]["volumes"][0]["azureDisk"]["diskName"] | noneexist.vhd                                          |
      | ["spec"]["volumes"][0]["azureDisk"]["diskURI"]  | <%= cb.vid.split("vhds").first+"vhds/noneexist.vhd" %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azcaro-pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["azureDisk"]["diskName"] | <%= cb.vid.split("/").last %> |
      | ["spec"]["volumes"][0]["azureDisk"]["diskURI"]  | <%= cb.vid %>                 |
    Then the step should succeed
    Given the pod named "azcaro" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | rm | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed

  # @author wehe@redhat.com
  # @case_id OCP-16399
  @admin
  Scenario: Azure file persistent volume plugin test
    Given I have a project
    And azure file dynamic provisioning is enabled in the project
    And the azure file secret name and key are stored to the clipboard
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure-file/azf-pv.yml" where:
      | ["metadata"]["name"] | azpv-<%= project.name %> |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azpvc.yaml" replacing paths:
      | ["spec"]["accessModes"][0] | ReadWriteMany |
    Then the step should succeed
    Given the "azpvc" PVC becomes bound to the "azpv-<%= project.name %>" PV
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure-file/azfpvcpod.yaml | 
      | n | <%= project.name %>                                                                                  |
    Then the step should succeed
    Given the pod named "azfpod" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/af-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/azure/af-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | rm | /mnt/azure/af-<%= project.name %> |
    Then the step should succeed

  # @author wehe@redhat.com
  # @case_id OCP-16498
  @admin
  Scenario: Azure file persistent volume parameters negative test 
    Given I have a project
    And azure file dynamic provisioning is enabled in the project
    And the azure file secret name and key are stored to the clipboard
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure-file/azf-pv.yml" where:
      | ["metadata"]["name"]               | azpv-<%= project.name %> |
      | ["spec"]["azureFile"]["shareName"] | azfnoexist               |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azpvc.yaml" replacing paths:
      | ["spec"]["accessModes"][0] | ReadWriteMany |
    Then the step should succeed
    Given the "azpvc" PVC becomes bound to the "azpv-<%= project.name %>" PV
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure-file/azfpvcpod.yaml | 
      | n | <%= project.name %>                                                                                             |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod/azfpod |
    Then the output should contain:
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
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure-file/azf-pv.yml" where:
      | ["metadata"]["name"]                     | pv-<%= project.name %> |
      | ["spec"]["azureFile"]["secretName"]      | <%= cb.secretName %>   |
      | ["spec"]["azureFile"]["shareName"]       | <%= cb.shareName %>    |
      | ["spec"]["storageClassName"]             | sc-<%= project.name %> |
      | ["spec"]["azureFile"]["secretNamespace"] | <%= cb.proj1 %>        |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["accessModes"][0]   | ReadWriteMany          |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
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
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure-file/azf-pv.yml" where:
      | ["metadata"]["name"]                | pv-<%= project.name %> |
      | ["spec"]["azureFile"]["secretName"] | <%= cb.secretName %>   |
      | ["spec"]["azureFile"]["shareName"]  | <%= cb.shareName %>    |
      | ["spec"]["storageClassName"]        | sc-<%= project.name %> |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["accessModes"][0]   | ReadWriteMany          |
    Then the step should succeed
    And the "mypvc" PVC becomes bound to the "pv-<%= project.name %>" PV
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
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
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure-file/azfsc-<sctype>.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["spec"]["storageClassName"] | sc-<%= project.name %> |
      | ["metadata"]["name"]         | mypvc                  |
      | ["spec"]["accessModes"][0]   | ReadWriteMany          |
    Then the step should succeed
    And the "mypvc" PVC becomes :bound within 120 seconds
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
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
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azsc-MANAGED.yaml" where:
      | ["metadata"]["name"]                 | sc-<%= project.name %> |
      | ["parameters"]["storageaccounttype"] | <storageaccounttype>   |
      | ["volumeBindingMode"]                | WaitForFirstConsumer   |
      | ["reclaimPolicy"]                    | Delete                 |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc-storageClass.json" replacing paths:
      | ["metadata"]["name"]                         | mypvc |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi   |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
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
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azsc-MANAGED.yaml" where:
      | ["metadata"]["name"]            | sc-<%= project.name %>      |
      | ["parameters"]["resourceGroup"] | <%= cb.vid.split("/")[4] %> |
      | ["volumeBindingMode"]           | WaitForFirstConsumer        |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]            | mypvc                  |
      | ["spec"]["storageClassName"]    | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pod.yaml" replacing paths:
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
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure/azsc-MANAGED.yaml" where:
      | ["metadata"]["name"]            | sc-<%= project.name %> |
      | ["parameters"]["resourceGroup"] | invalid                |
      | ["volumeBindingMode"]           | Immediate              |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
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
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/azure-file/azfsc-NOPAR.yaml" where:
      | ["metadata"]["name"]  | sc-<%= project.name %> |
      | ["volumeBindingMode"] | Immediate              |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc.json" replacing paths:
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

