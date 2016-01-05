Feature: networking isolation related scenarios
  # @author bmeng@redhat.com                                                                                                                                      
  # @case_id 497542
  @smoke
  @admin
  Scenario: The pods in default namespace can communicate with all the other pods
    Given I create a project via client with:
        | name | u1p1 |
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json | 
        | n | u1p1 |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    When I run the :get client command with:
        | resource | pod |
        | o | yaml |
        | n | u1p1 |
    Then the step should succeed
    And the output is parsed as YAML
    Given evaluation of `@result[:parsed]['items'][0]['status']['podIP']` is stored in the :pod1_ip clipboard
    Given I create a project via client with:
        | name | u1p2 |
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json | 
        | n | u1p2 |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    When I run the :get client command with:
        | resource | pod |
        | o | yaml |
        | n | u1p2 |
    Then the step should succeed
    And the output is parsed as YAML
    Given evaluation of `@result[:parsed]['items'][0]['status']['podIP']` is stored in the :pod2_ip clipboard
    Given I switch to cluster admin pseudo user
    And I use the "default" project
    When I run the :create client command with:
        | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/networking/pod-for-ping.json |
    Then the step should succeed
    Given the pod named "hello-pod" becomes ready
    When I run the :get client command with:
        | resource | pod |
        | resource_name | hello-pod | 
        | o | yaml |
        | n | default |
    Then the step should succeed
    And the output is parsed as YAML
    Given evaluation of `@result[:parsed]['status']['podIP']` is stored in the :default_ip clipboard
    When I execute on the "hello-pod" pod:
        | /usr/bin/curl | <%= cb.pod1_ip %>:8080 |
    Then the output should contain "Hello OpenShift!"
    When I execute on the "hello-pod" pod:
        | /usr/bin/curl | <%= cb.pod2_ip %>:8080 |
    Then the output should contain "Hello OpenShift!"
    Given I switch to the first user
    And I use the "u1p1" project
    When I execute on the "hello-pod" pod:
        | /usr/bin/curl | <%= cb.default_ip %>:8080 |
    Then the output should contain "Hello OpenShift!"
    Given I use the "u1p2" project
    When I execute on the "hello-pod" pod:
        | /usr/bin/curl | <%= cb.default_ip %>:8080 |
    Then the output should contain "Hello OpenShift!"
    Given I run the :delete admin command with:
        | object_type | pod |
        | object_name_or_id | hello-pod |
