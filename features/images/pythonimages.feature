Feature: Openshift build and configuration of enviroment variables check

  # @author wewang@redhat.com
  # @case_id 500963
  Scenario: Application with python-34-rhel7 base images lifecycle
    Given I have a project
    When I run the :new_app client command with:
      | file |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/python-34-rhel7-stibuild.json |
    Then the step should succeed
    Given I wait for the "frontend" service to become ready
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain:
      | OpenShift |
