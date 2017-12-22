  Feature: functions about notification_drawer

  # @author xiaocwan@redhat.com
  # @case_id OCP-15438
  @admin
  Scenario: Check meet and exceed message alert for compute-resource and object-count
    Given the master version >= "3.7"
    Given I have a project
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml"
    Then the step should succeed
    And I replace lines in "myquota.yaml":
      | cpu: "30"                    | cpu: "1"                    |
      | configmaps: "15"             | configmaps: "1"             |
    Then the step should succeed
    When I run the :create admin command with:
      | f | myquota.yaml        |
      | n | <%= project.name %> |
    Then the step should succeed 

    # Check at quota of compute-resource:
    When I run the :run client command with:
      | name      | myrc                     |
      | image     | aosqe/hello-openshift    |
      | limits    | cpu=500m,memory=500Mi    |
      | generator | run/v1                   |
    Then the step should succeed
    When I run the :scale client command with:
      | resource | rc   |
      | name     | myrc |
      | replicas | 2    |
    Then the step should succeed
    When I perform the :open_notification_drawer_on_overview web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_message_context_in_drawer web console action with:
      | status   | at            |
      | using    | 100%          |
      | total    | 1 core        |
      | resource | CPU (request) |
    Then the step should succeed
  
    # Check at quota of object-count:
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
    Then the step should succeed 
    When I perform the :open_notification_drawer_on_overview web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_message_context_in_drawer web console action with:
      | status   | at          |
      | using    | 1           |
      | total    | 1           |
      | resource | config maps |
    Then the step should succeed

    # Check exceed quota of compute-resource 
    When I run the :delete admin command with:
      | object_type       | resourcequota       |
      | object_name_or_id | myquota             |
      | n                 | <%= project.name %> |
    Then the step should succeed
    When I run the :scale client command with: 
      | resource | rc   |
      | name     | myrc |
      | replicas | 3    |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=myrc |
    Given I replace lines in "myquota.yaml":
      | pods: "20" | pods: "1" |
    When I run the :create admin command with:
      | f | myquota.yaml        |
      | n | <%= project.name %> |
    Then the step should succeed 
    When I perform the :open_notification_drawer_on_overview web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_message_context_in_drawer web console action with:
      | status   | over          |
      | using    | 150%          |
      | total    | 1 core        |
      | resource | CPU (request) |
    Then the step should succeed
    
    # Check message for exceed object-count quotas:
    When I perform the :check_message_context_in_drawer web console action with:
      | status   | over |
      | using    | 3    |
      | total    | 1    |
      | resource | pods |
    Then the step should succeed

    # Check quota page
    When I perform the :open_quota_page_from_kebab web console action with:
      | status   | over |
      | using    | 3    |
      | total    | 1    |
      | resource | pods |
    Then the step should succeed
    And the expression should be true> browser.url.end_with? "/project/<%= project.name %>/quota"

    # Check dont show me again
    When I perform the :open_notification_drawer_on_overview web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed  
    When I perform the :click_dont_show_me_again_from_kebab web console action with:
      | status   | at          |
      | using    | 1           |
      | total    | 1           |
      | resource | config maps |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type       | configmap      |
      | object_name_or_id | special-config |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/configmap/configmap.yaml |
    Then the step should succeed 
    When I perform the :open_notification_drawer_on_overview web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web console action with:
      | text | config maps |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-15231
  Scenario: Check notification goes into drawer in its own project
    Given the master version >= "3.7"
    # Create 2 projects, add 'python' app to 1st project, add 'php' app to 2nd project
    Given I have a project
    Then evaluation of `project.name` is stored in the :proj1_name clipboard
    Given I create a new project
    Then evaluation of `project.name` is stored in the :proj2_name clipboard
    When I run the :new_app client command with:
      | image_stream | openshift/python:latest                    |
      | code         | https://github.com/openshift/django-ex.git |
      | name         | python-sample                              |
      | n            | <%= cb.proj1_name %>                       |
    Then the step should succeed
    When I run the :new_app client command with:
      | image_stream | openshift/php:latest                         |
      | code         | https://github.com/openshift/cakephp-ex.git  |
      | name         | php-sample                                   |
      | n            | <%= cb.proj2_name %>                         |
    Then the step should succeed

    # check notification event
    When I perform the :open_notification_drawer_for_one_project web console action with:
      | project_name | <%= cb.proj1_name %> |
    Then the step should succeed
    When I perform the :check_drawer_notification_content web console action with:
      | event_reason | Build Started   |
      | event_object | python-sample-1 |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web console action with:
      | text | php |
    Then the step should succeed
    When I perform the :switch_project_in_project_lists web console action with:
      | current_project | <%= cb.proj1_name %> |
      | target_project  | <%= cb.proj2_name %> |
    Then the step should succeed
    When I perform the :check_drawer_notification_content web console action with:
      | event_reason | Build Started   |
      | event_object | php-sample-1    |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web console action with:
      | text | python |
    Then the step should succeed
    When I perform the :check_zero_unread_in_drawer web console action with:
      | unread_num | 0 |
    Then the step should succeed
    When I run the :check_drawer_info_when_no_events web console action
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-15235
  Scenario: Check build,deployment,pods events in notification drawer  
    Given the master version >= "3.7"
    Given I have a project
  
    # check build related notification in drawer
    When I run the :new_app client command with:
      | app_repo |   https://github.com/openshift/nodejs-ex |
    Then the step should succeed
    Given the "nodejs-ex-1" build was created
    When I run the :cancel_build client command with:
      | build_name | nodejs-ex-1 |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | bc                      |
      | resource_name | nodejs-ex               |
      | p             | {"spec":{"source":{"git":{"uri":"https://github.com/openshift/nodejs-ex-nont"}}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | nodejs-ex |
    Then the step should succeed
    Given the "nodejs-ex-2" build finishes
    When I perform the :open_notification_drawer_for_one_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_drawer_notification_content web console action with:
      | event_reason | Build Cancelled |
      | event_object | nodejs-ex-1     |
    Then the step should succeed
    When I perform the :check_drawer_notification_content web console action with:
      | event_reason | Build Started   |
      | event_object | nodejs-ex-2     |
    Then the step should succeed
    When I perform the :check_drawer_notification_content web console action with:
      | event_reason | Build Failed |
      | event_object | nodejs-ex-2  |
    Then the step should succeed
    
    # check deployment related notification in drawer
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/OCP-15235/test-dc.yaml |
    Then the step should succeed
    When I perform the :open_notification_drawer_for_one_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_drawer_notification_content web console action with:
      | event_reason          | Deployment Created |
      | event_resource_type   | Deployment Config  |
      | event_object          | php-apache         |
    Then the step should succeed
    When I run the :rollout_cancel client command with:
      | resource      | dc         |
      | resource_name | php-apache |
    Then the step should succeed
    And I wait until the status of deployment "php-apache" becomes :failed
    When I perform the :open_notification_drawer_for_one_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_drawer_notification_content web console action with:
      | event_reason          | Rollout Cancelled |
      | event_resource_type   | Deployment Config |
      | event_object          | php-apache        |
    Then the step should succeed
    
    # check pod related notification in drawer
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod-bad.json |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_pod_stuck_warning_message web console action with:
      | resource_name | hello-openshift |
    Then the step should succeed
    When I perform the :open_notification_drawer_for_one_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_drawer_notification_content web console action with:
      | event_reason          | Back Off        |
      | event_resource_type   | Pod             |
      | event_object          | hello-openshift |
    Then the step should succeed
    When I perform the :check_drawer_notification_content web console action with:
      | event_reason          | Failed          |
      | event_resource_type   | Pod             |
      | event_object          | hello-openshift |
    Then the step should succeed
