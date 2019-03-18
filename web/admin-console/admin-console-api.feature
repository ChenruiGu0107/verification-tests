Feature: admin console api related

  # @author xiaocwan@redhat.com
  # @case_id OCP-20748
  Scenario: Restrict XSS Vulnerability in K8s API proxy
    Given I have a project
    When I run the :new_app client command with:
      | app_repo   | centos/httpd-24-centos7~https://github.com/sclorg/httpd-ex |
    Then the step should succeed
    Given I open admin console in a browser
    Given a pod becomes ready with labels:
      | app=httpd-ex |
    When I access the "<%= browser.base_url %>api/kubernetes/api/v1/namespaces/<%= project.name %>/services/httpd-ex:8080-tcp/proxy/" url in the web browser
    Then the step should succeed
    When I get the html of the web page
    Then the output should not match "[Ww]elcome"