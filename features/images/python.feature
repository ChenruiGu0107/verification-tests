Feature: Python images

  # @author akostadi@redhat.com
  # @case_id 474099
  Scenario: [origin_devexp_367] Verify and test python-33-centos7 image
    Given I have a user
    And I have a project
    # And I pull the "openshift/python-33-centos7" image if needed
    When ???
    And create an application off the templete
    Then the app should be available
    When I set app replication count to 0
    Then the ap should be unavailable
    And app should have no pods
    And app should have no docker containers

    When I "STI" build "python-33-centos7" image
    And docker run the image
    Then the step should succeed
    And the container should be available
