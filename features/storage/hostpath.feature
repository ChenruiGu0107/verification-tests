Feature: Storage of Hostpath plugin testing

  # @author chaoyang@redhat.com
  # @case_id 508107
  @admin 
  Scenario: Create hostpath pv with RWO accessmode and Retain policy
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>                |
      | node_selector | testfor508107=<%= cb.proj_name %>  |
      | admin         | <%= user.name %>                   |
    Then the step should succeed
    And I switch to cluster admin pseudo user
    And I use the "<%= cb.proj_name %>" project 

    #Add label to the first node "testfor508107=<%= cb.proj_name %>"
    Given I store the schedulable nodes in the :nodes clipboard
    And I register clean-up steps:
      | I run the :label admin command with:   |
      | ! resource ! node                    ! |
      | ! name     ! <%= cb.nodes[0].name %> ! |
      | ! key_val  ! testfor508107-         ! |
      | the step should succeed                |
    When I run the :label admin command with:
      | resource  | node                              |
      | name      | <%= cb.nodes[0].name %>           |
      | key_val   | testfor508107=<%= cb.proj_name %> |
      | overwrite | true                              |
    Then the step should succeed

    #Create a dir on the first node
    Given I use the "<%= cb.nodes[0].name %>" node
    Given the "/etc/origin/hostpathtest" path is recursively removed on the host after scenario 
    Given I run commands on the host:
      | mkdir -p /etc/origin/hostpathtest     |
      | chmod -R 777 /etc/origin/hostpathtest |
    Then the step should succeed
   
    #Create PV with RWO accessmode and Retain Policy 
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/local-retain.yaml" where:
      | ["metadata"]["name"] | local-<%= cb.proj_name %>       |
      | ["spec"]["hostpath"] |  path: /etc/origin/hostpathtest |
    Then the step should succeed
    
    When I use the "<%= cb.proj_name %>" project  
    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/claim.yaml" replacing paths:
      | ["metadata"]["name"]   | localc-<%= cb.proj_name %> |
      | ["spec"]["volumeName"] | local-<%= cb.proj_name %>  |
    Then the step should succeed
    And the "localc-<%= cb.proj_name %>" PVC becomes bound to the "local-<%= cb.proj_name %>" PV
     
    Then I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/hostpath/pod.yaml" replacing paths:
      | ["metadata"]["name"]                                    | localpd-<%= cb.proj_name %> |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | localc-<%= cb.proj_name %> |
    Then the step should succeed
    
    Given the pod named "localpd-<%= cb.proj_name %>" becomes ready 
    When I execute on the pod:
      | touch | /mnt/local/test |
    Then the step should succeed
 
    When I run the :delete client command with:
      | object_type | pods |
      | object_name_or_id     | localpd-<%= cb.proj_name %> |
    Then the step should succeed

    Then I run the :delete client command with:
      | object_type | pvc |
      | object_name_or_id     | localc-<%= cb.proj_name %> |
    Then the step should succeed
    And the "local-<%= cb.proj_name %>" PV becomes :released
    
    Given I use the "<%= cb.nodes[0].name %>" node
    Given I run commands on the host:
      | ls | /etc/origin/hostpathtest |
    Then the outputs should contain:
      | test |
