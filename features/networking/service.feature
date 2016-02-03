Feature: Service related networking scenarios 
  # @author bmeng@redhat.com
  # @case_id 508796
  Scenario: Linking external services to OpenShift multitenant
    Given I have a project
    When I run the :create client command with:
       | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service.json |
    Then the step should succeed
    Given I use the "external-http" service
    And evaluation of `service.ip(user: user)` is stored in the :service_ip clipboard
    When I run the :get client command with:
       | resource      | endpoints  |
       | resource_name | external-http |
    Then the output should contain "61.135.218.25:80"
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json | 
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    When I execute on the "hello-pod" pod:
        | /usr/bin/curl | <%= cb.service_ip %>:10086 |
    Then the output should contain "www.youdao.com"


  # @author bmeng@redhat.com
  # @case_id 508149
  Scenario: The packets should be dropped when accessing the service which points to a pod in another project
    ## Create pod in project1 and copy the pod ip
    Given I have a project
    And evaluation of `project.name` is stored in the :project1 clipboard
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    And evaluation of `pod.ip` is stored in the :pod1_ip clipboard

    ## Create pod in project2
    Given I create a new project
    And evaluation of `project.name` is stored in the :project2 clipboard
    And I use the "<%= cb.project2 %>" project
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json | 
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready

    ## Create selector less service in project2 which point to the pod in project1
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service_to_external_pod.json" URL replacing paths:
        | ["items"][1]["subsets"][0]["addresses"][0]["ip"] | <%= cb.pod1_ip %> |
    Then the step should succeed
    Given I use the "selector-less-service" service
    And evaluation of `service.ip(user: user)` is stored in the :service2_ip clipboard

    ## Access the above service from the pod in project2
    When I execute on the "hello-pod" pod:
         | /usr/bin/curl | --connect-timeout | 4 | <%= cb.service2_ip %>:10086 |
    Then the step should fail
    And the output should not contain "Hello OpenShift!"


  # @author bmeng@redhat.com
  # @case_id 508150
  Scenario: The packets should be dropped when accessing the service which points to a service in another project
    ## Create pod and service in project1 and copy the service ip
    Given I have a project
    And evaluation of `project.name` is stored in the :project1 clipboard
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
    Then the step should succeed
    Given all pods in the project are ready
    Given I use the "test-service" service
    And evaluation of `service.ip(user: user)` is stored in the :service1_ip clipboard

    ## Create pod in project2
    Given I create a new project
    And evaluation of `project.name` is stored in the :project2 clipboard
    And I use the "<%= cb.project2 %>" project
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json | 
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready

    ## Create selector less service in project2 which point to the service in project1
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/external_service_to_external_service.json" URL replacing paths:
        | ["items"][1]["subsets"][0]["addresses"][0]["ip"] | <%= cb.service1_ip %> |
    Then the step should succeed
    Given I use the "selector-less-service" service
    And evaluation of `service.ip(user: user)` is stored in the :service2_ip clipboard

    ## Access the above service from the pod in project2
    When I execute on the "hello-pod" pod:
         | /usr/bin/curl | --connect-timeout | 4 | <%= cb.service2_ip %>:10086 |
    Then the step should fail
    And the output should not contain "Hello OpenShift!"
   
  # @author zzhao@redhat.com
  # @case_id 517641
  @admin
  Scenario: Be able to access the service via the nodeport
    Given I have a project
    And evaluation of `project.name` is stored in the :project1 clipboard
    When I run the :create client command with:
        | f |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/nodeport_service.json |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    When I get project node as JSON
    And evaluation of `@result[:parsed]['items'][0]['metadata']['name']` is stored in the :node1 clipboard
    When I open web server via the "<%= cb.node1 %>:30000" url
    Then the output should contain "Hello OpenShift!"

    When I use the "<%= cb.project1 %>" project
    And I run the :delete client command with:
      | object_type | service |
      | object_name_or_id | hello-pod |
    Then I wait for the resource "service" named "hello-pod" to disappear
    Then I wait up to 20 seconds for the steps to pass:
    """
    When I open web server via the "<%= cb.node1 %>:30000" url
    Then the step should fail
    """
