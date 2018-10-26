Feature: admin console api related

  # @author xiaocwan@redhat.com
  # @case_id OCP-20748
  Scenario: Restrict XSS Vulnerability in K8s API proxy
    Given I have a project
    When I run the :new_app client command with:
      | app_repo   | nodejs-mongo-persistent |
    Then the step should succeed
    Given I open admin console in a browser
    Given a pod becomes ready with labels:
      | name=nodejs-mongo-persistent |
    When I access the "<%= browser.base_url %>api/kubernetes/api/v1/namespaces/<%= project.name %>/services/nodejs-mongo-persistent:web/proxy/" url in the web browser
    Then the step should succeed
    When I get the html of the web page
    Then the output should not match "[Ww]elcome"