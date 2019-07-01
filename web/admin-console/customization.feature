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

  # @author yanpzhan@redhat.com
  # @case_id OCP-22330
  @destructive
  @admin
  Scenario: console customization
    Given I register clean-up steps:
    """
    When I run the :patch admin command with:
      | resource | console.operator/cluster         |
      | type     | merge                            |
      | p        | {"spec":{"customization": null}} |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource | console.config/cluster            |
      | type     | merge                             |
      | p        | {"spec":{"authentication": null}} |
    Then the step should succeed
    """

    When I run the :get admin command with:
      | resource      | deployment        | 
      | resource_name | console           |
      | o             | yaml              |
      | namespace     | openshift-console |
    Then the step should succeed
    And evaluation of `@result[:parsed]["metadata"]["annotations"]["deployment.kubernetes.io/revision"].to_i` is stored in the :version_before_deploy clipboard

    When I run the :patch admin command with:
      | resource | console.operator/cluster |
      | type     | merge                    |
      | p        | {"spec":{"customization": {"brand":"okd","documentationBaseURL":"https://docs.okd.io/latest/"}}} |
    Then the step should succeed

    When I run the :patch admin command with:
      | resource | console.config/cluster |
      | type     | merge                  |
      | p        | {"spec":{"authentication": {"logoutRedirect":"https://www.openshift.com"}}} |
    Then the step should succeed

    Given I wait for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | deployment        | 
      | resource_name | console           |
      | o             | yaml              |
      | namespace     | openshift-console |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["metadata"]["annotations"]["deployment.kubernetes.io/revision"].to_i > <%= cb.version_before_deploy %>+1
    """

    Given I switch to cluster admin pseudo user
    And I use the "openshift-console" project
    Given number of replicas of the current replica set for the "console" deployment becomes:
      | desired  | 2 |
      | current  | 2 |
      | ready    | 2 |

    Given I switch to the first user      
    And I open admin console in a browser
    When I perform the :check_header_brand web action with:
      | product_brand | OKD |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | documentation               |
      | link_url | https://docs.okd.io/latest/ |
    Then the step should succeed

    When I run the :click_logout web action
    Then the step should succeed
    And I wait up to 60 seconds for the steps to pass:
    """
    Given the expression should be true> browser.url.match("https://www.openshift.com")
    """

    When I run the :patch admin command with:
      | resource | console.config/cluster |
      | type     | merge                  |
      | p        | {"spec":{"authentication": {"logoutRedirect":"http://www.ocptest.com"}}} |
    Then the step should fail

    When I run the :patch admin command with:
      | resource | console.config/cluster |
      | type     | merge                  |
      | p        | {"spec":{"authentication": {"logoutRedirect":"www.ocptest.com"}}} |
    Then the step should fail
