Feature: tests on catalog page

  # @author yanpzhan@redhat.com
  # @case_id OCP-23610
  Scenario: Create labels when source-to-image/Deploy Image creation
    Given the master version >= "4.2"
    Given I have a project
    And I open admin console in a browser
    When I perform the :create_app_from_imagestream web action with:
      | project_name | <%= project.name %> |
      | is_name      | ruby                |
      | label        | testapp=one         |
    Then the step should succeed
    Given the "ruby-1" build completed
    And a pod is present with labels:
      | testapp=one |

    When I perform the :create_app_from_deploy_image web action with:
      | project_name   | <%= project.name %>   |
      | search_content | aosqe/hello-openshift |
      | label          | testdc=two            |
    Then the step should succeed
    And a pod is present with labels:
      | testdc=two |

  # @author yanpzhan@redhat.com
  # @case_id OCP-21250
  Scenario: Persist state for catalogs filters
    Given the master version >= "4.1"
    Given I have a project
    And I open admin console in a browser
    When I perform the :goto_catalog_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    When I run the :wait_for_catalog_loaded web action
    Then the step should succeed
    When I perform the :filter_by_category web action with:
      | category | Languages |
    Then the step should succeed
    And the expression should be true> browser.url.end_with? "category=languages"
    When I perform the :filter_by_keyword web action with:
      | keyword | php |
    Then the step should succeed
    And the expression should be true> browser.url.end_with? "category=languages&keyword=php"
    When I run the :filter_by_sourcetoimage_type web action
    Then the step should succeed
    When I run the :filter_by_serviceclass_type web action
    Then the step should succeed
    And the expression should be true>  browser.url =~ /category=languages&keyword=php&kind=.*ClusterServiceClass.*ImageStream/
    When I run the :clear_filter_by_keyword web action
    Then the step should succeed
    And the expression should be true>  browser.url =~ /category=languages&kind=.*ClusterServiceClass.*ImageStream/

  # @author yanpzhan@redhat.com
  # @case_id OCP-23615
  Scenario: Support template instance on catalog page
    Given the master version >= "4.2"
    Given I have a project
    And I open admin console in a browser
    When I perform the :goto_catalog_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :wait_for_catalog_loaded web action
    Then the step should succeed
    When I run the :filter_by_template_type web action
    Then the step should succeed
    And the expression should be true>  browser.url =~ /kind=.*Template/
    When I perform the :create_app_from_template web action with:
      | project_name | <%= project.name %> |
      | template_name | dotnet-example     |
    Then the step should succeed

    When I get project templateinstance as YAML
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :templateinstance clipboard
  
    When I perform the :check_templateinstance_name_and_icon web action with:
      | resource_name | <%= cb.templateinstance %> |
    Then the step should succeed
    When I perform the :check_resource_item web action with:
      | resource_type | Route |
      | resource_name | dotnet-example |
      | resource_link | /k8s/ns/<%= project.name %>/routes/dotnet-example |
    Then the step should succeed
    When I perform the :check_resource_item web action with:
      | resource_type | Service |
      | resource_name | dotnet-example |
      | resource_link | /k8s/ns/<%= project.name %>/services/dotnet-example |
    Then the step should succeed
    When I perform the :check_resource_item web action with:
      | resource_type | ImageStream |
      | resource_name | dotnet-example |
      | resource_link | /k8s/ns/<%= project.name %>/imagestreams/dotnet-example |
    Then the step should succeed
    When I perform the :check_resource_item web action with:
      | resource_type | BuildConfig |
      | resource_name | dotnet-example |
      | resource_link | /k8s/ns/<%= project.name %>/buildconfigs/dotnet-example |
    Then the step should succeed
    When I perform the :check_resource_item web action with:
      | resource_type | DeploymentConfig |
      | resource_name | dotnet-example |
      | resource_link | /k8s/ns/<%= project.name %>/deploymentconfigs/dotnet-example |
    Then the step should succeed

    When I run the :delete_template_instance_action web action
    Then the step should succeed
    And I wait for the resource "templateinstance" named "<%= cb.templateinstance %>" to disappear
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | all |
    Then the step should succeed
    And the output should not contain "dotnet-example"
    """
