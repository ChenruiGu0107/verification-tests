Feature: create nginx application from imagestream via oc new-app
  # @author wewang@redhat.com
  # @case_id OCP-13617
  Scenario: create nginx application from imagestream via oc new-app
    Given I have a project
    When I run the :new_app client command with:
      | app_repo    | openshift/nginx:1.10~https://github.com/sclorg/nginx-container.git |
      | context_dir | 1.10/test/test-app/ |
    Then the step should succeed
    And the "nginx-container-1" build was created
    Then the "nginx-container-1" build completed
    And a pod becomes ready with labels:
      | app=nginx-container |
    When I expose the "nginx-container" service
    Then I wait for a web server to become available via the "nginx-container" route
    And  the output should contain "NGINX is working"
