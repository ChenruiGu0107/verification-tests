Feature: quota related feature

  # @author yanpzhan@redhat.com
  # @case_id OCP-21958
  @admin
  Scenario: Show resource quota on project status page
    Given the master version >= "4.1"
    Given I have a project

    # create a quota with cpu, memory limits
    When I run the :create_quota admin command with:
      | name | myquota1                   |
      | hard | cpu=1,requests.memory=1G,limits.cpu=2,limits.memory=2G,pods=2,services=3 |
      | n    | <%= project.name %>        |
    Then the step should succeed

    # create a quota only with resource count limits
    When I run the :create_quota admin command with:
      | name | myquota2            |
      | hard | pods=3,services=13  |
      | n    | <%= project.name %> |
    Then the step should succeed

    Given I open admin console in a browser

    # quota with cpu, memory limits will show up in project dashboard
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

    # quota without cpu, memory limits will not show up in project dashboard
    When I perform the :check_page_not_match web action with:
      | content | myquota2 |
    Then the step should succeed

    # normal quota will still show up on quotas page
    When I perform the :goto_quotas_page web action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | myquota2 |
      | link_url | <%= project.name %>/resourcequotas/myquota2 |
    Then the step should succeed

    # create other types of quota with specific scopes
    Given I obtain test data file "quota/quota-terminating.yaml"
    When I run the :create admin command with:
      | f | quota-terminating.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "quota/quota-notbesteffort.yaml"
    When I run the :create admin command with:
      | f | quota-notbesteffort.yaml |
      | n | <%= project.name %> |
    Then the step should succeed

    # quota with specific scopes will show up on project dashboard
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
      | image     | quay.io/openshifttest/hello-openshift@sha256:aaea76ff622d2f8bcb32e538e7b3cd0ef6d291953f3e7c9f556c1ba5baf47e2e |
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
      | image     | quay.io/openshifttest/hello-openshift@sha256:aaea76ff622d2f8bcb32e538e7b3cd0ef6d291953f3e7c9f556c1ba5baf47e2e |
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
