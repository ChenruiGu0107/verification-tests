Feature: add idp from console
  # @author yanpzhan@redhat.com
  # @case_id OCP-23608
  @admin
  @destructive
  Scenario: Configure Basic Authentication IDP
    Given the master version >= "4.2"
    # restore oauth/cluster after scenarios
    Given the "cluster" oauth CRD is restored after scenario

    Given I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed

    When I perform the :add_basicauth_idp web action with:
      | idp_name   | ui_basicauth_test            |
      | remote_url | https://www.openshift.com    |
      | ca_path    | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/ca.pem                           |
      | crt_path   | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/edge/route_edge-www.edge.com.crt |
      | key_path   | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/edge/route_edge-www.edge.com.key |
    Then the step should succeed
    When I perform the :check_idp_in_table_list web action with:
      | idp_name | ui_basicauth_test |
      | idp_type | BasicAuth         |
    Then the step should succeed

    Given evaluation of `o_auth('cluster').idp(name:'ui_basicauth_test')` is stored in the :idp clipboard
    Given evaluation of `<%= cb.idp %>["basicAuth"]['ca']['name']` is stored in the :cm_name clipboard
    Given evaluation of `<%= cb.idp %>["basicAuth"]['tlsClientCert']['name']` is stored in the :secret_name clipboard
    Given admin ensures "<%= cb.secret_name %>" secret is deleted from the "openshift-config" project after scenario
    Given admin ensures "<%= cb.cm_name %>" configmap is deleted from the "openshift-config" project after scenario
    And the expression should be true> <%= cb.idp %>["basicAuth"]["url"] == 'https://www.openshift.com'
    And the expression should be true> <%= cb.idp %>["type"] == "BasicAuth"

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

    Given evaluation of `o_auth('cluster').idp(name:'ui_github_test')` is stored in the :idp clipboard
    Given evaluation of `<%= cb.idp %>["github"]['clientSecret']['name']` is stored in the :secret_name clipboard
    Given admin ensures "<%= cb.secret_name %>" secret is deleted from the "openshift-config" project after scenario
    And the expression should be true> <%= cb.idp %>["type"] == "GitHub"
    And the expression should be true> <%= cb.idp %>["github"]["clientID"] == 'testid'
    And the expression should be true> <%= cb.idp %>["github"]["organizations"][0] == 'orgtest'

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

  # @author yanpzhan@redhat.com
  # @case_id OCP-23283
  @admin
  @destructive
  Scenario: Add GitLab IDP on console
    Given the master version >= "4.2"
    # restore oauth/cluster after scenarios
    Given the "cluster" oauth CRD is restored after scenario

    Given I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed

    When I perform the :add_gitlab_idp web action with:
      | idp_name      | ui_gitlab_test            |
      | remote_url    | https://www.openshift.com |
      | client_id     | testid                    |
      | client_secret | testsecret                |
    Then the step should succeed
    When I perform the :check_idp_in_table_list web action with:
      | idp_name | ui_gitlab_test |
      | idp_type | GitLab         |
    Then the step should succeed
    Given evaluation of `o_auth('cluster').idp(name:'ui_gitlab_test')` is stored in the :idp clipboard

    Given evaluation of `<%= cb.idp %>["gitlab"]['clientSecret']['name']` is stored in the :secret_name clipboard
    Given admin ensures "<%= cb.secret_name %>" secret is deleted from the "openshift-config" project after scenario
    And the expression should be true> <%= cb.idp %>["type"] == "GitLab"
    And the expression should be true> <%= cb.idp %>["gitlab"]["clientID"] == "testid"
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
  # @case_id OCP-23230
  @admin
  @destructive
  Scenario: Add LDAP IDP from console
    Given the master version >= "4.2"
    # restore oauth/cluster after scenarios
    Given the "cluster" oauth CRD is restored after scenario

    Given I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed

    When I perform the :add_ldap_idp web action with:
      | idp_name           | ui_ldap_test                 |
      | remote_url         | ldap://www.openshift.com    |
      | bind_dn            | test                         |
      | bind_passwd        | testpasswd                   |
      | preferred_username | testuid                      |
      | attr_email         | test@redhat.com              |
      | ca_path            | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/ca.pem |
    Then the step should succeed
    When I perform the :check_idp_in_table_list web action with:
      | idp_name | ui_ldap_test |
      | idp_type | LDAP         |
    Then the step should succeed

    Given evaluation of `o_auth('cluster').idp(name:'ui_ldap_test')` is stored in the :idp clipboard

    Given evaluation of `<%= cb.idp %>["ldap"]['bindPassword']['name']` is stored in the :secret_name clipboard
    Given evaluation of `<%= cb.idp %>["ldap"]['ca']['name']` is stored in the :cm_name clipboard
    Given admin ensures "<%= cb.secret_name %>" secret is deleted from the "openshift-config" project after scenario
    Given admin ensures "<%= cb.cm_name %>" configmap is deleted from the "openshift-config" project after scenario

    And the expression should be true> <%= cb.idp %>["type"] == "LDAP"
    And the expression should be true> <%= cb.idp %>["ldap"]["url"] == "ldap://www.openshift.com"
    And the expression should be true> <%= cb.idp %>["ldap"]["bindDN"] == "test"
    And the expression should be true> <%= cb.idp %>["ldap"]["attributes"]["preferredUsername"] == ["testuid"]
    And the expression should be true> <%= cb.idp %>["ldap"]["attributes"]["email"] == ["test@redhat.com"]

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
  # @case_id OCP-23597
  @admin
  @destructive
  Scenario: Configure Google IDP for cluster
    Given the master version >= "4.2"
    # restore oauth/cluster after scenarios
    Given the "cluster" oauth CRD is restored after scenario

    Given I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed

    When I perform the :add_google_idp web action with:
      | idp_name      | ui_google_test |
      | client_id     | testid         |
      | client_secret | testsecret     |
      | hosted_domain | redhat.com     |
    Then the step should succeed
    When I perform the :check_idp_in_table_list web action with:
      | idp_name | ui_google_test |
      | idp_type | Google         |
    Then the step should succeed

    Given evaluation of `o_auth('cluster').idp(name:'ui_google_test')` is stored in the :idp clipboard

    Given evaluation of `<%= cb.idp %>["google"]['clientSecret']['name']` is stored in the :secret_name clipboard
    Given admin ensures "<%= cb.secret_name %>" secret is deleted from the "openshift-config" project after scenario
    And the expression should be true> <%= cb.idp %>["type"] == "Google"
    And the expression should be true> <%= cb.idp %>["google"]["clientID"] == 'testid'
    And the expression should be true> <%= cb.idp %>["google"]["hostedDomain"] == 'redhat.com'

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
  # @case_id OCP-23011
  @admin
  @destructive
  Scenario: Create OpenId Oauth IDP for Gitlab
    Given the master version >= "4.2"
    # restore oauth/cluster after scenarios
    Given the "cluster" oauth CRD is restored after scenario

    Given I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed

    When I perform the :add_openid_idp web action with:
      | idp_name           | ui_openid_test               |
      | issuer_url         | https://gitlab.com           |
      | client_id          | testid                       |
      | client_secret      | testsecret                   |
      | preferred_username | nickname                     |
      | ca_path            | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/ca.pem |
    Then the step should succeed
    When I perform the :check_idp_in_table_list web action with:
      | idp_name | ui_openid_test |
      | idp_type | OpenID         |
    Then the step should succeed

    Given evaluation of `o_auth('cluster').idp(name:'ui_openid_test')` is stored in the :idp clipboard

    Given evaluation of `<%= cb.idp %>["openID"]['clientSecret']['name']` is stored in the :secret_name clipboard
    Given evaluation of `<%= cb.idp %>["openID"]['ca']['name']` is stored in the :cm_name clipboard
    Given admin ensures "<%= cb.cm_name %>" configmap is deleted from the "openshift-config" project after scenario
    Given admin ensures "<%= cb.secret_name %>" secret is deleted from the "openshift-config" project after scenario

    And the expression should be true> <%= cb.idp %>["type"] == "OpenID"
    And the expression should be true> <%= cb.idp %>["openID"]["clientID"] == "testid"
    And the expression should be true> <%= cb.idp %>["openID"]["claims"]["preferredUsername"] == ["nickname"]

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
  # @case_id OCP-23929
  @admin
  @destructive
  Scenario: Check IDP with Request Header
    Given the master version >= "4.2"
   # restore oauth/cluster after scenarios
    Given the "cluster" oauth CRD is restored after scenario

    Given I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed

    When I perform the :add_requestheader_idp web action with:
      | idp_name                   | ui_requestheader_test        |
      | login_url                  | https://www.example.com/login-proxy/oauth/authorize?${query} |
      | ca_path                    | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/routing/ca.pem |
      | headers                    | X-Remote-User                |
      | more_headers               | SSO-User                     |
      | preferred_username_headers | X-Remote-User-Login          |
      | name_headers               | X-Remote-User-Display-Name   |
      | email_headers              | X-Remote-User-Email          |
    Then the step should succeed
    When I perform the :check_idp_in_table_list web action with:
      | idp_name | ui_requestheader_test |
      | idp_type | RequestHeader         |
    Then the step should succeed
    Given evaluation of `o_auth('cluster').idp(name:'ui_requestheader_test')` is stored in the :idp clipboard

    Given evaluation of `<%= cb.idp %>["requestHeader"]['ca']['name']` is stored in the :cm_name clipboard
    Given admin ensures "<%= cb.cm_name %>" configmap is deleted from the "openshift-config" project after scenario

    And the expression should be true> <%= cb.idp %>["type"] == "RequestHeader"
    And the expression should be true> <%= cb.idp %>["requestHeader"]["loginURL"] == "https://www.example.com/login-proxy/oauth/authorize?${query}"
    And the expression should be true> <%= cb.idp %>["requestHeader"]["headers"] == ["X-Remote-User","SSO-User"]
    And the expression should be true> <%= cb.idp %>["requestHeader"]["preferredUsernameHeaders"] == ["X-Remote-User-Login"] 
    And the expression should be true> <%= cb.idp %>["requestHeader"]["nameHeaders"] == ["X-Remote-User-Display-Name"] 
    And the expression should be true> <%= cb.idp %>["requestHeader"]["emailHeaders"] == ["X-Remote-User-Email"] 

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
  # @case_id OCP-23963
  @admin
  @destructive
  Scenario: Add Keystone as a IDP for cluster settings
    Given the master version >= "4.2"
   # restore oauth/cluster after scenarios
    Given the "cluster" oauth CRD is restored after scenario

    Given I open admin console in a browser
    Given the first user is cluster-admin
    When I run the :goto_cluster_oauth_configuration_page web action
    Then the step should succeed

    When I perform the :add_keystone_idp web action with:
      | idp_name    | ui_keystone_test          |
      | domain_name | default                   |
      | remote_url  | https://www.openshift.com |
    Then the step should succeed
    When I perform the :check_idp_in_table_list web action with:
      | idp_name | ui_keystone_test |
      | idp_type | Keystone         |
    Then the step should succeed

    Given evaluation of `o_auth('cluster').idp(name:'ui_keystone_test')` is stored in the :idp clipboard

    And the expression should be true> <%= cb.idp %>["type"] == "Keystone"
    And the expression should be true> <%= cb.idp %>["keystone"]["domainName"] == "default"
    And the expression should be true> <%= cb.idp %>["keystone"]["url"] == "https://www.openshift.com"

    Given I use the "openshift-authentication" project
    Given I wait up to 300 seconds for the steps to pass:
    """
    Given 1 pods become ready with labels:
      | app=oauth-openshift |
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("authentication").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("authentication").condition(type: 'Available')['status'] == "True"
    """
