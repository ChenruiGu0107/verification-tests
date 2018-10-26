Feature: oc_delete.feature

  # @author cryan@redhat.com
  # @case_id OCP-12280
  Scenario: Delete resources with multiple approach via cli
    Given I have a project
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json"
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | pods,services                          |
      | l           | template=application-template-stibuild |
    Then the step should succeed
    Given I get project services
    Then the output should not contain:
      | database |
      | frontend |
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/release-1.4/examples/jenkins/master-slave/jenkins-master-template.json"
    Given I download a file from "https://raw.githubusercontent.com/openshift/origin/release-1.4/examples/jenkins/master-slave/jenkins-slave-template.json"
    When I run the :create client command with:
      | f | . |
    Then the step should succeed
    And the output should match:
      | jenkins-maste.*created         |
      | jenkins-slave-builder.*created |
    When I run the :delete client command with:
      | f | . |
    Then the step should succeed
    And the output should match:
      | jenkins-master.*deleted        |
      | jenkins-slave-builder.*deleted |
    When I run the :create client command with:
      | f | . |
    Then the step should succeed
    And the output should match:
      | jenkins-master.*created        |
      | jenkins-slave-builder.*created |
    When I run the :delete client command with:
      | f | jenkins-master-template.json |
      | f | jenkins-slave-template.json  |
    Then the step should succeed
    And the output should match:
      | jenkins-master.*deleted        |
      | jenkins-slave-builder.*deleted |
