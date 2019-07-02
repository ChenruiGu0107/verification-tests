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

  # @author yapei@redhat.com
  # @case_id OCP-21677
  @admin
  @destructive
  Scenario: Check logging menu on console
    Given logging service is installed with:
      | keep_installation | false |
    And evaluation of `config_map('sharing-config').data['kibanaAppURL']` is stored in the :kibana_url clipboard
    Given cluster role "cluster-admin" is added to the "first" user
    Given I switch to the first user
    When I open admin console in a browser
    When I perform the :click_secondary_menu web action with:
      | primary_menu   | Monitoring |
      | secondary_menu | Logging    |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | Logging              |
      | link_url | <%= cb.kibana_url %> |
    Then the step should succeed
