Feature: custombuild.feature

  # @author wzheng@redhat.com
  # @case_id 470349
  Scenario: Build with custom image - origin-custom-docker-builder
   Given I have a project 
   When I run the :create client command with:
     | f | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json |
   Then the step should succeed
   And I create a new application with:
      | template | ruby-helloworld-sample |
   Then the step should succeed
   And the "ruby-sample-build-1" build was created
   And the "ruby-sample-build-1" build completed
   And all pods in the project are ready
   When I use the "ruby-sample-build" service
   Then I wait for a server to become available via the "ruby-sample-build" route
   Then the output should contain "<output>"
