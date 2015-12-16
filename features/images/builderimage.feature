Feature: builderimage.feature
  # @case_id 497680
  # @author haowang@redhat.com
  Scenario: Create nodejs + postgresql applicaion - nodejs-010-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/nodejs-template-stibuild.json|
    Then the step should succeed
    And the "nodejs-sample-build-1" build was created
    And the "nodejs-sample-build-1" build completed
    And a pod becomes ready with labels:
      |name=frontend|
    And a pod becomes ready with labels:
      |name=database|
    When I expose the "frontend" service
    Then I wait for a server to become available via the "frontend" route
    And  the output should contain "nodejs"
    And  the output should contain "postgresql"
