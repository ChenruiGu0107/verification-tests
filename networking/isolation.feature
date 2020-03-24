Feature: networking isolation related scenarios

  # @author bmeng@redhat.com
  # @case_id OCP-9642
  @admin
  Scenario: Make the network of given project be accessible to other projects via selector
    # Create 3 projects and each contains 1 pod and 1 service
    Given the env is using multitenant network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :proj1p1 clipboard
    And evaluation of `pod.name` is stored in the :proj1p1name clipboard
    And evaluation of `service("test-service-1").ip(user: user)` is stored in the :proj1s1 clipboard

    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :proj2p1 clipboard
    And evaluation of `service("test-service-2").ip(user: user)` is stored in the :proj2s1 clipboard

    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-3 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :proj3p1 clipboard
    And evaluation of `service("test-service-3").ip(user: user)` is stored in the :proj3s1 clipboard

    # Add labels to projects and merge the network of specific label, and check the netid
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I run the :label client command with:
      | resource | namespace |
      | name | <%= cb.proj1 %> |
      | key_val | ns=unified |
    And I run the :label client command with:
      | resource | namespace |
      | name | <%= cb.proj2 %> |
      | key_val | ns=isolated |
    When I run the :oadm_pod_network_join_projects admin command with:
      | selector | ns=unified |
      | to | <%= cb.proj3 %> |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | netnamespace |
      | resource_name | <%= cb.proj1 %> |
      | template | {{.netid}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :proj1netid clipboard
    When I run the :get admin command with:
      | resource | netnamespace |
      | resource_name | <%= cb.proj3 %> |
      | template | {{.netid}} |
    Then the step should succeed
    And the output should equal "<%= cb.proj1netid %>"

    Given I switch to the first user
    # Create another new pod and service in each project
    Given I use the "<%= cb.proj1 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][0]["metadata"]["name"] | new-test-rc |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | new-test-pods |
      | ["items"][1]["spec"]["selector"]["name"] | new-test-pods |
      | ["items"][1]["metadata"]["name"] | new-test-service-1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-test-pods |
    And evaluation of `pod.ip` is stored in the :proj1p2 clipboard
    And evaluation of `service("new-test-service-1").ip(user: user)` is stored in the :proj1s2 clipboard

    Given I use the "<%= cb.proj2 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][0]["metadata"]["name"] | new-test-rc |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | new-test-pods |
      | ["items"][1]["spec"]["selector"]["name"] | new-test-pods |
      | ["items"][1]["metadata"]["name"] | new-test-service-2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-test-pods |
    And evaluation of `pod.ip` is stored in the :proj2p2 clipboard
    And evaluation of `pod.name` is stored in the :proj2p2name clipboard
    And evaluation of `service("new-test-service-2").ip(user: user)` is stored in the :proj2s2 clipboard

    Given I use the "<%= cb.proj3 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][0]["metadata"]["name"] | new-test-rc |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | new-test-pods |
      | ["items"][1]["spec"]["selector"]["name"] | new-test-pods |
      | ["items"][1]["metadata"]["name"] | new-test-service-3 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-test-pods |
    And evaluation of `pod.ip` is stored in the :proj3p2 clipboard
    And evaluation of `pod.name` is stored in the :proj3p2name clipboard
    And evaluation of `service("new-test-service-3").ip(user: user)` is stored in the :proj3s2 clipboard

    # Access the pod/svc on other projects from project 1
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.proj1p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj2p2 %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj1p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj3s1 %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"
    # Access the pod/svc on other projects from project 2
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.proj2p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1s2 %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj2p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj3p2 %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    # Access the pod/svc on other projects from project 3
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.proj3p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj2s1 %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj3p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1p2 %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"

  # @author bmeng@redhat.com
  # @case_id OCP-12658
  @admin
  Scenario: Make the network of given projects be accessible globally via selector
    # Create 3 projects and each contains 1 pod and 1 service
    Given the env is using multitenant network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :proj1p1 clipboard
    And evaluation of `pod.name` is stored in the :proj1p1name clipboard
    And evaluation of `service("test-service-1").ip(user: user)` is stored in the :proj1s1 clipboard

    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :proj2p1 clipboard
    And evaluation of `service("test-service-2").ip(user: user)` is stored in the :proj2s1 clipboard

    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-3 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :proj3p1 clipboard
    And evaluation of `service("test-service-3").ip(user: user)` is stored in the :proj3s1 clipboard

    # Make the network of specific project global via selector, and check the netid
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I run the :label client command with:
      | resource | namespace |
      | name | <%= cb.proj3 %> |
      | key_val | ns=global |
    When I run the :oadm_pod_network_make_projects_global admin command with:
      | selector | ns=global |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | netnamespace |
      | resource_name | <%= cb.proj3 %> |
      | template | {{.netid}} |
    Then the step should succeed
    And the output should equal "0"

    Given I switch to the first user
    # Create another new pod and service in each project
    Given I use the "<%= cb.proj1 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][0]["metadata"]["name"] | new-test-rc |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | new-test-pods |
      | ["items"][1]["spec"]["selector"]["name"] | new-test-pods |
      | ["items"][1]["metadata"]["name"] | new-test-service-1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-test-pods |
    And evaluation of `pod.ip` is stored in the :proj1p2 clipboard
    And evaluation of `service("new-test-service-1").ip(user: user)` is stored in the :proj1s2 clipboard

    Given I use the "<%= cb.proj2 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][0]["metadata"]["name"] | new-test-rc |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | new-test-pods |
      | ["items"][1]["spec"]["selector"]["name"] | new-test-pods |
      | ["items"][1]["metadata"]["name"] | new-test-service-2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-test-pods |
    And evaluation of `pod.ip` is stored in the :proj2p2 clipboard
    And evaluation of `pod.name` is stored in the :proj2p2name clipboard
    And evaluation of `service("new-test-service-2").ip(user: user)` is stored in the :proj2s2 clipboard

    Given I use the "<%= cb.proj3 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][0]["metadata"]["name"] | new-test-rc |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | new-test-pods |
      | ["items"][1]["spec"]["selector"]["name"] | new-test-pods |
      | ["items"][1]["metadata"]["name"] | new-test-service-3 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-test-pods |
    And evaluation of `pod.ip` is stored in the :proj3p2 clipboard
    And evaluation of `pod.name` is stored in the :proj3p2name clipboard
    And evaluation of `service("new-test-service-3").ip(user: user)` is stored in the :proj3s2 clipboard

    # Access the pod/svc on other projects from project 1
    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.proj1p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj2p2 %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj1p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj3s1 %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"
    # Access the pod/svc on other projects from project 2
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.proj2p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1s2 %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj2p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj3p2 %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"
    # Access the pod/svc on other projects from project 3
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.proj3p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj2s1 %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.proj3p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1p2 %>:8080 |
    Then the step should succeed
    And the output should contain "Hello"

  # @author bmeng@redhat.com
  # @case_id OCP-9647
  @admin
  Scenario: Isolate the network for the joined network projects
    Given the env is using multitenant network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :oadm_pod_network_join_projects admin command with:
      | project | <%= cb.proj1 %> |
      | to | <%= cb.proj2 %> |
    Then the step should succeed

    Given I use the "<%= cb.proj1 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :proj1p1name clipboard
    And evaluation of `service("test-service-1").ip(user: user)` is stored in the :proj1s1 clipboard

    Given I use the "<%= cb.proj2 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :proj2p1 clipboard
    And evaluation of `pod.name` is stored in the :proj2p1name clipboard

    When I execute on the "<%= cb.proj2p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1s1 %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"

    When I run the :oadm_pod_network_isolate_projects admin command with:
      | project | <%= cb.proj1 %> |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | netnamespace |
      | resource_name | <%= cb.proj1 %> |
      | template | {{.netid}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :proj1netid clipboard
    When I run the :get admin command with:
      | resource | netnamespace |
      | resource_name | <%= cb.proj2 %> |
      | template | {{.netid}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :proj2netid clipboard
    And the expression should be true> "<%= cb.proj1netid %>" != "<%= cb.proj2netid %>"

    Given I use the "<%= cb.proj1 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][0]["metadata"]["name"] | new-test-rc |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | new-test-pods |
      | ["items"][1]["spec"]["selector"]["name"] | new-test-pods |
      | ["items"][1]["metadata"]["name"] | new-test-service-1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-test-pods |
    And evaluation of `pod.ip` is stored in the :proj1p2 clipboard

    Given I use the "<%= cb.proj2 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][0]["metadata"]["name"] | new-test-rc |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | new-test-pods |
      | ["items"][1]["spec"]["selector"]["name"] | new-test-pods |
      | ["items"][1]["metadata"]["name"] | new-test-service-2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-test-pods |
    And evaluation of `pod.name` is stored in the :proj2p2name clipboard
    And evaluation of `service("new-test-service-2").ip(user: user)` is stored in the :proj2s2 clipboard

    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.proj1p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj2p1 %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj1p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj2s2 %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"

    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.proj2p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1p2 %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj2p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1s1 %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"

  # @author bmeng@redhat.com
  # @case_id OCP-9649
  @admin
  Scenario: Isolate the network for the joined network projects via selector
    Given the env is using multitenant network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard
    When I run the :oadm_pod_network_join_projects admin command with:
      | project | <%= cb.proj1 %> |
      | to | <%= cb.proj2 %> |
    Then the step should succeed

    Given I use the "<%= cb.proj1 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :proj1p1name clipboard
    And evaluation of `service("test-service-1").ip(user: user)` is stored in the :proj1s1 clipboard

    Given I use the "<%= cb.proj2 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :proj2p1 clipboard
    And evaluation of `pod.name` is stored in the :proj2p1name clipboard

    When I execute on the "<%= cb.proj2p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1s1 %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And I run the :label client command with:
      | resource | namespace |
      | name | <%= cb.proj1 %> |
      | key_val | ns=group1 |
    And I run the :label client command with:
      | resource | namespace |
      | name | <%= cb.proj2 %> |
      | key_val | ns=group2 |
    When I run the :oadm_pod_network_isolate_projects admin command with:
      | selector | ns=group2 |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | netnamespace |
      | resource_name | <%= cb.proj1 %> |
      | template | {{.netid}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :proj1netid clipboard
    When I run the :get admin command with:
      | resource | netnamespace |
      | resource_name | <%= cb.proj2 %> |
      | template | {{.netid}} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :proj2netid clipboard
    And the expression should be true> "<%= cb.proj1netid %>" != "<%= cb.proj2netid %>"

    Given I switch to the first user
    And I use the "<%= cb.proj1 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][0]["metadata"]["name"] | new-test-rc |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | new-test-pods |
      | ["items"][1]["spec"]["selector"]["name"] | new-test-pods |
      | ["items"][1]["metadata"]["name"] | new-test-service-1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-test-pods |
    And evaluation of `pod.ip` is stored in the :proj1p2 clipboard

    Given I use the "<%= cb.proj2 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][0]["metadata"]["name"] | new-test-rc |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | new-test-pods |
      | ["items"][1]["spec"]["selector"]["name"] | new-test-pods |
      | ["items"][1]["metadata"]["name"] | new-test-service-2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-test-pods |
    And evaluation of `pod.name` is stored in the :proj2p2name clipboard
    And evaluation of `service("new-test-service-2").ip(user: user)` is stored in the :proj2s2 clipboard

    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.proj1p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj2p1 %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj1p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj2s2 %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"

    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.proj2p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1p2 %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj2p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1s1 %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"

  # @author bmeng@redhat.com
  # @case_id OCP-9648
  @admin
  Scenario: Isolate the network for the project which already make network global via selector
    Given the env is using multitenant network
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    Given I create a new project
    And evaluation of `project.name` is stored in the :proj2 clipboard

    Given I switch to cluster admin pseudo user
    And I run the :label client command with:
      | resource | namespace |
      | name | <%= cb.proj1 %> |
      | key_val | ns=group1 |
    And I run the :label client command with:
      | resource | namespace |
      | name | <%= cb.proj2 %> |
      | key_val | ns=group2 |
    When I run the :oadm_pod_network_make_projects_global admin command with:
      | selector | ns=group2 |
    Then the step should succeed

    Given I switch to the first user
    Given I use the "<%= cb.proj1 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.name` is stored in the :proj1p1name clipboard
    And evaluation of `service("test-service-1").ip(user: user)` is stored in the :proj1s1 clipboard

    Given I use the "<%= cb.proj2 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :proj2p1 clipboard
    And evaluation of `pod.name` is stored in the :proj2p1name clipboard

    When I execute on the "<%= cb.proj2p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1s1 %>:27017 |
    Then the step should succeed
    And the output should contain "Hello"

    When I run the :oadm_pod_network_isolate_projects admin command with:
      | selector | ns=group2 |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | netnamespace |
      | resource_name | <%= cb.proj2 %> |
      | template | {{.netid}} |
    Then the step should succeed
    And the expression should be true> @result[:response] != 0

    Given I use the "<%= cb.proj1 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][0]["metadata"]["name"] | new-test-rc |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | new-test-pods |
      | ["items"][1]["spec"]["selector"]["name"] | new-test-pods |
      | ["items"][1]["metadata"]["name"] | new-test-service-1 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-test-pods |
    And evaluation of `pod.ip` is stored in the :proj1p2 clipboard

    Given I use the "<%= cb.proj2 %>" project
    When I run oc create over "<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/networking/list_for_pods.json" replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][0]["metadata"]["name"] | new-test-rc |
      | ["items"][0]["spec"]["template"]["metadata"]["labels"]["name"] | new-test-pods |
      | ["items"][1]["spec"]["selector"]["name"] | new-test-pods |
      | ["items"][1]["metadata"]["name"] | new-test-service-2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=new-test-pods |
    And evaluation of `pod.name` is stored in the :proj2p2name clipboard
    And evaluation of `service("new-test-service-2").ip(user: user)` is stored in the :proj2s2 clipboard

    Given I use the "<%= cb.proj1 %>" project
    When I execute on the "<%= cb.proj1p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj2p1 %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj1p1name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj2s2 %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.proj2p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1s1 %>:27017 |
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj2p2name %>" pod:
      | curl | --connect-timeout | 5 | <%= cb.proj1p2 %>:8080 |
    Then the step should fail
    And the output should not contain "Hello"


  # @author bmeng@redhat.com
  # @case_id OCP-19809
  @admin
  Scenario: Do not allow default namespace to be isolated
    Given the env is using multitenant network
    And the master version >= "3.9"

    Given I switch to cluster admin pseudo user
    When I run the :oadm_pod_network_isolate_projects admin command with:
      | project | default |
    Then the step should fail
    And the output should contain "forbidden"

    When I run the :get admin command with:
      | resource | netnamespace |
      | resource_name | default |
    Then the step should succeed
    And the output should contain "0"
