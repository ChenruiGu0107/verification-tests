Feature: ONLY ONLINE registry related scripts in this file

  # @author yasun@redhat.com
  # @case_id OCP-14560
  Scenario: Registry url is available in the about page
    When I perform the :check_internal_registry_in_about_page_online web console action with:
      | internal_registry    | <%= env.master_hosts.first.hostname.gsub("api","registry") %> |
    Then the step should succeed
