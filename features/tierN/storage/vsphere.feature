Feature: vSphere test scenarios

  # @author jhou@redhat.com
  # @case_id OCP-13390
  @admin
  Scenario: Mounting a vSphere volume directly in Pod's specification
    Given I have a project

    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/vsphere/myDisk.yaml |
      | n | <%= project.name %>                                                                                       |
    Then the step should succeed
    And the pod named "vmdk" becomes ready
