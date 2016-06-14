Feature: Cinder Persistent Volume
  # @author wehe@redhat.com
  # @case_id 508144
  @admin
  Scenario: Persistent Volume with cinder volume plugin
    Given I have a project

    #Create a dynamic volume to obtain the volume id
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/misc/pvc.json" replacing paths:
      | ["metadata"]["name"]                         | cinder-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                        |
    Then the step should succeed
    Given the "cinder-<%= project.name %>" PVC becomes :bound

    When I run the :get admin command with:
      | resource      | pv                                                |
      | resource_name | <%= pvc.volume_name(user: admin, cached: true) %> |
      | o             | yaml                                              |
    Then the step should succeed
    Given the output is parsed as YAML
    And evaluation of `@result[:parsed]['spec']['cinder']['volumeID']` is stored in the :vid clipboard

    #create test pod
    And I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/cinder/cinder-pod.yaml" replacing paths:
      | ['spec']['volumes'][0]['cinder']['volumeID'] | <%= cb.vid %> | 
    Then the step should succeed
    And the pod named "cinder" becomes ready
    
    #create test file
    Given I execute on the "cinder" pod:
      | touch | /mnt/cinderfile |
    Then the step should succeed
    When I execute on the "cinder" pod:
      | ls | -l | /mnt/cinderfile |
    Then the step should succeed
