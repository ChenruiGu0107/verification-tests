Feature: console test

  Scenario: new project via console test
    When I perform the :new_project web action with:
      |project_name|<%= rand_str(5, :dns) %>|
      |description| sadfsdf is |
    Then the step should succeed
    When I create a new project via web
    Then the step should succeed
    When I create a new project via web
    Then the step should succeed
