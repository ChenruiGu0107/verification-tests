Feature: oc import-image related feature
    # @author haowang@redhat.com
    # @case_id 488868
    Scenario: import an invalid image stream
        When I have a project
        And I run the :import_image client command with:
            | image_name | test/invalidimagename|
        Then the step should fail
        And the output should contain:
            |Error from server|
            |cannot get imagestreams|
            |nvalidimagename|
