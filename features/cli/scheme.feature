Feature: senarios for checking transfer scheme
  # @author pruan@redhat.com
  # @case_id 533623
  Scenario: Check if client use protobuf data transfer scheme to communicate with master
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    When I run the :get client command with:
      | resource | pods |
      | loglevel | 8    |
    Then the step should succeed
    And the output should not contain:
      | protobuf |

