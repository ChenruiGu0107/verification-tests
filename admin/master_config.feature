Feature: test master config related steps

  # @author yinzhou@redhat.com
  # @case_id OCP-9906
  @admin
  @destructive
  Scenario: Check project limitation for users with and without label admin=true for online env
    Given the "cluster" "openshiftapiserver" CRD is recreated after scenario
    When I run the :patch admin command with:
      | resource      | openshiftapiserver |
      | resource_name | cluster            |
      | p             | {"spec":{"unsupportedConfigOverrides":{"admission":{"enabledPlugins":["project.openshift.io/ProjectRequestLimit"],"pluginConfig":{"project.openshift.io/ProjectRequestLimit":{"configuration":{"apiVersion":"project.openshift.io/v1","kind":"ProjectRequestLimitConfig","limits":[{"selector":{"admin":"true"}},{"maxProjects":1}]}}}}}}} |
      | type          | merge              |
    Then the step should succeed
    Given 100 seconds have passed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("openshift-apiserver").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("openshift-apiserver").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("openshift-apiserver").condition(type: 'Available')['status'] == "True"
    """
    When I run the :label admin command with:
      | resource | user             |
      | name     | <%= user.name %> |
      | key_val  | admin=true       |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :label admin command with:
      | resource | user             |
      | name     | <%= user.name %> |
      | key_val  | admin-           |
    """
    When I switch to the first user
    Given I create a new project via cli
    Then the step should succeed
    Given I create a new project via cli
    Then the step should succeed
    When I switch to the second user
    Given I create a new project via cli
    Then the step should succeed
    Given I create a new project via cli
    Then the step should fail
    And the output should contain:
      | cannot create more than |

  # @author chuyu@redhat.com
  # @case_id OCP-11928
  @admin
  @destructive
  Scenario: User can login when user exists and references identity which does not exist
    Given the user has all owned resources cleaned
    Given the "cluster" oauth CRD is restored after scenario
    Given a "htpasswd" file is created with the following lines:
    """
    509118_user:$apr1$7ma7rnTp$RkFR.KM7EwBRf61dm4D0F/
    """
    When I run the :create_secret admin command with:
      | name        | htpass-secret-11928 |
      | secret_type | generic             |
      | from_file   | htpasswd            |
      | n           | openshift-config    |
    Then the step should succeed
    And admin ensure "htpass-secret-11928" secret is deleted from the "openshift-config" project after scenario
    When I run the :patch admin command with:
      | resource      | oauth        |
      | resource_name | cluster      |
      | p             | {"spec":{"identityProviders":[{"name":"htpassidp-11928","mappingMethod":"claim","type":"HTPasswd","htpasswd":{"fileData":{"name":"htpass-secret-11928"}}}]}} |
      | type          | merge        |
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
      | username | 509118_user                 |
      | password | password                    |
    Then the step should succeed
    Given admin ensures identity "htpassidp-11928:509118_user" is deleted
    Then the step should succeed
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | 509118_user                 |
      | password | password                    |
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-9800
  @admin
  @destructive
  Scenario: User can customize the projectrequestlimit admission controller configuration
    Given the "cluster" "openshiftapiserver" CRD is recreated after scenario
    When I run the :patch admin command with:
      | resource      | openshiftapiserver |
      | resource_name | cluster            |
      | p             | {"spec":{"unsupportedConfigOverrides":{"admission":{"enabledPlugins":["project.openshift.io/ProjectRequestLimit"],"pluginConfig":{"project.openshift.io/ProjectRequestLimit":{"configuration":{"apiVersion":"project.openshift.io/v1","kind":"ProjectRequestLimitConfig","limits":[{"maxProjects":1,"selector":{}}]}}}}}}} |
      | type          | merge              |
    Then the step should succeed
    Given 100 seconds have passed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("openshift-apiserver").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("openshift-apiserver").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("openshift-apiserver").condition(type: 'Available')['status'] == "True"
    """
    When I switch to the first user
    Given I create a new project
    Then the step should succeed
    Given I create a new project
    Then the step should fail
    And the output should contain:
      | cannot create more than |
    Given I run the :delete client command with:
      | object_type | project |
      | all         |         |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | openshiftapiserver |
      | resource_name | cluster            |
      | p             | {"spec":{"unsupportedConfigOverrides":{"admission":{"enabledPlugins":["project.openshift.io/ProjectRequestLimit"],"pluginConfig":{"project.openshift.io/ProjectRequestLimit":{"configuration":{"apiVersion":"project.openshift.io/v1","kind":"ProjectRequestLimitConfig","limits":[{"selector":{"level":"platinum"},"maxProjects":1}]}}}}}}} |
      | type          | merge              |
    Then the step should succeed
    Given 100 seconds have passed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("openshift-apiserver").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("openshift-apiserver").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("openshift-apiserver").condition(type: 'Available')['status'] == "True"
    """
    When I run the :label admin command with:
      | resource | user             |
      | name     | <%= user.name %> |
      | key_val  | level=platinum   |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :label admin command with:
      | resource | user             |
      | name     | <%= user.name %> |
      | key_val  | level-           |
    Then the step should succeed
    """
    Given I create a new project
    Then the step should succeed
    Given I create a new project
    Then the step should fail
    And the output should contain:
      | cannot create more than |
    Given I run the :delete client command with:
      | object_type | project |
      | all         |         |
    Then the step should succeed
    When I switch to the second user
    Given I create a new project
    Then the step should succeed
    Given I create a new project
    Then the step should succeed
    Given I run the :delete client command with:
      | object_type | project |
      | all         |         |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | openshiftapiserver |
      | resource_name | cluster            |
      | p             | {"spec":{"unsupportedConfigOverrides":{"admission":{"enabledPlugins":["project.openshift.io/ProjectRequestLimit"],"pluginConfig":{"project.openshift.io/ProjectRequestLimit":{"configuration":{"apiVersion":"project.openshift.io/v1","kind":"ProjectRequestLimitConfig","limits":[{"selector":{"level":"platinum"},"maxProjects":2},{"selector":{},"maxProjects":1}]}}}}}}} |
      | type          | merge              |
    Then the step should succeed
    Given 100 seconds have passed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("openshift-apiserver").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("openshift-apiserver").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("openshift-apiserver").condition(type: 'Available')['status'] == "True"
    """
    When I switch to the first user
    Given I create a new project
    Then the step should succeed
    Given I create a new project
    Then the step should succeed
    Given I create a new project
    Then the step should fail
    And the output should contain:
      | cannot create more than |
    Given I run the :delete client command with:
      | object_type | project |
      | all         |         |
    Then the step should succeed
    When I switch to the second user
    Given I create a new project
    Then the step should succeed
    Given I create a new project
    Then the step should fail
    And the output should contain:
      | cannot create more than |
    Given I run the :delete client command with:
      | object_type | project |
      | all         |         |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | openshiftapiserver |
      | resource_name | cluster            |
      | p             | {"spec":{"unsupportedConfigOverrides":{"admission":{"enabledPlugins":["project.openshift.io/ProjectRequestLimit"],"pluginConfig":{"project.openshift.io/ProjectRequestLimit":{"configuration":{"apiVersion":"project.openshift.io/v1","kind":"ProjectRequestLimitConfig","limits":[{"selector":{"level":"platinum"},"maxProjects":1},{"selector":{"tag":"golden"},"maxProjects":2}]}}}}}}} |
      | type          | merge              |
    Then the step should succeed
    Given 100 seconds have passed
    And I wait for the steps to pass:
    """
    Then the expression should be true> cluster_operator("openshift-apiserver").condition(cached: false, type: 'Progressing')['status'] == "False"
    And  the expression should be true> cluster_operator("openshift-apiserver").condition(type: 'Degraded')['status'] == "False"
    And  the expression should be true> cluster_operator("openshift-apiserver").condition(type: 'Available')['status'] == "True"
    """
    When I run the :label admin command with:
      | resource | user             |
      | name     | <%= user.name %> |
      | key_val  | tag=golden       |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :label admin command with:
      | resource | user             |
      | name     | <%= user.name %> |
      | key_val  | tag-             |
    Then the step should succeed
    """
    When I switch to the first user
    Given I create a new project
    Then the step should succeed
    Given I create a new project
    Then the step should fail
    And the output should contain:
      | cannot create more than |

  # @author chuyu@redhat.com
  # @case_id OCP-12050
  @admin
  @destructive
  Scenario: User can not login when identity exists and references to the user which not exist
    Given I have a project
    And I restore user's context after scenario
    Given the "cluster" oauth CRD is restored after scenario
    Given a "htpasswd" file is created with the following lines:
    """
    509119_user:$apr1$8I.ROmAy$1p42pu.ZM5AGBzV4Qcj2d1
    509119_test:$apr1$PGbAOeFj$ImzQ77T1JQu2Gk29mOdZa.
    """
    When I run the :create_secret admin command with:
      | name        | htpass-secret-12050 |
      | secret_type | generic             |
      | from_file   | htpasswd            |
      | n           | openshift-config    |
    Then the step should succeed
    And admin ensure "htpass-secret-12050" secret is deleted from the "openshift-config" project after scenario
    When I run the :patch admin command with:
      | resource      | oauth        |
      | resource_name | cluster      |
      | p             | {"spec":{"identityProviders":[{"name":"htpassidp-12050","mappingMethod":"claim","type":"HTPasswd","htpasswd":{"fileData":{"name":"htpass-secret-12050"}}}]}} |
      | type          | merge        |
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
      | username | 509119_user                 |
      | password | password                    |
    Then the step should succeed
    When I run the :delete admin command with:
      | object_type       | users              |
      | object_name_or_id | 509119_user        |
    Then the step should succeed
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | 509119_user                 |
      | password | password                    |
    Then the step should fail
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | 509119_test                 |
      | password | password                    |
    Then the step should succeed
    Given admin ensures identity "htpassidp-12050:509119_user" is deleted
    Then the step should succeed
    When I run the :delete admin command with:
      | object_type       | users              |
      | object_name_or_id | 509119_test        |
    Then the step should succeed
    Given admin ensures identity "htpassidp-12050:509119_test" is deleted
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-12207
  @admin
  @destructive
  Scenario: User can not login when User exists and references identity which does not reference user
    Given I switch to the first user
    And I restore user's context after scenario
    Given the "cluster" oauth CRD is restored after scenario
    Given a "htpasswd" file is created with the following lines:
    """
    12207_user:$apr1$9C2g1iXq$CrAytA7/asCiU3mrSa.Bj.
    """
    When I run the :create_secret admin command with:
      | name        | htpass-secret-12207 |
      | secret_type | generic             |
      | from_file   | htpasswd            |
      | n           | openshift-config    |
    Then the step should succeed
    And admin ensure "htpass-secret-12207" secret is deleted from the "openshift-config" project after scenario
    When I run the :patch admin command with:
      | resource      | oauth        |
      | resource_name | cluster      |
      | p             | {"spec":{"identityProviders":[{"name":"htpassidp-12207","mappingMethod":"claim","type":"HTPasswd","htpasswd":{"fileData":{"name":"htpass-secret-12207"}}}]}} |
      | type          | merge        |
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
      | username | 12207_user                  |
      | password | password                    |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | identity                   |
      | resource_name | htpassidp-12207:12207_user |
      | p             | {"user": null}             |
    Then the step should succeed
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | 12207_user                  |
      | password | password                    |
    Then the step should fail
    And I register clean-up steps:
      """
      Given I run the :delete admin command with:
        | object_type       | user       |
        | object_name_or_id | 12207_user |
      Then the step should succeed
      """
    Given admin ensures identity "htpassidp-12207:12207_user" is deleted
    Then the step should succeed

  # @author chuyu@redhat.com
  # @case_id OCP-12146
  @admin
  @destructive
  Scenario: User can not login when identity exists and references to the user which not point back to identity
    Given I switch to the first user
    And I restore user's context after scenario
    Given the "cluster" oauth CRD is restored after scenario
    Given a "htpasswd" file is created with the following lines:
    """
    12146_user:$apr1$pEQr3zF4$I9I3T.FQ1V8fbq58Rg.pL.
    """
    When I run the :create_secret admin command with:
      | name        | htpass-secret-12146 |
      | secret_type | generic             |
      | from_file   | htpasswd            |
      | n           | openshift-config    |
    Then the step should succeed
    And admin ensure "htpass-secret-12146" secret is deleted from the "openshift-config" project after scenario
    When I run the :patch admin command with:
      | resource      | oauth        |
      | resource_name | cluster      |
      | p             | {"spec":{"identityProviders":[{"name":"htpassidp-12146","mappingMethod":"claim","type":"HTPasswd","htpasswd":{"fileData":{"name":"htpass-secret-12146"}}}]}} |
      | type          | merge        |
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
      | username | 12146_user                  |
      | password | password                    |
    Then the step should succeed
    When I run the :patch admin command with:
      | resource      | user                 |
      | resource_name | 12146_user           |
      | p             | {"identities": null} |
    Then the step should succeed
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | 12146_user                  |
      | password | password                    |
    Then the step should fail
    And I register clean-up steps:
      """
      Given I run the :delete admin command with:
        | object_type       | user       |
        | object_name_or_id | 12146_user |
      Then the step should succeed
      """
    Given admin ensures identity "htpassidp-12146:12146_user" is deleted
    Then the step should succeed

  # @author haowang@redhat.com
  # @case_id OCP-17499
  @admin
  @destructive
  Scenario: Deploy with multiple hooks of quota 3.9
    Given the master version >= "3.9"
    Given the user has all owned resources cleaned
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        ClusterResourceOverride:
          configuration:
            apiVersion: v1
            kind: ClusterResourceOverrideConfig
            limitCPUToMemoryPercent: 200
            cpuRequestToLimitPercent: 6
            memoryRequestToLimitPercent: 60
    """
    Given the master service is restarted on all master nodes

    Given I have a project
    Given I obtain test data file "limits/tc534581/limits.yaml"
    When I run the :create admin command with:
      | f | limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I obtain test data file "quota/quota-terminating.yaml"
    And I replace lines in "quota-terminating.yaml":
      | pods: "4" | pods: "2" |
    And I run the :create admin command with:
      | f | quota-terminating.yaml |
      | n | <%= project.name %>    |
    Then the step should succeed

    Given I obtain test data file "deployment/dc-with-pre-mid-post.yaml"
    When I run the :create client command with:
      | f | dc-with-pre-mid-post.yaml |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :rollout_latest client command with:
      | resource | dc/hooks |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete

  # @author haowang@redhat.com
  # @case_id OCP-17497
  @admin
  @destructive
  Scenario: Deploy with quota of 1 terminating pod 3.9
    Given the master version >= "3.9"
    Given the user has all owned resources cleaned
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        ClusterResourceOverride:
          configuration:
            apiVersion: v1
            kind: ClusterResourceOverrideConfig
            limitCPUToMemoryPercent: 200
            cpuRequestToLimitPercent: 6
            memoryRequestToLimitPercent: 60
    """
    Given the master service is restarted on all master nodes
    Given I have a project
    Given I obtain test data file "limits/tc534581/limits.yaml"
    When I run the :create admin command with:
      | f | limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I obtain test data file "quota/quota-terminating.yaml"
    And I replace lines in "quota-terminating.yaml":
      | pods: "4" | pods: "1" |
    And I run the :create admin command with:
      | f | quota-terminating.yaml |
      | n | <%= project.name %>    |
    Then the step should succeed

    When I run the :new_app client command with:
      | docker_image   | <%= project_docker_repo %>openshift/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete
    When I run the :rollout_latest client command with:
      | resource | dc/deployment-example |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete

  # @author scheng@redhat.com
  # @case_id OCP-15816
  @admin
  Scenario: accessTokenMaxAgeSeconds in oauthclient could not be set to other than positive integer number
    When I run the :patch admin command with:
      | resource      | oauthclient                         |
      | resource_name | openshift-browser-client            |
      | p             | {"accessTokenMaxAgeSeconds": abcde} |
    Then the step should fail
    And the output should contain "invalid character 'a' looking for beginning of value"
    When I run the :patch admin command with:
      | resource      | oauthclient                          |
      | resource_name | openshift-browser-client             |
      | p             | {"accessTokenMaxAgeSeconds": !@#$$%# |
    Then the step should fail
    And the output should contain "invalid character '!' looking for beginning of value"
    When I run the :patch admin command with:
      | resource      | oauthclient                          |
      | resource_name | openshift-browser-client             |
      | p             | {"accessTokenMaxAgeSeconds": 12.345} |
    Then the step should fail
    And the output should contain "cannot convert float64 to int32"
