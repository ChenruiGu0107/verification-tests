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
      | name        | htpass-secret-ocp23517   |
      | secret_type | generic                  |
      | from_file   | htpasswd                 |
      | n           | openshift-config         |
    Then the step should succeed
    And admin ensure "htpass-secret-ocp23517" secret is deleted from the "openshift-config" project after scenario
    When I run the :patch admin command with:
      | resource      | oauth                  |
      | resource_name | cluster                |
      | p             | {"spec":{"identityProviders":[{"name":"htpassidp-23517","mappingMethod":"lookup","type":"HTPasswd","htpasswd":{"fileData":{"name":"htpass-secret-ocp23517"}}}]}} |
      | type          | merge                  |
    Then the step should succeed
    Given 60 seconds have passed
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
      | config   | ocp23517_user.cofig         |
      | skip_tls_verify  | true                |
    Then the step should fail
    Given I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/idp/OCP-23517/ocp23517_user.json |
    Then the step should succeed
    And admin ensure "ocp23517_user" user is deleted after scenario
    Given I run the :create admin command with:
      | f |<%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/idp/OCP-23517/ocp23517_identity.json |
    Then the step should succeed
    And admin ensure "htpassidp-23517:ocp23517_user" identity is deleted after scenario
    Given I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/authorization/idp/OCP-23517/ocp23517_useridentitymapping.json |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | user/ocp23517_user          |
    Then the step should succeed
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | ocp23517_user               |
      | password | ocp23517_user               |
      | config   | ocp23517_user.cofig         |
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
      | config   | ocp23517_user.cofig         |
      | skip_tls_verify  | true                |
    Then the step should fail
