Feature: overview cases

  # @author yapei@redhat.com
  # @case_id OCP-20932
  Scenario: Check app resources on overview page
    Given the master version >= "4.1"
    Given I have a project
    When I run the :new_app_as_dc client command with:
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
    When I perform the :check_resource_details web action with:
      | name | python-sample |
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
    Given I obtain test data file "deployment/hello-deployment-1.yaml"
    When I run oc create over "hello-deployment-1.yaml" replacing paths:
      | ["spec"]["replicas"] | 1 |
    Then the step should succeed
    Given I obtain test data file "storage/misc/pvc-with-storageClassName.json"
    When I create a dynamic pvc from "pvc-with-storageClassName.json" replacing paths:
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
    When I run the :new_app_as_dc client command with:
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
    When I run the :new_app_as_dc client command with:
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

  # @author yapei@redhat.com
  # @case_id OCP-21256
  Scenario: Check stateful set on overview page
    Given the master version >= "4.1"
    Given I have a project
    Given I obtain test data file "statefulset/statefulset-hello.yaml"
    When I run the :create client command with:
      | f | statefulset-hello.yaml |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | app=hello |

    Given I open admin console in a browser
    When I perform the :goto_project_resources_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    # check pods links to correct page
    When I perform the :check_pod_number_and_link web action with:
      | text | 1 of 1 |
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
    When I perform the :check_resource_details web action with:
      | name | hello |
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
    When I run the :navigate_to_admin_console web action
    Then the step should succeed
    # check Installed Operator and Install Plan page
    When I perform the :goto_operator_subscription_page web action with:
      | package_name     | etcd                   |
      | catalog_name     | community-operators    |
      | target_namespace | <%= project.name %>    |
    Then the step should succeed
    When I run the :click_subscribe_button web action
    Then the step should succeed
    Given I wait for the "etcd" subscriptions to appear
    Given I wait up to 100 seconds for the steps to pass:
    """
    When I get project clusterserviceversions
    Then the output should contain "etcdoperator.v"
    """
    And evaluation of `subscription("etcd").current_csv` is stored in the :etcd_csv clipboard
    When I perform the :goto_csv_detail_page web action with:
      | project_name | <%= project.name %>       |
      | csv_name     | <%= cb.etcd_csv %> |
    Then the step should succeed
    When I perform the :check_link_in_breadcrumb web action with:
      | layer_number | 1                              |
      | link         | operators.coreos.com~v1alpha1~ClusterServiceVersion |
      | text         | InstalledOperators             |
    Then the step should succeed

    When I run the :browse_to_install_plan web action
    Then the step should succeed
    When I run the :wait_box_loaded web action
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

  # @author yapei@redhat.com
  # @case_id OCP-21270
  Scenario: Group resources
    Given the master version >= "4.1"
    Given I have a project
    And I open admin console in a browser

    # check Group by dropdown only have Application, Resource when no resources in project
    When I perform the :goto_project_resources_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :check_groupby_dropdown_when_no_resources web action
    Then the step should succeed
    When I run the :check_groupby_label_header_missing web action
    Then the step should succeed

    # add app resources
    When I run the :new_app_as_dc client command with:
      | image_stream | openshift/ruby:latest                         |
      | app_repo     | https://github.com/openshift/ruby-hello-world |
      | name         | ruby |
    Then the step should succeed

    # add non-app resources
    Given I obtain test data file "deployment/simpledc.json"
    Given I obtain test data file "deployment/simple-deployment.yaml"
    When I run the :create client command with:
      | f | simpledc.json |
      | f | simple-deployment.yaml |
    Then the step should succeed

    # Group by: Application
    When I perform the :goto_project_resources_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :group_by_application web action
    Then the step should succeed
    When I perform the :check_overview_group_heading web action with:
      | group_heading_name | ruby |
    Then the step should succeed
    When I perform the :check_overview_group_heading web action with:
      | group_heading_name | other resources |
    Then the step should succeed
    When I perform the :check_overview_group_items web action with:
      | group_heading_name | ruby             |
      | resource_type      | DeploymentConfig |
      | resource_name      | ruby             |
    Then the step should succeed
    When I perform the :check_overview_group_items web action with:
      | group_heading_name | other resources |
      | resource_type      | Deployment      |
      | resource_name      | example         |
    Then the step should succeed
    When I perform the :check_overview_group_items web action with:
      | group_heading_name | other resources  |
      | resource_type      | DeploymentConfig |
      | resource_name      | hooks            |
    Then the step should succeed

    # Group by: Resource
    When I run the :group_by_resource web action
    Then the step should succeed
    When I perform the :check_overview_group_heading web action with:
      | group_heading_name | Deployment |
    Then the step should succeed
    When I perform the :check_overview_group_heading web action with:
      | group_heading_name | Deployment Config |
    Then the step should succeed
    When I perform the :check_overview_group_items web action with:
      | group_heading_name | Deployment |
      | resource_type      | Deployment |
      | resource_name      | example    |
    Then the step should succeed
    When I perform the :check_overview_group_items web action with:
      | group_heading_name | Deployment Config |
      | resource_type      | DeploymentConfig  |
      | resource_name      | hooks             |
    Then the step should succeed
    When I perform the :check_overview_group_items web action with:
      | group_heading_name | Deployment Config |
      | resource_type      | DeploymentConfig  |
      | resource_name      | ruby              |
    Then the step should succeed

    # Group by: label
    When I run the :label client command with:
      | resource | deployment |
      | name     | example    |
      | key_val  | testlabel1=testvalue1 |
    Then the step should succeed
    When I run the :label client command with:
      | resource | deploymentconfig      |
      | name     | hooks                 |
      | key_val  | testlabel2=testvalue2 |
    Then the step should succeed

    # group by 'testlabel1' will show 'testvalue1' and 'other resources'
    When I perform the :group_by_label web action with:
      | label | testlabel1 |
    Then the step should succeed
    When I perform the :check_overview_group_items web action with:
      | group_heading_name | testvalue1 |
      | resource_type      | Deployment |
      | resource_name      | example    |
    Then the step should succeed
    When I perform the :check_overview_group_items web action with:
      | group_heading_name | other resources  |
      | resource_type      | DeploymentConfig |
      | resource_name      | hooks            |
    Then the step should succeed
    When I perform the :check_overview_group_items web action with:
      | group_heading_name | other resources  |
      | resource_type      | DeploymentConfig |
      | resource_name      | ruby             |
    Then the step should succeed

    # group by 'testlabel2' will show 'testvalue2' and 'other resources'
    When I perform the :group_by_label web action with:
      | label | testlabel2 |
    Then the step should succeed
    When I perform the :check_overview_group_heading web action with:
      | group_heading_name | testvalue2 |
    Then the step should succeed
    When I perform the :check_overview_group_heading web action with:
      | group_heading_name | other resources |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-20983
  Scenario: Check daemon set on Home Overview page
    Given the master version >= "4.1"
    Given I have a project
    Given I obtain test data file "daemon/daemonset.yaml"
    When I run the :create client command with:
      | f | daemonset.yaml |
    Then the step should succeed
    And "hello-daemonset" daemonset becomes ready in the "<%= project.name %>" project
    And evaluation of `daemon_set("hello-daemonset").desired_replicas(cached: false)` is stored in the :ds_disired_replicas clipboard
    And evaluation of `daemon_set("hello-daemonset").current_replicas(cached: false)` is stored in the :ds_current_replicas clipboard
    And evaluation of `daemon_set("hello-daemonset").pods(cached: false)` is stored in the :ds_all_pods clipboard

    # check pods links to correct page
    And I open admin console in a browser
    When I perform the :goto_project_resources_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_list_item web action with:
      | resource_kind | DaemonSet        |
      | resource_name | hello-daemonset  |
    Then the step should succeed
    When I perform the :check_pod_number_and_link web action with:
      | text | <%= cb.ds_current_replicas %> of <%= cb.ds_disired_replicas %> |
      | link | /k8s/ns/<%= project.name %>/daemonsets/hello-daemonset/pods    |
    Then the step should succeed

    # check basic info on overview view
    When I perform the :click_list_item web action with:
      | resource_kind | DaemonSet        |
      | resource_name | hello-daemonset  |
    Then the step should succeed
    When I run the :sidebar_is_loaded web action
    Then the step should succeed
    When I run the :click_sidebar_overview_tab web action
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | name | hello-daemonset |
    Then the step should succeed

    # make sure the 1st and last pod of daemonset are shown on page
    When I run the :click_sidebar_resources_tab web action
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | <%= cb.ds_all_pods[0].name %> |
    Then the step should succeed
    When I perform the :check_page_contains web action with:
      | content | <%= cb.ds_all_pods[-1].name %> |
    Then the step should succeed

  # @author xiaocwan@redhat.com
  # @case_id OCP-20984
  Scenario: Check k8s deployment on Home Overview page
    Given the master version >= "4.1"
    Given I have a project
    Given I obtain test data file "deployment/simple-deployment.yaml"
    When I run the :create client command with:
      | f | simple-deployment.yaml |
    Then the step should succeed
    When a pod becomes ready with labels:
      | app=hello-openshift |
    Then current replica set name of "example" deployment stored into :rs_name clipboard

    Given I open admin console in a browser
    When I perform the :goto_project_resources_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    # check ds link
    When I perform the :check_list_item web action with:
      | resource_name | example         |
      | resource_kind | Deployment      |
    Then the step should succeed
    # check rs link
    When I perform the :check_link_and_text web action with:
      | text     | 1 |
      | link_url | /k8s/ns/<%= project.name %>/replicasets/<%= cb.rs_name %> |
    Then the step should succeed
    When I perform the :check_pod_number_and_link web action with:
      | text | 1 of 1 |
      | link | /k8s/ns/<%= project.name %>/replicasets/<%= cb.rs_name %>/pods |
    Then the step should succeed
    # check actions on expanded sidebar
    When I perform the :click_list_item web action with:
      | resource_name | example         |
      | resource_kind | Deployment      |
    Then the step should succeed
    When I run the :check_deployment_availble_action_menus web action
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-27582
  @admin
  @destructive
  Scenario: Add Operators health in Status card
    Given the master version >= "4.4"
    Given the first user is cluster-admin
    And I open admin console in a browser
    Given I register clean-up steps:
    """
    When I run the :patch admin command with:
      | resource | console.operator/cluster         |
      | type     | merge                            |
      | p        | {"spec":{"customization": null}} |
    Then the step should succeed
    When I run the :delete admin command with:
      | object_type       | csv                 |
      | object_name_or_id | etcdoperator.v0.9.4 |
      | n                 | default             |
    """

    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :check_view_all_for_operators web action
    Then the step should succeed
    """
    And the expression should be true> browser.url.end_with? "ClusterServiceVersion"
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :check_view_all_for_cluster_operators web action
    Then the step should succeed
    """
    And the expression should be true> browser.url.end_with? "clusteroperators"

    Given I obtain test data file "cases/ocp-27582/etcd-testcsv.yaml"
    Given I use the "default" project
    When I run the :create client command with:
      | f | etcd-testcsv.yaml |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource | console.operator/cluster |
      | type     | merge                    |
      | p        | {"spec":{"customization": {"customProductName":"my-custom-name","customLogoFile":{"name":"myconfig","key":"mypic.jpg"}}}} |
    Then the step should succeed

    And I wait up to 200 seconds for the steps to pass:
    """
    When I perform the :check_operator_status_on_status_card web action with:
      | operator_type | Operators        |
      | operator_name | etcd             |
      | status        | 1 project failed |
    Then the step should succeed
    """
    And the expression should be true> browser.url.end_with? "/default/operators.coreos.com~v1alpha1~ClusterServiceVersion/etcdoperator.v0.9.4"

    And I wait up to 300 seconds for the steps to pass:
    """
    When I perform the :check_cluster_operator_status_on_status_card web action with:
      | operator_name | console           |
      | status        | Degraded          |
    Then the step should succeed
    """
    And the expression should be true> browser.url.end_with? "config.openshift.io~v1~ClusterOperator/console"

  # @author schituku@redhat.com
  # @case_id OCP-23609
  Scenario: Check the short cuts on the workloads tab
    Given the master version >= "4.2"
    And I have a project
    # create a dc and deployment
    And I obtain test data file "deployment/simpledc.json"
    And I obtain test data file "deployment/simple-deployment.yaml"
    When I run the :create client command with:
      | f | simple-deployment.yaml |
      | f | simpledc.json          |
    Then the step should succeed
    # Go to the workloads tab on project details page.
    Given I open admin console in a browser
    When I perform the :goto_project_resources_page web action with:
      | project_name | <%= project.name %> |
    # check short cut "down arrow" and check the highlighted workload.
    And I perform the :check_shortcuts_on_workloads web action with:
      | workload      | Deployment  |
      | workload_name | example     |
      | key           | :arrow_down |
    Then the step should succeed
    # check short cut "up arrow" and check the highlighted workload.
    And I perform the :check_next_shortcut_on_workloads web action with:
      | workload      | DeploymentConfig |
      | workload_name | hooks            |
      | key           | :arrow_up        |
    Then the step should succeed
    # check short cut "esc" and check the overview close.
    And I perform the :check_escape_on_workloads web action with:
      | key | :escape |
    Then the step should succeed
    # check short cut "j" and check the highlighted workload.
    And I perform the :check_shortcuts_on_workloads web action with:
      | workload      | Deployment |
      | workload_name | example    |
      | key           | j          |
    Then the step should succeed
    # check short cut "k" and check the highlighted workload.
    And I perform the :check_next_shortcut_on_workloads web action with:
      | workload      | DeploymentConfig |
      | workload_name | hooks            |
      | key           | k                |
    Then the step should succeed
    # check short cut "/" highlights the filter input field and the hint inside becomes invisible.
    And I perform the :check_filter_on_workloads web action with:
      | workload      | Deployment |
      # the name of the workload here should be of the missing workload.
      | workload_name | hooks      |
      | key           | /          |
    Then the step should succeed
