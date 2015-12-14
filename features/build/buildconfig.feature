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
    Then the step should fail
    And the output should contain "spec.source.type: required value"
    When I replace resource "bc" named "php-sample-build":
      | Source | Source123 |
    Then the step should fail
    And the output should contain "spec.strategy.type: invalid value 'Source123'"
