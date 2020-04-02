Feature: Check overview page

  # @author hasha@redhat.com
  # @case_id OCP-11684
  Scenario: Check ReplicaSet/StatefulSet/k8s deployment on overview page
    Given the master version >= "3.6"
    Given I have a project
    # create ReplicaSet
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/replicaSet/tc536601/replicaset.yaml" replacing paths:
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/statefulset/statefulset-hello.yaml |
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
    When I run oc create over "<%= BushSlicer::HOME %>/features/tierN/testdata/deployment/tc536600/hello-deployment-1.yaml" replacing paths:
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web console action with:
      | text | service-unsecure |
    Then the step should succeed
    When I perform the :check_service_list_page web console action with:
      | project_name  | <%= project.name%> |
      | service_name  | service-unsecure   |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/build/test-buildconfig.json |
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
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/pipeline/ui-pipeline-stage.yaml |
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
    Given the "sample-pipeline-2" build was created
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
