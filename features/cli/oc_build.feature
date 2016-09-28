Feature: oc build related scenarios
  # @author xiaocwan@redhat.com
  # @case_id 533684
  Scenario: oc start-build with output flag
    Given I have a project
    When I run the :new_app client command with:
      | file  | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc470422/application-template-stibuild.json |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build   |
      | o           | name                |
    Then the step should succeed
    And the output should contain:
      | ruby-sample-build-2               |
    And the output should not match:
      | build .* started                  |
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build   |
      | from_build  | ruby-sample-build-1 |
      | o           | name                |   
    And the output should contain:
      | ruby-sample-build-3               |
    And the output should not match:
      | build .* started                  |
    ## negative flag
    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build   |
      | o           | invalidname         |
    Then the step should fail 
    And the output should match:
      | error.*[Uu]nsupported.*invalidname |   
