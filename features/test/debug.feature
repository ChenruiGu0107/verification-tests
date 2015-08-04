@some_feature_tag
Feature: Debug and Explore Stuff

  @pry
  Scenario: I want to pry
    Given I pry

  Scenario: I want to pry again
    Given I pry

  @pry_outline
  Scenario Outline: I want to pry an outline
    When I pry
    Examples:
      | garga|marga |
      |hodi | brodi |
      |mura |    ura|

  @pry_table_step
  Scenario: I want to pry in a step with table
    When I pry in a step with table
      | h1 | h2 |
      |va1|va2|
      |vb1|vb2|
      |vc1|vc2|
