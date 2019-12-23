Feature: quota related feature

  # @author yanpzhan@redhat.com
  # @case_id OCP-21958
  @admin
  Scenario: Show resource quota on project status page
    Given the master version >= "4.1"
    Given I have a project
    When I run the :create_quota admin command with:
      | name | myquota1                   |
      | hard | cpu=1,requests.memory=1G,limits.cpu=2,limits.memory=2G,pods=2,services=3 |
      | n    | <%= project.name %>        |
    Then the step should succeed
    Given I open admin console in a browser
    When I perform the :goto_one_project_dashboard_page web action with:
      | project_name  | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | myquota1 |
      | link_url | <%= project.name %>/resourcequotas/myquota1 |
    Then the step should succeed
    When I perform the :check_used_quota_ratio web action with:
      | quota_name           | myquota1 |
      | cpu_request_ratio    | 0% |
      | cpu_limit_ratio      | 0% |
      | memory_request_ratio | 0% |
      | memory_limit_ratio   | 0% |
    Then the step should succeed

    When I run the :create_quota admin command with:
      | name | myquota2            |
      | hard | pods=3,services=13  |
      | n    | <%= project.name %> |
    Then the step should succeed
    When I perform the :goto_quotas_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | myquota2 |
      | link_url | <%= project.name %>/resourcequotas/myquota2 |
    Then the step should succeed
    When I perform the :goto_one_project_dashboard_page web action with:
      | project_name  | <%= project.name %> |
    Then the step should succeed
    When I run the :wait_box_loaded web action
    Then the step should succeed
    When I perform the :check_page_not_match web action with:
      | content | myquota2 |
    Then the step should succeed

    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota-terminating.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota-notbesteffort.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I perform the :goto_one_project_dashboard_page web action with:
      | project_name  | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | quota-terminating |
      | link_url | <%= project.name %>/resourcequotas/quota-terminating |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | quota-notbesteffort |
      | link_url | <%= project.name %>/resourcequotas/quota-notbesteffort |
    Then the step should succeed

    When I run the :run client command with:
      | name      | mypod                 |
      | image     | aosqe/hello-openshift |
      | requests  | cpu=50m,memory=100Mi  |
      | limits    | cpu=50m,memory=100Mi  |
      | generator | run-pod/v1            |
    Then the step should succeed
    When I perform the :check_used_quota_ratio web action with:
      | quota_name           | myquota1 |
      | cpu_request_ratio    | 5%       |
    Then the step should succeed
    When I perform the :check_chart_color web action with:
      | quota_name  | myquota1    |
      | graph_title | CPU Request |
      | chart_color | green       |
    Then the step should succeed

    When I run the :run client command with:
      | name      | mypod2                |
      | image     | aosqe/hello-openshift |
      | requests  | cpu=950m,memory=100Mi |
      | limits    | cpu=1,memory=1Gi      |
      | generator | run-pod/v1            |
    Then the step should succeed
    When I perform the :check_chart_color web action with:
      | quota_name  | myquota1    |
      | graph_title | CPU Request |
      | chart_color | yellow      |
    Then the step should succeed

    When I run the :create_quota admin command with:
      | name | myquota3              |
      | hard | cpu=500m,memory=100Mi |
      | n    | <%= project.name %>   |
    Then the step should succeed
    When I perform the :check_chart_color web action with:
      | quota_name  | myquota3    |
      | graph_title | CPU Request |
      | chart_color | red         |
    Then the step should succeed
