Feature: auth prometheus metrics feature
  # @author xxia@redhat.com
  # @case_id OCP-15431
  @admin
  Scenario: Oauth Prometheus endpoint coverage
    # oc login
    Given I have a project
    # web login
    Given I open admin console in a browser

    When I run the :login client command with:
      | username | xxxxxxx2 |
      | password | yyyyyyy3 |
    # "result":"failure"
    Then the step should fail

    When I run the :get admin command with:
      | resource | identity                                                            |
      | o        | jsonpath={.items[?(@.user.name=="<%= user.name %>")].metadata.name} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :identity_name clipboard

    Given admin ensures "<%= cb.identity_name %>" identity is deleted after scenario
    # the user is broken, below need re-login to make user back for normal use
    When admin ensures "<%= user.name %>" user is deleted
    When I run the :login client command with:
      | username | <%= user.name %>      |
      | password | <%= user.password %>  |
    # "result":"error"
    Then the step should fail

    # if not ensuring this, this user's login in all following scenarios will fail
    Given admin ensures "<%= cb.identity_name %>" identity is deleted

    When I run the :login client command with:
      | username | <%= user.name %>      |
      | password | <%= user.password %>  |
    Then the step should succeed

    Given the first user is cluster-admin
    # do prometheus query with method other than web UI
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                             |
      | query | openshift_auth_basic_password_count_result |
    Then the step should succeed
    And the output should contain:
      | "result":"success" |
      | "result":"failure" |
      | "result":"error"   |
    """

    # metrics for web login
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                            |
      | query | openshift_auth_form_password_count_result |
    Then the step should succeed
    And the output should contain:
      | "result":"success" |

    # must re-login to web
    Given I open admin console in a browser
    # do prometheus query with method of web UI
    When I run the :goto_monitoring_metrics_page web action
    Then the step should succeed
    When I perform the :perform_metric_query_textarea web action with:
      | metrics | openshift_auth_basic_password_count |
    Then the step should succeed
    When I perform the :check_metric_query_result web action with:
      | table_text | oauth-openshift |
    Then the step should succeed
