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
    When I execute on the pod:
      | curl | -s | <%= service.url %>/websocket-chat/ |
    Then the step should succeed
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
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-template-sti.json |
    Then the step should succeed

    When I run the :describe client command with:
      | resource | bc               |
      | name     | ruby-sample-build |
    Then the output should match:
      | URL:\\s+https://github.com/openshift/ruby-hello-world.git|
      | From Image:\\s+ImageStreamTag openshift/ruby:2.0|
    Given the pod named "ruby-sample-build-1-build" becomes ready
    When I run the :get client command with:
      | resource | builds |
    Then the output should contain:
      | NAME                |
      | ruby-sample-build-1 |
    Given I wait for the "frontend" service to become ready
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    And the output should contain "Hello from OpenShift v3"
