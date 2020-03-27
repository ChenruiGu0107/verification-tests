Feature: operatorhub feature related

  # @author hasha@redhat.com
  # @case_id OCP-24340
  @admin
  Scenario: Add "custom form" vs "YAML editor" on "Create Custom Resource" page	
    Given the master version >= "4.3"
    Given I have a project
    Given the first user is cluster-admin
    And I open admin console in a browser
    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | etcd                   |
      | catalog_name     | community-operators    |
      | target_namespace | <%= project.name %>    |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text  | Subscribe |
    Then the step should succeed
    """

    # wait until etcd operator is successfully installed
    Given I use the "<%= project.name %>" project
    Given a pod becomes ready with labels:
      | name=etcd-operator-alm-owned |

    # create etcd Cluster via Edit Form
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :create_custom_resource web action with:
      | api      | etcd Cluster |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text  | Edit Form |
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    When I run the :get client command with:
      | resource      | etcdclusters |
    Then the step should succeed
    And the output should contain "example"


  # @author hasha@redhat.com
  # @case_id OCP-25931
  @admin
  @destructive
  Scenario: check Custom serviceCatalog on console
    Given the master version >= "4.3"
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    Given the first user is cluster-admin
    Given admin ensures "custom-cs-keycloak" catalog_source is deleted from the "openshift-marketplace" project after scenario
    Given admin ensures "custom-cs-keycloak-ns" catalog_source is deleted from the "default" project after scenario

    # create cluster-wide CatalogSource
    Given I open admin console in a browser
    When I perform the :create_catalog_source web action with:
      | catalog_source_name | custom-cs-keycloak        |
      | display_name        | Custom Catalog Source     |
      | publisher_name      | OpenShift QE              |
      | image               | docker.io/aosqe/custom-keycloak:latest |
    Then the step should succeed
    Given I use the "openshift-marketplace" project
    And a pod becomes ready with labels:
      | olm.catalogSource=custom-cs-keycloak |

    # subscribe operator to one namespace
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | keycloak-operator   |
      | catalog_name     | custom-cs-keycloak  |
      | target_namespace | <%= cb.proj_name %> |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text  | Subscribe |
    Then the step should succeed
    """
    Given I wait for the "keycloak-operator" subscription to appear in the "<%= cb.proj_name %>" project up to 30 seconds
    
    # console will show 'Catalog Source Removed' on Subscription page when CatalogSource is removed
    When I run the :goto_catalog_source_page web action
    Then the step should succeed
    When I run the :wait_box_loaded web action
    Then the step should succeed
    When I perform the :click_one_operation_in_kebab web action with:
      | resource_name | custom-cs-keycloak   |
      | kebab_item    | Delete CatalogSource |
    Then the step should succeed
    When I perform the :confirm_deletion web action with:
      | resource_name | custom-cs-keycloak |
    Then the step should succeed
    Given I use the "openshift-marketplace" project
    Given I wait for the resource "catalogsource" named "custom-cs-keycloak" to disappear within 30 seconds
    When I perform the :goto_one_project_subscription_page web action with:
      | project_name      | <%= cb.proj_name %>   |
      | subscription_name | keycloak-operator     |
    Then the step should succeed
    When I perform the :check_page_match web action with:
      | content | Catalog Source Removed |
    Then the step should succeed

    # create namespace scoped CatalogSource
    When I perform the :create_catalog_source web action with:
      | catalog_source_name | custom-cs-keycloak-ns       |
      | display_name        | Custom Catalog Source NS    |
      | publisher_name      | OpenShift QE                |
      | item                | default                     |
      | image               | docker.io/aosqe/custom-keycloak:latest |
    Then the step should succeed

    Given I use the "default" project
    And a pod is present with labels:
      | olm.catalogSource=custom-cs-keycloak-ns |
    Given I use the "kube-system" project
    When I get project pods
    And the output should not contain:
      | custom-cs-keycloak |

  # @author hasha@redhat.com
  # @case_id OCP-26029
  @admin
  @destructive
  Scenario: Check container security on console
    Given the master version >= "4.3"
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/deployment/vul_deployment.yaml |
    Then the step should succeed
    Given the first user is cluster-admin
    Given I open admin console in a browser

    # install container security operator
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | container-security-operator |
      | catalog_name     | community-operators         |
      | target_namespace | <%= project.name %>         |
    Then the step should succeed
    When I run the :wait_box_loaded web action
    Then the step should succeed
    When I perform the :select_target_namespace web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Subscribe |
    Then the step should succeed

    # wait until container security operator is successfully installed
    Given I use the "<%= project.name %>" project
    Given a pod becomes ready with labels:
      | name=container-security-operator-alm-owned |
    Then I wait for the "sha256.c51f9b027d358a07b7201e37163e0fabb12b1ac06a640ab1a84a78f541e6c3fa" image_manifest_vuln to appear in the "<%= project.name %>" project up to 30 seconds


    #check the display when have vulnerabilities in cluster
    When I run the :goto_cluster_dashboards_page web action
    Then the step should succeed
    When I run the :check_quay_image_security_exists_on_dashboard web action
    Then the step should succeed
    When I run the :click_quay_image_security_button web action
    Then the step should succeed
    When I perform the :check_quay_image_security_popup web action with:
      | severity | 1 High       |
      | text     | 1 namespace  |
      | link_url | k8s/all-namespaces/secscan.quay.redhat.com~v1alpha1~ImageManifestVuln?name=sha256.c51f9b027d358a07b7201e37163e0fabb12b1ac06a640ab1a84a78f541e6c3fa |
    Then the step should succeed

    #check Image Manifest Vulnerabilities page for 4.4 and above
    When I perform the :goto_ImageManifestVuln_list_page web action with:
      | project_name |  <%= project.name %> |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Highest Severity  |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Affected Pods |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Fixable |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Manifest  |
    Then the step should succeed
    When I perform the :goto_one_ImageManifestVuln_page web action with:
      | project_name |  <%= project.name %> |
      | manifest     | sha256.c51f9b027d358a07b7201e37163e0fabb12b1ac06a640ab1a84a78f541e6c3fa |
    Then the step should succeed
    When I run the :check_affected_pods_tab web action
    Then the step should succeed

    #uninstall the operator on web console
    When I perform the :goto_installed_operators_page web action with:
      | project_name | openshift-operators |
    Then the step should succeed
    When I perform the :uninstall_operator_on_console web action with:
      | resource_name | Container Security |
    Then the step should succeed
    Given I use the "<%= project.name %>" project
    And I wait for the resource "subscription" named "container-security-operator" to disappear within 30 seconds

  # @author xiaocwan@redhat.com
  # @case_id OCP-27495
  @admin
  Scenario: Check Operator hub link to IBM Marketplace
    Given the master version >= "4.4"
    Given the first user is cluster-admin
    When I open admin console in a browser
    Then the step should succeed
    When I run the :goto_operator_hub_page web action
    Then the step should succeed

    # check link to Red Hat Marketplace and Developer Catalog
    When I run the :check_link_for_marketplace web action
    Then the step should succeed
    When I run the :check_link_for_developer_catalog web action
    Then the step should succeed

    # check Marketplace item badge and description on overlay
    When I perform the :check_catalog_badge_by_checkbox web action with:
      | text | Marketplace |
    Then the step should succeed
    When I run the :check_marketplace_operator_description_on_overlay web action
    Then the step should succeed

    # check Community item badge and description on overlay
    When I perform the :check_catalog_badge_by_checkbox web action with:
      | text | Community |
    Then the step should succeed
    When I run the :check_community_operator_description_on_overlay web action
    Then the step should succeed

