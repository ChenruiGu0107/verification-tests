Feature: Home related pages via admin console

  # @author xiaocwan@redhat.com
  # @case_id OCP-19678
  Scenario: Check general info on console
    When I run the :version client command
    Then the step should succeed
    And evaluation of `@result[:props][:openshift_server_version]` is stored in the :openshift_version clipboard
    And evaluation of `@result[:props][:kubernetes_version]` is stored in the :k8s_version clipboard
    Given I open admin console in a browser
    When I perform the :go_to_project_status web action with:
      | project   | default |
    Then the step should succeed
    When I perform the :check_software_info_versions web action with:
      | k8s_version       | <%= cb.k8s_version  %>      |
      | openshift_version | <%= cb.openshift_version %> |
    Then the step should succeed