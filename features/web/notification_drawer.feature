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