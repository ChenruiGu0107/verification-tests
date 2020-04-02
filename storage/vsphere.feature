Feature: vSphere test scenarios

  # @author jhou@redhat.com
  # @case_id OCP-13390
  @admin
  Scenario: Mounting a vSphere volume directly in Pod's specification
    Given I have a project
    And I have a 1 GB volume and save volume id in the :vid clipboard
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/vsphere/myDisk.yaml" replacing paths:
      | ["spec"]["volumes"][0]["vsphereVolume"]["volumePath"] | "<%= cb.vid %>" |
    Then the step should succeed
    And the pod named "vmdk" becomes ready
