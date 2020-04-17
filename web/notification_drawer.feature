  Feature: functions about notification_drawer

  # @author xiaocwan@redhat.com
  # @case_id OCP-15438
  @admin
  Scenario: Check meet and exceed message alert for compute-resource and object-count
    Given the master version >= "3.7"
    Given I have a project
    When I obtain test data file "quota/myquota.yaml"
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap.yaml |
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/configmap/configmap.yaml |
    Then the step should succeed
    When I perform the :open_notification_drawer_on_overview web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_page_not_contain_text web console action with:
      | text | config maps |
    Then the step should succeed

  # @author yapei@redhat.com
  # @case_id OCP-15235
  Scenario: Check build,deployment,pods events in notification drawer
    Given the master version >= "3.7"
    Given I have a project

    # check build related notification in drawer
    When I run the :new_app client command with:
      | app_repo |   https://github.com/sclorg/nodejs-ex |
    Then the step should succeed
    Given the "nodejs-ex-1" build was created
    When I run the :cancel_build client command with:
      | build_name | nodejs-ex-1 |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | bc                      |
      | resource_name | nodejs-ex               |
      | p             | {"spec":{"source":{"git":{"uri":"https://github.com/sclorg/nodejs-ex-nont"}}}} |
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/OCP-15235/test-dc.yaml |
    Then the step should succeed
    When I perform the :open_notification_drawer_for_one_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_drawer_notification_content web console action with:
      | event_reason          | Deployment Created |
      | event_resource_type   | Deployment Config  |
      | event_object          | php-apache         |
    Then the step should succeed
    # make sure cancel succeed
    When I run the :rollout_cancel client command with:
      | resource | dc         |
      | name     | php-apache |
    Then the step should succeed
    Given I wait up to 120 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | dc         |
      | name     | php-apache |
    Then the step should succeed
    And the output should match:
      | [Cc]ancelled |
    """
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
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/hello-pod-bad.json |
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

  # @author hasha@redhat.com
  # @case_id OCP-15746
  Scenario: Check events for service provision in notification drawer
    Given I have a project
    Given the master version >= "3.7"
    When I run the :goto_home_page web console action
    Then the step should succeed
    When I perform the :provision_serviceclass_without_binding_on_homepage web console action with:
      | primary_catagory | Databases  |
      | sub_catagory     | MySQL      |
      | service_item     | MySQL      |
    Then the step should succeed
    Given I wait for all serviceinstances in the project to become ready
    When I run the :get client command with:
      | resource | serviceinstance |
    Then the step should succeed
    And evaluation of `@result[:response].split("mysql-")[1].split(" ")[0]` is stored in the :name clipboard
    When I perform the :open_notification_drawer_for_one_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_drawer_notification_content web console action with:
      | event_reason | Provisioning   |
      | event_object | <%= cb.name %> |
    Then the step should succeed
    When I run the :click_notification_drawer web console action
    Then the step should succeed
    When I perform the :delete_serviceinstance_on_overview_page web console action with:
      | resource_name | MySQL |
    Then the step should succeed
    When I perform the :open_notification_drawer_for_one_project web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I perform the :check_drawer_notification_content web console action with:
      | event_reason | Deprovisioning   |
      | event_object | <%= cb.name %> |
    Then the step should succeed


