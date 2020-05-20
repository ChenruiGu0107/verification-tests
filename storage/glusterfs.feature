Feature: Storage of GlusterFS plugin testing

  # @author wehe@redhat.com
  # @case_id OCP-9932
  @admin
  @destructive
  Scenario: Gluster storage testing with Invalid gluster endpoint
    Given I have a project

    #Create a invalid endpoint
    And I obtain test data file "storage/gluster/endpoints.json"
    And I replace content in "endpoints.json":
      | /\d{2}/ | 11 |
    And I run the :create client command with:
      | f | endpoints.json |
    Then the step should succeed
    When admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pv-retain-rwo.json" where:
      | ["metadata"]["name"] | gluster-<%= project.name %> |
    Then the step should succeed

    #Create gluster pvc
    When I create a manual pvc from "<%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/claim-rwo.json" replacing paths:
      | ["metadata"]["name"] | glusterc |
    Then the step should succeed
    And the PV becomes :bound

    #Create the pod
    And I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/storage/gluster/pod.json |
    Then the step should succeed
    And I wait up to 500 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | pods    |
      | name     | gluster |
    Then the output should contain:
      | FailedMount  |
      | mount failed |
    """
