Feature: senarios for checking transfer scheme
  # @author pruan@redhat.com
  # @case_id OCP-10933
  Scenario: Check if client use protobuf data transfer scheme to communicate with master
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/pods/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" becomes ready
    When I run the :get client command with:
      | resource | pods |
      | loglevel | 8    |
    Then the step should succeed
    And the output should not contain:
      | protobuf |

