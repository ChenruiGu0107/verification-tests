Feature: oc logs related features
  # @author wzheng@redhat.com
  Scenario Outline: Get buildlogs with invalid parameters
    Given I have a project
    When I run the :logs client command with:
      | resource_name | 123 |
    Then the step should fail
    And the output should contain "pods "123" not found"
    When I run the :logs client command with:
      | resource_name |   |
    Then the step should fail
    And the output should contain "<warning>"

    Examples:
      | warning                                                        |
      | You must provide one or more resources by argument or filename | # @case_id OCP-17383

  # @author xxia@redhat.com
  Scenario Outline: oc logs for a resource with miscellaneous options
    Given I have a project
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    When I create a new application with:
      | file | application-template-stibuild-without-customize-route.json |
    Given I obtain test data file "pods/pod_with_two_containers.json"
    When I run the :create client command with:
      | f    | pod_with_two_containers.json |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed

    Given the pod named "doublecontainers" becomes ready
    When I run the :logs client command with:
      | _tool            | <tool>               |
      | resource_name    | pod/doublecontainers |
      | c                | hello-openshift      |
    Then the step should succeed
    When I run the :logs client command with:
      | _tool            | <tool>               |
      | resource_name    | pod/doublecontainers |
      | c                | no-this              |
    Then the step should fail

    Given the pod named "hello-openshift" becomes ready
    When I run the :logs client command with:
      | _tool            | <tool>               |
      | resource_name    | pod/hello-openshift  |
      | limit-bytes      | 5                    |
    Then the step should succeed
    And the expression should be true> @result[:response].length == 5

    # Waiting ensures we could see logs in case the pod has not printed logs yet.
    Given I wait for the steps to pass:
    """
    When I run the :logs client command with:
      | _tool            | <tool>               |
      | resource_name    | pod/hello-openshift  |
      | timestamps       |                      |
      | since            | 3h                   |
    Then the step should succeed
    And the output should match:
      | T[0-9:.]+ |
    And evaluation of `@result[:response]` is stored in the :logs clipboard
    """
    And 2 seconds have passed
    # Once met cucumber ran fast: previous `oc logs` printed "2016-03-07T06:18:33...Z serving on 8080", and following `oc logs` was run at "[06:18:34] INFO> Shell Commands" and printed the same logs
    # Thus, "2 seconds have passed" could make scripts robuster
    When I run the :logs client command with:
      | _tool            | <tool>               |
      | resource_name    | pod/hello-openshift  |
      | timestamps       |                      |
      | since            | 1s                   |
    Then the step should succeed
    # Only logs newer than given time will be shown
    And the output should not contain "<%= cb.logs %>"
    When I run the :logs client command with:
      | _tool            | <tool>               |
      | resource_name    | pod/hello-openshift  |
      | timestamps       |                      |
      | since-time       | 2000-01-01T00:00:00Z |
    Then the step should succeed
    And the output should match:
      | T[0-9:.]+ |

    # Only one of "--since" and "--since-time" can be used
    When I run the :logs client command with:
      | _tool            | <tool>               |
      | resource_name    | pod/hello-openshift  |
      | since            | 2m                   |
      | since-time       | 2000-01-01T00:00:00Z |
    Then the step should fail

    Given the "ruby-sample-build-1" build finished
    When I run the :logs client command with:
      | resource_name    | bc/ruby-sample-build |
      | version          | 1                    |
    Then the step should succeed
    When I run the :logs client command with:
      | resource_name    | bc/ruby-sample-build |
      | version          | 5                    |
    Then the step should fail
    And the output should contain:
      | not found |

    When I run the :logs client command with:
      | _tool            | <tool>               |
      | resource_name    | pod/hello-openshift  |
      | since-time       | #@234                |
    Then the step should fail

    Examples:
      | tool     |
      | oc       | # @case_id OCP-10740
      | kubectl  | # @case_id OCP-21116
