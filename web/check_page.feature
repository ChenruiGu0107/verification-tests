Feature: check page info related
  # @author cryan@redhat.com
  # @case_id OCP-11879
  Scenario: Check the login url in config.js
    When I download a file from "<%= env.api_endpoint_url %>/console/config.js"
    Then the step should succeed
    And the output should match "oauth_authorize_uri:\s+"https?:\/\/.+""

  # @author xxing@redhat.com
  # @case_id OCP-9907
  Scenario: Check volumes info on pod page
    Given the master version >= "3.2"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/pod-dapi-volume.yaml |
    Then the step should succeed
    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | pod-dapi-volume     |
    Then the step should succeed
    Given evaluation of `service_account("default").get_secret_names.select{|a| a.include?("default-token")}[0]` is stored in the :sname clipboard
    When I get the visible text on web html page
    Then the output should match:
      | ^podinfo$                                           |
      | Type:\sdownward API                                 |
      | Volume [Ff]ile:\smetadata.labels → labels           |
      | Volume [Ff]ile:\smetadata.annotations → annotations |
      | Volume [Ff]ile:\smetadata.name → name               |
      | Volume [Ff]ile:\smetadata.namespace → namespace     |
      | ^<%= cb.sname %>                                    |
      | Type:\ssecret                                       |
      | [Secret\|Secret Name]:\s<%= cb.sname %>             |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/pod-configmap-volume1.yaml |
    Then the step should succeed
    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | dapi-test-pod-1     |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should match:
      | ^config-volume$                         |
      | Type:\sconfig map                       |
      | [Name\|Config Map]:\sspecial-config     |
      | ^<%= cb.sname %>$                       |
      | Type:\ssecret                           |
      | [Secret\|Secret Name]:\s<%= cb.sname %> |
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/pod-configmap-volume2.yaml |
    Then the step should succeed
    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | dapi-test-pod-2     |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should match:
      | ^config-volume$                                     |
      | Type:\sconfig map                                   |
      | [Name\|Config Map]:\sspecial-config                 |
      | Key to [Ff]ile:\sspecial.type → path/to/special-key |
      | ^<%= cb.sname %>$                                   |
      | Type:\ssecret                                       |
      | [Secret\|Secret Name]:\s<%= cb.sname %>             |

  # @author xiaocwan@redhat.com
  # @case_id OCP-11012
  Scenario: Improve Project list/selection page - check and search project
    Given the master version >= "3.4"
    When I run the :new_project client command with:
      | project_name | 9-xiaocwan                  |
      | display_name | a display name              |
      | description  | b description name          |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | my-project                  |
      | display_name | c, d, e , display           |
      | description  | q, w, e description         |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | zzz-project                 |
      | display_name | f,g,h,display               |
      | description  | r,t,y,description           |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | 09-xiaocwan                 |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | a-xiaocwan                  |
      | description  | zzz description for a-xiaoc |
    Then the step should succeed
    When I run the :new_project client command with:
      | project_name | z-xiaocwan                  |
      | display_name | 0a display for z-xiaocwan   |
    Then the step should succeed

    ## check search box button exist first, following steps will use it directly
    When I run the :check_project_search_box web console action
    Then the step should succeed

    When I perform the :search_project web console action with:
      | input_str    | 9               |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should not contain:
      | a-xiaocwan                     |
      | z-xiaocwan                     |
    And the output should contain:
      | 09-xiaocwan                    |
      | a display name                 |
    """

    ## After first search, check clear search box,
    ## after this check, following steps will use it directly because page will not refresh
    When I run the :clear_input_box web console action
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should contain:
      | 0a display for z-xiaocwan      |
      | a display name                 |
      | a-xiaocwan                     |
      | c, d, e , display              |
      | f,g,h,display                  |
    """

    When I perform the :search_project web console action with:
      | input_str    | name            |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should not contain "09-xiaocwan"
    And the output should contain:
      | a display name                 |
    """

    When I run the :clear_input_box web console action
    And I perform the :search_project web console action with:
      | input_str    | zzz             |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the visible text on web html page
    Then the output should not contain "z-xiaocwan"
    And the output should contain:
      | zzz-project                    |
      | zzz description for a-xiaoc    |
    """

    When I run the :clear_input_box web console action
    And  I perform the :search_project web console action with:
      | input_str    | my-             |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should not contain "zzz-project"
    And the output should contain:
      | c, d, e , display  |
    """

    When I run the :clear_input_box web console action
    And I perform the :search_project web console action with:
      | input_str    | d, e            |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should not contain "z-xiaocwan"
    And the output should contain:
      | c, d, e , display              |
    """

    When I run the :clear_input_box web console action
    And I perform the :search_project web console action with:
      | input_str    | t,y             |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get the html of the web page
    Then the output should not contain "9-xiaocwan"
    And the output should contain:
      | f,g,h,display                  |
    """

  # @author xiaocwan@redhat.com
  # @case_id OCP-15067
  Scenario: Check Masthead - Project Selection and navigation
    Given the master version >= "3.7"
    Given I have a project
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :goto_projects_page web console action
    Then the step should succeed
    ## check no masthead on project list page
    When I run the :check_missing_masthead web console action
    Then the step should succeed
    ## check no masthead on About page
    When I run the :goto_about_page web console action
    Then the step should succeed
    When I run the :check_missing_masthead web console action
    Then the step should succeed

    ## check navigation menus in the left sidebar
    When I perform the :goto_deployments_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :check_navitator_menus web console action
    Then the step should succeed

    ## check navigator exist with hightlight item on dc edit page
    When I run the :run client command with:
      | name      | myrun                     |
      | image     | openshift/hello-openshift |
    Then the step should succeed
    When I perform the :goto_one_dc_edit_page web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | myrun               |
    Then the step should succeed
    When I perform the :check_navigator_item_active web console action with:
      | menu_name       | Applications |
      | hightlight_item | Deployments  |
    Then the step should succeed

    ## check collapse/expand menu
    When I run the :click_expand_collapse_navigator_button web console action
    Then the step should succeed
    When I run the :check_navigator_collapse web console action
    Then the step should succeed
    When I run the :click_expand_collapse_navigator_button web console action
    Then the step should succeed
    When I run the :check_navigator_expand web console action
    Then the step should succeed
