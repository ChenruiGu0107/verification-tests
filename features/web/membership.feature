Feature: memberships related features via web

# @author etrott@redhat.com
# @case_id OCP-11651
Scenario: Manage project membership about groups
  Given the master version >= "3.4"
  When I create a new project via web
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Groups              |
    | count        | 0                   |
  Then the step should succeed
  When I perform the :add_role_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Groups              |
    | name         | test_group          |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_entry_content_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Groups              |
    | name         | test_group          |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Groups              |
    | count        | 1                   |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
    | resource_name | basic-user  |
  Then the output should contain:
    | test_group |
  When I perform the :delete_role_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Groups              |
    | name         | test_group          |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Groups              |
    | count        | 0                   |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
    | resource_name | basic-user  |
  Then the output should not contain:
    | test_group |

  When I perform the :check_entry_content_on_membership web console action with:
    | project_name | <%= project.name %>                        |
    | tab_name     | System Groups                              |
    | name         | system:serviceaccounts:<%= project.name %> |
    | role         | system:image-puller                        |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | System Groups       |
    | count        | 1                   |
  Then the step should succeed
  When I perform the :add_role_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | System Groups       |
    | name         | test_group          |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | System Groups       |
    | count        | 2                   |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
    | resource_name | basic-user  |
  Then the output should contain:
    | system:test_group |
  When I perform the :delete_role_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | System Groups       |
    | name         | system:test_group   |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | System Groups       |
    | count        | 1                   |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
    | resource_name | basic-user  |
  Then the output should not contain:
    | system:test_group |

# @author etrott@redhat.com
# @case_id OCP-11843
Scenario: Manage project membership about users
  Given the master version >= "3.4"
  When I create a new project via web
  Then the step should succeed

  When I perform the :check_entry_content_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Users               |
    | name         | <%= user.name %>    |
    | role         | admin               |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Users               |
    | count        | 1                   |
  Then the step should succeed
  When I perform the :add_role_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Users               |
    | name         | test_user           |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_entry_content_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Users               |
    | name         | test_user           |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Users               |
    | count        | 2                   |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
    | resource_name | basic-user  |
  Then the output should contain:
    | test_user |
  When I perform the :delete_role_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Users               |
    | name         | test_user           |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Users               |
    | count        | 1                   |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
    | resource_name | basic-user  |
  Then the output should not contain:
    | test_user |

  When I perform the :check_entry_content_on_membership_with_namespace web console action with:
    | project_name | <%= project.name %>  |
    | tab_name     | Service Accounts     |
    | namespace    | <%= project.name %>  |
    | name         | builder              |
    | role         | system:image-builder |
  Then the step should succeed
  When I perform the :check_entry_content_on_membership_with_namespace web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Service Accounts    |
    | namespace    | <%= project.name %> |
    | name         | deployer            |
    | role         | system:deployer     |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Service Accounts    |
    | count        | 2                   |
  Then the step should succeed
  When I perform the :add_role_on_membership_with_namespace web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Service Accounts    |
    | namespace    | <%= project.name %> |
    | name         | test.sa             |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_entry_content_on_membership_with_namespace web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Service Accounts    |
    | namespace    | <%= project.name %> |
    | name         | test.sa             |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Service Accounts    |
    | count        | 3                   |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
    | resource_name | basic-user  |
  Then the output should contain:
    | test.sa |
  When I perform the :delete_role_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Service Accounts    |
    | namespace    | <%= project.name %> |
    | name         | test.sa             |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Service Accounts    |
    | count        | 2                   |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
    | resource_name | basic-user  |
  Then the output should not contain:
    | test.sa |

  When I perform the :add_role_on_membership_with_typed_namespace web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Service Accounts    |
    | namespace    | default             |
    | name         | test.sa             |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_entry_content_on_membership_with_namespace web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Service Accounts    |
    | namespace    | default             |
    | name         | test.sa             |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Service Accounts    |
    | count        | 3                   |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
    | resource_name | basic-user  |
  Then the output should contain:
    | test.sa |
  When I perform the :delete_role_on_membership_with_namespace web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Service Accounts    |
    | namespace    | default             |
    | name         | test.sa             |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Service Accounts    |
    | count        | 2                   |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
    | resource_name | basic-user  |
  Then the output should not contain:
    | test.sa |

  When I perform the :add_role_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | System Users        |
    | name         | test_user           |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | System Users        |
    | count        | 1                   |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
    | resource_name | basic-user  |
  Then the output should contain:
    | system:test_user |
  When I perform the :delete_role_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | System Users        |
    | name         | system:test_user    |
    | role         | basic-user          |
  Then the step should succeed
  When I perform the :check_tab_count_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | System Users        |
    | count        | 0                   |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
    | resource_name | basic-user  |
  Then the output should not contain:
    | system:test_user |

# @author etrott@redhat.com
# @case_id OCP-12099
Scenario: Check rolebinding duplication when editing membership
  Given the master version >= "3.4"
  Given I have a project
  When I run the :policy_add_role_to_user client command with:
    | role            |   view                |
    | user name       |   star                |
    | n               |   <%= project.name %> |
  Then the step should succeed
  And I run the :export client command with:
    | resource      | rolebinding |
    | name          | view        |
  Then the step should succeed
  And I save the output to file> rolebinding_view.yaml
  When I run oc create over "rolebinding_view.yaml" replacing paths:
    | ["metadata"]["name"] | view2nd |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
  Then the output should contain:
    | view2nd |
  When I perform the :check_entry_content_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Users               |
    | name         | star                |
    | role         | view                |
  Then the step should succeed
  When I perform the :check_entry_content_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Users               |
    | name         | star                |
    | role         | view2nd             |
  Then the step should fail

  When I perform the :add_role_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Users               |
    | name         | bob           |
    | role         | view          |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
  Then the output should contain:
    | bob |
  When I perform the :add_role_on_membership web console action with:
    | project_name | <%= project.name %> |
    | tab_name     | Users               |
    | name         | bob           |
    | role         | view          |
  Then the step should succeed
  When I perform the :check_error_message_on_membership web console action with:
    | name | bob  |
    | role | view |
  Then the step should succeed
  And I run the :get client command with:
    | resource      | rolebinding |
  Then the output should not contain 2 times:
    | bob |
