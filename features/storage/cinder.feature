Feature: Cinder Persistent Volume
  # @author wehe@redhat.com
  # @case_id 508144
  @admin
  Scenario: Persistent Volume with cinder volume plugin
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard

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

  # @author wehe@redhat.com
  # @case_id 522393
  @admin
  Scenario: Create a cinder volume with RWO access mode and Delete policy
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard

    #Creat the pv using the volume id
    When admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/cinder/pv-rwo-delete.json" where:
      | ["metadata"]["name"]                      | cin-<%= project.name %> |
      | ['spec']['cinder']['volumeID']            | <%= cb.vid %>           |
    Then the step should succeed
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/cinder/pvc-rwo.json" replacing paths:
      | ["metadata"]["name"]                         | cpvc-<%= project.name %> |
      | ["spec"]["volumeName"]                       | cin-<%= project.name %>  |
    Then the step should succeed
    And the "cpvc-<%= project.name %>" PVC becomes bound to the "cin-<%= project.name %>" PV

    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/cinder/pod.json" replacing paths:
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | cpvc-<%= project.name %>  |
    Then the step should succeed
    Given the pod named "cinderpd" becomes ready
    When I execute on the pod:
      | touch | /mnt/cinder/cinderfile |
    Then the step should succeed

    When I run the :delete client command with:
      | object_type       | pod      |
      | object_name_or_id | cinderpd |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | pvc                      |
      | object_name_or_id | cpvc-<%= project.name %> |
    Then the step should succeed
    And I wait for the resource "pv" named "<%= pv.name %>" to disappear within 1800 seconds
