Feature: AWS specific scenarios

  # @author jhou@redhat.com
  # @case_id 533137
  @admin
  Scenario: PV with invalid volume id should be prevented from creating
    Given admin ensures "ebsinvalid" pv is deleted after scenario
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/ebs/pv-invalid.yaml |
    Then the step should fail
    And the output should contain:
      | The volume 'vol-00000123' does not exist |
