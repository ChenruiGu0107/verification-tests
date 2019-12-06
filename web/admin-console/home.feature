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
    Given evaluation of `cb.resource.downcase` is stored in the :resource_url clipboard
    When I perform the :goto_resource_page_under_default_project web action with:
      | resource_url_name   | <%= cb.resource_url.id2name.delete(" ")+"s" %> |
    Then the step should succeed

    When I run the :check_getting_started web action
    Then the step should succeed
    When I perform the :check_dim_resource_list web action with:
      | resource_url_name | <%= cb.resource_url.id2name.delete(" ")+"s" %>  |
      | resource_singular | <%= cb.resource %>  |
    Then the step should succeed
    """

    # create project
    When I perform the :create_project web action with:
      | project_name | <%= cb.pro_name %> |
    Then the step should succeed
    When I perform the :goto_project_resources_page web action with:
      | project_name | <%= cb.pro_name %> |
    Then the step should succeed
    When I run the :check_get_started_message_when_no_resources web action
    Then the step should succeed
