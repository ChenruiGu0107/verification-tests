Feature: HPA related

  # @author hasha@redhat.com
  # @case_id OCP-19695
  Scenario: check HPAs page
    Given I have a project
    Given the master version >= "4.1"
    When I run the :new_app client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/sclorg/ruby-ex.git |
    Then the step should succeed
    Given 1 pods become ready with labels:
      | deploymentconfig=ruby-ex |
    When I run the :expose client command with:
      | resource      | svc     |
      | resource name | ruby-ex |
    Then the step should succeed
    Given I wait for the "ruby-ex" service to become ready
    When I run the :set_resources client command with:
      | resource     | dc                    |
      | resourcename | ruby-ex               |
      | limits       | cpu=100m,memory=256Mi |
    Then the step should succeed
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/testdata/hpa/hpa_rubyex.yaml |
    Then the step should succeed

    # check hpa list page
    Given I open admin console in a browser
    When I perform the :goto_hpas_page web action with:
      | project_name  | <%= project.name %>  |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Scale Target |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Min Pods |
    Then the step should succeed
    When I perform the :check_column_in_table web action with:
      | field | Max Pods |
    Then the step should succeed

    # check hpa details
    When I perform the :goto_one_hpa_page web action with:
      | project_name  | <%= project.name %> |
      | hpa_name      | test-hpa            |
    Then the step should succeed
    When I perform the :check_resource_details web action with:
      | scale_target     | ruby-ex |
      | min_replicas     | 1       |
      | max_replicas     | 5       |
      | desired_replicas | 0       |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text      | ruby-ex                                               |
      | link_url  | /k8s/ns/<%= project.name %>/deploymentconfigs/ruby-ex |
    Then the step should succeed
    When I perform the :check_hpa_metrics_table web action with:
      | target_resource_memory | 200Mi |
      | target_resource_cpu    | 1%    |
    Then the step should succeed

    #check replicas changes by hpa
    When I run the :create client command with:
      | f |  <%= BushSlicer::HOME %>/testdata/infrastructure/hpa/hello-pod.yaml |
    Then the step should succeed
    Given the pod named "hello-pod" status becomes :running within 60 seconds
    When I run the :exec background client command with:
      | pod              | hello-pod |
      | oc_opts_end      |           |
      | exec_command     | sh        |
      | exec_command_arg | -c        |
      | exec_command_arg | while true;do curl -sS http://<%= service.url %> &> /dev/null;done |
    Then the step should succeed
    Given I wait up to 600 seconds for the steps to pass:
    """
    Then expression should be true> hpa('test-hpa').current_replicas(cached: false) > 1
    And expression should be true> hpa('test-hpa').current_cpu_utilization_percentage > hpa('test-hpa').target_cpu_utilization_percentage
    """
    And evaluation of `hpa("test-hpa").current_replicas` is stored in the :current_replicas clipboard
    And evaluation of `hpa("test-hpa").current_cpu_utilization_percentage` is stored in the :current_cpu clipboard
    When I perform the :check_resource_details web action with:
      | current_replicas | <%= cb.current_replicas %> |
    Then the step should succeed
    When I perform the :check_hpa_metrics_table web action with:
      | current_cpu_utilization | <%= cb.current_cpu %> |
    Then the step should succeed
    Given I ensure "hello-pod" pod is deleted
    Given I wait up to 600 seconds for the steps to pass:
    """
    Then expression should be true> hpa('test-hpa').current_cpu_utilization_percentage(cached: false) == 0
    """
