Feature: console
  Scenario: new project via console
    When I do the :new_project web operation with:
      |project_name|asdfdsf|
      |description| sadfsdf is |
    When I create a new project via web
    When I create a new project via web
