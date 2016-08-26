Feature: some storage related scenarios

  # @author mcurlej@redhat.com
  # @case_id none
  @admin
  Scenario: test openstack rest api
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/dynamic-provisioning-pvc.json |
    Then the step should succeed
    And the "ebsc" PVC becomes :bound
    And evaluation of `pvc.volume_name(user: user)` is stored in the :volume_name clipboard
    # ready statuses: GCE -> READY, AWS -> available, OS -> available
    When I verify that the IAAS volume for the "<%= cb.volume_name %>" PV becomes "READY"
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | pvc |
      | all         |     |
    Then the step should succeed
    And I verify that the IAAS volume for the "<%= cb.volume_name%>" PV was deleted
