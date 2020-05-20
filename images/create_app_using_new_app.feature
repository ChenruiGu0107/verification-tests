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
