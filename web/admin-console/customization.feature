Feature: customize console related

  # @author yanpzhan@redhat.com
  # @case_id OCP-19811
  @destructive
  @admin
  Scenario: Customize console logout url
    Given the master version >= "3.11"
    And system verification steps are used:
    """
    I switch to cluster admin pseudo user
    I use the "openshift-console" project
    Given a pod becomes ready with labels:
      | app=openshift-console |                      
    When admin executes on the pod:
      | cat | /var/console-config/console-config.yaml |
    Then the step should succeed
    And the output should not contain "https://www.example.com"
    """

    And I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type | pod                   |
      | l           | app=openshift-console |
    the step should succeed
    """
    And the "console-config" configmap is recreated by admin in the "openshift-console" project after scenario

    When value of "console-config.yaml" in configmap "console-config" as YAML is merged with:
    """
    auth:
      logoutRedirect: 'https://www.example.com'
    """
    And I run the :delete admin command with:
      | object_type | pod                   |
      | l           | app=openshift-console |
    Then the step should succeed

    Given a pod becomes ready with labels:
      | app=openshift-console |
    When admin executes on the pod:
      | cat | /var/console-config/console-config.yaml |
    Then the step should succeed
    And the output should contain "https://www.example.com"

    Given I switch to the first user
    Given I open admin console in a browser
    When I run the :goto_projects_list_page web action
    Then the step should succeed

    When I run the :click_logout web action
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    Given the expression should be true> browser.url.match("https://www.example.com/")
    """
