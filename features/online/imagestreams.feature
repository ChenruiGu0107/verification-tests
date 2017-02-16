Feature: ONLY ONLINE Imagestreams related scripts in this file

  # @author etrott@redhat.com
  # @case_id 533084
  # @case_id OCP-10165
  Scenario Outline: Imagestream should not be tagged with 'builder'
    When I create a new project via web
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain:
      | <is> |
    When I run the :get client command with:
      | resource      | is        |
      | resource_name | <is>      |
      | n             | openshift |
      | o             | json      |
    Then the step should succeed
    And the output should not contain "builder"
    Examples:
      | is                     |
      | jboss-eap70-openshift  |
      | redhat-sso70-openshift |
