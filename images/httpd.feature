Feature: httpd.feature

  # @author wewang@redhat.com
  # @case_id OCP-14703
  Scenario: Deploy the httpd application with rhel httpd24 image
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | openshift/httpd:2.4~https://github.com/sclorg/httpd-ex |
    Then the step should succeed
    Given the "httpd-ex-1" build was created
    And the "httpd-ex-1" build completed
    Given a pod becomes ready with labels:
      | app=httpd-ex |
    When I expose the "httpd-ex" service
    Then I wait for a web server to become available via the "httpd-ex" route
    And  the output should contain "httpd application"
