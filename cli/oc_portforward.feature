Feature: oc_portforward.feature

  # @author cryan@redhat.com
  # @case_id OCP-11884
  Scenario: Forwarding a pod that isn't running
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/hello-pod-bad.json |
    Given the pod named "hello-openshift" status becomes :pending
    When I run the :port_forward client command with:
      | pod | hello-openshift |
      | port_spec | :8080 |
    Then the step should fail
    And the output should match "[Uu]nable.+because pod is not running. Current status=Pending"

  # @author cryan@redhat.com
  Scenario Outline: Forwarding local port to a pod
    Given I have a project
    When I run the :create client command with:
      | _tool    | <tool>   |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    When I run the :get client command with:
      | _tool    | <tool>   |
      | resource | pod |
    Then the output should contain "Running"
    When I run the :port_forward client command with:
      | _tool    | <tool>   |
      | pod | hello-openshift   |
      | port_spec | 5000:8080   |
      | _timeout | 10           |
    Then the step should have timed out
    And the output should match "Forwarding from 127.0.0.1:5000 -> 8080"
    When I run the :port_forward client command with:
      | _tool    | <tool>   |
      | pod | hello-openshift  |
      | port_spec | :8080      |
      | _timeout | 10          |
    Then the step should have timed out
    And the output should match "Forwarding from 127.0.0.1:\d+ -> 8080"
    When I run the :port_forward client command with:
      | _tool    | <tool>   |
      | pod | hello-openshift  |
      | port_spec | 8000:8080  |
      | _timeout | 10          |
    Then the step should have timed out
    And the output should match "Forwarding from 127.0.0.1:8000 -> 8080"

    Examples:
      | tool     |
      | oc       | # @case_id OCP-12023
      | kubectl  | # @case_id OCP-21010

  # @author pruan@redhat.com
  # @case_id OCP-11533
  Scenario: Forwarding local port to a non-existing port in a pod
    Given I have a project
    And evaluation of `rand(5000..7999)` is stored in the :porta clipboard
    And I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/pods/pod_with_two_containers.json |
    Given the pod named "doublecontainers" status becomes :running
    And I run the :port_forward background client command with:
      | pod       | doublecontainers        |
      | port_spec | <%= cb[:porta] %>:58087 |
      | _timeout  | 20                      |
    Then the step should succeed
    And I perform the HTTP request:
    """
      :url: 127.0.0.1:<%= cb[:porta] %>
      :method: :get
    """
    Then the step should fail

  # @author xxia@redhat.com
  # @case_id OCP-12387
  Scenario: Check race condition in port forward connection handling logic
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    And evaluation of `rand(5000..7999)` is stored in the :port clipboard
    And I run the :port_forward background client command with:
      | pod       | hello-openshift        |
      | port_spec | <%= cb[:port] %>:8080  |
      | _timeout  | 100                    |
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I open web server via the "http://127.0.0.1:<%= cb[:port] %>" url
    Then the step should succeed
    And the output should contain:
      | Hello OpenShift |
    """
    When I perform 100 HTTP GET requests with concurrency 25 to: http://127.0.0.1:<%= cb[:port] %>/
    Then the step should succeed

