Feature: check page info related

  # @author xxing@redhat.com
  # @case_id 499945
  Scenario: Help info on project page
    Given I login via web console
    When I get the html of the web page
    Then the output should contain:
      | OpenShift helps you quickly develop, host, and scale applications |
      | Create a project for your application                             |
    When I perform the :new_project web console action with:
      | project_name | <%= rand_str(5, :dns) %> |
      | display_name | :null                    |
      | description  ||
    Then the step should succeed
    And I get the html of the web page
    Then the output should contain:
      | Choose from web frameworks, databases, and other components |

  # @author xxing@redhat.com
  # @case_id 479237
  Scenario: Check project annotation info on web console
    When I create a project via web with:
      | display_name | Test |
      | description  ||
    Then the step should succeed
    When I run the :check_project_list web console action
    And I get the "text" attribute of the "a" web element:
      | href | project/<%= project.name %> |
    Then the output should contain "Test"
    When I perform the :check_project_overview_without_resource web console action with:
      | project_name | <%= project.name %> |
    And I get the "text" attribute of the "element" web element:
      | xpath | //div/ul/li[1]/a[@tabindex="0"] |
    Then the output should contain "Test"
    When I perform the :check_project_without_quota_settings web console action with:
      | project_name | <%= project.name %> |
    When I get the html of the web page
    Then the output should match:
      | <div.+Test |

  # @author cryan@redhat.com
  # @case_id 467928
  Scenario: Check the login url in config.js
    When I download a file from "<%= env.api_endpoint_url %>/console/config.js"
    Then the step should succeed
    And the output should match "oauth_authorize_uri:\s+"https?:\/\/.+""

  # @author wsun@redhat.com
  # @case_id 479002
  Scenario: Check Events page
    Given I login via web console
    Given I have a project
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                        |
      | image_name   | nodejs                                     |
      | image_tag    | 0.10                                       |
      | namespace    | openshift                                  |
      | app_name     | nodejs-sample                              |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should succeed
    When I perform the :create_from_image_complete_info_on_next_page web console action with:
      | project_name | <%= project.name %> |
      | image_name   | nodejs              |
      | image_tag    | 0.10                |
      | namespace    | openshift           |
      | app_name     | nodejs-sample       |
    Then the step should succeed
    When I perform the :check_events_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id 457796
  Scenario: Check home page to list user projects
    Given I login via web console
    When I get the html of the web page
    Then the output should contain:
      | Welcome to OpenShift                                              |
      | OpenShift helps you quickly develop, host, and scale applications |
      | Create a project for your application                             |
    Given an 8 character random string of type :dns is stored into the :prj_name clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.prj_name %> |
    Then the step should succeed
    When I run the :check_project_list web console action
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | <%= cb.prj_name %> |

  # @author yanpzhan@redhat.com
  # @case_id 515689
  Scenario: Check storage page on web console
    When I create a new project via web
    Then the step should succeed

    When I perform the :check_empty_storage_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    Given I use the "<%= project.name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo-ui.json |
    Then the step should succeed

    When I get project PersistentVolumeClaim as JSON
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :pvc_name clipboard

    Then I perform the :check_pvcs_on_storage_page web console action with:
      | project_name | <%= project.name %> |
      | pvc_name     | <%= cb.pvc_name %> |
    Then the step should succeed

    When I perform the :check_one_pvc_detail web console action with:
      | project_name | <%= project.name %> |
      | pvc_name     | <%= cb.pvc_name %> |
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id 521541
  Scenario: Check volumes info on pod page
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/pod-dapi-volume.yaml |
    Then the step should succeed
    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | pod-dapi-volume     |
    Then the step should succeed
    Given evaluation of `service_account("default").get_secret_names(by: user).select{|a| a.include?("default-token")}[0]` is stored in the :sname clipboard
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
      | Secret [Nn]ame:\s<%= cb.sname %>                    |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-volume1.yaml |
    Then the step should succeed
    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | dapi-test-pod-1     |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should match:
      | ^config-volume$                  |
      | Type:\sconfig map                |
      | Name:\sspecial-config            |
      | ^<%= cb.sname %>$                |
      | Type:\ssecret                    |
      | Secret [Nn]ame:\s<%= cb.sname %> |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-volume2.yaml |
    Then the step should succeed
    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | dapi-test-pod-2     |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should match:
      | ^config-volume$                                     |
      | Type:\sconfig map                                   |
      | Name:\sspecial-config                               |
      | Key to [Ff]ile:\sspecial.type → path/to/special-key |
      | ^<%= cb.sname %>$                                   |
      | Type:\ssecret                                       |
      | Secret [Nn]ame:\s<%= cb.sname %>                    |

  # @author yapei@redhat.com
  # @case_id 477635
  Scenario: Check Overview details for project
    Given I create a new project
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %> |
      | image_name   | nodejs              |
      | image_tag    | 0.10                |
      | namespace    | openshift           |
      | app_name     | nodejs-sample       |
      | source_url   | https://github.com/openshift/nodejs-ex.git |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    Given the "nodejs-sample-1" build becomes :running
    # check build info banner when build is running & complete
    When I perform the :check_build_info_on_overview_page web console action with:
      | build_config     | nodejs-sample  |
      | build_id         | #1             |
      | build_status     | running        |
    Then the step should succeed
    Given the "nodejs-sample-1" build becomes :complete
    When I perform the :check_build_info_on_overview_page web console action with:
      | build_config     | nodejs-sample  |
      | build_id         | #1             |
      | build_status     | completed      |
    Then the step should succeed
    # check View log and Dismiss function
    When I perform the :check_view_log_link_info_on_overview web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | nodejs-sample       |
      | bc_build_id  | nodejs-sample-1     |
    Then the step should succeed
    When I run the :dismiss_build_log_on_overview web console action
    Then the step should succeed
    Given 5 seconds have passed
    When I perform the :check_build_info_on_overview_page web console action with:
      | build_config     | nodejs-sample  |
      | build_id         | #1             |
      | build_status     | completed      |
    Then the step should fail
    # check service and route info
    When I perform the :check_service_link_on_overview web console action with:
      | project_name | <%= project.name %> |
      | service_name | nodejs-sample       |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | route          |
      | resource_name | nodejs-sample  |
      | template      | {{.spec.host}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :route_hostname clipboard
    When I perform the :check_route_link_on_overview web console action with:
      | route_host_name | <%= cb.route_hostname %> |
    Then the step should succeed
    # check deployment info on overview
    When I perform the :check_deployment_config_link_info_on_overview web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | nodejs-sample       |
    Then the step should succeed
    When I perform the :check_deployments_link_info_on_overview web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | nodejs-sample       |
      | deployments  | nodejs-sample-1     |
    Then the step should succeed
    When I perform the :check_pod_info_on_overview web console action with:
      | pod_display | 1pod |
    Then the step should succeed
    # check pod-template detail
    When I perform the :check_pod_template_image_link web console action with:
      | project_name | <%= project.name %> |
      | image_name   | nodejs-sample       |
    Then the step should succeed
    When I perform the :check_pod_template_build_link web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | nodejs-sample       |
      | bc_build_id  | nodejs-sample-1     |
    Then the step should succeed
    When I run the :check_pod_template_source_info web console action
    Then the step should succeed
    When I perform the :check_pod_template_port_info web console action with:
      | port_number | 8080 |
    Then the step should succeed
    # standalone RC
    When I run the :run client command with:
      | name      | myrun-rc              |
      | image     | aosqe/hello-openshift |
      | generator | run/v1                |
    Then the step should succeed
    Given I wait until replicationController "myrun-rc" is ready
    When I perform the :check_standalone_rc_info_on_overview web console action with:
      | rc_name | myrun-rc |
    Then the step should succeed
    # standalone Pod
    When I run the :run client command with:
      | name      | myrun-pod             |
      | image     | aosqe/hello-openshift |
      | generator | run-pod/v1            |
    Then the step should succeed
    Given the pod named "myrun-pod" becomes ready
    When I perform the :check_standalone_pod_info_on_overview web console action with:
      | pod_name | myrun-pod |
    Then the step should succeed

  # @author xxing@redhat.com
  # @case_id 533677
  Scenario: Check ImageStream tag page on web console
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json |
    Then the step should succeed
    Given the "python" image stream becomes ready
    # check the latest image tag
    When I perform the :check_one_image_stream web console action with:
      | project_name | <%= project.name %> |
      | image_name   | python              |
    Then the step should succeed
    When I perform the :check_is_tag_basic_page web console action with:
      | image_name | python |
      | istag      | 2.7    |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should contain:
      | $ sudo docker pull registry/python:2.7 |
    Given the "python:2.7" image stream tag was created
    When I perform the :check_is_tag_details_tab web console action with:
      | digest         | <%= image_stream_tag.digest(user: user) %>                                                                                          |
      | docker_version | <%= image_stream_tag.docker_version(user: user) %>                                                                                  |
      | annotations    | <%= anno=[];image_stream_tag.annotations(user: user).each{\|key,value\| anno.push(key+": "+value)};anno %>                          |
      | labels         | <%= label=[];image_stream_tag.labels(user: user).each{\|key,value\| label.push(key + "=" + value) if(key != "build-date")};label %> |
    Then the step should succeed
    # check istag page  "Config" tab 
    When I perform the :check_is_tag_config_tab web console action with:
      | config_cmd | <%= image_stream_tag.config_cmd(user: user).join(" ") %>  |
      | run_as     | <%= image_stream_tag.config_user(user: user) %>           |
      | workdir    | <%= image_stream_tag.workingdir(user: user) %>            |  
      | ports      | <%= image_stream_tag.exposed_ports(user: user).keys[0] %> |
      | config_env | <%= image_stream_tag.config_env(user: user) %>            |
    Then the step should succeed
    When I perform the :check_is_tag_layers_tab web console action with:
      | layers_len | <%= image_stream_tag.image_layers(user: user).length %> |
    Then the step should succeed
    # Generated IS
    Given the "php" image stream becomes ready
    When I perform the :create_app_from_image web console action with:
      | project_name | <%= project.name %>                         |
      | image_name   | php                                         |
      | image_tag    | 5.6                                         |
      | namespace    | <%= project.name %>                         |
      | app_name     | php56                                       |
      | source_url   | https://github.com/openshift/cakephp-ex.git |
    Then the step should succeed
    Given the "php56-1" build completed
    Given I wait for the "php56" service to become ready
    Given the "php56" image stream becomes ready
    When I perform the :goto_one_image_stream_page web console action with:
      | project_name | <%= project.name %> |
      | image_name   | php56               |
    Then the step should succeed 
    When I perform the :check_is_tag_basic_page web console action with:
      | image_name | php56     |
      | istag      | latest    |
    Then the step should succeed
    Given the "php56:latest" image stream tag was created
    When I perform the :check_is_tag_details_tab web console action with:
      | digest         | <%= image_stream_tag.digest(user: user) %>                                                                                          |
      | docker_version | <%= image_stream_tag.docker_version(user: user) %>                                                                                  |
      | annotations    | <%= anno=[];image_stream_tag.annotations(user: user).each{\|key,value\| anno.push(key+": "+value)};anno %>                          |
      | labels         | <%= label=[];image_stream_tag.labels(user: user).each{\|key,value\| label.push(key + "=" + value) if(key != "build-date")};label %> |
    Then the step should succeed
    When I perform the :check_is_tag_layers_tab web console action with:
      | layers_len | <%= image_stream_tag.image_layers(user: user).length %> |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id 538299
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
    When I get the html of the web page
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
  # @case_id 544856
  Scenario: Improve Project list/selection page - show creater and edit membership 
    Given the master version >= "3.4"
    Given I have a project
    When I run the :policy_add_role_to_user client command with:
      | role       | admin                                       |
      | user_name  | <%= user(1, switch: false).name %>          |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role       | view                                        |
      | user_name  | <%= user(2, switch: false).name %>          |
    Then the step should succeed
    When I perform the :check_project_creator web console action with:
      | project_name | <%= project.name %> |
      | creator      | <%= user.name %>    |
    Then the step should succeed

    Given I switch to the second user
    When I perform the :check_project_creator web console action with:
      | project_name | <%= project.name %> |
      | creator      | <%= user(0, switch: false).name %>        |
    Then the step should succeed
    When I perform the :click_project_membership web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :edit_membership web console action
    Then the step should succeed

    Given I switch to the third user
    When I perform the :check_project_creator web console action with:
      | project_name | <%= project.name %> |
      | creator      | <%= user(0, switch: false).name %>        |
    Then the step should succeed
     When I perform the :click_project_membership web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :check_permission_error_on_membership web console action
    Then the step should succeed
