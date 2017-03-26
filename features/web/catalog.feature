Feature: scenarios related to catalog page

  # @author chali@redhat.com
  # @case_id OCP-11675
  Scenario: Don't show hidden image stream tags in the catalog
    Given the master version >= "3.5"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-centos7.json |
    Then the step should succeed
    And I wait up to 10 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | istag |
    Then the output should contain:
      | ruby:2.2 |
    """
    When I run the :patch client command with:
      | resource      | istag                                                       |
      | resource_name | ruby:2.2                                                    |
      | p             | {"metadata":{"annotations":{"tags":"hidden,builder,ruby"}}} |
    Then the step should succeed
    When I perform the :goto_overview_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed
    When I run the :click_add_to_project web console action
    Then the step should succeed
    When I perform the :select_category_in_catalog web console action with:
      | category | Ruby |
    Then the step should succeed
    When I perform the :select_card_version_in_catalog web console action with:
      | card_name | Ruby                |
      | namespace | <%= project.name %> |
      | version   | latest              |
    Then the step should succeed
    When I perform the :check_card_version_missing_in_catalog web console action with:
      | card_name | Ruby                |
      | namespace | <%= project.name %> |
      | version   | 2.2                 |
    Then the step should succeed
