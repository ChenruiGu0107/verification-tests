Feature: overview cases

  # @author yapei@redhat.com
  # @case_id OCP-20932
  Scenario: Check app resources on overview page
    Given the master version >= "4.1"
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/python:latest                 |
      | code         | https://github.com/sclorg/django-ex.git |
      | name         | python-sample                           |
    Then the step should succeed
    When I run the :expose client command with:
      | resource      | svc           | 
      | resource_name | python-sample |
    Then the step should succeed

    Given I open admin console in a browser
    When I perform the :goto_project_resources_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_list_heading_shown web action with:
      | heading | python-sample |
    Then the step should succeed

    # click list item will open sidebar
    When I perform the :click_list_item web action with:
      | resource_kind | DeploymentConfig |
      | resource_name | python-sample    |
    Then the step should succeed
    When I run the :sidebar_is_loaded web action
    Then the step should succeed

    # check basic info on overview view
    When I run the :click_sidebar_overview_tab web action
    Then the step should succeed
    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Name          |
      | value | python-sample |
    Then the step should succeed
    When I perform the :check_key_and_resource_link web action with:
      | key           | Namespace                                   |
      | resource_link | /k8s/cluster/namespaces/<%= project.name %> |
    Then the step should succeed
    When I perform the :check_key_and_action_link web action with:
      | key            | Tolerations   |
    Then the step should succeed
    When I perform the :check_key_and_action_link web action with:
      | key            | Annotations  |
    Then the step should succeed

    # check builds, service, routes info on resources view
    When I run the :click_sidebar_resources_tab web action
    Then the step should succeed
    When I perform the :check_resource_name_and_icon web action with:
      | service_name | python-sample |
    Then the step should succeed
    When I perform the :check_resource_name_and_icon web action with:
      | buildconfig_name | python-sample |
    Then the step should succeed
    When I perform the :check_resource_name_and_icon web action with:
      | route_name | python-sample |
    Then the step should succeed

    # check resource links are correct
    When I perform the :check_resource_link web action with:
      | resource_link | /k8s/ns/<%= project.name %>/buildconfigs/python-sample |
    Then the step should succeed
    When I perform the :check_resource_link web action with:
      | resource_link | /k8s/ns/<%= project.name %>/services/python-sample |
    Then the step should succeed  
    When I perform the :check_resource_link web action with:
      | resource_link | /k8s/ns/<%= project.name %>/routes/python-sample |
    Then the step should succeed
    When I perform the :check_resource_link web action with:
      | resource_link | <%= route("python-sample").dns(by: user) %> |
    Then the step should succeed

    # check action menus available
    When I run the :click_resource_action_button web action
    Then the step should succeed
    When I run the :check_dc_available_action_menus web action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-21000
  Scenario: Show alerts on overview
    Given the master version >= "4.2"
    Given I have a project

    # check deployment error on overview
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/hello-deployment-1.yaml" replacing paths:
      | ["spec"]["replicas"] | 1 |
    Then the step should succeed
    When I create a dynamic pvc from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/storage/misc/pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]                         | pvc-<%= project.name %> |
      | ["spec"]["resources"]["requests"]["storage"] | 1Gi                     |
      | ["spec"]["storageClassName"]                 | sc-<%= project.name %>  |
    Then the step should succeed
    When I run the :set_volume client command with:
      | resource      | deployment              |
      | resource_name | hello-openshift         |
      | add           | true                    |
      | claim-name    | pvc-<%= project.name %> |
      | mount-path    | /tmp/data               |
    Then the step should succeed
    Given I open admin console in a browser
    When I perform the :goto_project_resources_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :check_error_icon_for_overview_item web action
    Then the step should succeed

    # check build error on overview
    When I run the :new_app client command with:
      | image_stream | openshift/python:latest                 |
      | code         | https://github.com/sclorg/django-ex.git |
      | name         | python-sample                           |
    Then the step should succeed
    Given the "python-sample-1" build was created
    When I run the :patch client command with:
      | resource      | buildconfig     |
      | resource_name | python-sample   |
      | p             | {"spec":{"source":{"git":{"uri":"https://github.com/sclorg/testdjango-ex.git"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | python-sample |
    Then the step should succeed
    Given the "python-sample-2" build finished
    When I perform the :goto_project_resources_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :check_error_icon_for_overview_item web action
    Then the step should succeed
    When I perform the :click_list_item web action with:
      | resource_kind | DeploymentConfig |
      | resource_name | python-sample    |
    Then the step should succeed
    When I run the :click_sidebar_resources_tab web action
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | Failed to fetch the input source |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-25792
  @admin
  Scenario: Check popover help on resource detail page
    Given the master version >= "4.3"
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/python:latest                 |
      | code         | https://github.com/sclorg/django-ex.git |
      | name         | python-sample                           |
    Then the step should succeed
    Given I open admin console in a browser
    # check BC page
    When I perform the :goto_one_buildconfig_page web action with:
      | project_name  | <%= project.name %>  |
      | bc_name       | python-sample        |
    Then the step should succeed
    When I perform the :check_popover_info web action with:
      | popover_item | Run Policy |
    Then the step should succeed
    # check build page
    When I perform the :goto_one_build_page web action with:
      | project_name  | <%= project.name %>  |
      | build_name    | python-sample-1      |
    Then the step should succeed
    When I perform the :check_popover_info web action with:
      | popover_item | Triggered By |
    Then the step should succeed
    # check DC page
    When I perform the :goto_one_dc_page web action with:
      | project_name  | <%= project.name %>  |
      | dc_name       | python-sample        |
    Then the step should succeed
    When I perform the :check_popover_info web action with:
      | popover_item | Update Strategy |
    Then the step should succeed
    # check deployment page
    Given the first user is cluster-admin
    When I perform the :goto_one_deployment_page web action with:
      | project_name | openshift-console |
      | deploy_name  | console           |
    Then the step should succeed
    When I perform the :check_popover_info web action with:
      | popover_item | Namespace |
    Then the step should succeed
    # check secret page
    When I perform the :goto_one_secret_page web action with:
      | project_name | openshift-console    |
      | secret_name  | console-serving-cert |
    Then the step should succeed
    When I perform the :check_popover_info web action with:
      | popover_item | Labels |
    Then the step should succeed
    # check route page
    When I perform the :goto_one_route_page web action with:
      | project_name | openshift-console    |
      | route_name   | console              |
    Then the step should succeed
    When I perform the :check_popover_info web action with:
      | popover_item | Service |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-21256
  Scenario: Check stateful set on overview page
    Given the master version >= "4.1"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/statefulset/statefulset-hello.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | app=hello |

    Given I open admin console in a browser
    When I perform the :goto_project_resources_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    # check pods links to correct page
    When I perform the :check_pod_number_and_link web action with:
      | text | 1 of 1 pods |
      | link | /k8s/ns/<%= project.name %>/statefulsets/hello/pods |
    Then the step should succeed

    # open sidebar
    When I perform the :click_list_item web action with:
      | resource_kind | StatefulSet |
      | resource_name | hello       |
    Then the step should succeed

    # check info in Overview sidebar
    When I run the :click_sidebar_overview_tab web action
    Then the step should succeed
    When I perform the :check_resource_details_key_and_value web action with:
      | key   | Name   |
      | value | hello  |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | hello |
      | link_url | /k8s/ns/<%= project.name %>/statefulsets/hello |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | <%= project.name %>                          |
      | link_url | /k8s/cluster/namespaces/<%= project.name %>  |
    Then the step should succeed

    # check info in Resources sidebar
    When I run the :click_sidebar_resources_tab web action
    Then the step should succeed
    When I perform the :check_pod_info_on_overview_sidebar web action with:
      | content | <%= pod.name %> |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-24106
  @admin
  Scenario: Check breadcrumb on resource detail page
    Given the master version >= "4.2"
    Given I open admin console in a browser
    Given I have a project
    Given the first user is cluster-admin
    # check Installed Operator and Install Plan page
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | etcd                   |
      | catalog_name     | community-operators    |
      | target_namespace | <%= project.name %>    |
    Then the step should succeed
    When I perform the :click_button web action with:
      | button_text  | Subscribe |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I perform the :check_page_contains web action with:
      | content | InstallSucceeded |
    Then the step should succeed
    """
    When I perform the :click_first_item_from_gridcell_list_and_check_breadcrumb web action with:
      | layer_number | 1                              |
      | link         | operators.coreos.com~v1alpha1~ClusterServiceVersion |
      | text         | InstalledOperators             |
    Then the step should succeed
    
    When I run the :browse_to_install_plan web action
    Then the step should succeed
    When I perform the :check_link_in_breadcrumb web action with:
      | layer_number | 1                         |
      | link         | operators.coreos.com~v1alpha1~InstallPlan |
      | text         | InstallPlans              |
    Then the step should succeed
    When I perform the :check_text_in_breadcrumb web action with:
      | layer_number | 2                         |
      | text         | InstallPlanDetails        |
    Then the step should succeed 

    # check project page
    When I run the :goto_projects_list_page web action
    Then the step should succeed
    When I perform the :click_first_item_from_resource_list_and_check_breadcrumb web action with:
      | layer_number | 1                         |
      | link         | cluster/projects          |
      | text         | Projects                  |
    Then the step should succeed
    When I perform the :check_text_in_breadcrumb web action with:
      | layer_number | 2                         |
      | text         | ProjectDetails            |
    Then the step should succeed

    # check replica sets page
    When I perform the :goto_replica_sets_page web action with:
      | project_name | openshift-console |
    Then the step should succeed
    When I perform the :click_first_item_from_resource_list_and_check_breadcrumb web action with:
      | layer_number | 1                         |
      | link         | /replicasets              |
      | text         | ReplicaSets               |
    Then the step should succeed
    When I perform the :check_text_in_breadcrumb web action with:
      | layer_number | 2                         |
      | text         | ReplicaSetDetails         |
    Then the step should succeed   

    # check machine page
    When I run the :goto_all_machines_page web action
    Then the step should succeed
    When I perform the :click_first_item_from_resource_list_and_check_breadcrumb web action with:
      | layer_number | 1                         |
      | link         | /machine.openshift.io~v1beta1~Machine |
      | text         | Machines                  |
    Then the step should succeed
    When I perform the :check_text_in_breadcrumb web action with:
      | layer_number | 2                         |
      | text         | MachineDetails            |
    Then the step should succeed    
    # check machine set page
    When I run the :goto_all_machine_sets_page web action
    Then the step should succeed
    When I perform the :click_first_item_from_resource_list_and_check_breadcrumb web action with:
      | layer_number | 1                         |
      | link         | /machine.openshift.io~v1beta1~MachineSet |
      | text         | MachineSets               |
    Then the step should succeed
    When I perform the :check_text_in_breadcrumb web action with:
      | layer_number | 2                         |
      | text         | MachineSetDetails         |
    Then the step should succeed   

    # check pod and container page
    When I perform the :goto_project_pods_list_page web action with:
      | project_name | openshift-console | 
    Then the step should succeed
    When I perform the :click_first_item_from_resource_list_and_check_breadcrumb web action with:
      | layer_number | 1                              |
      | link         | /k8s/ns/openshift-console/pods |
      | text         | Pods                           |
    Then the step should succeed
    And evaluation of `browser.url` is stored in the :url clipboard
    When I perform the :click_first_item_from_sub_resource_list_and_check_breadcrumb web action with:
      | layer_number | 2                              |
      | link         | pods/<%= cb.url.split("pods/")[-1].gsub("/","") %> |
      | text         | <%= cb.url.split("pods/")[-1].gsub("/","") %>      |
    Then the step should succeed
    When I perform the :check_text_in_breadcrumb web action with:
      | layer_number | 3                              |
      | text         | ContainerDetails               |
    Then the step should succeed

    # check image stream and image stream tag page
    When I run the :goto_all_imagestreams_list web action
    Then the step should succeed
    When I perform the :click_first_item_from_resource_list_and_check_breadcrumb web action with:
      | layer_number | 1                              |
      | link         | imagestreams                   |
      | text         | ImageStreams                   |
    Then the step should succeed
    And evaluation of `browser.url` is stored in the :url clipboard
    When I perform the :click_first_item_from_sub_resource_list_and_check_breadcrumb web action with:
      | layer_number | 2                              |
      | link         | imagestreams/<%= cb.url.split("imagestreams/")[-1].gsub("/","") %> |
      | text         | <%= cb.url.split("imagestreams/")[-1].gsub("/","") %>              |
    Then the step should succeed
    When I perform the :check_text_in_breadcrumb web action with:
      | layer_number | 3                              |
      | text         | ImageStreamTagDetails          |
    Then the step should succeed

    