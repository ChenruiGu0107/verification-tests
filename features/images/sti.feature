Feature: sti.feature

  # @author cryan@redhat.com
  # @case_id 494658
  Scenario: Test S2I using sinatra example
    Given I have a project
    When I run the :new_app client command with:
      | output | json |
      | code | https://github.com/openshift/simple-openshift-sinatra-sti.git |
      | strategy | source |
    Then the step should succeed
    And the output should contain ""kind": "BuildConfig""
    And the output should contain ""kind": "ImageStream""
    Given I save the output to file> simple-openshift-sinatra-sti.json
    #The following step removes an error message that prevents the app
    #creation, specifically: because no exposed ports were detected,
    #Use 'oc expose dc "simple-openshift-sinatra-sti" --port=[port]'
    #to create a service.
    Given I replace lines in "simple-openshift-sinatra-sti.json":
      |/^.*service will not.*$/||
    When I run the :create client command with:
      | f | simple-openshift-sinatra-sti.json |
    Then the step should succeed
    Given the "simple-openshift-sinatra-sti-1" build was created
    Given the "simple-openshift-sinatra-sti-1" build completed
    When I run the :get client command with:
      | resource | pods |
    Then the output should contain "simple-openshift-sinatra-sti-1-build"
    When I run the :get client command with:
      | resource | svc |
    Then the output should contain "simple-openshift-sinatra"
