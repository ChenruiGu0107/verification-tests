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
      | image               | docker.io/aosqe/custom-keycloak@sha256:14af7be507288acca377896ea07b390901795598a539b5128841a77fc669d10d |
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
      | image               | docker.io/aosqe/custom-keycloak@sha256:14af7be507288acca377896ea07b390901795598a539b5128841a77fc669d10d |
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
    Given the master version >= "4.4"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/vul_deployment.yaml |
    Then the step should succeed
    Given the first user is cluster-admin
    Given I open admin console in a browser

    # install container security operator
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | container-security-operator |
      | catalog_name     | community-operators         |
      | target_namespace | <%= project.name %>         |
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
      | project_name | <%= project.name %> |
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

  # @author hasha@redhat.com
  # @case_id OCP-27666
  @admin
  Scenario: Add Special support link for template and operator
    Given the master version >= "4.4"
    Given I have a project
    #check support link for template
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/testdata/image/language-image-templates/php-55-rhel7-stibuild.json |
    Then the step should succeed
    Given I successfully merge patch resource "template/php-helloworld-sample" with:
      | {"metadata":{"annotations":{"openshift.io/support-url":"https://access.redhat.test.com"}}} |
    Given I open admin console in a browser
    When I perform the :goto_catalog_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :filter_by_template_type web action
    Then the step should succeed
    When I perform the :click_catalog_item web action with:
      | catalog_item | php-helloworld-sample |
    Then the step should succeed
    When I perform the :check_the_support_link web action with:
      | link_url | https://access.redhat.test.com |
    Then the step should succeed

    #check support link for operators
    Given the first user is cluster-admin
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | cockroachdb-certified-rhmp |
      | catalog_name     | redhat-marketplace         |
      | target_namespace | <%= project.name %>        |
    Then the step should succeed
    When I perform the :select_target_namespace web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Subscribe |
    Then the step should succeed
    Given I wait for the "cockroachdb-certified-rhmp" subscriptions to appear
    And evaluation of `subscription("cockroachdb-certified-rhmp").current_csv` is stored in the :cockroachdb_csv clipboard
    Given I successfully merge patch resource "csv/<%= cb.cockroachdb_csv %>" with:
      | {"metadata":{"annotations":{"marketplace.openshift.io/support-workflow": "https://marketplace.redhat.com/en-us/operators/cockroachdb-certified-rhmp/support-updated"}}} |
    When I perform the :goto_csv_detail_page web action with:
      | project_name | <%= project.name %>       |
      | csv_name     | <%= cb.cockroachdb_csv %> |
    Then the step should succeed
    When I perform the :check_the_support_link web action with:
      | link_url | https://marketplace.redhat.com/en-us/operators/cockroachdb-certified-rhmp/support-updated |
    Then the step should succeed

    #check support link for Operator Backed service
    When I perform the :goto_catalog_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_catalog_item web action with:
      | catalog_item | CockroachDB |
    Then the step should succeed
    When I perform the :check_the_support_link web action with:
      | link_url | https://marketplace.redhat.com/en-us/operators/cockroachdb-certified-rhmp/support-updated |
    Then the step should succeed

  # @author hasha@redhat.com
  # @case_id OCP-28954
  @admin
  Scenario: Form & YAML Toggle Interactions for Create Operand
    Given the master version >= "4.5"
    Given I have a project
    Given the first user is cluster-admin
    When I open admin console in a browser
    Then the step should succeed
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | radanalytics-spark  |
      | catalog_name     | community-operators |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    When I perform the :select_target_namespace web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Subscribe |
    Then the step should succeed
    Given I wait for the "radanalytics-spark" subscriptions to appear
    And evaluation of `subscription("radanalytics-spark").current_csv` is stored in the :spark_csv clipboard
    When I perform the :goto_operand_list_page web action with:
      | project_name | <%= project.name %>              |
      | csv_name     | <%= cb.spark_csv %>              |
      | operand_name | radanalytics.io~v1~SparkCluster  |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text | Create SparkCluster |
    Then the step should succeed
    When I run the :check_default_view_is_form_view web action
    Then the step should succeed
    When I run the :switch_to_yaml_view web action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-27835
  @admin
  Scenario: Check operator's capability level in operator hub
    Given the master version >= "4.4"
    Given the first user is cluster-admin
    When I open admin console in a browser
    Then the step should succeed
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :click_checkbox_from_capability_level web action with:
      | text | Full Lifecycle |
    Then the step should succeed
    When I perform the :filter_by_keyword web action with:
      | keyword | local storage |
    Then the step should succeed
    When I run the :open_first_card_in_overlay web action
    Then the step should succeed
    When I run the :check_basic_install_capability web action
    Then the step should succeed
    When I run the :check_seamless_upgrade_capability web action
    Then the step should succeed
    When I run the :check_full_lifecycle_capability web action
    Then the step should succeed
    When I run the :check_deep_insights_capability web action
    Then the step should fail

    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :click_checkbox_from_capability_level web action with:
      | text | Seamless Upgrades |
    Then the step should succeed
    When I perform the :filter_by_keyword web action with:
      | keyword | elastic |
    Then the step should succeed
    When I run the :open_first_card_in_overlay web action
    Then the step should succeed
    When I run the :check_basic_install_capability web action
    Then the step should succeed
    When I run the :check_seamless_upgrade_capability web action
    Then the step should succeed
    When I run the :check_full_lifecycle_capability web action
    Then the step should fail
    
  # @author yapei@redhat.com
  # @case_id OCP-29198
  @admin
  Scenario: Infrastructure Features and Valid Subscriptions annotation support for Operators
    Given the master version >= "4.5"
    Given the first user is cluster-admin
    Given admin ensures "custom-console-catalogsource-infrasubs" catalog_source is deleted from the "openshift-marketplace" project after scenario
    When I process and create:
      | f | <%= BushSlicer::HOME %>/testdata/olm/catalogsource-template.yaml |
      | p | NAME=custom-console-catalogsource-infrasubs                      |
      | p | IMAGE=quay.io/openshifttest/uitestoperators:infrasubs            |
      | p | DISPLAYNAME=Custom Console AUTO Testing                          |
    Then the step should succeed
    Given I use the "openshift-marketplace" project
    And a pod becomes ready with labels:
      | olm.catalogSource=custom-console-catalogsource-infrasubs |
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I get project packagemanifests
    Then the output should match 5 times:
      | Custom Console AUTO Testing |
    """

    Given I open admin console in a browser
    When I run the :goto_operator_hub_page web action
    Then the step should succeed

    # Check infrastructure feature(Disconnected/Proxy/FIPS Mode) value is shown in modal when corresponding type is checked
    When I run the :check_disconnected_infra_value_in_operator_modal web action
    Then the step should succeed
    When I run the :check_proxy_infra_value_in_operator_modal web action
    Then the step should succeed
    When I run the :check_fips_mode_infras_value_in_operator_modal web action
    Then the step should succeed

    # check operator KEDA has infrastructure feature && valid subscription badge in operator modal
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I run the :click_checkbox_proxy_from_infrastructure_features web action
    Then the step should succeed
    When I perform the :open_operator_modal web action with:
      | operator_name | KEDA |
    Then the step should succeed
    When I run the :check_disconnected_infra_value web action
    Then the step should succeed
    When I run the :check_proxy_infra_value web action
    Then the step should succeed
    When I run the :check_fips_infra_value web action
    Then the step should fail
    When I run the :check_3scale_subs_value web action
    Then the step should succeed
    When I run the :check_integration_subs_value web action
    Then the step should succeed

    # check operator Kubestone only has infrastructure feature badge in operator modal
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I run the :click_checkbox_fips_from_infrastructure_features web action
    Then the step should succeed
    When I perform the :open_operator_modal web action with:
      | operator_name | Kubestone |
    Then the step should succeed
    When I run the :check_disconnected_infra_value web action
    Then the step should succeed
    When I run the :check_proxy_infra_value web action
    Then the step should succeed
    When I run the :check_fips_infra_value web action
    Then the step should succeed
    When I run the :check_3scale_subs_value web action
    Then the step should fail
