Feature: search or filter items related

  # @author xxia@redhat.com
  # @case_id OCP-13997
  Scenario: Check search catalog on web console
    Given the master version >= "3.6"
    When I run the :goto_home_page web console action
    Then the step should succeed
    When I perform the :check_max_shown_matches_in_search web console action with:
      | keyword  | builder    |
    Then the step should succeed
    When I perform the :check_name_match_in_search web console action with:
      | keyword  | rails |
    Then the step should succeed
    # Search keyword is case insensitive
    When I perform the :check_tag_match_in_search web console action with:
      | keyword  | BUILDER |
    Then the step should succeed

    # search image
    When I perform the :search_and_click_first_item_from_catalog web console action with:
      | keyword  | builder php |
    Then the step should succeed
    When I run the :click_cancel web console action
    Then the step should succeed
    # search serviceclass
    When I perform the :search_and_click_first_item_from_catalog web console action with:
      | keyword  | mediawiki apb |
      | has_tag  |               |
    Then the step should succeed
    When I run the :click_cancel web console action
    Then the step should succeed
    When I perform the :search_catalog_no_result web console action with:
      | keyword  | not exist |
    Then the step should succeed

    When I perform the :check_name_prior_to_tag_in_search web console action with:
      | keyword  | ruby |
    # Currently has bug 1449038, so put the check at end
    Then the step should succeed

