Feature: add idp from console
  # @author yanpzhan@redhat.com
  # @case_id OCP-23608
  @admin
  @destructive
  Scenario: Configure Basic Authentication IDP
    Given the master version >= "4.2"
    # restore oauth/cluster after scenarios
    Given the "cluster" oauth CRD is restored after scenario
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.key"
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/edge/route_edge-www.edge.com.crt"
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem"
    Then the step should succeed

    Given I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed

    When I perform the :add_basicauth_idp web action with:
      | idp_name   | ui_basicauth_test            |
      | remote_url | https://www.openshift.com    |
      | ca_path    | <%= expand_path("ca.pem") %> |
      | crt_path   | <%= expand_path("route_edge-www.edge.com.crt") %> |
      | key_path   | <%= expand_path("route_edge-www.edge.com.key") %> |
    Then the step should succeed
    When I perform the :check_idp_in_table_list web action with:
      | idp_name | ui_basicauth_test |
      | idp_type | BasicAuth         |
    Then the step should succeed

    When I run the :get admin command with:
      | resource      | oauth   |
      | resource_name | cluster |
      | o             | yaml    |
    Then the step should succeed
    Given evaluation of `@result[:parsed]['spec']['identityProviders'].length()` is stored in the :idp_count clipboard
    Given evaluation of `@result[:parsed]['spec']['identityProviders'][<%= cb.idp_count %>-1]["basicAuth"]['ca']['name']` is stored in the :cm_name clipboard
    Given evaluation of `@result[:parsed]['spec']['identityProviders'][<%= cb.idp_count %>-1]["basicAuth"]['tlsClientCert']['name']` is stored in the :secret_name clipboard
    Given admin ensures "<%= cb.secret_name %>" secret is deleted from the "openshift-config" project after scenario
    Given admin ensures "<%= cb.cm_name %>" configmap is deleted from the "openshift-config" project after scenario
    And the expression should be true> @result[:parsed]["spec"]["identityProviders"][<%= cb.idp_count %>-1]["basicAuth"]["url"] == 'https://www.openshift.com'
    And the expression should be true> @result[:parsed]["spec"]["identityProviders"][<%= cb.idp_count %>-1]["name"] == "ui_basicauth_test"
    And the expression should be true> @result[:parsed]["spec"]["identityProviders"][<%= cb.idp_count %>-1]["type"] == "BasicAuth"

    Given I use the "openshift-authentication" project
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given 1 pods become ready with labels:
      | app=oauth-openshift |
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("authentication").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("authentication").condition(type: 'Available')['status'] == "True"
    """

  # @author yanpzhan@redhat.com
  # @case_id OCP-23202
  @admin
  @destructive
  Scenario: Config github IDP from cluster setting page
    Given the master version >= "4.2"
    # restore oauth/cluster after scenarios
    Given the "cluster" oauth CRD is restored after scenario
    Given I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed

    # create github idp without org and team set
    When I perform the :add_github_idp web action with:
      | idp_name      | ui_githug_test |
      | client_id     | testid         |
      | client_secret | testsecret     |
    Then the step should succeed
    When I run the :check_error_info_for_no_org_and_team web action
    Then the step should succeed

    # create github idp with both org and team set
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed
    When I perform the :add_github_idp web action with:
      | idp_name      | ui_githug_test |
      | client_id     | testid         |
      | client_secret | testsecret     |
      | org_name      | orgtest        |
      | team_name     | org/teamtest   |
    Then the step should succeed
    When I run the :check_error_info_for_both_org_and_team web action
    Then the step should succeed

    # create correct github idp with org set
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed
    When I perform the :add_github_idp web action with:
      | idp_name      | ui_github_test |
      | client_id     | testid         |
      | client_secret | testsecret     |
      | org_name      | orgtest        |
    Then the step should succeed 
    When I perform the :check_idp_in_table_list web action with:
      | idp_name | ui_github_test |
      | idp_type | GitHub         |
    Then the step should succeed

    When I run the :get admin command with:
      | resource      | oauth   |
      | resource_name | cluster |
      | o             | yaml    |
    Then the step should succeed
    Given evaluation of `@result[:parsed]['spec']['identityProviders'].length()` is stored in the :idp_count clipboard
    Given evaluation of `@result[:parsed]['spec']['identityProviders'][<%= cb.idp_count %>-1]["github"]['clientSecret']['name']` is stored in the :secret_name clipboard
    Given admin ensures "<%= cb.secret_name %>" secret is deleted from the "openshift-config" project after scenario
    And the expression should be true> @result[:parsed]["spec"]["identityProviders"][<%= cb.idp_count %>-1]["name"] == "ui_github_test"
    And the expression should be true> @result[:parsed]["spec"]["identityProviders"][<%= cb.idp_count %>-1]["type"] == "GitHub"
    And the expression should be true> @result[:parsed]["spec"]["identityProviders"][<%= cb.idp_count %>-1]["github"]["clientID"] == 'testid'
    And the expression should be true> @result[:parsed]["spec"]["identityProviders"][<%= cb.idp_count %>-1]["github"]["organizations"][0] == 'orgtest'

    Given I use the "openshift-authentication" project
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given 1 pods become ready with labels:
      | app=oauth-openshift |
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("authentication").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("authentication").condition(type: 'Available')['status'] == "True"
    """

    # create github idp with existing idp name
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed
    When I perform the :add_github_idp web action with:
      | idp_name      | ui_github_test |
      | client_id     | testid1        |
      | client_secret | testsecret1    |
      | org_name      | orgtest1       |
    Then the step should succeed
    When I run the :check_error_info_for_dupicated_idp_name web action
    Then the step should succeed
