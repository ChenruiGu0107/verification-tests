Feature: operatorhub feature related

  # @author hasha@redhat.com
  # @case_id OCP-24340
  @admin
  @destructive
  Scenario: Add "custom form" vs "YAML editor" on "Create Custom Resource" page
    Given the master version >= "4.3"
    Given I have a project
    Given evaluation of `project.name` is stored in the :userproject_name clipboard
    Given admin creates "ui-auto-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators:latest"
    Given I switch to the first user
    Given the first user is cluster-admin

    And I open admin console in a browser
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | etcd                        |
      | catalog_name     | ui-auto-operators           |
      | target_namespace | <%= cb.userproject_name %>  |
    Then the step should succeed
    When I perform the :select_target_namespace web action with:
      | project_name | <%= cb.userproject_name %> |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed

    # wait until etcd operator is successfully installed
    Given I use the "<%= cb.userproject_name %>" project
    Given a pod becomes ready with labels:
      | name=etcd-operator-alm-owned |

    # create etcd Cluster via Edit Form
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= cb.userproject_name %> |
    Then the step should succeed
    When I perform the :create_custom_resource web action with:
      | api      | etcd Cluster |
    Then the step should succeed
    When I run the :open_edit_form_view web action
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
      | image               | quay.io/openshifttest/custom-keycloak@sha256:14af7be507288acca377896ea07b390901795598a539b5128841a77fc669d10d |
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
    When I run the :click_subscribe_button web action
    Then the step should succeed
    """
    Given I wait for the "keycloak-operator" subscription to appear in the "<%= cb.proj_name %>" project up to 30 seconds

    # console will show 'Catalog Source Removed' on Subscription page when CatalogSource is removed
    When I run the :goto_catalog_source_page web action
    Then the step should succeed
    When I perform the :delete_catalogsource_kabab_operation web action with:
      | resource_name | custom-cs-keycloak |
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
    When I run the :check_catalogsource_removed_message web action
    Then the step should succeed

    # create namespace scoped CatalogSource
    When I perform the :create_catalog_source web action with:
      | catalog_source_name | custom-cs-keycloak-ns       |
      | display_name        | Custom Catalog Source NS    |
      | publisher_name      | OpenShift QE                |
      | item                | default                     |
      | image               | quay.io/openshifttest/custom-keycloak@sha256:14af7be507288acca377896ea07b390901795598a539b5128841a77fc669d10d |
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
    Given evaluation of `project.name` is stored in the :userproject_name clipboard
    Given I obtain test data file "deployment/vul_deployment.yaml"
    When I run the :create client command with:
      | f | vul_deployment.yaml |
    Then the step should succeed

    Given admin creates "ui-auto-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators:latest"
    Given I switch to the first user
    Given the first user is cluster-admin
    Given I use the "<%= cb.userproject_name %>" project

    # install container security operator
    Given I open admin console in a browser
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | container-security-operator |
      | catalog_name     | ui-auto-operators           |
      | target_namespace | <%= cb.userproject_name %>  |
    Then the step should succeed
    When I perform the :select_target_namespace web action with:
      | project_name | <%= cb.userproject_name %> |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed

    # wait until container security operator is successfully installed
    Given a pod becomes ready with labels:
      | name=container-security-operator-alm-owned |
    Then I wait for the "sha256.eb253bef954ea760b834e6d736ad40fa900a1b8b688d97aac5cc9487b91f1b6d" image_manifest_vuln to appear in the "<%= cb.userproject_name %>" project up to 30 seconds


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
      | link_url | k8s/all-namespaces/secscan.quay.redhat.com~v1alpha1~ImageManifestVuln?name=sha256.eb253bef954ea760b834e6d736ad40fa900a1b8b688d97aac5cc9487b91f1b6d |
    Then the step should succeed

    #check Image Manifest Vulnerabilities page for 4.4 and above
    When I perform the :goto_ImageManifestVuln_list_page web action with:
      | project_name |  <%= cb.userproject_name %> |
    Then the step should succeed
    When I run the :check_highest_severity_column_in_table web action
    Then the step should succeed
    When I run the :check_affected_pods_column_in_table web action
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Fixable |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Manifest  |
    Then the step should succeed
    When I perform the :goto_one_ImageManifestVuln_page web action with:
      | project_name |  <%= cb.userproject_name %> |
      | manifest     | sha256.eb253bef954ea760b834e6d736ad40fa900a1b8b688d97aac5cc9487b91f1b6d |
    Then the step should succeed
    When I run the :wait_box_loaded web action
    Then the step should succeed
    When I run the :check_affected_pods_tab web action
    Then the step should succeed

    #uninstall the operator on web console
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= cb.userproject_name %> |
    Then the step should succeed
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I perform the :uninstall_operator_on_console web action with:
      | resource_name | Quay Container Security |
    Then the step should succeed
    """
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

    When I perform the :filter_by_keyword web action with:
      | keyword | kibana |
    Then the step should succeed
    When I run the :check_logging_operator_filtered_out web action
    Then the step should succeed

  # @author hasha@redhat.com
  # @case_id OCP-27666
  @admin
  @destructive
  Scenario: Add Special support link for template and operator
    Given the master version >= "4.4"
    Given I have a project
    Given evaluation of `project.name` is stored in the :userproject_name clipboard
    #check support link for template
    Given I obtain test data file "image/language-image-templates/php-55-rhel7-stibuild.json"
    When I run the :create client command with:
      | f | php-55-rhel7-stibuild.json |
    Then the step should succeed
    Given I successfully merge patch resource "template/php-helloworld-sample" with:
      | {"metadata":{"annotations":{"openshift.io/support-url":"https://www.redhat.com"}}} |
    Given I open admin console in a browser
    When I perform the :goto_catalog_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :filter_by_template_type web action
    Then the step should succeed
    When I perform the :filter_by_keyword web action with:
      | keyword | php |
    Then the step should succeed

    When I perform the :click_catalog_item web action with:
      | catalog_item | php-helloworld-sample |
    Then the step should succeed
    When I perform the :check_the_support_link web action with:
      | link_url | https://www.redhat.com |
    Then the step should succeed

    #check support link for operators
    Given admin creates "ui-auto-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators:latest"
    Given I switch to the first user
    Given the first user is cluster-admin
    Given I use the "<%= cb.userproject_name %>" project
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | cockroachdb                |
      | catalog_name     | ui-auto-operators          |
      | target_namespace | <%= cb.userproject_name %> |
    Then the step should succeed
    When I perform the :select_target_namespace web action with:
      | project_name | <%= cb.userproject_name %> |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed

    And I wait for the "cockroachdb" subscription to become ready
    And evaluation of `subscription("cockroachdb").current_csv` is stored in the :cockroachdb_csv clipboard
    Given I successfully merge patch resource "csv/<%= cb.cockroachdb_csv %>" with:
      | {"metadata":{"annotations":{"marketplace.openshift.io/support-workflow": "https://marketplace.redhat.com/en-us/operators/cockroachdb-certified-rhmp/support-updated"}}} |
    When I perform the :goto_csv_detail_page web action with:
      | project_name | <%= cb.userproject_name %>  |
      | csv_name     | <%= cb.cockroachdb_csv %>   |
    Then the step should succeed
    When I perform the :check_the_support_link web action with:
      | link_url | https://marketplace.redhat.com/en-us/operators/cockroachdb-certified-rhmp/support-updated |
    Then the step should succeed

    #check support link for Operator Backed service
    When I perform the :goto_catalog_page web action with:
      | project_name | <%= cb.userproject_name %> |
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
  @destructive
  Scenario: Form & YAML Toggle Interactions for Create Operand
    Given the master version >= "4.5"
    Given I have a project
    Given evaluation of `project.name` is stored in the :userproject_name clipboard
    Given admin creates "ui-auto-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators:latest"
    Given I switch to the first user
    Given the first user is cluster-admin
    Given I use the "<%= cb.userproject_name %>" project

    When I open admin console in a browser
    Then the step should succeed
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | radanalytics-spark         |
      | catalog_name     | ui-auto-operators          |
      | target_namespace | <%= cb.userproject_name %> |
    Then the step should succeed
    When I perform the :select_target_namespace web action with:
      | project_name | <%= cb.userproject_name %> |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    And I wait for the "radanalytics-spark" subscription to become ready
    And evaluation of `subscription("radanalytics-spark").current_csv` is stored in the :spark_csv clipboard
    When I perform the :goto_operand_list_page web action with:
      | project_name | <%= cb.userproject_name %>       |
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
    Given I use the "openshift-marketplace" project
    Given I obtain test data file "olm/catalogsource-template.yaml"
    When I process and create:
      | f | catalogsource-template.yaml |
      | p | NAME=custom-console-catalogsource-infrasubs         |
      | p | IMAGE=quay.io/openshifttest/uioperatorsinfra:latest |
      | p | DISPLAYNAME=Custom Console AUTO Testing             |
    Then the step should succeed
    And a pod becomes ready with labels:
      | olm.catalogSource=custom-console-catalogsource-infrasubs |
    Given I wait up to 120 seconds for the steps to pass:
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

    # check operator has infrastructure feature && valid subscription badge in operator modal
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :click_checkbox_from_provider_type web action with:
      | text | Custom Console AUTO Testing |
    Then the step should succeed
    When I perform the :open_operator_modal web action with:
      | operator_name | keda |
    Then the step should succeed
    When I run the :check_disconnected_infra_value web action
    Then the step should succeed
    When I run the :check_proxy_infra_value web action
    Then the step should succeed
    When I run the :check_fips_infra_value web action
    Then the step should fail
    When I run the :check_integration_subs_value web action
    Then the step should succeed
    When I run the :check_3scale_subs_value web action
    Then the step should fail

    # check operator only has infrastructure feature badge in operator modal
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :click_checkbox_from_provider_type web action with:
      | text | Custom Console AUTO Testing |
    Then the step should succeed
    When I perform the :open_operator_modal web action with:
      | operator_name | kubestone |
    Then the step should succeed
    When I run the :check_disconnected_infra_value web action
    Then the step should succeed
    When I run the :check_proxy_infra_value web action
    Then the step should succeed
    When I run the :check_fips_infra_value web action
    Then the step should succeed
    When I run the :check_3scale_subs_value web action
    Then the step should fail

    # check operator only has Valid Subscription badge in operator modal
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :click_checkbox_from_provider_type web action with:
      | text | Custom Console AUTO Testing |
    Then the step should succeed
    When I perform the :open_operator_modal web action with:
      | operator_name | cockroachdb |
    Then the step should succeed
    When I run the :check_integration_subs_value web action
    Then the step should succeed
    When I run the :check_3scale_subs_value web action
    Then the step should succeed
    When I run the :check_disconnected_infra_value web action
    Then the step should fail

    # check operator Valid Subscription annotation accepts any string value
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :click_checkbox_from_provider_type web action with:
      | text | Custom Console AUTO Testing |
    Then the step should succeed
    When I perform the :open_operator_modal web action with:
      | operator_name | postgresql |
    Then the step should succeed
    When I run the :check_other_subs_value web action
    Then the step should succeed        

    # check operator has no Valid Subscription and Infrastucture Features property shown
    # when no annotations
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :click_checkbox_from_provider_type web action with:
      | text | Custom Console AUTO Testing |
    Then the step should succeed
    When I perform the :open_operator_modal web action with:
      | operator_name | teiid |
    Then the step should succeed
    When I run the :check_validsubscription_property_missing web action
    Then the step should succeed
    When I run the :check_infrastructure_property_missing web action
    Then the step should succeed    


  # @author hasha@redhat.com
  # @case_id OCP-29477
  @admin
  @destructive
  Scenario: Populate displayName of CatalogSource into filter sidebar for custom catalogs
    Given the master version >= "4.5"
    Given I have a project
    Given the first user is cluster-admin
    Given admin ensures "custom-cs-keycloak" catalog_source is deleted from the "openshift-marketplace" project after scenario
    Given admin ensures "custom-cs-akka" catalog_source is deleted from the "openshift-marketplace" project after scenario

    # create catalogsource with displayname
    Given I open admin console in a browser
    When I perform the :create_catalog_source web action with:
      | catalog_source_name | custom-cs-keycloak        |
      | display_name        | custom-cs-keycloak        |
      | publisher_name      | OpenShift QE              |
      | image               | quay.io/openshifttest/custom-keycloak@sha256:14af7be507288acca377896ea07b390901795598a539b5128841a77fc669d10d |
    Then the step should succeed

    When I perform the :create_catalog_source web action with:
      | catalog_source_name | custom-cs-akka |
      | display_name        | custom-cs-akka |
      | publisher_name      | OpenShift QE   |
      | image               | quay.io/openshifttest/akka-operator@sha256:122e47f4d7788465ca980f172494e14ed7e1f565f0d0c2e3eba7f666b70d465c |
    Then the step should succeed
    Given I use the "openshift-marketplace" project
    And a pod becomes ready with labels:
      | olm.catalogSource=custom-cs-keycloak |
    And a pod becomes ready with labels:
      | olm.catalogSource=custom-cs-akka |
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I get project packagemanifests
    Then the output should match:
      | keycloak-operator.*custom-cs-keycloak |
      | akka-cluster-operator.*custom-cs-akka |
    """

    # check the filter with displayname of catalogsource
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :click_checkbox_from_provider_type web action with:
      | text | custom-cs-keycloak |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | Keycloak Operator |
    Then the step should succeed
    When I perform the :click_checkbox_from_provider_type web action with:
      | text | custom-cs-akka |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | Akka Cluster Operator |
    Then the step should succeed

    # check filter missing after deleting catalogsource
    When I run the :goto_catalog_source_page web action
    Then the step should succeed
    When I perform the :delete_catalogsource_kabab_operation web action with:
      | resource_name | custom-cs-akka |
    Then the step should succeed
    When I perform the :confirm_deletion web action with:
      | resource_name | custom-cs-akka |
    Then the step should succeed
    Given I use the "openshift-marketplace" project
    Given I wait for the resource "catalogsource" named "custom-cs-akka" to disappear within 30 seconds
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :click_checkbox_from_provider_type web action with:
      | text | custom-cs-akka |
    Then the step should fail

    #check the filter changed as the displayname changed
    Given I run the :patch admin command with:
      | resource      | catalogsource                           |
      | resource_name | custom-cs-keycloak                      |
      | p             | {"spec": {"displayName": "cs-display"}} |
      | type          | merge                                   |
      | namespace     | openshift-marketplace                   |
    Then the step should succeed
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :click_checkbox_from_provider_type web action with:
      | text | cs-display |
    Then the step should succeed

  # @author hasha@redhat.com
  # @case_id OCP-27646
  @admin
  @destructive
  Scenario: Check marketplace operator annotations
    Given the master version >= "4.4"
    Given admin creates "ui-auto-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators:latest"
    Given I switch to the first user
    Given the first user is cluster-admin
    When I run the :get client command with:
      | resource      | packagemanifests      |
      | resource_name | argocd-operator       |
      | n             | openshift-marketplace |
      | output        | yaml                  |
    Then the step should succeed
    Given evaluation of `@result[:parsed]["status"]["channels"][0]["currentCSVDesc"]["annotations"]["marketplace.openshift.io/action-text"]` is stored in the :actiontext clipboard
    Given evaluation of `@result[:parsed]["status"]["channels"][0]["currentCSVDesc"]["annotations"]["marketplace.openshift.io/remote-workflow"]` is stored in the :remoteworkflow clipboard

    When I open admin console in a browser
    Then the step should succeed
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :open_operator_modal web action with:
      | operator_name | Argo CD ui test |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | <%= cb.actiontext %>     |
      | link_url | <%= cb.remoteworkflow %> |
    Then the step should succeed

    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I run the :click_qe_customized_provider web action
    Then the step should succeed
    When I perform the :open_operator_modal web action with:
      | operator_name | Teiid |
    Then the step should succeed
    When I run the :check_customized_operator_purchase_link web action
    Then the step should succeed

  # @author hasha@redhat.com
  # @case_id OCP-27631
  @admin
  @destructive
  Scenario: check operator install process when operator bundle pre-defined namespace/installplan/monitoring
    Given the master version >= "4.4"
    Given admin creates "ui-auto-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators:latest"
    Given I switch to the first user
    Given I have a project
    Given the first user is cluster-admin
    And I open admin console in a browser

    #The operators that pre-defined the install mode is not recommending an install namespace
    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | serverless-operator |
      | catalog_name     | ui-auto-operators   |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    """
    When I run the :check_all_namespace_installation_mode_without_recommended_ns web action
    Then the step should succeed

    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | spark-gcp           |
      | catalog_name     | ui-auto-operators   |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    """
    When I run the :check_specific_namespace_installation_mode_without_recommended_ns web action
    Then the step should succeed
    When I perform the :select_installed_namespace web action with:
      | project_name | openshift-operators |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | Namespace does not support installation mode |
    Then the step should succeed

    # operator has recommended ns for installation but user still can subscribe to other ns
    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | sealed-secrets-operator-helm |
      | catalog_name     | community-operators          |
      | target_namespace | <%= project.name %>          |
    Then the step should succeed
    """
    When I perform the :check_specific_namespace_installation_mode_with_recommended_ns web action with:
      | recommended_ns | sealed-secrets |
    Then the step should succeed

    When I run the :click_radio_to_pick_ns web action
    Then the step should succeed
    When I perform the :select_installed_namespace web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    Given I wait for the "sealed-secrets-operator-helm" subscription to appear in the "<%= project.name %>" project up to 30 seconds

    #enable metrics service discovery
    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | ocs-operator        |
      | catalog_name     | ui-auto-operators   |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    """
    When I run the :enable_cluster_monitoring web action
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    And admin ensures "openshift-storage" project is deleted after scenario
    And I wait for the "openshift-storage" projects to appear
    When I run the :describe admin command with:
      | resource | project           |
      | name     | openshift-storage |
    Then the output should contain:
      | openshift.io/cluster-monitoring=true |

  # @author yanpzhan@redhat.com
  # @case_id OCP-24478
  @admin
  Scenario: Configure Knative Serving from Cluster Settings
    Given the master version >= "4.2"

    Given the first user is cluster-admin
    Given admin ensures "serverless-operator" subscription is deleted from the "openshift-operators" project after scenario
    Given I open admin console in a browser
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | serverless-operator |
      | catalog_name     | redhat-operators    |
      | target_namespace | openshift-operators |
    Then the step should succeed
    Given admin ensures "openshift-serverless" project is deleted after scenario
    When I run the :click_subscribe_button web action
    Then the step should succeed
    Given I use the "openshift-serverless" project
    Given I wait for the "serverless-operator" subscription to appear
    Given admin waits for the "serverless-operator" subscription to become ready in the "openshift-serverless" project up to 240 seconds
    And evaluation of `subscription("serverless-operator").current_csv` is stored in the :current_csv clipboard
    Given admin ensures "<%= cb.current_csv %>" clusterserviceversions is deleted from the "openshift-serverless" project after scenario
    Given admin ensures "knative-serving" project is deleted after scenario
    # create knative-serving namespace and instance
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/knative-serving/serving.yaml |
    Then the step should succeed
    When I run the :goto_global_configuration_page web action
    Then the step should succeed
    When I perform the :click_link_with_text web action with:
      | text     | KnativeServing |
      | link_url | operator.knative.dev~v1alpha1~KnativeServing/knative-serving |
    Then the step should succeed
    When I run the :check_edit_yaml_enabled web action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-29724
  @admin
  Scenario: Check Installed Operators list page
    Given the master version >= "4.5"
    # prepare an operator for current namespace
    Given I have a project
    Given the first user is cluster-admin
    When I open admin console in a browser
    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | spark-gcp           |
      | catalog_name     | community-operators |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    """
    Given I wait for the "spark-gcp" subscription to become ready in the "<%= project.name %>" project up to 360 seconds
    And evaluation of `subscription("spark-gcp").current_csv` is stored in the :spark_csv clipboard
    And evaluation of `project.name` is stored in the :project_name clipboard

    # prepare an operator for all namespaces
    Given admin ensures "argocd-operator" subscription is deleted from the "openshift-operators" project after scenario
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | argocd-operator     |
      | catalog_name     | community-operators |
      | target_namespace |                     |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    """
    Given I wait for the "argocd-operator" subscription to become ready in the "openshift-operators" project up to 360 seconds
    Given admin ensures "<%= subscription('argocd-operator').current_csv %>" clusterserviceversions is deleted from the "openshift-operators" project after scenario

    ## project selector: one project
    #check column: Managed Namespaces
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= cb.project_name %> |
    Then the step should succeed
    When I run the :check_column_header_for_one_namespace web action
    Then the step should succeed
    When I perform the :check_managed_namespace_column_installed_for_one_ns web action with:
      | operator_name | Spark Operator         |
      | project_name  | <%= cb.project_name %> |
    Then the step should succeed
    When I perform the :check_managed_namespace_column_installed_for_all_ns web action with:
      | operator_name | Argo CD |
    Then the step should succeed

    ## project selector: all projects
    #check column: Namespace
    When I run the :goto_all_installed_operators_page web action
    Then the step should succeed
    When I perform the :check_namespace_column_installed_for_one_ns_under_all_projects web action with:
      | operator_name | Spark Operator         |
      | project_name  | <%= cb.project_name %> |
    Then the step should succeed
    When I perform the :check_namespace_column_installed_for_all_ns_under_all_projects web action with:
      | operator_name | Argo CD |
    Then the step should succeed
    #check column: Managed Namespaces
    When I perform the :check_managed_namespace_column_installed_for_one_ns_under_all_projects web action with:
      | operator_name | Spark Operator         |
      | project_name  | <%= cb.project_name %> |
    Then the step should succeed
    When I perform the :check_managed_namespace_column_installed_for_all_ns_under_all_projects web action with:
      | operator_name | Argo CD |
    Then the step should succeed

    ## check operators detail page and subscription page
    When I perform the :goto_csv_detail_page web action with:
      | project_name | <%= cb.project_name %> |
      | csv_name     | <%= cb.spark_csv %>    |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | namespace         | <%= cb.project_name %> |
      | managed_namespace | <%= cb.project_name %> |
    Then the step should succeed
    When I perform the :goto_csv_subscription_page web action with:
      | project_name | <%= cb.project_name %> |
      | csv_name     | <%= cb.spark_csv %>    |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | namespace | <%= cb.project_name %> |
    Then the step should succeed

    When I perform the :goto_csv_detail_page web action with:
      | project_name | openshift-operators                                            |
      | csv_name     | <%= subscription("argocd-operator").current_csv %> |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | namespace         | openshift-operators |
      | managed_namespace | All Namespaces      |
    Then the step should succeed
    When I perform the :goto_csv_subscription_page web action with:
      | project_name | openshift-operators                                            |
      | csv_name     | <%= subscription("argocd-operator").current_csv %> |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | namespace | openshift-operators |
    Then the step should succeed

  # @author hasha@redhat.com
  # @case_id OCP-26917
  @admin
  Scenario: Custom Resource List view updates
    Given the master version >= "4.4"
    Given I have a project
    Given evaluation of `project.name` is stored in the :userproject_name clipboard
    Given the first user is cluster-admin
    And I open admin console in a browser
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | etcd                |
      | catalog_name     | community-operators |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    When I perform the :select_target_namespace web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=etcd-operator-alm-owned |
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :create_custom_resource web action with:
      | api | etcd Cluster |
    Then the step should succeed
    When I run the :open_edit_form_view web action
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    Given admin checks that the "example" etcd_cluster exists in the "<%= project.name %>" project

    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | postgresql          |
      | catalog_name     | community-operators |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    When I perform the :select_target_namespace web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=postgres-operator |
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :create_custom_resource web action with:
      | api | Postgres Primary Cluster Member |
    Then the step should succeed
    When I run the :open_edit_form_view web action
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    Given admin checks that the "hippo" pgcluster exists in the "<%= project.name %>" project

    Given admin ensures "kiali-ossm" subscription is deleted from the "openshift-operators" project after scenario
    Given admin ensures "kiali-operator.v1.24.7" clusterserviceversions is deleted from the "openshift-operators" project after scenario
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | kiali-ossm          |
      | catalog_name     | redhat-operators    |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    Given I use the "openshift-operators" project
    And a pod becomes ready with labels:
      | app=kiali-operator |
    And evaluation of `subscription("kiali-ossm").current_csv` is stored in the :kiali_csv clipboard
    Given I use the "<%= cb.userproject_name %>" project
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= cb.userproject_name %> |
    Then the step should succeed
    When I perform the :create_custom_resource web action with:
      | api | Kiali |
    Then the step should succeed
    When I run the :open_edit_form_view web action
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    Given admin checks that the "kiali" kiali exists in the "<%= cb.userproject_name %>" project
    #check phase status
    When I run the :get admin command with:
      | resource      | etcdcluster                |
      | resource_name | example                    |
      | n             | <%= cb.userproject_name %> |
      | output        | yaml                       |
    Then the step should succeed
    Given evaluation of `@result[:parsed]["status"]["phase"]` is stored in the :etcd_phase clipboard
    And evaluation of `subscription("etcd").current_csv` is stored in the :etcd_csv clipboard
    When I perform the :goto_operand_list_page web action with:
      | project_name | <%= cb.userproject_name %>                   |
      | csv_name     | <%= cb.etcd_csv %>                           |
      | operand_name | etcd.database.coreos.com~v1beta2~EtcdCluster |
    Then the step should succeed
    When I perform the :check_phase_status web action with:
      | status | <%= cb.etcd_phase %> |
    Then the step should succeed

    #check state status
    When I run the :get admin command with:
      | resource      | pgcluster                  |
      | resource_name | hippo                      |
      | n             | <%= cb.userproject_name %> |
      | output        | yaml                       |
    Then the step should succeed
    Given evaluation of `@result[:parsed]["status"]["state"]` is stored in the :postgresql_state clipboard
    And evaluation of `subscription("postgresql").current_csv` is stored in the :postgresql_csv clipboard
    When I perform the :goto_operand_list_page web action with:
      | project_name | <%= cb.userproject_name %>   |
      | csv_name     | <%= cb.postgresql_csv %>     |
      | operand_name | crunchydata.com~v1~Pgcluster |
    Then the step should succeed
    When I perform the :check_state_status web action with:
      | status | <%= cb.postgresql_state %> |
    Then the step should succeed

    # check condition status
    When I run the :get admin command with:
      | resource      | kiali                      |
      | resource_name | kiali                      |
      | n             | <%= cb.userproject_name %> |
      | output        | yaml                       |
    Then the step should succeed
    Given evaluation of `@result[:parsed]["status"]["conditions"][-1]["type"]` is stored in the :kiali_condition clipboard
    When I perform the :goto_operand_list_page web action with:
      | project_name | <%= cb.userproject_name %> |
      | csv_name     | <%= cb.kiali_csv %>        |
      | operand_name | kiali.io~v1alpha1~Kiali    |
    Then the step should succeed
    When I perform the :check_condition_status web action with:
      | status | <%= cb.kiali_condition %> |
    Then the step should succeed

    #check all instance page
    When I perform the :goto_operator_all_instance_page web action with:
      | project_name | <%= cb.userproject_name %> |
      | csv_name     | <%= cb.etcd_csv %>         |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Status |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-32151
  @admin
  Scenario: k8sResourcePrefix specDescriptor supports CRD instance
    Given the master version >= "4.6"
    Given I obtain test data file "customresource/mock-k8s-crd.yaml"
    Given I obtain test data file "customresource/mock-k8s-operator-csv.yaml"
    Given I obtain test data file "customresource/mock-k8s-cr.yaml"
    Given admin ensures "mock-k8s-dropdown-resources.test.tectonic.com" customresourcedefinitions is deleted after scenario
    When I run the :create admin command with:
      | f | mock-k8s-crd.yaml |
    Then the step should succeed
    Given I have a project
    When I run the :create admin command with:
      | f | mock-k8s-operator-csv.yaml |
      | f | mock-k8s-cr.yaml           |
      | n | <%= project.name %>        |
    Then the step should succeed
    Given the first user is cluster-admin
    And I open admin console in a browser
    When I perform the :goto_operand_list_page web action with:
      | project_name | <%= project.name %>                          |
      | csv_name     | mock-k8s-resource-dropdown-operator          |
      | operand_name | test.tectonic.com~v1~MockK8sDropdownResource |
    Then the step should succeed
    When I run the :click_create_mockk8sdropdownresouce web action
    Then the step should succeed
    When I run the :open_k8sresource_dropdown web action
    Then the step should succeed
    When I perform the :check_k8sresource_dropdown_items web action with:
      | item | mock-k8s-dropdown-resource-instance-1 |
    Then the step should succeed
    When I perform the :check_k8sresource_dropdown_items web action with:
      | item | mock-k8s-dropdown-resource-instance-2 |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-33743
  @admin
  @destructive
  Scenario: Add button to operator install workflow to direct user to create operand based on annotation
    Given the master version >= "4.6"
    Given I have a project
    Given evaluation of `project.name` is stored in the :userproject_name clipboard
    Given admin creates "ui-auto-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators@sha256:feb39d5dca35fcbf73713672016b8c802146252a96e3864a0a34209b154b6482"

    # check required badge and button during operator installation phase
    Given I switch to the first user
    Given I use the "<%= cb.userproject_name %>" project
    Given the first user is cluster-admin
    Given I open admin console in a browser
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | portworx-essentials         |
      | catalog_name     | ui-auto-operators           |
      | target_namespace | <%= cb.userproject_name %>  |
    Then the step should succeed
    When I run the :check_required_badge_on_operator_installation_page web action
    Then the step should succeed
    When I perform the :select_target_namespace web action with:
      | project_name | <%= cb.userproject_name %> |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    When I run the :check_create_operand_button_and_requied_badge_when_ready web action
    Then the step should succeed
    When I perform the :check_operand_button_link web action with:
      | project_name | <%= cb.userproject_name %> |
    Then the step should succeed

    # check required badge and button on CSV details page
    When I perform the :goto_csv_detail_page web action with:
      | project_name | <%= cb.userproject_name %>  |
      | csv_name     | portworx-essentials.v1.3.4  |
    Then the step should succeed
    When I perform the :check_create_operand_button_and_requied_badge_on_csv_details web action with:
      | project_name | <%= cb.userproject_name %> |
    Then the step should succeed
    When I run the :click_create_storagecluster_button web action
    Then the step should succeed
    When I run the :switch_to_yaml_view web action
    Then the step should succeed
    When I perform the :check_content_in_yaml_editor web action with:
      | yaml_content | autotest |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-29690
  @admin
  @destructive
  Scenario: Show operator installation flow
    Given the master version >= "4.6"
    Given admin creates "ui-auto-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators:latest"
    Given I switch to the first user
    Given I have a project
    Given the first user is cluster-admin
    Given I open admin console in a browser
    When I perform the :subscribe_operator_to_namespace_with_manually_approval web action with:
      | package_name     | strimzi-kafka-operator |
      | catalog_name     | ui-auto-operators      |
      | target_namespace | <%= project.name %>    |
    Then the step should succeed
    When I run the :check_manual_approve_info web action
    Then the step should succeed

    When I run the :click_approve_button web action
    Then the step should succeed
    When I perform the :check_message_during_installing web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I get project csvs
    And the output should match "strimzi-cluster-operator.*Failed"
    """
    When I run the :check_installation_failure_message web action
    Then the step should succeed
    When I perform the :check_view_error_button web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-33748
  @admin
  @destructive
  Scenario: schema grouping for specDescriptors and statusDescriptors
    Given the master version >= "4.6"
    Given admin creates "ui-auto-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators@sha256:feb39d5dca35fcbf73713672016b8c802146252a96e3864a0a34209b154b6482"
    Given I switch to the first user
    Given I have a project
    Given the first user is cluster-admin
    Given I open admin console in a browser
    When I perform the :subscribe_operator_to_namespace web action with:
      | package_name     | argocd-operator      |
      | catalog_name     | ui-auto-operators    |
      | target_namespace | <%= project.name %>  |
    Then the step should succeed
    Given admin waits for the "argocd-operator" subscription to become ready in the "<%= project.name %>" project up to 360 seconds
    And evaluation of `subscription("argocd-operator").current_csv` is stored in the :argocd_csv clipboard
    When I perform the :create_operand web action with:
      | project_name | <%= project.name %>   |
      | csv_name     | <%= cb.argocd_csv %>  |
      | operand_kind | ArgoCD                |
    Then the step should succeed
    Given admin wait for the "example-argocd" argo_c_d to appear in the "<%= project.name %>" project up to 10 seconds
    When I perform the :goto_operand_details_page web action with:
      | project_name    | <%= project.name %>  |
      | csv_name        | <%= cb.argocd_csv %> |
      | operand_group   | argoproj.io          |
      | operand_version | v1alpha1             |
      | operand_kind    | ArgoCD               |
      | operand_name    | example-argocd       |
    Then the step should succeed
    When I run the :check_status_descriptor_grouping web action
    Then the step should succeed
    When I run the :check_spec_descriptor_grouping web action
    Then the step should succeed
    When I perform the :set_controller_group_resource_limits web action with:
      | cpu_cores_value | 500m |
      | memory_value    | 50Mi |
      | storage_value   | 50Mi |
    Then the step should succeed
    Given I wait up to 10 seconds for the steps to pass:
    """
    When I perform the :check_resource_requirement_values web action with:
      | cpu_cores_value | 500m |
      | memory_value    | 50Mi |
      | storage_value   | 50Mi |
    Then the step should succeed
    """
    When I perform the :set_controller_group_resource_requests web action with:
      | cpu_cores_value | 300m |
      | memory_value    | 30Mi |
      | storage_value   | 30Mi |
    Then the step should succeed
    # wait for changes updated in YAML
    Given I wait up to 10 seconds for the steps to pass:
    """
    When I get project argo_c_d as YAML
    And the output should match:
      | cpu.*300m               |
      | ephemeral-storage.*30Mi |
      | memory.*30Mi            |
    """
    # then check on console
    Given I wait up to 5 seconds for the steps to pass:
    """
    When I perform the :check_resource_requirement_values web action with:
      | cpu_cores_value | 300m |
      | memory_value    | 30Mi |
      | storage_value   | 30Mi |
    Then the step should succeed
    """

  # @author yapei@redhat.com
  # @case_id OCP-33716
  @admin
  @destructive
  Scenario: Check warnings when editing operator managed resources
    Given the master version >= "4.6"
    Given admin creates "ui-auto-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators@sha256:feb39d5dca35fcbf73713672016b8c802146252a96e3864a0a34209b154b6482"
    Given I switch to the first user
    Given I have a project
    Given the first user is cluster-admin
    Given I open admin console in a browser
    When I perform the :subscribe_operator_to_namespace web action with:
      | package_name     | argocd-operator      |
      | catalog_name     | ui-auto-operators    |
      | target_namespace | <%= project.name %>  |
    Then the step should succeed
    Given admin waits for the "argocd-operator" subscription to become ready in the "<%= project.name %>" project up to 360 seconds
    And evaluation of `subscription("argocd-operator").current_csv` is stored in the :argocd_csv clipboard
    When I perform the :create_operand web action with:
      | project_name | <%= project.name %>   |
      | csv_name     | <%= cb.argocd_csv %>  |
      | operand_kind | ArgoCD                |
    Then the step should succeed
    Given admin wait for the "example-argocd" argo_c_d to appear in the "<%= project.name %>" project up to 10 seconds
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I get project configmaps
    Then the output should match "argocd-cm"
    When I get project deployments
    Then the output should match "example-argocd-redis"
    """
    When I perform the :goto_one_configmap_page web action with:
      | project_name   | <%= project.name %>  |
      | configmap_name | argocd-cm            |
    Then the step should succeed
    When I perform the :check_managed_by_badge web action with:
      | project_name    | <%= project.name %>  |
      | csv_name        | <%= cb.argocd_csv %> |
      | operand_group   | argoproj.io          |
      | operand_version | v1alpha1             |
      | operand_kind    | ArgoCD               |
      | operand_name    | example-argocd       |
    Then the step should succeed
    When I perform the :check_resource_owner_type_and_link web action with:
      | project_name     | <%= project.name %> |
      | resource_group   | argoproj.io         |
      | resource_version | v1alpha1            |
      | resource_kind    | ArgoCD              |
      | resource_name    | example-argocd      |
    Then the step should succeed
    When I perform the :goto_one_deployment_page web action with:
      | project_name | <%= project.name %>  |
      | deploy_name  | example-argocd-redis |
    Then the step should succeed
    When I perform the :check_managed_by_badge web action with:
      | project_name    | <%= project.name %>  |
      | csv_name        | <%= cb.argocd_csv %> |
      | operand_group   | argoproj.io          |
      | operand_version | v1alpha1             |
      | operand_kind    | ArgoCD               |
      | operand_name    | example-argocd       |
    Then the step should succeed
    When I perform the :check_resource_owner_type_and_link web action with:
      | project_name     | <%= project.name %> |
      | resource_group   | argoproj.io         |
      | resource_version | v1alpha1            |
      | resource_kind    | ArgoCD              |
      | resource_name    | example-argocd      |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-33053
  @admin
  @destructive
  Scenario: Check Operand description, subscription status and event tab
    Given the master version >= "4.6"
    Given admin creates "ui-auto-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators@sha256:feb39d5dca35fcbf73713672016b8c802146252a96e3864a0a34209b154b6482"
    Given I switch to the first user
    Given I have a project
    Given the first user is cluster-admin
    Given I open admin console in a browser

    # check operand description on operator subscription page
    When I perform the :check_operand_des_during_operator_subscription web action with:
      | package_name     | argocd-operator     |
      | catalog_name     | ui-auto-operators   |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    Given admin waits for the "argocd-operator" subscription to become ready in the "<%= project.name %>" project up to 360 seconds
    And evaluation of `subscription("argocd-operator").current_csv` is stored in the :argocd_csv clipboard

    # check operand description on operator details page and Subscription page details
    When I perform the :goto_csv_detail_page web action with:
      | project_name | <%= project.name %>  |
      | csv_name     | <%= cb.argocd_csv %> |
    Then the step should succeed
    When I run the :check_truncated_description web action
    Then the step should succeed
    When I perform the :check_operator_subscription_details web action with:
      | subscription_name  | argocd-operator   |
      | catalogsource_name | ui-auto-operators |
    Then the step should succeed

    # check operand description on operand creation form
    When I perform the :check_operand_des_during_creating_operand web action with:
      | project_name | <%= project.name %>  |
      | csv_name     | <%= cb.argocd_csv %> |
      | operand_kind | Application          |
    Then the step should succeed
    Given admin wait for the "guestbook" application to appear in the "<%= project.name %>" project up to 10 seconds

    # then check operand Events page
    When I perform the :goto_operand_events_page web action with:
      | project_name    | <%= project.name %>  |
      | csv_name        | <%= cb.argocd_csv %> |
      | operand_group   | argoproj.io          |
      | operand_version | v1alpha1             |
      | operand_kind    | Application          |
      | operand_name    | guestbook            |
    Then the step should succeed
    When I run the :check_event_is_streaming web action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-28832
  @admin
  Scenario: Basic sync of YAML and Form for creating operator instance
    Given the master version >= "4.4"
    Given I have a project
    Given admin ensures "mock-resources.test.tectonic.com" custom_resource_definition is deleted after scenario
    Given I obtain test data file "customresource/mock-operator-csv-and-crd.yaml"
    When I run the :create admin command with:
      | f | mock-operator-csv-and-crd.yaml |
      | n | <%= project.name %>            |
    Then the step should succeed
    Given the first user is cluster-admin
    Given I open admin console in a browser
    When I perform the :goto_operand_list_page web action with:
      | project_name  | <%= project.name %>  |
      | csv_name      | mock-operator |
      | operand_name  | test.tectonic.com~v1~MockResource |
    Then the step should succeed
    When I perform the :click_create_operand_button web action with:
      | operand_kind | MockResource |
    Then the step should succeed
    When I perform the :set_operand_name web action with:
      | operand_name | mock-resource-instance-test |
    Then the step should succeed
    When I run the :remove_operand_label web action
    Then the step should succeed
    When I perform the :set_selector_value web action with:
      | selector_value | ERROR |
    Then the step should succeed
    When I perform the :set_password web action with:
      | password | testpassword |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I perform the :set_k8s_resource web action with:
      | k8s_resource | default |
    Then the step should succeed
    """
    When I perform the :set_pod_count web action with:
      | pod_count | 5 |
    Then the step should succeed
    When I run the :increase_pod_count web action
    Then the step should succeed
    When I run the :decrease_pod_count web action
    Then the step should succeed
    When I run the :toggle_boolean_switch web action
    Then the step should succeed
    When I run the :toggle_checkbox web action
    Then the step should succeed
    When I perform the :set_image_pull_policy web action with:
      | image_pull_policy | Always |
    Then the step should succeed
    When I perform the :set_update_strategy web action with:
      | update_strategy | RollingUpdate |
    Then the step should succeed
    When I perform the :set_simple_text web action with:
      | simple_text | my_simple_text_test |
    Then the step should succeed
    When I perform the :set_simple_number web action with:
      | simple_number | 3 |
    Then the step should succeed
    When I perform the :set_field_group web action with:
      | field_group_value_one | groupvalueone |
      | field_group_value_two | 6             |
    Then the step should succeed
    When I perform the :set_array_field_group web action with:
      | array_field_group_value_one            | my_arraygroup_value_one     |
      | array_field_group_value_two            | 8                           |
      | additional_array_field_group_value_one | my_add_arraygroup_value_one |
      | additional_array_field_group_value_two | 10                          |
    Then the step should succeed
    When I perform the :set_advanced_configuration web action with:
      | advanced_text | this_is_advanced_configuration |
    Then the step should succeed
    When I run the :switch_to_yaml_view web action
    Then the step should succeed
    When I perform the :check_yaml_line_content web action with:
      | key   | name                        |
      | value | mock-resource-instance-test |
    Then the step should succeed
    When I perform the :check_yaml_line_content web action with:
      | key   | advanced                       |
      | value | this_is_advanced_configuration |
    Then the step should succeed
    When I perform the :check_yaml_line_content web action with:
      | key   | checkbox |
      | value | false    |
    Then the step should succeed
    When I perform the :check_yaml_line_content web action with:
      | key   | k8sResourcePrefix |
      | value | default           |
    Then the step should succeed
    When I perform the :check_yaml_line_content web action with:
      | key   | number |
      | value | 3      |
    Then the step should succeed
    When I perform the :check_yaml_line_content web action with:
      | key   | podCount |
      | value | 5        |
    Then the step should succeed
    When I perform the :check_yaml_line_content web action with:
      | key   | text                |
      | value | my_simple_text_test |
    Then the step should succeed
    When I perform the :check_yaml_line_content web action with:
      | key   | imagePullPolicy |
      | value |  Always         |
    Then the step should succeed
    When I perform the :check_yaml_line_content web action with:
      | key   | password     |
      | value | testpassword |
    Then the step should succeed
    When I perform the :check_yaml_line_content web action with:
      | key   | select |
      | value | ERROR  |
    Then the step should succeed
    When I perform the :check_yaml_line_content web action with:
      | key   | booleanSwitch |
      | value | false         |
    Then the step should succeed
    When I run the :click_create_button web action
    Then the step should succeed
    Given I wait up to 5 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | mockresource.test.tectonic.com |
      | resource_name | mock-resource-instance-test    |
      | n             | <%= project.name %>            |
      | o             | yaml                           |
    Then the step should succeed
    """
    Then the output by order should match:
      | fieldGroup                              |
      | itemOne: Field group item groupvalueone |
      | itemTwo: 6                              |
    Then the output by order should match:
      | arrayFieldGroup                        |
      | - itemOne: my_arraygroup_value_one     |
      | itemTwo: 8                             |
      | - itemOne: my_add_arraygroup_value_one |
      | itemTwo: 10                            |

  # @author yanpzhan@redhat.com
  # @case_id OCP-33250
  @admin
  Scenario: Hide "non-standalone" Operators from UI
    Given the master version >= "4.6"
    Given admin creates "ui-33250-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators@sha256:feb39d5dca35fcbf73713672016b8c802146252a96e3864a0a34209b154b6482" with display name "UI OCP-33250 Test"
    Given I switch to the first user
    Given I have a project
    Given the first user is cluster-admin
    When I get project packagemanifests
    Then the output should match:
      | jaeger.*UI OCP-33250 Test |

    Given I open admin console in a browser
    # Check jaeger operator is hidden on operatorhub page
    When I perform the :check_operator_hidden_on_operatorhub_page web action with:
      | text    | UI OCP-33250 Test |
      | keyword | jaeger            |
    Then the step should succeed

    When I perform the :subscribe_operator_to_namespace web action with:
      | package_name     | etcd                |
      | catalog_name     | ui-33250-operators  |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    Given I wait for the "etcd" subscription to appear in the "<%= project.name %>" project up to 20 seconds
    When I perform the :subscribe_operator_to_namespace web action with:
      | package_name     | strimzi-kafka-operator |
      | catalog_name     | ui-33250-operators     |
      | target_namespace | <%= project.name %>    |
    Then the step should succeed
    Given I wait up to 300 seconds for the steps to pass:
    """
    When I get project csv
    Then the output should match:
      | etcdoperator.*Succeeded          |
      | strimzi-cluster-operator.*Failed |
    """

    # Suceeded/Failed csv are shown on intalled operators list page
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_managed_namespace_column_installed_for_one_ns web action with:
      | operator_name | Strimzi Kafka       |
      | project_name  | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_managed_namespace_column_installed_for_one_ns web action with:
      | operator_name | etcd                |
      | project_name  | <%= project.name %> |
    Then the step should succeed

    And evaluation of `subscription("strimzi-kafka-operator").current_csv` is stored in the :kafka_csv clipboard
    And evaluation of `subscription("etcd").current_csv` is stored in the :etcd_csv clipboard
    Given I successfully merge patch resource "csv/<%= cb.kafka_csv %>" with:
      | {"metadata":{"annotations":{"operators.operatorframework.io/operator-type":"non-standalone"}}} |
    Given I successfully merge patch resource "csv/<%= cb.etcd_csv %>" with:
      | {"metadata":{"annotations":{"operators.operatorframework.io/operator-type":"non-standalone"}}} |

    #Check succeeded csv is hidden and failed csv is shown after add annotation.
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_managed_namespace_column_installed_for_one_ns web action with:
      | operator_name | Strimzi Kafka       |
      | project_name  | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_managed_namespace_column_installed_for_one_ns web action with:
      | operator_name | etcd                |
      | project_name  | <%= project.name %> |
    Then the step should fail

    #Check related resources are shown even csv is hidden
    When I perform the :goto_deployment_page web action with:
      | project_name  | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | etcd-operator |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | strimzi-cluster-operator |
    Then the step should succeed

    When I run the :goto_crds_page web action
    Then the step should succeed
    When I perform the :set_strings_in_filter_box web action with:
      | test_id_value | item-filter |
      | filter_text   | etcd        |
    Then the step should succeed

    When I perform the :check_page_contains web action with:
      | content | Etcd |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | EtcdBackup |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | EtcdCluster |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | EtcdRestore |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-37098
  @admin
  Scenario: Improved OperatorHub view
    Given the master version >= "4.7"
    Given admin creates "ui-37098-operators" catalog source with image "quay.io/openshifttest/ui-auto-operators@sha256:feb39d5dca35fcbf73713672016b8c802146252a96e3864a0a34209b154b6482" with display name "UI OCP-37098 Test"
    Given I switch to the first user
    Given the first user is cluster-admin

    Given I open admin console in a browser
    When I run the :goto_catalog_source_page web action
    Then the step should succeed

    # check kebab actions for default catalogsource
    When I run the :check_kebab_menus_for_default_cs web action
    Then the step should succeed

    # check kebab actions for customized catalogsource
    When I perform the :check_kebab_menus_for_custom_cs web action with:
      | cs_name | ui-37098-operators |
    Then the step should succeed

    # check catalogsource columns for one catalogsource
    When I perform the :check_columns_for_cs web action with:
      | cs_name              | redhat-operators | 
      | cs_status            | <%= catalog_source("redhat-operators").status %>               |
      | publisher            | <%= catalog_source("redhat-operators").publisher %>            |
      | registrypullinterval | <%= catalog_source("redhat-operators").registrypollinterval %> |
      | endpoint             | <%= catalog_source("redhat-operators").endpoint %>             |
    Then the step should succeed

    When I perform the :check_columns_for_cs web action with:
      | cs_name              | ui-37098-operators | 
      | cs_status            | <%= catalog_source("ui-37098-operators").status %>               |
      | publisher            | <%= catalog_source("ui-37098-operators").publisher %>            |
      | registrypullinterval | <%= catalog_source("ui-37098-operators").registrypollinterval %> |
      | endpoint             | <%= catalog_source("ui-37098-operators").endpoint %>             |
    Then the step should succeed  

    # check catalogsource details
    When I perform the :goto_one_catalogsource_page web action with:
      | cs_name | certified-operators |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | status               | <%= catalog_source("certified-operators").status %>               |
      | display_name         | <%= catalog_source("certified-operators").displayname %>          |
      | publisher            | <%= catalog_source("certified-operators").publisher %>            |
      | endpoint             | <%= catalog_source("certified-operators").endpoint %>             |
      | registrypullinterval | <%= catalog_source("certified-operators").registrypollinterval %> |
    Then the step should succeed
    
    # check catalogsource operators tab
    When I run the :check_catalogsource_operators_info web action
    Then the step should succeed
    
    # packagemanifests page have catalogsource link
    When I run the :check_packagemanifests_have_cs_link web action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-39596
  @admin
  @destructive
  Scenario: Add a UI for enabling and disabling dynamic plugins during operator install
    Given the master version >= "4.8"
    Given admin creates "ui-dynamic-plugin-operators" catalog source with image "quay.io/openshifttest/dynamic-plugin-oprs:latest" with display name "ui dynamic plugin test"
    Given I switch to the first user
    Given I have a project
    And the first user is cluster-admin
    Given I open admin console in a browser
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | prometheus                  |
      | catalog_name     | ui-dynamic-plugin-operators |
      | target_namespace | <%= project.name %>         |
    Then the step should succeed
    When I perform the :select_target_namespace web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    # check plugins are disabled by default
    When I run the :check_extension_help_block web action
    Then the step should succeed
    When I run the :check_plugins_are_disabled_bydefault web action
    Then the step should succeed

    # check enablement help message
    When I perform the :check_warning_for_enablement web action with:
      | plugin_name | prometheus-plugin1 |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    Given I wait up to 20 seconds for the steps to pass:
    """
    When I run the :get admin command with:
      | resource | clusterserviceversion |
      | n        | <%= project.name %>   |
    Then the step should succeed
    And the output should contain "prometheusoperator"
    """

    # installed operators list page shows 'UI extension available' and redirects user to operator details page
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :check_extension_available_guide web action
    Then the step should succeed

    # operator details page show correct status of enabled & disabled plugins
    When I perform the :check_plugin_status_on_operator_details_page web action with:
      | plugin_1_name   | prometheus-plugin1 |
      | plugin_1_status | Enabled            |
      | plugin_2_name   | prometheus-plugin2 |
      | plugin_2_status | Disabled           |
    Then the step should succeed
    Then the expression should be true> console_operator("cluster").plugins.index("prometheus-plugin1") != nil
    Then the expression should be true> console_operator("cluster").plugins.index("prometheus-plugin2") == nil

    # enable & disable plugin on operator details page
    When I perform the :disable_plugin web action with:
      | plugin_name | prometheus-plugin1 |
    Then the step should succeed
    When I perform the :enable_plugin web action with:
      | plugin_name | prometheus-plugin2 |
    Then the step should succeed
    When I perform the :check_plugin_status_on_operator_details_page web action with:
      | plugin_1_name   | prometheus-plugin1 |
      | plugin_1_status | Disabled           |
      | plugin_2_name   | prometheus-plugin2 |
      | plugin_2_status | Enabled            |
    Then the step should succeed
    Then the expression should be true> console_operator("cluster").plugins.index("prometheus-plugin1") == nil
    Then the expression should be true> console_operator("cluster").plugins.index("prometheus-plugin2") != nil
