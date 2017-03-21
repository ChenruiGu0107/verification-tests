Feature: Azure disk specific scenarios

  # @author wehe@redhat.com
  # @case_id OCP-10204 OCP-10205 OCP-10203
  @admin
  Scenario Outline: azureDisk volume with readwrite/readonly cachingmode and xfs fstype 
    Given I have a project
    Then I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/<azpodname>-pod.yaml | 
      | n | <%= project.name %>                                                                                              |
    Then the step should succeed
    Given the pod named "<azpodname>" becomes ready
    When admin executes on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When admin executes on the pod:
      | ls | /mnt/azure/ad-<%= project.name %> | 
    Then the step should succeed
    When admin executes on the pod:
      | rm | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed

    Examples:
      | azpodname |
      | azcaro    |
      | azrarw    |
      | azxfs     |
      
  # @author wehe@redhat.com
  # @case_id OCP-10206
  @admin
  Scenario: azureDisk volume with readwrite cachingmode and readonly filesystem 
    Given I have a project
    Then I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azrwro-pod.yaml | 
      | n | <%= project.name %>                                                                                         |
    Then the step should succeed
    Given the pod named "azrwro" becomes ready
    When admin executes on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should fail
    When admin executes on the pod:
      | ls | /mnt/azure/ | 
    Then the output should not contain "ad-<%= project.name %>" 

  # @author wehe@redhat.com
  # @case_id OCP-10198
  @admin
  @destructive
  Scenario: Persistent Volume with azureDisk volume plugin  
    Given I have a project
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpv.yaml" where:
      | ["metadata"]["name"] | ad-<%= project.name %> |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc.yaml | 
    Then the step should succeed
    Given the "azpvc" PVC becomes bound to the "ad-<%= project.name %>" PV
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvcpod.yaml | 
      | n | <%= project.name %>                                                                                       |
    Then the step should succeed
    Given the pod named "azpvcpo" becomes ready
    When admin executes on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When admin executes on the pod:
      | ls | /mnt/azure/ad-<%= project.name %> | 
    Then the step should succeed
    When admin executes on the pod:
      | rm | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed

  # @author wehe@redhat.com
  # @case_id OCP-10254 OCP-10255 OCP-10256 OCP-10257 OCP-10258 OCP-10259 OCP-10262 OCP-10413 OCP-13330 
  @admin
  Scenario Outline: azureDisk dynamic provisioning with storage class
    Given I have a project
    When admin creates a StorageClass from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azsc-<sctype>.yaml" where:
      | ["metadata"]["name"]      | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/weherdh/v3-testfiles/azsc/persistent-volumes/azure/azpvc-sc.yaml" replacing paths:
      | ["metadata"]["annotations"]["volume.beta.kubernetes.io/storage-class"] | sc-<%= project.name %>  |
    Then the step should succeed
    And the "azpvc" PVC becomes :bound within 120 seconds
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvcpod.yaml | 
      | n | <%= project.name %>                                                                                       |
    Then the step should succeed
    Given the pod named "azpvcpo" becomes ready
    When admin executes on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When admin executes on the pod:
      | ls | /mnt/azure/ad-<%= project.name %> | 
    Then the step should succeed
    When admin executes on the pod:
      | rm | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    Given I ensure "azpvcpo" pod is deleted
    And I ensure "azpvc" pvc is deleted
    And I switch to cluster admin pseudo user
    And I wait for the resource "pv" named "<%= pvc.volume_name(user: user) %>" to disappear within 300 seconds

    Examples:
      | sctype |
      | LRS    |
      | GRS    |
      | RAGRS  |
      | PLRS   |
      | NOPAR  |
      | COMBSL |
      | IGNOR  |
      | LCONLY |
      | ACONLY |

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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc.yaml | 
    Then the step should succeed
    Given the "azpvc" PVC becomes bound to the "ad-<%= project.name %>" PV
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvcpod.yaml | 
      | n | <%= project.name %>                                                                                       |
    Then the step should succeed
    Given the pod named "azpvcpo" becomes ready
    When admin executes on the pod:
      | touch | /mnt/azure/ad-<%= project.name %> |
    Then the step should succeed
    When admin executes on the pod:
      | ls | /mnt/azure/ad-<%= project.name %> | 
    Then the step should succeed
    When admin executes on the pod:
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
    When admin creates a StorageClass from "https://raw.githubusercontent.com/weherdh/v3-testfiles/azsc/persistent-volumes/azure/azsc-<sctype>.yaml" where:
      | ["metadata"]["name"] | sc-<%= project.name %> |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/weherdh/v3-testfiles/azsc/persistent-volumes/azure/azpvc-sc.yaml" replacing paths:
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
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/azure/azpvc.yaml" replacing paths:
      | ["spec"]["volumeName"] | pv-<%= project.name %>  |
    Then the step should succeed
    And the "azpvc" PVC becomes bound to the "pv-<%= project.name %>" PV
