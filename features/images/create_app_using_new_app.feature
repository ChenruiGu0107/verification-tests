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
      | bash                       |
      | -c                         |
      | curl -s <%= service.url %>/websocket-chat/ |
    Then the step should succeed
    And the output should contain "WebSocket connection opened"
    Examples:
      | jws_image |
      | openshift/jboss-webserver30-tomcat7-openshift:latest |
      | openshift/jboss-webserver30-tomcat8-openshift:latest |

