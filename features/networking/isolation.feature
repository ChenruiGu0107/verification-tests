Feature: networking isolation related scenarios
  # @author bmeng@redhat.com
  # @case_id 497542
  @smoke
  @admin
  Scenario: The pods in default namespace can communicate with all the other pods
    Given I have a project
    And evaluation of `project.name` is stored in the :u1p1 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json |
      | n | <%= cb.u1p1 %> |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    Then evaluation of `pod.ip` is stored in the :pod1_ip clipboard

    Given I create a new project
    And evaluation of `project.name` is stored in the :u1p2 clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json |
      | n | <%= cb.u1p2 %> |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    Then evaluation of `pod.ip` is stored in the :pod2_ip clipboard

    Given I switch to cluster admin pseudo user
    And I use the "default" project
    And evaluation of `rand_str(5, :dns)` is stored in the :default_name clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json" URL replacing paths:
      # | ["spec"]["containers"][0]["name"] | <%= cb.default_name %> |
      | ["metadata"]["name"]              | <%= cb.default_name %> |
    Then the step should succeed
    And I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type | pod |
      | object_name_or_id | <%= cb.default_name %> |
    the step should succeed
    """
    Given the pod named "<%= cb.default_name %>" becomes ready
    Given evaluation of `pod.ip` is stored in the :default_ip clipboard

    When I execute on the "<%= cb.default_name %>" pod:
      | /usr/bin/curl | <%= cb.pod1_ip %>:8080 |
    Then the output should contain "Hello OpenShift!"
    When I execute on the "<%= cb.default_name %>" pod:
      | /usr/bin/curl | <%= cb.pod2_ip %>:8080 |
    Then the output should contain "Hello OpenShift!"
    Given I switch to the first user
    And I use the "<%= cb.u1p1 %>" project
    When I execute on the "hello-pod" pod:
      | /usr/bin/curl | <%= cb.default_ip %>:8080 |
    Then the output should contain "Hello OpenShift!"
    Given I use the "<%= cb.u1p2 %>" project
    When I execute on the "hello-pod" pod:
      | /usr/bin/curl | <%= cb.default_ip %>:8080 |
    Then the output should contain "Hello OpenShift!"


  # @author bmeng@redhat.com
  # @case_id 497541
  @smoke
  Scenario: Only the pods nested in a same namespace can communicate with each other
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
      | n | <%= project(0).name %> |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `@pods[0].ip` is stored in the :pr1ip0 clipboard
    And evaluation of `@pods[1].ip` is stored in the :pr1ip1 clipboard
    And evaluation of `@pods[0].name` is stored in the :pr1pod0 clipboard

    Given I create a new project
    And I use the "<%= project(1).name %>" project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json |
      | n | <%= project(1).name %> |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=test-pods |
    And evaluation of `@pods[2].ip` is stored in the :pr2ip0 clipboard
    And evaluation of `@pods[3].ip` is stored in the :pr2ip1 clipboard

    Given I use the "<%= project(0).name %>" project
    When I execute on the "<%= cb.pr1pod0 %>" pod:
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.pr1ip1 %>:8080|
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.pr1pod0 %>" pod:
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.pr2ip1 %>:8080|
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.pr1pod0 %>" pod:
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.pr2ip0 %>:8080|
    Then the step should fail
    And the output should not contain "Hello"


  # @author bmeng@redhat.com
  # @case_id 508109
  @admin
  Scenario: Make the network of given project be accessible to other projects
    # Create 3 projects and each contains 1 pod and 1 service
    Given I have a project
    And evaluation of `project.name` is stored in the :proj1 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" URL replacing paths:
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
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" URL replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-2 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :proj2p1 clipboard
    And evaluation of `service("test-service-2").ip(user: user)` is stored in the :proj2s1 clipboard

    Given I create a new project
    And evaluation of `project.name` is stored in the :proj3 clipboard
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" URL replacing paths:
      | ["items"][0]["spec"]["replicas"] | 1 |
      | ["items"][1]["metadata"]["name"] | test-service-3 |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | name=test-pods |
    And evaluation of `pod.ip` is stored in the :proj3p1 clipboard
    And evaluation of `service("test-service-3").ip(user: user)` is stored in the :proj3s1 clipboard

    # Merge the network of project 1 and 2, and check the netid
    When I run the :oadm_pod_network_join_projects admin command with:
      | project | <%= cb.proj1 %> |
      | to | <%= cb.proj2 %> |
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
    And the output should equal "<%= cb.proj1netid %>"

    # Create another new pod and service in each project
    Given I use the "<%= cb.proj1 %>" project
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" URL replacing paths:
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
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" URL replacing paths:
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
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/list_for_pods.json" URL replacing paths:
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
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.proj2p2 %>:8080|
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.proj1p1name %>" pod:
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.proj3p1 %>:8080|
    Then the step should fail
    And the output should not contain "Hello"
    
    When I execute on the "<%= cb.proj1p1name %>" pod:
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.proj2s1 %>:27017|
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.proj1p1name %>" pod:
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.proj3s2 %>:27017|
    Then the step should fail
    And the output should not contain "Hello"

    # Access the pod/svc on other projects from project 2
    Given I use the "<%= cb.proj2 %>" project
    When I execute on the "<%= cb.proj2p2name %>" pod:
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.proj1p1 %>:8080|
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.proj2p2name %>" pod:
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.proj3p2 %>:8080|
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj2p2name %>" pod:
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.proj1s2 %>:27017|
    Then the step should succeed
    And the output should contain "Hello"
    When I execute on the "<%= cb.proj2p2name %>" pod:
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.proj3s1 %>:27017|
    Then the step should fail
    And the output should not contain "Hello"

    # Access the pod/svc on other projects from project 3
    Given I use the "<%= cb.proj3 %>" project
    When I execute on the "<%= cb.proj3p2name %>" pod:
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.proj1p2 %>:8080|
    Then the step should fail
    And the output should not contain "Hello"
    When I execute on the "<%= cb.proj3p2name %>" pod:
      |bash|
      |-c|
      |curl --connect-timeout 5 <%= cb.proj2s1 %>:27017|
    Then the step should fail
    And the output should not contain "Hello"
