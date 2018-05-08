Feature:Create apps using new_app cmd feature
  # @author xiuwang@redhat.com
  Scenario Outline: Create tomcat7 application from imagestream via oc new_app
    Given I have a project

    When I run the :new_app client command with:
      | image_stream |<jws_image> |
      | code |https://github.com/jboss-openshift/openshift-quickstarts.git#1.2 |
      | context_dir|tomcat-websocket-chat |
    Then the step should succeed

    Given I wait for the "openshift-quickstarts" service to become ready up to 300 seconds up to 300 seconds
    And I get the service pods
    And I wait up to 900 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %>/websocket-chat/ |
    Then the step should succeed
    """
    And the output should contain "WebSocket connection opened"

    Examples:
      | jws_image                                         |
      | openshift/jboss-webserver30-tomcat7-openshift:1.3 | # @case_id OCP-9657
      | openshift/jboss-webserver30-tomcat8-openshift:1.3 | # @case_id OCP-9658

  # @author xiuwang@redhat.com
  # @case_id OCP-10595
  Scenario: Application with ruby-20-rhel7 base images lifecycle
    Given I have a project

    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/tc476349/ruby20rhel7-template-sti.json |
    Then the step should succeed

    When I run the :describe client command with:
      | resource | bc                |
      | name     | ruby-sample-build |
    Then the output should match:
      | URL:\\s+https://github.com/openshift/ruby-hello-world.git |
      | From Image:\\s+ImageStreamTag openshift/ruby:2.0          |
    And the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed
    Given I wait for the "frontend" service to become ready up to 300 seconds up to 300 seconds
    When I expose the "frontend" service
    Then I wait for a web server to become available via the "frontend" route
    And the output should contain "Hello from OpenShift v3"

  # @author haowang@redhat.com
  @smoke
  Scenario Outline: create nodejs resource from imagestream via oc new-app
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | nodejs:<tag>                               |
      | code         | https://github.com/openshift/nodejs-ex.git |
    Then the step should succeed
    And the "nodejs-ex-1" build was created
    And the "nodejs-ex-1" build completed
    And a pod becomes ready with labels:
      | app=nodejs-ex |
    When I expose the "nodejs-ex" service
    Then I wait for a web server to become available via the "nodejs-ex" route
    And  the output should contain "Welcome to your Node.js application on OpenShift"
    Examples:
      | tag  |
      | 0.10 | # @case_id OCP-9653
      | 4    | # @case_id OCP-12215
      | 6    | # @case_id OCP-13513

  # @author haowang@redhat.com
  # @case_id OCP-11137
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
      | resource | bc               |
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
      | l        | app=test                                          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | bc |
    Then the output should contain "ruby-hello-world"
    And the output should not contain "ruby-hello-world-1"

  # @author cryan@redhat.com
  Scenario Outline: Create jenkins resources with oc new-app from imagestream
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | jenkins:<ver>            |
      | env          | JENKINS_PASSWORD=test123 |
      | p            | OAUTH_ENABLED=false      |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | app=jenkins |
    When I run the :expose client command with:
      | resource      | service |
      | resource_name | jenkins | 
      | port          | 8080    | 
    Then the step should succeed
    #Checking for 'ready to work' to disappear; this shows that
    #jenkins is ready to accept user/pass
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I open web server via the "http://<%= route("jenkins", service("jenkins")).dns(by: user) %>/login" url
    Then the output should contain "Jenkins"
    And the output should not contain "ready to work"
    """
    Given I have a browser with:
      | rules    | lib/rules/web/images/jenkins_<ver>/                              |
      | base_url | http://<%= route("jenkins", service("jenkins")).dns(by: user) %> |
    When I perform the :jenkins_standard_login web action with:
      | username | admin   |
      | password | test123 |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> /Dashboard \[Jenkins\]/ =~ browser.title
    """
    Examples:
      | ver |
      | 1   | # @case_id OCP-9666
      | 2   | # @case_id OCP-10366

  # @author xiuwang@redhat.com
  # @case_id OCP-12216 OCP-12265
  Scenario Outline: Nodejs-ex quickstart test with nodejs-4-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | template  | <buildcfg> |
    Then the step should succeed
    And the "<buildcfg>-1" build was created
    And the "<buildcfg>-1" build completed
    When I use the "<buildcfg>" service
    Then I wait for a web server to become available via the "<buildcfg>" route
    Then the output should contain "Welcome to your Node.js application on OpenShift"

    Examples:
      |buildcfg              |
      |nodejs-example        |
      |nodejs-mongodb-example|

  # @author wzheng@redhat.com
  # @case_id OCP-14099
  Scenario: Create Passenger app from imagestream - passenger-40-rhel7
    Given I have a project
    When I run the :import_image client command with:
      | from       | <%= product_docker_repo %>rhscl/passenger-40-rhel7 |
      | confirm    | true                                               |
      | image_name | passenger-40-rhel7                                 |
      | insecure   | true                                               |
    Then the step should succeed
    When I run the :new_app client command with:
      | image_stream | passenger-40-rhel7                                |
      | app_repo     | https://github.com/sclorg/passenger-container.git |
      | context_dir  | 4.0/test/puma-test-app                            |
    Then the step should succeed
    And the "passenger-container-1" build was created
    And the "passenger-container-1" build completed
    When I run the :expose client command with:
      | resource      | service             |
      | resource_name | passenger-container |
    Then the step should succeed
    When I use the "passenger-container" service
    Then I wait for a web server to become available via the "passenger-container" route
    Then the output should contain "Hello world"

  # @author xiuwang@redhat.com
  # @case_id OCP-15349
  Scenario: Dotnet-example quickstart test on web console with dotnet-2.0
    Given I have a project
    When I run the :new_app client command with:
      | template    | dotnet-runtime-example|
    Then the step should succeed
    And the "dotnet-runtime-example-build-1" build was created
    And the "dotnet-runtime-example-build-1" build completed
    Then the "dotnet-runtime-example-runtime-2" build was created
    And the "dotnet-runtime-example-runtime-2" build completed
    Then I wait for a web server to become available via the "dotnet-runtime-example" route
    And the output should contain "Sample pages using ASP.NET Core MVC"
   
    # Manually start chain build
    When I run the :start_build client command with:
      | buildconfig | dotnet-runtime-example-build |
    Then the step should succeed
    And the "dotnet-runtime-example-build-2" build was created
    And the "dotnet-runtime-example-build-2" build completed
    Then the "dotnet-runtime-example-runtime-3" build was created
    And the "dotnet-runtime-example-runtime-3" build completed

  # @author xiuwang@redhat.com
  # @case_id OCP-16887
  Scenario: Validate dotnet imagestream works well in online env
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/redhat-developer/s2i-dotnetcore/master/templates/dotnet-example.json |
    Then the step should succeed
    And the "dotnet-example-1" build was created
    And the "dotnet-example-1" build completed
    Then I wait for a web server to become available via the "dotnet-example" route
    And the output should contain "Sample pages using ASP.NET Core MVC"
