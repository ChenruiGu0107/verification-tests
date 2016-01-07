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
