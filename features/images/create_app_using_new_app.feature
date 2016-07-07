Feature:Create apps using new_app cmd feature
  # @author xiuwang@redhat.com
  # @case_id 508988 508989
  Scenario Outline: Create tomcat7 application from imagestream via oc new_app
    Given I have a project

    When I run the :new_app client command with:
      | image_stream |<jws_image> |
      | code |https://github.com/jboss-openshift/openshift-quickstarts.git#1.2 |
      | context_dir|tomcat-websocket-chat |
    Then the step should succeed

    Given I wait for the "openshift-quickstarts" service to become ready
    And I wait up to 900 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %>/websocket-chat/ |
    Then the step should succeed
    """
    And the output should contain "WebSocket connection opened"

    Examples:
      | jws_image |
      | openshift/jboss-webserver30-tomcat7-openshift:latest |
      | openshift/jboss-webserver30-tomcat8-openshift:latest |

  # @author xiuwang@redhat.com
  # @case_id 476349
  Scenario: Application with ruby-20-rhel7 base images lifecycle
    Given I have a project

    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc476349/ruby20rhel7-template-sti.json |
    Then the step should succeed

    When I run the :describe client command with:
      | resource | bc               |
      | name     | ruby-sample-build |
    Then the output should match:
      | URL:\\s+https://github.com/openshift/ruby-hello-world.git|
      | From Image:\\s+ImageStreamTag openshift/ruby:2.0|
    And the "ruby-sample-build-1" build was created
        And the "ruby-sample-build-1" build completed
    Given I wait for the "frontend" service to become ready
    When I expose the "frontend" service
    Then I wait for a web server to become available via the "frontend" route
    And the output should contain "Hello from OpenShift v3"

  # @author haowang@redhat.com
  # @case_id 508976
  Scenario: create resource from imagestream via oc new-app openshift/nodejs-010-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | nodejs |
      | code         | https://github.com/openshift/nodejs-ex.git |
    Then the step should succeed
    And the "nodejs-ex-1" build was created
    And the "nodejs-ex-1" build completed
    And a pod becomes ready with labels:
      |app=nodejs-ex|
    When I expose the "nodejs-ex" service
    Then I wait for a web server to become available via the "nodejs-ex" route
    And  the output should contain "Welcome to your Node.js application on OpenShift"

  # @author haowang@redhat.com
  # @case_id 491259
  Scenario: Create applications with multiple repos
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/xiuwang/ruby-hello-world.git   |
      | app_repo | https://github.com/openshift/ruby-hello-world.git |
      | l        | app=test |
    Then the step should succeed
    And the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1-1" build was created
    When I run the :describe client command with:
      | resource | bc    |
      | name     | ruby-hello-world |
    Then the output should contain "https://github.com/xiuwang/ruby-hello-world.git"
    When I run the :describe client command with:
      | resource | bc    |
      | name     | ruby-hello-world-1 |
    Then the output should contain "https://github.com/openshift/ruby-hello-world.git"
    When I create a new project
    Then I run the :new_app client command with:
      | app_repo | https://github.com/openshift/ruby-hello-world.git |
      | app_repo | https://github.com/openshift/ruby-hello-world.git |
      | l        | app=test |
    Then the step should succeed
    When I run the :get client command with:
      | resource | bc |
    Then the output should contain "ruby-hello-world"
    And the output should not contain "ruby-hello-world-1"

  # @author cryan@redhat.com
  # @case_id 509050
  Scenario: Create jenkins resources with oc new-app from imagestream -jenkins-1-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | jenkins |
      | env | JENKINS_PASSWORD=test123 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | app=jenkins |
    When I expose the "jenkins" service
    Then the step should succeed
    #Checking for 'ready to work' to disappear; this shows that
    #jenkins is ready to accept user/pass
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route("jenkins", service("jenkins")).dns(by: user) %>/login" url
    Then the output should contain "Jenkins"
    And the output should not contain "ready to work"
    """
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins/     |
      | base_url | http://<%= route.dns(by: user) %> |
    When I perform the :login web action with:
      | username | admin   |
      | password | test123 |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> /Dashboard \[Jenkins\]/ =~ browser.title
    """

  # @author xiuwang@redhat.com
  # @case_id 529321
  Scenario: create resource from imagestream via oc new-app nodejs-4-rhel7
    Given I have a project
    When I run the :import_image client command with:
      | image_name | nodejs:4 |
      | from | <%= product_docker_repo %>rhscl/nodejs-4-rhel7 |
      | confirm  | true |
      | insecure | true |
    Then the step should succeed
    When I run the :new_app client command with:
      | image_stream | <%= project.name %>/nodejs:4 |
      | code         | https://github.com/openshift/nodejs-ex.git |
    Then the step should succeed
    And the "nodejs-ex-1" build was created
    And the "nodejs-ex-1" build completed
    And a pod becomes ready with labels:
      |app=nodejs-ex|
    When I expose the "nodejs-ex" service
    Then I wait for a web server to become available via the "nodejs-ex" route
    And  the output should contain "Welcome to your Node.js application on OpenShift"

  # @author xiuwang@redhat.com
  # @case_id 529370 529371
  Scenario Outline: Nodejs-ex quickstart test with nodejs-4-rhel7
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift/nodejs-ex/master/openshift/templates/<template>" 
    When I run the :import_image client command with:
      | image_name | nodejs:4 |
      | from | <%= product_docker_repo %>rhscl/nodejs-4-rhel7 |
      | confirm  | true |
      | insecure | true |
    Then the step should succeed
    And I replace lines in "<template>":
      |nodejs:0.10|nodejs:4|
      |${NAMESPACE}|<%= project.name %>|
    When I run the :new_app client command with:
      | file  | <template> |
    Then the step should succeed
    And the "<buildcfg>-1" build was created
    And the "<buildcfg>-1" build completed
    When I use the "<buildcfg>" service
    Then I wait for a web server to become available via the "<buildcfg>" route
    Then the output should contain "Welcome to your Node.js application on OpenShift"

    Examples:
      |template           |buildcfg              |
      |nodejs.json        |nodejs-example        |
      |nodejs-mongodb.json|nodejs-mongodb-example|
