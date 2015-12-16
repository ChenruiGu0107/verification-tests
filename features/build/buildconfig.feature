Feature: buildconfig.feature

  # @author cryan@redhat.com
  # @case_id 495017
  Scenario: Buildconfig spec part cannot be updated
    Given I have a project
    When I run the :process client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/php-56-rhel7-stibuild.json |
    Then the step should succeed
    Given I save the output to file> tcms495017_out.json
    When I run the :create client command with:
      | f | tcms495017_out.json |
    Then the step should succeed
    When I replace resource "bc" named "php-sample-build":
      | ImageStreamTag | ImageStreamTag123 |
    Then the step should fail
    And the output should contain "spec.output.to.kind: invalid value 'ImageStreamTag123'"
    When I replace resource "bc" named "php-sample-build":
      | Git | Git123 |
    Then the step should succeed
    And the output should contain "replaced"
    And the output should not contain "Git123"
    When I replace resource "bc" named "php-sample-build":
      | Source | Source123 |
    Then the step should succeed
    And the output should contain "replaced"
    And the output should not contain "Source123"

    # @author wzheng@redhat.com
    # @case_id 508799
    Scenario: Build go failed if pending time exceeds completionDeadlineSeconds limitation
      Given I have a project
      When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sourcebuildconfig.json |
      Then the step should succeed
      When I run the :describe client command with:
        | resource | buildconfig  |
        | name     | source-build |
      Then the step should succeed
      And the output should contain "Fail Build After:	5s"
      When I run the :start_build client command with:
        | buildconfig | source-build |
      Then the step should succeed
      And the "source-build-1" build was created
      And the "source-build-1" build failed
