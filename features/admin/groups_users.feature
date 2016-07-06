Feature: groups and users related features

  # @author xiaocwan@redhat.com
  # @case_id 498661
  @admin
  Scenario: Add/remove user to/from the group
    When I run the :oadm_groups_new admin command with:
      | group_name | <%= project.name %>group |
    Then the step should succeed
    And I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | group                     |
      | object_name_or_id | <%= project.name %>group  |
    the step should succeed
    I run the :get admin command with:
      | resource      | group |
    the step should succeed
    the output should not match:
      | <%= project.name %>group |
    """
    When I run the :oadm_groups_add_users admin command with:
      | group_name | <%= project.name %>group |
      | user_name  | <%= project.name %>user1 |
      | user_name  | <%= project.name %>user2 |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | group |
    Then the step should succeed
    And the output should match:
      | <%= project.name %>group |
      | <%= project.name %>user1 |
      | <%= project.name %>user2 |
    When I run the :oadm_groups_remove_users admin command with:
      | group_name   | <%= project.name %>group |
      | user_name    | <%= project.name %>user2 |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | group                    |
    Then the output should match:
      | <%= project.name %>user1 |
    And the output should not match:
      | <%= project.name %>user2 |

  # @author xiaocwan@redhat.com
  # @case_id 498664
  @admin
  Scenario: Create/Edit/delete the cluster group
    When I run the :oadm_groups_new admin command with:
      | group_name | <%= project.name %>group |
    Then the step should succeed
    And I register clean-up steps:
    """
    I run the :delete admin command with:
      | object_type       | group                     |
      | object_name_or_id | <%= project.name %>group  |
    the step should succeed
    I run the :get admin command with:
      | resource      | group |
    the step should succeed
    the output should not match:
      | <%= project.name %>group |
    """
    When I run the :oadm_groups_add_users admin command with:
      | group_name | <%= project.name %>group |
      | user_name  | <%= project.name %>user1 |
    Then the step should succeed

    # get group to file, edit and replace it, check by describe
    When I run the :get admin command with:
      | resource      | group |
      | resource_name | <%= project.name %>group |
      | o             | yaml  |
    Then the step should succeed
    And I save the output to file>group.yaml
    Given I delete matching lines from "group.yaml":
      | <%= project.name %>user1 |
    When I run the :replace admin command with:
      | f             | group.yaml  |
    Then the step should succeed
    And the output should match:
      | [Rr]eplaced   |
    When I run the :describe admin command with:
      | resource | group                   |
      | name     | <%= project.name %>group |
    Then the step should succeed
    And the output should not match:
      | <%= project.name %>user1 |
    
  # @author xiaocwan@redhat.com
  # @case_id 498662
  @admin
  Scenario: Add/remove view role to the project group in one or all projects
    Given admin creates a project
    Then evaluation of `project.name` is stored in the :project1 clipboard
    Given admin creates a project
    Then evaluation of `project.name` is stored in the :project2 clipboard    
    
    When I run the :oadm_groups_new admin command with:
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
    Then the step should succeed
    Given admin ensures "<%= cb.project1 %>-<%= cb.project2 %>-group" group is deleted after scenario
    When I run the :oadm_groups_add_users admin command with:
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | user_name  | <%= user(0, switch: false).name %>          |
    Then the step should succeed

    When I run the :policy_add_role_to_group admin command with:
      | role       | view                                        |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project1 %>                          |
    Then the step should succeed
    When I switch to the first user 
    And I run the :get client command with:
      | resource | project |
    Then the step should succeed
    Then the output should contain:
      | <%= cb.project1 %> |
    And the output should not contain:
      | <%= cb.project2 %> |
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | n    | <%= cb.project1 %> |
    Then the step should fail
    And the output should match:
      |cannot create .* in project.*<%= cb.project1 %> |
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project1 %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project2 %> |
    Then the step should fail
    And the output should match:
      | cannot list .* in project.*<%= cb.project2 %> |

    When I run the :policy_add_role_to_group admin command with:
      | role       | view                                        |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project2 %>                          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project2 %> |
    Then the step should succeed

    When I run the :policy_remove_role_from_group admin command with:
      | role       | view                                        |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project1 %>                          |
    And I run the :policy_remove_role_from_group admin command with:
      | role       | view                                        |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project2 %>                          |   
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project1 %> |
    Then the step should fail 
    And the output should match:
      | cannot list .* in project.*<%= cb.project1 %> |
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project2 %> |
    Then the step should fail
    And the output should match:
      | cannot list .* in project.*<%= cb.project2 %> |

  # @author xiaocwan@redhat.com
  # @case_id 498658
  @admin
  Scenario: Add/remove edit and admin role to the cluster group in one or more projects
    Given admin creates a project
    Then evaluation of `project.name` is stored in the :project1 clipboard
    Given admin creates a project
    Then evaluation of `project.name` is stored in the :project2 clipboard    

    When I run the :oadm_groups_new admin command with:
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
    Then the step should succeed
    Given admin ensures "<%= cb.project1 %>-<%= cb.project2 %>-group" group is deleted after scenario
    When I run the :oadm_groups_add_users admin command with:
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | user_name  | <%= user(0, switch: false).name %>          |
    Then the step should succeed

    When I run the :policy_add_role_to_group admin command with:
      | role       | admin                                       |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project1 %>                          |
    Then the step should succeed
    When I switch to the first user 
    And I run the :get client command with:
      | resource | project |
    Then the step should succeed
    And the output should contain:
      | <%= cb.project1 %> |
    And the output should not contain:
      | <%= cb.project2 %> |
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | n          | <%= cb.project1 %>                          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project1 %> |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role       | edit                                        |
      | user_name  | <%= user(1, switch: false).name %>          |
      | n          | <%= cb.project1 %>                          |
    Then the step should succeed
    When I run the :policy_remove_role_from_user client command with:
      | role       | edit                                        |
      | user_name  | <%= user(1, switch: false).name %>          |
      | n          | <%= cb.project1 %>                          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project2 %> |
    Then the step should fail
    And the output should match:
      | cannot list .* in project.*<%= cb.project2 %>            |

    When I run the :policy_add_role_to_group admin command with:
      | role       | edit                                        |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project2 %>                          |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project2 %> |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | n          | <%= cb.project2 %>                          |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role       | edit                                        |
      | user_name  | <%= user(1, switch: false).name %>          |
      | n          | <%= cb.project2 %>                          |
    Then the step should fail  
    And the output should match:
      | cannot get policybindings in project.*<%= cb.project2 %> |

    When I run the :policy_remove_role_from_group admin command with:
      | role       | admin                                       |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project1 %>                          |
    And I run the :policy_remove_role_from_group admin command with:
      | role       | edit                                        |
      | group_name | <%= cb.project1 %>-<%= cb.project2 %>-group |
      | n          | <%= cb.project2 %>                          |   
    Then the step should succeed
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project1 %> |
    Then the step should fail 
    And the output should match:
      | cannot list .* in project.*<%= cb.project1 %> |
    When I run the :get client command with:
      | resource | all                |
      | n        | <%= cb.project2 %> |
    Then the step should fail
    And the output should match:
      | cannot list .* in project.*<%= cb.project2 %> |