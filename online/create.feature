Feature: ONLY ONLINE Create related feature's scripts in this file

  # @author etrott@redhat.com
  Scenario Outline: Create resource from imagestream via oc new-app
    Given I have a project
    Then I run the :new_app client command with:
      | name         | resource-sample |
      | image_stream | <is>            |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=resource-sample-1 |
    When I expose the "resource-sample" service
    Then the step should succeed
    And I wait for a web server to become available via the route
    Examples:
      | is                               |
      | openshift/jboss-eap70-openshift  | # @case_id OCP-10149
      | openshift/redhat-sso70-openshift | # @case_id OCP-10179

  # @author etrott@redhat.com
  Scenario Outline: Create applications with persistent storage using pre-installed templates
    Given I have a project
    Then I run the :new_app client command with:
      | template | <template> |
    Then the step should succeed
    And all pods in the project are ready
    Then the step should succeed
    And I wait for the "<service_name>" service to become ready
    Then I wait for a web server to become available via the "<service_name>" route
    And I wait for the "secure-<service_name>" service to become ready
    Then I wait for a secure web server to become available via the "secure-<service_name>" route
    Examples:
      | template                   | service_name |
      | eap70-mysql-persistent-s2i | eap-app      | # @case_id OCP-10150
      | sso70-mysql-persistent     | sso          | # @case_id OCP-10180
