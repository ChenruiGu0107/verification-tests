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
    When I run the :click_subscribe_button web action
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
    Given I obtain test data file "deployment/vul_deployment.yaml"
    When I run the :create client command with:
      | f | vul_deployment.yaml |
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
    When I run the :click_subscribe_button web action
    Then the step should succeed

    # wait until container security operator is successfully installed
    Given I use the "<%= project.name %>" project
    Given a pod becomes ready with labels:
      | name=container-security-operator-alm-owned |
    Then I wait for the "sha256.eb253bef954ea760b834e6d736ad40fa900a1b8b688d97aac5cc9487b91f1b6d" image_manifest_vuln to appear in the "<%= project.name %>" project up to 30 seconds


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
      | manifest     | sha256.eb253bef954ea760b834e6d736ad40fa900a1b8b688d97aac5cc9487b91f1b6d |
    Then the step should succeed
    When I run the :wait_box_loaded web action
    Then the step should succeed
    When I run the :check_affected_pods_tab web action
    Then the step should succeed

    #uninstall the operator on web console
    When I perform the :goto_installed_operators_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    Given I wait up to 40 seconds for the steps to pass:
    """
    When I perform the :uninstall_operator_on_console web action with:
      | resource_name | Container Security |
    Then the step should succeed
    """
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
    When I perform the :click_catalog_item web action with:
      | catalog_item | php-helloworld-sample |
    Then the step should succeed
    When I perform the :check_the_support_link web action with:
      | link_url | https://www.redhat.com |
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
    When I run the :click_subscribe_button web action
    Then the step should succeed
    And I wait for the "cockroachdb-certified-rhmp" subscriptions to become ready
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
    When I run the :click_subscribe_button web action
    Then the step should succeed
    And I wait for the "radanalytics-spark" subscriptions to become ready
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
    Given I use the "openshift-marketplace" project
    Given I obtain test data file "olm/catalogsource-template.yaml"
    When I process and create:
      | f | catalogsource-template.yaml |
      | p | NAME=custom-console-catalogsource-infrasubs                      |
      | p | IMAGE=quay.io/openshifttest/uitestoperators:infrasubs            |
      | p | DISPLAYNAME=Custom Console AUTO Testing                          |
    Then the step should succeed
    And a pod becomes ready with labels:
      | olm.catalogSource=custom-console-catalogsource-infrasubs |
    Given I wait up to 60 seconds for the steps to pass:
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
    When I perform the :click_one_operation_in_kebab web action with:
      | resource_name | custom-cs-akka       |
      | kebab_item    | Delete CatalogSource |
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
  Scenario: Check marketplace operator annotations
    Given the master version >= "4.4"
    Given I have a project
    Given the first user is cluster-admin
    When I open admin console in a browser
    Then the step should succeed
    When I run the :get client command with:
      | resource      | packagemanifests      |
      | resource_name | tigera-operator       |
      | n             | openshift-marketplace |
      | output        | yaml                  |
    Then the step should succeed
    Given evaluation of `@result[:parsed]["status"]["channels"][0]["currentCSVDesc"]["annotations"]["marketplace.openshift.io/action-text"]` is stored in the :actiontext clipboard
    Given evaluation of `@result[:parsed]["status"]["channels"][0]["currentCSVDesc"]["annotations"]["marketplace.openshift.io/remote-workflow"]` is stored in the :remoteworkflow clipboard
    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :open_operator_modal web action with:
      | operator_name | Tigera |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | <%= cb.actiontext %>     |
      | link_url | <%= cb.remoteworkflow %> |
    Then the step should succeed

    When I run the :goto_operator_hub_page web action
    Then the step should succeed
    When I perform the :click_checkbox_from_provider_type web action with:
      | text | Marketplace |
    Then the step should succeed
    When I perform the :open_operator_modal web action with:
      | operator_name | Hazelcast Jet |
    Then the step should succeed
    When I run the :check_Hazelcastjet_default_action_and_remote_workflow web action
    Then the step should succeed

  # @author hasha@redhat.com
  # @case_id OCP-27631
  @admin
  Scenario: check operator install process when operator bundle pre-defined namespace/installplan/monitoring
    Given the master version >= "4.4"
    Given I have a project
    Given the first user is cluster-admin
    And admin ensures "openshift-storage" project is deleted after scenario
    And I open admin console in a browser

    #The operators that pre-defined the install mode is not recommending an install namespace
    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | amq7-cert-manager   |
      | catalog_name     | redhat-operators    |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    """
    When I run the :check_all_namespace_installation_mode_without_recommended_ns web action
    Then the step should succeed

    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | amq7-interconnect-operator |
      | catalog_name     | redhat-operators           |
      | target_namespace | <%= project.name %>        |
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

    #The operator is recommending an install namespace
    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | elasticsearch-operator |
      | catalog_name     | redhat-operators       |
      | target_namespace | <%= project.name %>    |
    Then the step should succeed
    """
    When I perform the :check_all_namespace_installation_mode_with_recommended_ns web action with:
      | recommended_ns | openshift-operators-redhat |
    Then the step should succeed

    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | kubevirt-hyperconverged |
      | catalog_name     | redhat-operators        |
      | target_namespace | <%= project.name %>     |
    Then the step should succeed
    """
    When I perform the :check_specific_namespace_installation_mode_with_recommended_ns web action with:
      | recommended_ns | openshift-cnv |
    Then the step should succeed

    When I run the :click_radio_to_pick_ns web action
    Then the step should succeed
    When I perform the :select_installed_namespace web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    Given I wait for the "kubevirt-hyperconverged" subscription to appear in the "<%= project.name %>" project up to 30 seconds

    #enable metrics service discovery
    And I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | ocs-operator        |
      | catalog_name     | redhat-operators    |
      | target_namespace | <%= project.name %> |
    Then the step should succeed
    """
    When I run the :enable_cluster_monitoring web action
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
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
    When I run the :click_subscribe_button web action
    Then the step should succeed
    Given I use the "openshift-operators" project
    Given I wait for the "serverless-operator" subscriptions to appear
    Given admin waits for the "serverless-operator" subscriptions to become ready in the "openshift-operators" project up to 240 seconds
    And evaluation of `subscription("serverless-operator").current_csv` is stored in the :current_csv clipboard
    Given admin ensures "<%= cb.current_csv %>" clusterserviceversions is deleted from the "openshift-operators" project after scenario

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
    Given I wait for the "spark-gcp" subscriptions to become ready up to 360 seconds
    And evaluation of `subscription("spark-gcp").current_csv` is stored in the :spark_csv clipboard
    And evaluation of `project.name` is stored in the :project_name clipboard

    # prepare an operator for all namespaces
    When I use the "openshift-operators" project
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | container-security-operator |
      | catalog_name     | community-operators         |
      | target_namespace |                             |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    """
    Given admin ensures "container-security-operator" subscriptions is deleted from the "openshift-operators" project after scenario
    Given I wait for the "container-security-operator" subscriptions to become ready up to 360 seconds
    Given admin ensures "<%= subscription('container-security-operator').current_csv %>" clusterserviceversions is deleted from the "openshift-operators" project after scenario

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
      | operator_name | Container Security |
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
      | operator_name | Container Security |
    Then the step should succeed
    #check column: Managed Namespaces
    When I perform the :check_managed_namespace_column_installed_for_one_ns_under_all_projects web action with:
      | operator_name | Spark Operator         |
      | project_name  | <%= cb.project_name %> |
    Then the step should succeed
    When I perform the :check_managed_namespace_column_installed_for_all_ns_under_all_projects web action with:
      | operator_name | Container Security |
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
      | csv_name     | <%= subscription("container-security-operator").current_csv %> |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | namespace         | openshift-operators |
      | managed_namespace | All Namespaces      |
    Then the step should succeed
    When I perform the :goto_csv_subscription_page web action with:
      | project_name | openshift-operators                                            |
      | csv_name     | <%= subscription("container-security-operator").current_csv %> |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | namespace | openshift-operators |
    Then the step should succeed
