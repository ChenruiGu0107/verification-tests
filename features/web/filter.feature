Feature: filter on create page
  # @author: yapei@redhat.com
  # @case_id: 470357
  Scenario: search and filter for things on the create page
    When I create a new project via web
    Then the step should succeed
    
    # filter by tag instant-app
    When I perform the :filter_by_tags web console action with:
      | tag_name | instant-app |
    Then the step should succeed
    When I get the html of the web page
    Then the output should match:
      | Instant Apps |
    # filter by tag xPaas
    When I perform the :filter_by_tags web console action with:
      | tag_name | xpaas |
    Then the step should succeed
    When I get the html of the web page
    Then the output should match:
      | xPaaS |
      | jboss |
      | amq62 |
    # filter by tag java
    When I perform the :filter_by_tags web console action with:
      | tag_name | java |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | Python |
      | Instant Apps |
      | NodeJS |
      | PHP |
      | Other |
      | Ruby |
      | Perl |
      | Databases |
    # filter by tag ruby
    When I perform the :filter_by_tags web console action with:
      | tag_name | ruby |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | Python |
      | NodeJS |
      | Other |
      | xPaaS |
      | Perl |
      | Databases |
      | PHP |
    # filter by tag perl
    When I perform the :filter_by_tags web console action with:
      | tag_name | perl |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | Python |
      | NodeJS |
      | Other |
      | Ruby |
      | Databases |
      | xPaaS |
      | PHP |
    # filter by tag python
    When I perform the :filter_by_tags web console action with:
      | tag_name | python |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | NodeJS |
      | Perl |
      | Other |
      | Ruby |
      | Databases |
      | xPaaS |
      | PHP |
    # filter by tag nodejs
    When I perform the :filter_by_tags web console action with:
      | tag_name | nodejs |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | Perl |
      | Other |
      | Python |
      | Ruby |
      | Databases |
      | xPaaS |
      | PHP |
    # filter by tag database
    When I perform the :filter_by_tags web console action with:
      | tag_name | database |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | Databases |
      | mongodb |
      | mysql |
      | xPaaS |
      | eap64 |
    # filter by tag messaging
    When I perform the :filter_by_tags web console action with:
      | tag_name | messaging |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | xPaaS |
      | amq |
    # filter by tag php
    When I perform the :filter_by_tags web console action with:
      | tag_name | php |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | Python |
      | NodeJS |
      | Other |
      | xPaaS |
      | Ruby |
      | Perl |
      | Databases |
    When I run the :clear_tag_filters web console action
    Then the step should succeed
    # filter by partial keyword
    When I perform the :filter_by_keywords web console action with:
      | keyword | ph |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | php |
      | ephemeral |
    When I run the :clear_keyword_filters web console action
    Then the step should succeed
    When I perform the :filter_by_keywords web console action with:
      | keyword | php |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | Instant Apps |
      | PHP |
    When I run the :clear_keyword_filters web console action
    Then the step should succeed
    # filter by multi-keywords
    When I perform the :filter_by_keywords web console action with:
      | keyword | instant-app perl |
    Then the step should succeed
    When I get the html of the web page
    Then the output should match:
      | dancer-example |
      | dancer-.+-example |
    When I run the :clear_keyword_filters web console action
    Then the step should succeed
    # filter by non-exist keyword
    When I perform the :filter_by_keywords web console action with:
      | keyword | hello |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | All builder images and templates are hidden by the current filter |
    When I run the :clear_keyword_filters web console action
    Then the step should succeed
    # filter by invalid character keyword
    When I perform the :filter_by_keywords web console action with:
      | keyword | $#@ |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | All builder images and templates are hidden by the current filter |
    # Clear filter link
    When I click the following "a" element:
      | text | Clear filter |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | All builder images and templates are hidden by the current filter |
    # filter by keyword and tag 
    When I perform the :filter_by_keywords web console action with:
      | keyword | nodejs |
    Then the step should succeed
    When I get the html of the web page
    Then the output should contain:
      | Instant Apps |
      | NodeJS |
    When I perform the :filter_by_tags web console action with:
      | tag_name | instant-app |
    Then the step should succeed
    When I get the html of the web page
    Then the output should not contain:
      | NodeJS |
