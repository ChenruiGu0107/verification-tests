Feature: Azure disk and Azure file specific scenarios

  # @author wehe@redhat.com
  @admin
  Scenario Outline: azureDisk volume with readwrite/readonly cachingmode and xfs fstype
    Given I have a project
    And I have a 1 GB volume from provisioner "azure-disk" and save volume id in the :vid clipboard
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/<azpodname>-pod.yaml" replacing paths:
      | ["spec"]["volumes"][0]["azureDisk"]["diskName"] | <%= cb.vid.split("/").last %> |
      | ["spec"]["volumes"][0]["azureDisk"]["diskURI"]  | <%= cb.vid %>                 |
    Then the step should succeed
    Given the pod named "<azpodname>" becomes ready
    When I execute on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When I execute on the pod:
      | rm | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed

    Examples:
      | azpodname |
      | azcaro    | # @case_id OCP-10204
      | azrarw    | # @case_id OCP-10205

  # @author wehe@redhat.com
  # @case_id OCP-10206
  @admin
  Scenario: azureDisk volume with readwrite cachingmode and readonly filesystem
    Given I have a project
    And I have a 1 GB volume from provisioner "azure-disk" and save volume id in the :vid clipboard
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azrwro-pod.yaml" replacing paths:
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
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpv.yaml" where:
      | ["metadata"]["name"]              | ad-<%= project.name %>        |
      | ["spec"]["azureDisk"]["diskName"] | <%= cb.vid.split("/").last %> |
      | ["spec"]["azureDisk"]["diskURI"]  | <%= cb.vid %>                 |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc.yaml" replacing paths:
      | ["metadata"]["name"] | azpvc |
    Then the step should succeed
    Given the "azpvc" PVC becomes bound to the "ad-<%= project.name %>" PV
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
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
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azsc-<sctype>.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc-sc.yaml" replacing paths:
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "azpvc" PVC becomes :bound within 120 seconds
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
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

  # @author wehe@redhat.com
  # @case_id OCP-10200
  @admin
  @destructive
  Scenario: azureDisk volume with RWO access mode and Delete policy
    Given I have a project
    And I have a 1 GB volume from provisioner "azure-disk" and save volume id in the :vid clipboard
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvdelete.yaml" where:
      | ["metadata"]["name"]              | ad-<%= project.name %>        |
      | ["spec"]["azureDisk"]["diskName"] | <%= cb.vid.split("/").last %> |
      | ["spec"]["azureDisk"]["diskURI"]  | <%= cb.vid %>                 |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc.yaml" replacing paths:
      | ["metadata"]["name"] | azpvc |
    Then the step should succeed
    Given the "azpvc" PVC becomes bound to the "ad-<%= project.name %>" PV
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pod.yaml" replacing paths:
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
    Given I ensure "azpvcpo" pod is deleted
    And I ensure "azpvc" pvc is deleted
    Given I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pv.name %>" to disappear within 1200 seconds

  # @author wehe@redhat.com
  # @case_id OCP-10260 OCP-10407
  @admin
  Scenario Outline: Negative test of azureDisk with storage class
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azsc-<sctype>.yaml" where:
      | ["metadata"]["name"]   | sc-<%= project.name %> |
      | ["parameters"]["kind"] | Dedicated              |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc-sc.yaml" replacing paths:
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "azpvc" PVC becomes :pending
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pvc/azpvc |
    Then the output should contain:
      | ProvisioningFailed |
      | Failed to provision volume with StorageClass "sc-<%= project.name %>" |
      | failed to find a matching storage account |
    """

    Examples:
      | sctype  |
      | invalid |
      | noext   |

  # @author wehe@redhat.com
  # @case_id OCP-13486
  @admin
  @destructive
  Scenario: pre-bound still works with storage class on Azure
    Given I have a project
    And I have a 1 GB volume from provisioner "azure-disk" and save volume id in the :vid clipboard
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpv.yaml" where:
      | ["metadata"]["name"]              | pv-<%= project.name %>        |
      | ["spec"]["azureDisk"]["diskName"] | <%= cb.vid.split("/").last %> |
      | ["spec"]["azureDisk"]["diskURI"]  | <%= cb.vid %>                 |
    Then the step should succeed
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/storageClass.yaml" where:
      | ["metadata"]["name"]                                                            | sc-<%= project.name %>   |
      | ["provisioner"]                                                                 | kubernetes.io/azure-disk |
      | ["metadata"]["annotations"]["storageclass.beta.kubernetes.io/is-default-class"] | true                     |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc.yaml" replacing paths:
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
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azsc-NOPAR.yaml" where:
      | ["metadata"]["name"]      | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc-sc.yaml" replacing paths:
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "azpvc" PVC becomes :bound within 120 seconds
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/dc.yaml |
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
    When I run the :oadm_manage_node admin command with:
      | node_name   | <%= pod.node_name %> |
      | schedulable | false                |
    Then the step should succeed
    Given I register clean-up steps:
    """
    I run the :oadm_manage_node admin command with:
      | node_name   | <%= cb.pod_node %> |
      | schedulable | true               |
    the step should succeed
    """
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
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azcaro-pod.yaml" replacing paths:
      | ["metadata"]["name"]                            | baddiskpod                                             |
      | ["spec"]["volumes"][0]["azureDisk"]["diskName"] | noneexist.vhd                                          |
      | ["spec"]["volumes"][0]["azureDisk"]["diskURI"]  | <%= cb.vid.split("vhds").first+"vhds/noneexist.vhd" %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azcaro-pod.yaml" replacing paths:
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
    And the azure file secret name and key are stored to the clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azure-secret.yaml" replacing paths:
      | ["data"]["azurestorageaccountname"] | <%= cb.asan %> |
      | ["data"]["azurestorageaccountkey"]  | <%= cb.asak %> |
    Then the step should succeed
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azf-pv.yml" where:
      | ["metadata"]["name"] | azpv-<%= project.name %> |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc.yaml" replacing paths:
      | ["spec"]["accessModes"][0] | ReadWriteMany |
    Then the step should succeed
    Given the "azpvc" PVC becomes bound to the "azpv-<%= project.name %>" PV
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azfpvcpod.yaml | 
      | n | <%= project.name %>                                                                                             |
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
    And the azure file secret name and key are stored to the clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azure-secret.yaml" replacing paths:
      | ["data"]["azurestorageaccountname"] | <%= cb.asan %> |
      | ["data"]["azurestorageaccountkey"]  | <%= cb.asak %> |
    Then the step should succeed
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azf-pv.yml" where:
      | ["metadata"]["name"]               | azpv-<%= project.name %> |
      | ["spec"]["azureFile"]["shareName"] | azfnoexist               |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc.yaml" replacing paths:
      | ["spec"]["accessModes"][0] | ReadWriteMany |
    Then the step should succeed
    Given the "azpvc" PVC becomes bound to the "azpv-<%= project.name %>" PV
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azfpvcpod.yaml | 
      | n | <%= project.name %>                                                                                             |
    Then the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pod/azfpod |
    Then the output should contain:
      | No such file or directory | 
    """

  # @author wehe@redhat.com
  # @case_id OCP-10174
  @admin
  Scenario: Azure file with secretNamespace parameter of different project
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    And the azure file secret name and key are stored to the clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azure-secret.yaml" replacing paths:
      | ["data"]["azurestorageaccountname"] | <%= cb.asan %> |
      | ["data"]["azurestorageaccountkey"]  | <%= cb.asak %> |
    Then the step should succeed
    Given I create a new project
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azf-pv.yml" where:
      | ["metadata"]["name"]                     | azpv-<%= project.name %> |
      | ["spec"]["azureFile"]["secretNamespace"] | <%= cb.proj1 %>          |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc.yaml" replacing paths:
      | ["spec"]["accessModes"][0] | ReadWriteMany |
    Then the step should succeed
    Given the "azpvc" PVC becomes bound to the "azpv-<%= project.name %>" PV
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azfpvcpod.yaml | 
      | n | <%= project.name %>                                                                                             |
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
  # @case_id OCP-14526
  @admin
  Scenario: Azure file with secretNamespace parameter of current project 
    Given I have a project
    And the azure file secret name and key are stored to the clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azure-secret.yaml" replacing paths:
      | ["data"]["azurestorageaccountname"] | <%= cb.asan %> |
      | ["data"]["azurestorageaccountkey"]  | <%= cb.asak %> |
    Then the step should succeed
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azf-pv.yml" where:
      | ["metadata"]["name"]                     | azpv-<%= project.name %> |
      | ["spec"]["azureFile"]["secretNamespace"] | <%= project.name %>      |
    Then the step should succeed
    When I create a manual pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc.yaml" replacing paths:
      | ["spec"]["accessModes"][0] | ReadWriteMany |
    Then the step should succeed
    Given the "azpvc" PVC becomes bound to the "azpv-<%= project.name %>" PV
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azfpvcpod.yaml | 
      | n | <%= project.name %>                                                                                             |
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
  @admin
  Scenario Outline: azureFile dynamic provisioning with storage class
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azfsc-<sctype>.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/azfpvc-sc.yaml" replacing paths:
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %> |
    Then the step should succeed
    And the "azpvc" PVC becomes :bound within 120 seconds
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure-file/<podname>pod.yaml | 
      | n | <%= project.name %>                                                                                                |
    Then the step should succeed
    Given the pod named "azfpod" becomes ready
    When admin executes on the pod:
      | touch | /mnt/azure/af-<%= project.name %> |
    Then the step should succeed
    When admin executes on the pod:
      | ls | /mnt/azure/af-<%= project.name %> |
    Then the step should succeed
    When admin executes on the pod:
      | rm | /mnt/azure/af-<%= project.name %> |
    Then the step should succeed
    Given I ensure "azfpod" pod is deleted
    And I ensure "azpvc" pvc is deleted
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name %>" to disappear within 300 seconds

    Examples:
      | sctype | podname |
      | NOPAR  | azfpvc  | # @case_id OCP-10203
      | MODIR  | azpvc   | # @case_id OCP-13689
      | MOUID  | azpvc   | # @case_id OCP-15852
