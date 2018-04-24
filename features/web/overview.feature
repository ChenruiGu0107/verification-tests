Feature: Check overview page
  # @author xiaocwan@redhat.com
  # @case_id OCP-10101
  Scenario: Check overview page
    Given the master version <= "3.5"
    Given I have a project
    When I perform the :check_project_overview_without_resource web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    When I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git |
    Then the step should succeed
    When I perform the :goto_builds_page web console action with:
      | project_name | <%= project.name%> |
    Then the step should succeed
    When I run the :delete client command with:
      | all_no_dash | |
      | all         | |
    Then the step should succeed

    When I run the :new_app client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_service_link_on_overview web console action with:
      | project_name | <%= project.name %> |
      | service_name | ruby-ex             |
    Then the step should succeed
    When I perform the :check_deployment_config_link_info_on_overview web console action with:
      | project_name | <%= project.name %> |
      | dc_name      | ruby-ex             |
    Then the step should succeed
    When I perform the :check_view_log_link_info_on_overview web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-ex             |
      | bc_build_id  | ruby-ex-1           |
    Then the step should succeed
    When I perform the :check_alert_info_for_add_health_checks web console action with:
      | app_name | Ruby Ex |
      | dc_name  | ruby-ex |
    Then the step should succeed
    When I run the :click_close_alert web console action
    Then the step should succeed
    # below checks are only valid when the build is completed
    Given the "ruby-ex-1" build completed
    And 1 pods become ready with labels:
      | app=ruby-ex |
    When I perform the :check_deployments_rc_link_info_on_overview web console action with:
      | project_name | <%= project.name %> |
      | rc_name      | ruby-ex-1           |
    Then the step should succeed
    When I perform the :check_pod_info_on_overview web console action with:
      | pod_display | 1pod |
    Then the step should succeed
    When I perform the :check_pod_container_info web console action with:
      | container_name | ruby-ex                     |
      | image_name     | <%= project.name %>/ruby-ex |
      | port           | 8080/TCP                    |
    Then the step should succeed

    When I run the :click_create_route_on_overview web console action
    Then the step should succeed
    When I perform the :create_unsecured_route_from_service_or_overview_page web console action with:
      | route_name | service-ruby-ex |
    Then the step should succeed
    And evaluation of `route("service-ruby-ex", service("service-ruby-ex")).dns` is stored in the :route_hostname clipboard
    When I perform the :check_route_link_on_overview web console action with:
      | route_host_name | <%= cb.route_hostname %> |
    When I run the :delete client command with:
      | all_no_dash | |
      | all         | |
    Then the step should succeed

    # step 7. Create standalone DC and check standalone DC on overview
    When I run the :run client command with:
      | name     | myrun                 |
      | image    | openshift/hello-openshift |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | deploymentconfig=myrun |
    When I perform the :check_pod_container_image web console action with:
      | image_name | openshift/hello-openshift |
    Then the step should succeed
    When I run the :scale_up_once web console action
    Then the step should succeed
    When I perform the :check_pod_scaled_numbers web console action with:
      | scaled_number | 2 |
    Then the step should succeed
    When I run the :scale_down_once web console action
    Then the step should succeed
    When I perform the :check_pod_scaled_numbers web console action with:
      | scaled_number | 1 |
    Then the step should succeed
    When I perform the :check_deployments_rc_link_info_on_overview web console action with:
      | project_name | <%= project.name %> |
      | rc_name      | myrun-1             |
    Then the step should succeed
    # test step 11. For running Deployments, user could "Cancel" on overview page
    # For Cancelled deployment #2, it will not be shown on overview
    When I run the :deploy client command with:
      | deployment_config | myrun |
      | latest            |       |
    Then the step should succeed
    When I run the :click_cancel_and_confirm web console action
    Then the step should succeed
    When I perform the :check_page_not_contain_text web console action with:
      | text | #2 |
    Then the step should succeed
    When I run the :delete client command with:
      | all_no_dash | |
      | all         | |
    Then the step should succeed

    # step 8. Create standalone RC and check standalone RC info on overview
    When I run the :run client command with:
      | name      | myrun-rc              |
      | image     | openshift/hello-openshift |
      | generator | run-controller/v1     |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | run=myrun-rc |
    When I perform the :check_pod_container_image web console action with:
      | image_name | openshift/hello-openshift |
    Then the step should succeed
    When I run the :scale_up_once web console action
    Then the step should succeed
    When I perform the :check_pod_scaled_numbers web console action with:
      | scaled_number | 2 |
    Then the step should succeed
    When I run the :scale_down_once web console action
    Then the step should succeed
    When I perform the :check_pod_scaled_numbers web console action with:
      | scaled_number | 1 |
    Then the step should succeed
    When I perform the :check_deployments_rc_link_info_on_overview web console action with:
      | project_name | <%= project.name %> |
      | rc_name      | myrun-rc            |
    Then the step should succeed
    When I run the :delete client command with:
      | all_no_dash | |
      | all         | |
    Then the step should succeed

    # step 9. Create standalone Pod and check standalone Pod info on overview
    When I run the :run client command with:
      | name      | myrun-pod             |
      | image     | openshift/hello-openshift |
      | generator | run-pod/v1            |
    Then the step should succeed
    When I perform the :check_pod_container_image web console action with:
      | image_name | openshift/hello-openshift |
    Then the step should succeed
    When I run the :check_pod_scaling_disabled web console action
    Then the step should succeed
    When I perform the :check_pod_scaled_numbers web console action with:
      | scaled_number | 1 |
    Then the step should succeed
    When I run the :delete client command with:
      | all_no_dash | |
      | all         | |
    Then the step should succeed

    # step 10. Create standalone service and check standalone service info on overview
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/standalone-service.json |
      | n | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_page_contain_text web console action with:
      | text | standalone-service |
    Then the step should succeed

    When I run the :check_no_deployments_or_pods web console action
    Then the step should succeed

  # @author hasha@redhat.com
  # @case_id OCP-13641
  Scenario: Check app resources on overview page
    Given the master version >= "3.6"
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | openshift/ruby:latest                    |
      | app_repo     | https://github.com/openshift/ruby-ex.git |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | app=ruby-ex |
    When I expose the "ruby-ex" service
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_application_block_info_on_overview web console action with:
      | resource_name        | ruby-ex                            |
      | resource_type        | deployment                         |
      | project_name         | <%= project.name %>                |
      | build_num            | 1                                  |
      | build_status         | complete                           |
      | route_url            | http://<%= route("ruby-ex").dns %> |
      | route_port_info      | 8080-tcp                           |
      | service_port_mapping | 8080/TCP (8080-tcp) 8080           |
      | container_image      | ruby-ex                            |
      | container_source     | Merge pull request                 |
      | container_ports      | 8080/TCP                           |
      | bc_name              | ruby-ex                            |
    Then the step should succeed
    When I perform the :operate_in_kebab_drop_down_list_on_overview web console action with:
      | project_name  | <%= project.name %> |
      | resource_name | ruby-ex             |
      | viewlog_type  | rc                  |
      | log_name      | ruby-ex-1           |
    Then the step should succeed

  # @author hasha@redhat.com
  # @case_id OCP-11684
  Scenario: Check ReplicaSet/StatefulSet/k8s deployment on overview page
    Given the master version >= "3.6"
    Given I have a project
    # create ReplicaSet
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/replicaSet/tc536601/replicaset.yaml" replacing paths:
       | ["spec"]["replicas"] | 1 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=guestbook |
    Then evaluation of `pod.name` is stored in the :replica_pod clipboard
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :operate_in_kebab_drop_down_list_on_overview web console action with:
      | project_name  | <%= project.name %> |
      | edityaml_type | ReplicaSet          |
      | resource_name | frontend            |
      | yaml_name     | frontend            |
      | viewlog_type  | pods                |
      | log_name      | <%= cb.replica_pod%>|
    Then the step should succeed
    When I run the :scale client command with:
      | resource | replicaset |
      | name     | frontend   |
      | replicas | 0          |
    Then the step should succeed

    # create StatefulSet
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/statefulset/statefulset-hello.yaml |
      | n | <%= project.name %>                                                                                   |
    Then the step should succeed
    And a pod becomes ready with labels:
      | app=hello |
    Then evaluation of `pod.name` is stored in the :hello_pod clipboard
    When I perform the :operate_in_kebab_drop_down_list_on_overview web console action with:
      | project_name  | <%= project.name %> |
      | edityaml_type | StatefulSet         |
      | resource_name | hello               |
      | yaml_name     | hello               |
      | viewlog_type  | pods                |
      | log_name      | <%= cb.hello_pod%>  |
    Then the step should succeed

    # create k8s deployment
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc536600/hello-deployment-1.yaml" replacing paths:
       | ["spec"]["replicas"] | 1 |
    Then the step should succeed

    And a pod becomes ready with labels:
      | app=hello-openshift |
    Then evaluation of `pod.name` is stored in the :openshift_pod clipboard
    When I perform the :operate_in_kebab_drop_down_list_on_overview web console action with:
      | project_name  | <%= project.name %>   |
      | edityaml_type | Deployment            |
      | resource_name | hello-openshift       |
      | yaml_name     | hello-openshift       |
      | viewlog_type  | pods                  |
      | log_name      | <%= cb.openshift_pod%>|
    Then the step should succeed


  # @author hasha@redhat.com
  # @case_id OCP-13649
  Scenario: Check standalone resources on overview page
    Given the master version >= "3.6"
    Given I have a project
    When I run the :run client command with:
      | name      | myrun                     |
      | image     | openshift/hello-openshift |
      | limits    | cpu=200m,memory=250Mi     |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :operate_in_kebab_drop_down_list_on_overview web console action with:
      | project_name  | <%= project.name%>|
      | resource_name | myrun             |
      | viewlog_type  | rc                |
      | log_name      | myrun-1           |
    Then the step should succeed
    When I run the :run client command with:
      | name      | myrun-rc               |
      | image     | aosqe/hello-openshift  |
      | generator | run-controller/v1      |
      | limits    | cpu=300m,memory=250Mi  |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=myrun-rc |
    Then evaluation of `pod.name` is stored in the :myrunrc_pod clipboard
    When I perform the :operate_in_kebab_drop_down_list_on_overview web console action with:
      | resource_name | myrun-rc              |
      | project_name  | <%= project.name%>    |
      | edityaml_type | ReplicationController |
      | yaml_name     | myrun-rc              |
      | viewlog_type  | pods                  |
      | log_name      | <%= cb.myrunrc_pod%>  |
    Then the step should succeed
    When I run the :run client command with:
      | name      | myrun-pod             |
      | image     | aosqe/hello-openshift |
      | generator | run-pod/v1            |
      | limits    | cpu=300m,memory=250Mi |
    Then the step should succeed
    When I perform the :operate_in_kebab_drop_down_list_on_overview web console action with:
      | resource_name | myrun-pod          |
      | project_name  | <%= project.name%> |
      | edityaml_type | Pod                |
      | yaml_name     | myrun-pod          |
      | viewlog_type  | pods               |
      | log_name      | myrun-pod          |
    Then the step should succeed
    When I run the :run client command with:
      | name      | myrun-pod-warning              |
      | image     | aosqe/hello-openshift-nonexist |
      | generator | run-pod/v1                     |
      | limits    | cpu=300m,memory=250Mi          |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web console action with:
      | text | service-unsecure |
    Then the step should succeed
    When I perform the :check_service_list_page web console action with:
      | project_name  | <%= project.name%> |
      | service_name  | service-unsecure   |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/test-buildconfig.json |
      | n | <%= project.name %>                                                                            |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web console action with:
      | text | ruby-sample-build |
    Then the step should succeed
    When I perform the :check_bc_exists_in_list web console action with:
      | project_name | <%= project.name%> |
      | bc_name   | ruby-sample-build  |
    Then the step should succeed

  # @author yanpzhan@redhat.com
  # @case_id OCP-13652
  Scenario: Check pipeline on overview page
    Given the master version >= "3.6"
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pipeline/ui-pipeline-stage.yaml |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | sample-pipeline |
    Then the step should succeed

    Given the "sample-pipeline-1" build was created
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :list_by_type_on_overview_page web console action with:
      | type | Pipeline |
    Then the step should succeed

    Given I wait until the status of deployment "jenkins" becomes :complete
    Given the "sample-pipeline-1" build becomes :complete
    When I perform the :check_pipeline_info_on_overview web console action with:
      | project_name       | <%= project.name %>    |
      | pipeline_name      | sample-pipeline        |
      | pipeline_build_num | 1                      |
      | jenkins_log_url    | job/<%= project.name %>-sample-pipeline/1/console |
    Then the step should succeed

    When I perform the :check_pipeline_stage_appear web console action with:
      | stage_name | stageone |
    Then the step should succeed
    When I perform the :check_pipeline_stage_appear web console action with:
      | stage_name | stagetwo |
    Then the step should succeed

    When I run the :click_start_pipeline web console action
    Then the step should succeed
    When I perform the :check_pipeline_info_on_overview web console action with:
      | project_name       | <%= project.name %>    |
      | pipeline_name      | sample-pipeline        |
      | pipeline_build_num | 2                      |
      | jenkins_log_url    | job/<%= project.name %>-sample-pipeline/2/console |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-18266
  @admin
  Scenario: Check Daemon Sets on Overview
    Given the master version >= "3.10"
    Given cluster role "cluster-admin" is added to the "first" user
    And I use the "openshift-template-service-broker" project
    Given a pod becomes ready with labels:
      | apiserver=true |
    When I perform the :goto_overview_page web console action with:
      | project_name | openshift-template-service-broker |
    Then the step should succeed
    When I perform the :operate_in_kebab_drop_down_list_on_overview web console action with:
      | resource_name        | apiserver                          |
      | resource_type        | daemon set                         |
      | project_name         | openshift-template-service-broker  |
      | viewlog_type         | pods                               |
      | log_name             | <%= pod.name %>                    |
      | edityaml_type        | DaemonSet                          |
      | yaml_name            | apiserver                          |
    Then the step should succeed
    When I perform the :expand_resource_entry web console action with:
      | resource_name | apiserver |
    Then the step should succeed
    When I perform the :check_internal_traffic web console action with:
      | project_name         | openshift-template-service-broker |
      | service_name         | apiserver                         |
      | service_port_mapping | 443/TCP 8443                      |
    Then the step should succeed
    When I perform the :check_container_info_on_overview web console action with:
      | container_image | openshift3/ose-template-service-broker |
      | container_ports | 8443/TCP                               |
    Then the step should succeed
