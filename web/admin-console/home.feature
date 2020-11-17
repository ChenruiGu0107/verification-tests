Feature: Home related pages via admin console

  # @author xiaocwan@redhat.com
  # @case_id OCP-19678
  Scenario: Check general info on console
    When I run the :version client command
    Then the step should succeed
    And evaluation of `@result[:props][:openshift_server_version]` is stored in the :openshift_version clipboard
    And evaluation of `@result[:props][:kubernetes_version]` is stored in the :k8s_version clipboard
    Given I open admin console in a browser
    When I perform the :goto_project_status web action with:
      | project   | default |
    Then the step should succeed
    When I perform the :check_software_info_versions web action with:
      | k8s_version       | <%= cb.k8s_version  %>      |
      | openshift_version | <%= cb.openshift_version %> |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-21772
  Scenario: Check user guide on console
    Given the master version >= "4.1"
    Given I open admin console in a browser
    When I run the :navigate_to_admin_console web action
    Then the step should succeed
    Given an 5 character random string of type :dns is stored into the :pro_name clipboard
    And I wait up to 60 seconds for the steps to pass:
    """
    Given the expression should be true> browser.url.end_with?("/k8s/cluster/projects")
    """
    When I perform the :check_button_enabled web action with:
      | button_text | Create Project |
    Then the step should succeed
    When I run the :check_user_starter_guide_message_when_no_projects web action
    Then the step should succeed
    When I perform the :check_message_and_doc_for_new_user web action with:
      | documentationbaseurl | docs.openshift.com/container-platform |
    Then the step should succeed
    Given I saved following keys to list in :resources clipboard:
      | Deployment Config         | |
      | Pod                       | |
      | Deployment                | |
      | Stateful Set              | |
      | Config Map                | |
      | Cron Job                  | |
      | Job                       | |
      | Daemon Set                | |
      | Replication Controller    | |
      | Horizontal Pod Autoscaler | |
      | Service                   | |
      | Route                     | |
      | Persistent Volume Claim   | |
      | Build Config              | |
      | Image Stream              | |
      | Service Account           | |

    When I repeat the following steps for each :resource in cb.resources:
    """
    When I perform the :goto_resource_page_under_default_project web action with:
      | resource_url_name   | <%= cb.resource.downcase.to_s.delete(" ")+"s" %> |
    Then the step should succeed

    When I run the :check_getting_started web action
    Then the step should succeed
    When I perform the :check_dim_resource_list web action with:
      | resource_url_name | <%= cb.resource.downcase.to_s.delete(" ")+"s" %>  |
      | resource_singular | <%= cb.resource %>  |
    Then the step should succeed
    """

    # create project
    When I perform the :create_project_from_get_started_instru web action with:
      | project_name | <%= cb.pro_name %> |
    Then the step should succeed
    When I run the :nagivate_to_project_resources_page web action
    Then the step should succeed
    When I run the :check_get_started_message_when_no_resources web action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-24306
  @admin
  Scenario: Check API explorer
    Given the master version >= "4.2"
    Given I open admin console in a browser

    #normal user checks api explore page
    When I run the :goto_api_explore_page web action
    Then the step should succeed
    When I perform the :click_on_resource_name web action with:
      | item | ConfigMap |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | kind        | ConfigMap |
      | api_version | v1        |
      | namespaced  | true      |
      | short_names | cm        |
    Then the step should succeed
    When I run the :click_instances_tab web action
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | Restricted Access |
    Then the step should succeed
    When I perform the :create_project_from_dropdown web action with:
      | project_name | project-ocp-24306 |
    Then the step should succeed
    When I perform the :goto_one_api_explore_page web action with:
      | project_name     | project-ocp-24306 |
      | api_explore_name | core~v1~ConfigMap |
    Then the step should succeed
    When I run the :click_access_review_tab web action
    Then the step should succeed
    When I perform the :check_page_not_match web action with:
      | content | Error Loading Access Review |
    Then the step should succeed
    When I run the :click_instances_tab web action
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | No Config Maps Found |
    Then the step should succeed

    #cluster admin checks api explore page
    Given the first user is cluster-admin
    When I run the :goto_api_explore_page web action
    Then the step should succeed
    When I perform the :set_filter_strings_on_explore_page web action with:
      | filter_text | build |
    Then the step should succeed
    When I perform the :click_item_in_resource_list web action with:
      | line_index | 3 |
    Then the step should succeed
    When I perform the :check_dropdown_missing web action with:
      | dropdown_name | namespace-bar |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | kind        | Build               |
      | api_group   | config.openshift.io |
      | api_version | v1                  |
      | namespaced  | false               |
    Then the step should succeed
    When I run the :click_schema_tab web action
    Then the step should succeed
    When I run the :check_info_in_schema web action
    Then the step should succeed
    When I run the :click_instances_tab web action
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | cluster |
      | link_url | /k8s/cluster/config.openshift.io~v1~Build/cluster |
    Then the step should succeed
    When I run the :click_access_review_tab web action
    Then the step should succeed
    When I run the :check_access_review_table web action
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-29210
  @admin
  Scenario: check cluster detail card and doc url set by OCP console-operator
    Given the master version >= "4.4"
    Given the first user is cluster-admin
    And I store master major version in the clipboard
    And I use the "openshift-console" project
    When I get project configmap as YAML
    Then the output should match "documentationBaseURL.*docs.openshift.com/container-platform/<%= cb.master_version %>"

    Given I open admin console in a browser
    When I perform the :check_documentation_link_in_helpmenu web action with:
      | version | <%= cb.master_version %> |
    Then the step should succeed

    When I run the :goto_cluster_dashboards_page web action
    Then the step should succeed
    # check Cluster API Address
    Given I store default router subdomain in the :subdomain clipboard
    When I perform the :check_cluster_api_in_details_card web action with:
      | api | <%= cb.subdomain.gsub('apps','api') %> |
    Then the step should succeed

    # check Cluster ID
    When I perform the :check_cluster_id_in_details_card web action with:
      | cluster_id | <%= cluster_version("version").cluster_id %> |
    Then the step should succeed  

    # check Provider
    When I perform the :check_cluster_provider_in_details_card web action with:
      | provider | <%= infrastructure("cluster").platform %> |
    Then the step should succeed  

    # check OpenShift Version
    When I perform the :check_cluster_version_in_details_card web action with:
      | version | <%= cb.master_version %> |
    Then the step should succeed

    # check Update channel
    When I perform the :check_update_channel_in_details_card web action with:
      | update_channel | <%= cluster_version("version").channel %> |
    Then the step should succeed 

    # browse to view settings
    When I run the :view_all_settings web action
    Then the step should succeed
    And the expression should be true> browser.url.include? "settings/cluster/"
