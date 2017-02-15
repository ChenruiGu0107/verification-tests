Feature: ONLY ONLINE Storage related scripts in this file

  # @author bingli@redhat.com
  # @case_id OCP-9967
  Scenario: Delete pod with mounting error
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/tc526564/pod_volumetest.json |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pod |
    Then the output should match:
      | volumetest\\s+0/1\\s+RunContainerError.+ |
    """
    When I run the :describe client command with:
      | resource | pod        |
      | name     | volumetest |
    Then the step should succeed
    And the output should contain:
      | mkdir /var/lib/docker/volumes/ |
      | permission denied              |
    When I run the :delete client command with:
      | object_type       | pod        |
      | object_name_or_id | volumetest |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource | pod |
    Then the output should not contain:
      | volumetest |
    """
