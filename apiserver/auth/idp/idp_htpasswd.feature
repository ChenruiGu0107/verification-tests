Feature: idp feature

  # @author pmali@redhat.com
  # @case_id OCP-23517
  @admin
  @destructive
  Scenario: User can login if and only if user and identity exist and reference to correct user or identity for provision strategy lookup
    Given the "cluster" oauth CRD is restored after scenario
    Given a "htpasswd" file is created with the following lines:
    """
    ocp23517_user:$2y$05$tm9rviPntbmDEL0S5pbF/eWYNP.rcws.dx.KNjfiqwFWH/hC9Dh1e
    """
    When I run the :create_secret admin command with:
      | name        | htpass-secret-ocp23517 |
      | secret_type | generic                |
      | from_file   | htpasswd               |
      | n           | openshift-config       |
    Then the step should succeed
    And admin ensures "htpass-secret-ocp23517" secret is deleted from the "openshift-config" project after scenario
    Given as admin I successfully merge patch resource "oauth/cluster" with:
      | {"spec":{"identityProviders":[{"name":"htpassidp-23517","mappingMethod":"lookup","type":"HTPasswd","htpasswd":{"fileData":{"name":"htpass-secret-ocp23517"}}}]}} |
    Given I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Available')['status'] == "True"
    """
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | ocp23517_user               |
      | password | ocp23517_user               |
      | config   | ocp23517_user.config        |
      | skip_tls_verify  | true                |
    Then the step should fail
    Given I obtain test data file "authorization/idp/OCP-23517/ocp23517_user.json"
    Given I run the :create admin command with:
      | f | ocp23517_user.json |
    Then the step should succeed
    And admin ensures "ocp23517_user" user is deleted after scenario
    Given I obtain test data file "authorization/idp/OCP-23517/ocp23517_identity.json"
    Given I run the :create admin command with:
      | f |ocp23517_identity.json |
    Then the step should succeed
    And admin ensures "htpassidp-23517:ocp23517_user" identity is deleted after scenario
    Given I obtain test data file "authorization/idp/OCP-23517/ocp23517_useridentitymapping.json"
    Given I run the :create admin command with:
      | f | ocp23517_useridentitymapping.json |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | user/ocp23517_user |
    Then the step should succeed
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | ocp23517_user               |
      | password | ocp23517_user               |
      | config   | ocp23517_user.config        |
      | skip_tls_verify  | true                |
    Then the step should succeed
    Given I run the :delete admin command with:
      | object_type       | identity                      |
      | object_name_or_id | htpassidp-23517:ocp23517_user |
    Then the step should succeed
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | ocp23517_user               |
      | password | ocp23517_user               |
      | config   | ocp23517_user.config        |
      | skip_tls_verify  | true                |
    Then the step should fail

  # @author pmali@redhat.com
  # @case_id OCP-23514
  @admin
  @destructive
  Scenario: Config provision strategy as "add"(4.x)	
    Given the "cluster" oauth CRD is restored after scenario
    Given a "htpasswd" file is created with the following lines:
    """
    ocp23514_user:$2y$05$qpxXM/d/GSXVsTp0wwJ.guOCEOSSZeX4JOkG631tQUTXprDDSfYGm
    """
    When I run the :create_secret admin command with:
      | name        | htpass-secret-ocp23514 |
      | secret_type | generic                |
      | from_file   | htpasswd               |
      | n           | openshift-config       |
    Then the step should succeed
    And admin ensures "htpass-secret-ocp23514" secret is deleted from the "openshift-config" project after scenario
    Given as admin I successfully merge patch resource "oauth/cluster" with:
      | {"spec":{"identityProviders":[{"name":"htpassidp-23514","mappingMethod":"add","type":"HTPasswd","htpasswd":{"fileData":{"name":"htpass-secret-ocp23514"}}}]}} |
    Given I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Available')['status'] == "True"
    """
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | ocp23514_user               |
      | password | ocp23514_user               |
      | config   | ocp23514_user.config        |
      | skip_tls_verify  | true                |
    Then the step should succeed
    And admin ensures "ocp23514_user" user is deleted after scenario
    And admin ensures "htpassidp-23514:ocp23514_user" identity is deleted after scenario
    When I run the :get admin command with:
      | resource | user/ocp23514_user |
    Then the step should succeed
   
    Given as admin I successfully merge patch resource "oauth/cluster" with:
      | {"spec":{"identityProviders":[{"name":"new-htpassidp-23514","mappingMethod":"add","type":"HTPasswd","htpasswd":{"fileData":{"name":"htpass-secret-ocp23514"}}}]}} |
    Given I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Available')['status'] == "True"
    """
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | ocp23514_user               |
      | password | ocp23514_user               |
      | config   | ocp23514_user.config        |
      | skip_tls_verify  | true                |
    Then the step should succeed
    And admin ensures "new-htpassidp-23514:ocp23514_user" identity is deleted after scenario
    Then I wait for the steps to pass:
    """
    When I run the :get admin command with:
      | resource | user/ocp23514_user |
    Then the step should succeed
    """
    And the output should contain:
      | htpassidp-23514:ocp23514_user, new-htpassidp-23514:ocp23514_user |

  # @author pmali@redhat.com
  # @case_id OCP-23515
  @admin
  @destructive
  Scenario: Config provision strategy as "claim"(4.x)	
    Given the "cluster" oauth CRD is restored after scenario

    # htpasswd file creation	    
    Given a "htpasswd" file is created with the following lines:
    """
    ocp23515_user:$2y$05$Y.cO61j/5B6tnSmOZMcKXu7QrXbUJBlEGYT6sqD.5z7SFboEbnwsa
    """
    When I run the :create_secret admin command with:
      | name        | htpass-secret-ocp23515 |
      | secret_type | generic                |
      | from_file   | htpasswd               |
      | n           | openshift-config       |
    Then the step should succeed
    And admin ensures "htpass-secret-ocp23515" secret is deleted from the "openshift-config" project after scenario

    # Adding htpasswd idp as claim method
    Given as admin I successfully merge patch resource "oauth/cluster" with:
      | {"spec":{"identityProviders":[{"name":"htpassidp-23515","mappingMethod":"claim","type":"HTPasswd","htpasswd":{"fileData":{"name":"htpass-secret-ocp23515"}}}]}} |
    Given I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Available')['status'] == "True"
    """

    # Login should successful with user details as claim method
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | ocp23515_user               |
      | password | ocp23515_user               |
      | config   | ocp23515_user.config        |
      | skip_tls_verify  | true                |
    Then the step should succeed
    And admin ensures "ocp23515_user" user is deleted after scenario
    And admin ensures "htpassidp-23515:ocp23515_user" identity is deleted after scenario
    When I run the :get admin command with:
      | resource | user/ocp23515_user |
    Then the step should succeed

    # Adding new htpasswd idp with claim method
    Given as admin I successfully merge patch resource "oauth/cluster" with:
      | {"spec":{"identityProviders":[{"name":"new-htpassidp-23515","mappingMethod":"claim","type":"HTPasswd","htpasswd":{"fileData":{"name":"htpass-secret-ocp23515"}}}]}} |
    Given I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Available')['status'] == "True"
    """
    # Login should fail as username is already mapped with other idp
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | ocp23515_user               |
      | password | ocp23515_user               |
      | config   | ocp23515_user.config        |
      | skip_tls_verify  | true                |
    Then the step should fail

    # Delete Identity for user and try to relogin
    Given I run the :delete admin command with:
      | object_type       | identity                      |
      | object_name_or_id | htpassidp-23515:ocp23515_user |
    Then the step should succeed
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | ocp23517_user               |
      | password | ocp23517_user               |
      | config   | ocp23517_user.config        |
      | skip_tls_verify  | true                |
    Then the step should fail


  # @author pmali@redhat.com
  # @case_id OCP-29916
  @admin
  @destructive
  Scenario: [BUG: 1814898] User should able to login when ldap query times out when htpasswd IDP credentials are used.	
    Given the "cluster" oauth CRD is restored after scenario
    Given a "htpasswd" file is created with the following lines:
    """
    newton:$2y$05$i1Q2aEoyGGMEVscWl9rGlO5ELMf3gmfea7oZ/eI0Qe0LkdB.Nn75q
    """
    When I run the :create_secret admin command with:
      | name        | htpass-secret-ocp29916 |
      | secret_type | generic                |
      | from_file   | htpasswd               |
      | n           | openshift-config       |
    Then the step should succeed
    And admin ensures "htpass-secret-ocp29916" secret is deleted from the "openshift-config" project after scenario
    Given I obtain test data file "authorization/idp/OCP-29916/OCP-29916_idp_spec.json"
    Given as admin I successfully merge patch resource "oauth/cluster" with:
      | <%= File.read("OCP-29916_idp_spec.json") %> |
    Given I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "True"
    """
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("authentication").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("authentication").condition(type: 'Available')['status'] == "True"
    """
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | newton                      |
      | password | password                    |
      | config   | newton.config               |
      | skip_tls_verify  | true                |
    Then the step should succeed
    And admin ensures "newton" user is deleted after scenario
    And admin ensures "htpassidp-29916:newton" identity is deleted after scenario
    When I run the :get admin command with:
      | resource | user/newton |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | pods                               |
      | n        | openshift-authentication           |
      | o        | jsonpath={.items[0].metadata.name} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :auth_pod_name clipboard
    Given I run the :logs admin command with:
      | resource_name | <%= cb.auth_pod_name %>  |
      | n             | openshift-authentication |
    Then the step should succeed
    And the output should match:
      | Error.*login.*newton.*LDAP.*Network Error.*0.0.0.0:386.*connection refused | 
      
