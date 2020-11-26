Feature: file-integrity operator related scenarios
  # @author xiyuan@redhat.com
  # @case_id OCP-35899
  @admin
  Scenario: file-integrity operator should get installed successfully in stage environment
    Given I switch to cluster admin pseudo user
    When I use the "openshift-file-integrity" project
    #check fio related pods are ready in openshift-file-integrity projects
    And all existing pods are ready with labels:
      | name=file-integrity-operator |
