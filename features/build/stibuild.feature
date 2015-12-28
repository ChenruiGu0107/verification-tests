Feature: stibuild.feature
  # @author haowang@redhat.com
  # @case_id 476410
  Scenario: STI build with SourceURI and context dir
    Given I have a project 
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/python-27-rhel7-context-stibuild.json |
    Then the step should succeed
    When I run the :start_build client command with: 
      | buildconfig | python-sample-build |
    And the "python-sample-build-1" build was created
    And the "python-sample-build-1" build completed


