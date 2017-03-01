Feature: Testing imagestream

  # @author haowang@redhat.com
  # @case_id OCP-11035
  Scenario: oc import-image should pull "highest" tags
    Given I have a project
    When I run the :import_image client command with:
      | image_name | busybox                           |
      | from       | docker.io/aosqe/busybox-multytags |
      | all        | true                              |
      | confirm    | true                              |
    Then the step should succeed
    And the "busybox" image stream was created
    And the expression should be true> image_stream('busybox').tags(user: user).length == 5
    And the expression should be true> image_stream('busybox').tags(user: user)
    And the "busybox:latest" image stream tag was created
    And the "busybox:v1.3-2" image stream tag was created
    And the "busybox:v1.3-3" image stream tag was created
    And the "busybox:v1.3-4" image stream tag was created
    And the "busybox:v1.2-5" image stream tag was created
