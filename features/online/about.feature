Feature: only about page related to Online env

  # @author xiaocwan@redhat.com
  # @case_id OCP-18245
  Scenario: Default Route information should be included in the "about" page
    When I run the :goto_about_page web console action
    Then the step should succeed
    ## get custom route eg. 717f.online-stg.openshiftapps.com
    And evaluation of `browser.execute_script("return window.OPENSHIFT_EXTENSION_PROPERTIES.default_route_suffix")` is stored in the :route_suffix clipboard
    When I perform the :check_routes_with_custom_route web console action with:
      | route_suffix | <%= cb.route_suffix %> |
    Then the step should succeed
