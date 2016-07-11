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
      | Select Image or Template |
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
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo.json |
    Then the step should succeed

    When I get project PersistentVolumeClaim as JSON
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :pvc_name clipboard

    Then I perform the :check_pvcs_on storage_page web console action with:
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
    When I get the visible text on web html page
    Then the output should match:
      | ^podinfo$                                                                      |
      | Type:\sdownward API                                                            |
      | Volume file:\smetadata.labels → labels                                         |
      | Volume file:\smetadata.annotations → annotations                               |
      | Volume file:\smetadata.name → name                                             |
      | Volume file:\smetadata.namespace → namespace                                   |
      | ^<%= service_account("default").get_secret_names(by: user)[0] %>$              |
      | Type:\ssecret                                                                  |
      | Secret name:\s<%= service_account("default").get_secret_names(by: user)[0] %>  |
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
      | ^config-volume$                                                               |
      | Type:\sconfig map                                                             |
      | Name:\sspecial-config                                                         |
      | ^<%= service_account("default").get_secret_names(by: user)[0] %>$             |
      | Type:\ssecret                                                                 |
      | Secret name:\s<%= service_account("default").get_secret_names(by: user)[0] %> |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/pod-configmap-volume2.yaml |
    Then the step should succeed
    When I perform the :goto_one_pod_page web console action with:
      | project_name | <%= project.name %> |
      | pod_name     | dapi-test-pod-2     |
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should match:
      | ^config-volume$                                                               |
      | Type:\sconfig map                                                             |
      | Name:\sspecial-config                                                         |
      | Key to file:\sspecial.type → path/to/special-key                              |
      | ^<%= service_account("default").get_secret_names(by: user)[0] %>$             |
      | Type:\ssecret                                                                 |
      | Secret name:\s<%= service_account("default").get_secret_names(by: user)[0] %> |

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
