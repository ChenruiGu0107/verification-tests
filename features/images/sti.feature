Feature: sti.feature

  # @author cryan@redhat.com
  # @case_id OCP-12614
  Scenario: Test S2I using sinatra example
    Given I have a project
    When I run the :new_app client command with:
      | output | json |
      | code | https://github.com/openshift/simple-openshift-sinatra-sti.git |
      | strategy | source |
    Then the step should succeed
    Given I save the output to file> simple-openshift-sinatra-sti.json
    When I run the :create client command with:
      | f | simple-openshift-sinatra-sti.json |
    Then the step should succeed
    Given I get project builds
    Then the output should contain "simple-openshift-sinatra-sti-1"
    Given the "simple-openshift-sinatra-sti-1" build completed
    Given I get project pods
    Then the output should contain "simple-openshift-sinatra-sti-1-build"
    Given I get project services
    Then the output should contain "simple-openshift-sinatra"
    Given a pod becomes ready with labels:
      | app=simple-openshift-sinatra-sti |
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | /usr/bin/curl | <%= @pods[0].props[:ip] %>:8080 |
    Then the step should succeed
    """
    And the output should contain "Hello, Sinatra!"
    Given I get project routes
    Then the output should not contain "sinatra"
    When I expose the "simple-openshift-sinatra-sti" service
    Then the step should succeed
    Given I wait for the "simple-openshift-sinatra-sti" service to become ready
    And I wait for a web server to become available via the route
    And the output should contain "Hello, Sinatra!"
    When I run the :scale client command with:
      | replicas | 3 |
      | resource | dc |
      | name | simple-openshift-sinatra-sti |
    Then the step should succeed
    Given I wait until number of replicas match "3" for replicationController "simple-openshift-sinatra-sti-1"

  # @author wzheng@redhat.com
  # @case_id OCP-15360
  Scenario: Nodejs image works well with DEV_MODE=true - nodejs-6-rhel7	
    Given I have a project
    When I run the :new_app client command with:
      | template | nodejs-mongodb-example |
      | e | DEV_MODE=true |
    Then the step should succeed
    Given the "nodejs-mongodb-example-1" build completed
    And I wait for the "nodejs-mongodb-example" service to become ready
    Then I wait for a web server to become available via the "nodejs-mongodb-example" route
    Then the output should contain "Welcome to your Node.js application on OpenShift"
