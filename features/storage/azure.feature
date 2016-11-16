Feature: Azure disk specific scenarios

  # @author wehe@redhat.com
  # @case_id 533904 533905 533844
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
  # @case_id 533906
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
  # @case_id 533797 
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
