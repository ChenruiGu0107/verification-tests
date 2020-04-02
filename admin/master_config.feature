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
  # @case_id OCP-11265
  @admin
  @destructive
  Scenario: User can configure a password identity provider with special characters in the name
    Given I have a project
    Given I have LDAP service in my project

    When I execute on the pod:
      | bash |
      | -c   |
      | curl -Ss <%= BushSlicer::HOME %>/features/tierN/testdata/admin/tc521728_add_user_to_ldap.ldif \| ldapadd -h 127.0.0.1 -p 389 -D cn=Manager,dc=example,dc=com -w admin |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "my idp #2?"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: true
          url: "ldap://<%= cb.ldap_pod.ip %>/dc=example,dc=com?uid"
    """
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | user                        |
      | password | password                    |
      | skip_tls_verify | true                 |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | users        |
    Then the step should succeed
    And the output should contain:
      | NAME       | user		    |
      | FULL NAME  | openshift user	    |
      | IDENTITIES | my idp #2?:uid=user,dc=example,dc=com |
    When I run the :get admin command with:
      | resource | identity    |
    Then the step should succeed
    And the output should contain:
      | NAME       | my idp #2?:uid=user,dc=example,dc=com |

  # @author yinzhou@redhat.com
  # @case_id OCP-10955
  @admin
  @destructive
  Scenario: Deploy with multiple hooks of quota
    Given the user has all owned resources cleaned
    Given master config is merged with the following hash:
    """
    kubernetesMasterConfig:
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
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/limits/tc534581/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I download a file from "<%= BushSlicer::HOME %>/features/tierN/testdata/quota/quota-terminating.yaml"
    And I replace lines in "quota-terminating.yaml":
      | pods: "4" | pods: "2" |
    And I run the :create admin command with:
      | f | quota-terminating.yaml |
      | n | <%= project.name %>    |
    Then the step should succeed

    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/dc-with-pre-mid-post.yaml |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete
    When I run the :deploy client command with:
      | deployment_config | hooks |
      | latest            |       |
    Then the step should succeed
    And I wait until the status of deployment "hooks" becomes :complete

  # @author yinzhou@redhat.com
  # @case_id OCP-11358
  @admin
  @destructive
  Scenario: Deploy with quota of 1 terminating pod
    Given the user has all owned resources cleaned
    Given master config is merged with the following hash:
    """
    kubernetesMasterConfig:
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
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/limits/tc534581/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I download a file from "<%= BushSlicer::HOME %>/features/tierN/testdata/quota/quota-terminating.yaml"
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
    When I run the :deploy client command with:
      | deployment_config | deployment-example |
      | latest            |                    |
    Then the step should succeed
    And I wait until the status of deployment "deployment-example" becomes :complete

  # @author chuyu@redhat.com
  # @case_id OCP-10792
  @admin
  @destructive
  Scenario: Configure openshift to consume extended identity attributes from auth proxy
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - name: my_request_header_provider
        challenge: true
        login: true
        mappingMethod: claim
        provider:
          apiVersion: v1
          kind: RequestHeaderIdentityProvider
          challengeURL: "https://www.example.com/challenging-proxy/oauth/authorize?${query}"
          loginURL: "https://www.example.com/login-proxy/oauth/authorize?${query}"
          headers:
          - X-Remote-User
          - SSO-User
          emailHeaders:
          - X-Remote-User-Email
          nameHeaders:
          - X-Remote-User-Display-Name
          preferredUsernameHeaders:
          - X-Remote-User-Login
    """
    Given the master service is restarted on all master nodes
    And I select a random node's host
    When I run commands on the host:
      | curl <%= env.api_endpoint_url %>/oauth/authorize?response_type=token\&client_id=openshift-challenging-client -H "SSO-User: email" -H "X-Remote-User-Email: email@redhat.com" -k -I |
    Then the step should succeed
    And the output should contain:
      | Location:     |
      | Set-Cookie:   |
      | Content-Type: |
    When I run the :get admin command with:
      | resource      | identity |
      | o             | yaml     |
    Then the step should succeed
    And the output should contain "email: email@redhat.com"
    When I run commands on the host:
      | curl <%= env.api_endpoint_url %>/oauth/authorize?response_type=token\&client_id=openshift-challenging-client -H "SSO-User: display" -H "X-Remote-User-Display-Name: display user" -k -I |
    Then the step should succeed
    And the output should contain:
      | Location:     |
      | Set-Cookie:   |
      | Content-Type: |
    When I run the :get admin command with:
      | resource      | users    |
    Then the step should succeed
    And the output should contain:
      | FULL NAME     | display user                       |
      | IDENTITIES    | my_request_header_provider:display |
    When I run the :get admin command with:
      | resource      | identity |
    Then the step should succeed
    And the output should contain:
      | NAME          | my_request_header_provider:display |
      | USER NAME     | display                            |
    When I run commands on the host:
      | curl <%= env.api_endpoint_url %>/oauth/authorize?response_type=token\&client_id=openshift-challenging-client -H "SSO-User: testlogin" -H "X-Remote-User-Login: login" -k -I |
    Then the step should succeed
    And the output should contain:
      | Location:     |
      | Set-Cookie:   |
      | Content-Type: |
    When I run the :get admin command with:
      | resource      | users    |
    Then the step should succeed
    And the output should contain:
      | NAME          | login                                |
      | IDENTITIES    | my_request_header_provider:testlogin |
    When I run the :get admin command with:
      | resource      | identity |
    Then the step should succeed
    And the output should contain:
      | NAME          | my_request_header_provider:testlogin |
      | USER NAME     | login                                |

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
  # @case_id OCP-11530
  @admin
  @destructive
  Scenario: User can login if and only if user and identity exist and reference to correct user or identity for provision strategy lookup
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | 509116_user                 |
      | password | password                    |
    Then the step should fail
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        mappingMethod: lookup
        name: anypassword
        provider:
          apiVersion: v1
          kind: AllowAllPasswordIdentityProvider
    """
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | 509116_user                 |
      | password | password                    |
    Then the step should fail
    Given I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/admin/tc509116/tc509116_user.json |
    Then the step should succeed
    And I register clean-up steps:
      """
      Given I run the :delete admin command with:
        | object_type       | user        |
        | object_name_or_id | 509116_user |
      Then the step should succeed
      """
    Given I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/admin/tc509116/tc509116_identity.json |
    Then the step should succeed
    And I register clean-up steps:
      """
      Given I run the :delete admin command with:
        | object_type       | identity                |
        | object_name_or_id | anypassword:509116_user |
      Then the step should succeed
      """
    Given I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/admin/tc509116/tc509116_useridentitymapping.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource   | projects |
    Then the step should succeed
    When I run the :get admin command with:
     | resource | users                        |
    Then the step should succeed
    And the output should contain:
     | NAME       | 509116_user                |

  # @author chuyu@redhat.com
  # @case_id OCP-10594
  @admin
  @destructive
  Scenario: The client certificate validation should be optional
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - name: my_request_header_provider
        challenge: false
        login: false
        provider:
          apiVersion: v1
          kind: RequestHeaderIdentityProvider
          headers:
          - X-Remote-User
          - SSO-User
    """
    Given the master service is restarted on all master nodes
    And I select a random node's host
    When I run commands on the host:
      | curl <%= env.api_endpoint_url %>/oauth/authorize?response_type=token\&client_id=openshift-challenging-client -H "SSO-User: admin" -k -I |
    Then the step should succeed
    And the output should contain:
      | Cache-Control: no-cache |
      | access_token=           |
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - name: my_request_header_provider
        challenge: false
        login: false
        provider:
          apiVersion: v1
          kind: RequestHeaderIdentityProvider
          clientCA: ca.crt
          headers:
          - X-Remote-User
          - SSO-User
    """
    Given the master service is restarted on all master nodes
    And I select a random node's host
    When I run commands on the host:
      | curl <%= env.api_endpoint_url %>/oauth/authorize?response_type=token\&client_id=openshift-challenging-client -H "SSO-User: admin" -k -I |
    Then the step should succeed
    And the output should contain:
      | error=access_denied&error_description=The+resource+owner+or+authorization+server+denied+the+request |
    Given I use the first master host
    And I run commands on the host:
      | curl <%= env.api_endpoint_url %>/oauth/authorize?response_type=token\&client_id=openshift-challenging-client -H "SSO-User: admin" --cacert /etc/origin/master/ca.crt --cert /etc/origin/master/admin.crt --key /etc/origin/master/admin.key -k -I |
    Then the step should succeed
    And the output should contain:
      | Cache-Control: no-cache |
      | access_token=           |

  # @author yinzhou@redhat.com
  # @case_id OCP-12155
  @admin
  @destructive
  Scenario: Apply an external file in config file
    Given the user has all owned resources cleaned
    And I use the first master host
    When I run commands on the host:
      | echo -n "password" >/etc/origin/master/bindassword.txt |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "testldap"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "cn=read-only-admin,dc=example,dc=com"
          bindPassword:
            file: /etc/origin/master/bindassword.txt
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: true
          url: "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
    """
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | newton                      |
      | password | password                    |
      | skip_tls_verify | true                 |
    Then the step should succeed
    Given I use the first master host
    When I run commands on the host:
      | oc get users |
    And the output should contain:
      | NAME       | newton		                    |
      | FULL NAME  | Isaac Newton	                    |
      | IDENTITIES | testldap:uid=newton,dc=example,dc=com |


  # @author yinzhou@redhat.com
  # @case_id OCP-12261
  @admin
  @destructive
  Scenario: Apply env var in the config file
    Given the user has all owned resources cleaned
    And I use the first master host
    And master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "testldap"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "cn=read-only-admin,dc=example,dc=com"
          bindPassword:
            env: BIND_PASSWORD_ENV_VAR_NAME
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: true
          url: "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
    """
    When I run commands on the host:
      | echo "BIND_PASSWORD_ENV_VAR_NAME=password" >> /etc/sysconfig/atomic-openshift-master |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run commands on the host:
      | sed -i '/^BIND_PASSWORD_ENV_VAR_NAME*/d' /etc/sysconfig/atomic-openshift-master |
    Then the step should succeed
    """
    Given the master service is restarted on all master nodes
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | newton                      |
      | password | password                    |
      | skip_tls_verify | true                 |
    Then the step should succeed
    Given I use the first master host
    When I run commands on the host:
      | oc get users |
    And the output should contain:
      | NAME       | newton		                    |
      | FULL NAME  | Isaac Newton	                    |
      | IDENTITIES | testldap:uid=newton,dc=example,dc=com  |

  # @author chuyu@redhat.com
  # @case_id OCP-9796
  @admin
  @destructive
  Scenario: Configure projectrequestlimit to invalid specific number
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginOrderOverride:
      - ProjectRequestLimit
      pluginConfig:
        ProjectRequestLimit:
          configuration:
            apiVersion: v1
            kind: ProjectRequestLimitConfig
            limits:
            - selector:
                admin: "true"
              maxProjects: -1
    """
    Given I try to restart the master service on all master nodes
    Then the step should fail
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginOrderOverride:
      - ProjectRequestLimit
      pluginConfig:
        ProjectRequestLimit:
          configuration:
            apiVersion: v1
            kind: ProjectRequestLimitConfig
            limits:
            - selector:
                admin: "true"
              maxProjects: 1.23
    """
    Given I try to restart the master service on all master nodes
    Then the step should fail
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginOrderOverride:
      - ProjectRequestLimit
      pluginConfig:
        ProjectRequestLimit:
          configuration:
            apiVersion: v1
            kind: ProjectRequestLimitConfig
            limits:
            - selector:
                admin: "true"
              maxProjects: -2.3
    """
    Given I try to restart the master service on all master nodes
    Then the step should fail

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
  # @case_id OCP-11080
  @admin
  @destructive
  Scenario: Error message should be shown up on startup stage when assertConfig.publicURL is different with oauthConfig.assertpublicURL
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/con/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        mappingMethod: claim
        name: anypassword
        provider:
          apiVersion: v1
          kind: AllowAllPasswordIdentityProvider
    """
    Given I try to restart the master service on all master nodes
    Then the step should fail

  # @author chuyu@redhat.com
  # @case_id OCP-11146
  @admin
  @destructive
  Scenario: openshift can not start when give invalid arguments for ldap authentication
  Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/con/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "testldap"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "cn=read-only-admin,dc=example,dc=com"
          bindPassword: "password"
          ca: inexist.crt
          kind: LDAPPasswordIdentityProvider
          insecure: false
          url: "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
    """
    Given I try to restart the master service on all master nodes
    Then the step should fail
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/con/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "testldap"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "cn=read-only-admin,dc=example,dc=com"
          bindPassword: "password"
          ca: ca.key
          kind: LDAPPasswordIdentityProvider
          insecure: false
          url: "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
    """
    Given I try to restart the master service on all master nodes
    Then the step should fail
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/con/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "testldap"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "cn=read-only-admin,dc=example,dc=com"
          bindPassword: "password"
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: true
          url: "ldaps://ldap.forumsys.com/dc=example,dc=com?uid"
    """
    Given I try to restart the master service on all master nodes
    Then the step should fail
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/con/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "testldap"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: ""
          bindPassword: "password"
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: false
          url: "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
    """
    Given I try to restart the master service on all master nodes
    Then the step should fail
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/con/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "testldap"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "cn=read-only-admin,dc=example,dc=com"
          bindPassword: ""
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: false
          url: "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
    """
    Given I try to restart the master service on all master nodes
    Then the step should fail
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/con/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "testldap"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id: null
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "cn=read-only-admin,dc=example,dc=com"
          bindPassword: "password"
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: false
          url: "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
    """
    Given I try to restart the master service on all master nodes
    Then the step should fail

  # @author yinzhou@redhat.com
  # @case_id OCP-10831
  @admin
  @destructive
  Scenario: Apply a noexist file in the OpenShift config file
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "testldap"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "cn=read-only-admin,dc=example,dc=com"
          bindPassword:
            file: /etc/origin/master/bindasswordnoexist.txt
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: true
          url: "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
    """
    Given I try to restart the master service on all master nodes
    Then the step should fail

    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "testldap"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "cn=read-only-admin,dc=example,dc=com"
          bindPassword:
            file: /etc/origin/master/bindPasswordnoexist.encrypted
            keyFile: /etc/origin/master/bindPasswordnoexist.key
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: true
          url: "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
    """
    Given I try to restart the master service on all master nodes
    Then the step should fail

  # @author yinzhou@redhat.com
  # @case_id OCP-11581
  @admin
  @destructive
  Scenario: Apply an encrypted file in OpenShift config file
    Given the user has all owned resources cleaned
    And I use the first master host
    When I run commands on the host:
      | echo -n "password" >/etc/origin/master/bindassword.txt                                                                                                 |
      | cat /etc/origin/master/bindassword.txt \| oadm ca encrypt --genkey=/etc/origin/master/bindPassword.key --out=/etc/origin/master/bindPassword.encrypted |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "testldap"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "cn=read-only-admin,dc=example,dc=com"
          bindPassword:
            file: /etc/origin/master/bindPassword.encrypted
            keyFile: /etc/origin/master/bindPassword.key
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: true
          url: "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
    """
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | newton                      |
      | password        | password                    |
      | skip_tls_verify | true                        |
    Then the step should succeed
    Given I use the first master host
    When I run commands on the host:
      | oc get users |
    And the output should contain:
      | NAME       | newton                                 |
      | FULL NAME  | Isaac Newton                           |
      | IDENTITIES | testldap:uid=newton,dc=example,dc=com  |

  # @author yinzhou@redhat.com
  # @case_id OCP-12323
  @admin
  @destructive
  Scenario: Could only specify one env and file in the OpenShift config
    Given the user has all owned resources cleaned
    And I use the first master host
    And the "/etc/sysconfig/atomic-openshift-master" file is restored on host after scenario
    And master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "testldap"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "cn=read-only-admin,dc=example,dc=com"
          bindPassword:
            env: BIND_PASSWORD_ENV_VAR_NAME
            env: BIND_PASSWORD_ENV_VAR_NAME1
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: true
          url: "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
    """
    When I run commands on the host:
      | echo "BIND_PASSWORD_ENV_VAR_NAME=password" >> /etc/sysconfig/atomic-openshift-master   |
      | echo "BIND_PASSWORD_ENV_VAR_NAME1=password1" >> /etc/sysconfig/atomic-openshift-master |
    Then the step should succeed
    Given the master service is restarted on all master nodes
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | newton                      |
      | password | password                    |
      | skip_tls_verify | true                 |
    Then the step should fail

  # @author xiuwang@redhat.com
  # @case_id OCP-11383
  @admin
  @destructive
  Scenario: Allow set Annotation with BuildDefaults and BuildOverrides admission plugin
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            env: []
            kind: BuildDefaultsConfig
            annotations:
              key1: value1
              key2: value2
            resources:
              limits: {}
              requests: {}
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :new_build client command with:
      | image_stream | openshift/ruby:latest                |
      | app_repo     | https://github.com/sclorg/ruby-ex |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    When the "ruby-ex-1" build becomes :running
    Then the expression should be true> pod("ruby-ex-1-build").annotation("key1", user: user) == "value1"
    And  the expression should be true> pod("ruby-ex-1-build").annotation("key2", user: user) == "value2"
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            env: []
            kind: BuildDefaultsConfig
            annotations:
              key1: value1
              key2: value2
            resources:
              limits: {}
              requests: {}
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
            annotations:
              key1: value3
              key2: value4
    """
    And the master service is restarted on all master nodes
    When I run the :start_build client command with:
      | buildconfig | ruby-ex |
    Then the step should succeed
    And the "ruby-ex-2" build was created
    When the "ruby-ex-2" build becomes :running
    Then the expression should be true> pod("ruby-ex-2-build").annotation("key1", user: user) == "value3"
    And  the expression should be true> pod("ruby-ex-2-build").annotation("key2", user: user) == "value4"

  # @author xiuwang@redhat.com
  # @case_id OCP-14102
  @admin
  @destructive
  Scenario: Set env vars via build defaults
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            env:
            - name: FOO
              value: bar
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :new_build client command with:
      | image_stream | openshift/ruby:latest                |
      | app_repo     | https://github.com/sclorg/ruby-ex |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    When the "ruby-ex-1" build becomes :running
    When evaluation of `YAML.load pod("ruby-ex-1-build").env_var("BUILD", user: user)` is stored in the :build clipboard
    Then the expression should be true> cb.build.dig("spec", "strategy", "sourceStrategy", "env", 0, "name") == "FOO"
    Then the expression should be true> cb.build.dig("spec", "strategy", "sourceStrategy", "env", 0, "value") == "bar"
    When I run the :start_build client command with:
      | buildconfig | ruby-ex  |
      | env         | FOO=test |
    Then the step should succeed
    And the "ruby-ex-2" build was created
    When the "ruby-ex-2" build becomes :running
    When evaluation of `YAML.load pod("ruby-ex-2-build").env_var("BUILD", user: user)` is stored in the :build clipboard
    Then the expression should be true> cb.build.dig("spec", "strategy", "sourceStrategy", "env", 0, "name") == "FOO"
    Then the expression should be true> cb.build.dig("spec", "strategy", "sourceStrategy", "env", 0, "value") == "test"

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
  # @case_id OCP-12190
  @admin
  @destructive
  Scenario: osc login can be prompted messages for how to generate a token with challenge=false for identity provider
    Given I have a project
    And I restore user's context after scenario
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: false
        login: true
        mappingMethod: claim
        name: anypassword
        provider:
          apiVersion: v1
          kind: AllowAllPasswordIdentityProvider
    """
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
    Then the step should fail
    And the output should match "You must obtain an API token by visiting.*oauth/token/request"
    Given master config is restored from backup
    And the master service is restarted on all master nodes

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

  # @author yinzhou@redhat.com
  # @case_id OCP-16448
  @admin
  @destructive
  Scenario: Apply env var in the config file for 3.7
    Given the master version >= "3.7"
    Given the user has all owned resources cleaned
    And I use the first master host
    Given I have a project
    Given I have LDAP service in my project
    When I execute on the pod:
      | bash |
      | -c   |
      | curl -Ss <%= BushSlicer::HOME %>/features/tierN/testdata/admin/tc521728_add_user_to_ldap.ldif \| ldapadd -h 127.0.0.1 -p 389 -D cn=Manager,dc=example,dc=com -w admin |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "my idp #2?"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "uid=user,ou=people,ou=rfc2307,dc=example,dc=com"
          bindPassword:
            env: BIND_PASSWORD_ENV_VAR_NAME
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: true
          url: "ldap://<%= cb.ldap_pod.ip %>/dc=example,dc=com?uid"
    """
    And the "/etc/sysconfig/atomic-openshift-master-controllers" file is restored on host after scenario
    And the "/etc/sysconfig/atomic-openshift-master-api" file is restored on host after scenario
    And the "/etc/origin/master/master.env" file is restored on host after scenario
    When I run commands on the host:
      | echo "BIND_PASSWORD_ENV_VAR_NAME=password" >> /etc/sysconfig/atomic-openshift-master-api         |
      | echo "BIND_PASSWORD_ENV_VAR_NAME=password" >> /etc/sysconfig/atomic-openshift-master-controllers |
      | echo "BIND_PASSWORD_ENV_VAR_NAME=password" >> /etc/origin/master/master.env                      |
    Then the step should succeed
    Given the master service is restarted on all master nodes
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | user                        |
      | password | password                    |
      | skip_tls_verify | true                 |
    Then the step should succeed
    Given I use the first master host
    When I run commands on the host:
      | oc get users |
    And the output should contain:
      | NAME       | user                                   |
      | FULL NAME  | openshift user                         |
      | IDENTITIES | my idp #2?:uid=user,dc=example,dc=com  |

  # @author yinzhou@redhat.com
  # @case_id OCP-16450
  @admin
  @destructive
  Scenario: Could only specify one env and file in the OpenShift config for 3.7
    Given the master version >= "3.7"
    Given the user has all owned resources cleaned
    And I use the first master host
    Given I have a project
    Given I have LDAP service in my project
    When I execute on the pod:
      | bash |
      | -c   |
      | curl -Ss <%= BushSlicer::HOME %>/features/tierN/testdata/admin/tc521728_add_user_to_ldap.ldif \| ldapadd -h 127.0.0.1 -p 389 -D cn=Manager,dc=example,dc=com -w admin |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: "my idp #2?"
        provider:
          apiVersion: v1
          attributes:
            email: null
            id:
            - dn
            name:
            - cn
            preferredUsername:
            - uid
          bindDN: "uid=user,ou=people,ou=rfc2307,dc=example,dc=com"
          bindPassword:
            env: BIND_PASSWORD_ENV_VAR_NAME
            env: BIND_PASSWORD_ENV_VAR_NAME1
          ca: ""
          kind: LDAPPasswordIdentityProvider
          insecure: true
          url: "ldap://<%= cb.ldap_pod.ip %>/dc=example,dc=com?uid"
    """
    And the "/etc/sysconfig/atomic-openshift-master-controllers" file is restored on host after scenario
    And the "/etc/sysconfig/atomic-openshift-master-api" file is restored on host after scenario
    And the "/etc/origin/master/master.env" file is restored on host after scenario
    When I run commands on the host:
      | echo "BIND_PASSWORD_ENV_VAR_NAME=password" >> /etc/sysconfig/atomic-openshift-master-api           |
      | echo "BIND_PASSWORD_ENV_VAR_NAME1=password1" >> /etc/sysconfig/atomic-openshift-master-api         |
      | echo "BIND_PASSWORD_ENV_VAR_NAME=password" >> /etc/sysconfig/atomic-openshift-master-controllers   |
      | echo "BIND_PASSWORD_ENV_VAR_NAME1=password1" >> /etc/sysconfig/atomic-openshift-master-controllers |
      | echo "BIND_PASSWORD_ENV_VAR_NAME=password" >> /etc/origin/master/master.env                        |
      | echo "BIND_PASSWORD_ENV_VAR_NAME1=password1" >> /etc/origin/master/master.env                      |
    Then the step should succeed
    Given the master service is restarted on all master nodes
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | newton                      |
      | password | password                    |
      | skip_tls_verify | true                 |
    Then the step should fail

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
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/limits/tc534581/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I download a file from "<%= BushSlicer::HOME %>/features/tierN/testdata/quota/quota-terminating.yaml"
    And I replace lines in "quota-terminating.yaml":
      | pods: "4" | pods: "2" |
    And I run the :create admin command with:
      | f | quota-terminating.yaml |
      | n | <%= project.name %>    |
    Then the step should succeed

    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/dc-with-pre-mid-post.yaml |
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
    When I run the :create admin command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/limits/tc534581/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I download a file from "<%= BushSlicer::HOME %>/features/tierN/testdata/quota/quota-terminating.yaml"
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

  # @author wzheng@redhat.com
  # @case_id OCP-19027
  @admin
  @destructive
  Scenario: Build keeps pending if set nodeSelector with BuildDefaults admission plugin
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            env: []
            kind: BuildDefaultsConfig
            nodeSelector:
              key1: value1
            resources:
              limits: {}
              requests: {}
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :new_build client command with:
      | image_stream | openshift/ruby:latest                |
      | app_repo     | https://github.com/sclorg/ruby-ex |
    Then the step should succeed
    And the "ruby-ex-1" build was created
    And the "ruby-ex-1" build becomes :pending
    Given 60 seconds have passed
    Then the "ruby-hello-world-1" build status is any of:
      | pending |

  # @author scheng@redhat.com
  # @case_id OCP-17481
  @admin
  Scenario: AccessTokenInactivityTimeoutSeconds should greater than 300s
    When I run the :patch admin command with:
      | resource      | oauthclient                                     |
      | resource_name | openshift-challenging-client                    |
      | p             | {"accessTokenInactivityTimeoutSeconds": 200}    |
    Then the step should fail
    And the output should contain "The minimum valid timeout value is 300 seconds"
    When I run the :patch admin command with:
      | resource      | oauthclient                                       |
      | resource_name | openshift-challenging-client                      |
      | p             | {"accessTokenInactivityTimeoutSeconds": abcde}    |
    Then the step should fail
    And the output should contain "invalid character 'a' looking for beginning of value"
    When I run the :patch admin command with:
      | resource      | oauthclient                                         |
      | resource_name | openshift-challenging-client                        |
      | p             | {"accessTokenInactivityTimeoutSeconds": !@#$$%#}    |
    Then the step should fail
    And the output should contain "invalid character '!' looking for beginning of value"
    When I run the :patch admin command with:
      | resource      | oauthclient                                         |
      | resource_name | openshift-challenging-client                        |
      | p             | {"accessTokenInactivityTimeoutSeconds": 500.123}    |
    Then the step should fail
    And the output should contain "cannot convert float64 to int32"

  # @author scheng@redhat.com
  # @case_id OCP-17482 OCP-17475
  @admin
  @destructive
  Scenario: AccessTokenInactivityTimeoutSeconds will take effective in oauthclient and master-config
    Given the expression should be true> user.password?
    When I run the :patch admin command with:
      | resource      | oauthclient                                     |
      | resource_name | openshift-challenging-client                    |
      | p             | {"accessTokenInactivityTimeoutSeconds": 300}    |
    Then the step should succeed
    Given I register clean-up steps:
    """
    When I run the :patch admin command with:
         | resource      | oauthclient                                   |
         | resource_name | openshift-challenging-client                  |
         | p             | {"accessTokenInactivityTimeoutSeconds": null} |
    """
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | u               | <%= user.name %>            |
      | p               | <%= user.password %>        |
    Then the step should succeed
    And the output should match "Login successful|Logged into"
    When I run the :whoami client command
    Then the step should succeed
    Given 320 seconds have passed
    When I run the :whoami client command
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    oauthConfig:
      tokenConfig:
        accessTokenInactivityTimeoutSeconds: 400
    """
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | u               | <%= user.name %>            |
      | p               | <%= user.password %>        |
    Then the step should succeed
    And the output should match "Login successful|Logged into"
    Given 320 seconds have passed
    When I run the :whoami client command
    Then the step should fail
    When I run the :patch admin command with:
      | resource      | oauthclient                                      |
      | resource_name | openshift-challenging-client                     |
      | p             | {"accessTokenInactivityTimeoutSeconds": null}    |
    Then the step should succeed
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | u               | <%= user.name %>            |
      | p               | <%= user.password %>        |
    Then the step should succeed
    And the output should match "Login successful|Logged into"
    Given 320 seconds have passed
    When I run the :whoami client command
    Then the step should succeed
    Given 450 seconds have passed
    When I run the :whoami client command
    Then the step should fail
    Given master config is merged with the following hash:
    """
    oauthConfig:
      tokenConfig:
        accessTokenInactivityTimeoutSeconds: 0
    """
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | u               | <%= user.name %>            |
      | p               | <%= user.password %>        |
    Then the step should succeed

  # @author scheng@redhat.com
  # @case_id OCP-10713
  @admin
  @destructive
  Scenario: Config provision strategy as "add"
    And I restore user's context after scenario
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        mappingMethod: add
        name: anypassword
        provider:
          apiVersion: v1
          kind: AllowAllPasswordIdentityProvider
    """
    And the master service is restarted on all master nodes
    Given admin ensures "my_htpasswd_provider:user_add" identity is deleted after scenario
    Given admin ensures "anypassword:user_add" identity is deleted after scenario
    Given admin ensures "user_add" user is deleted after scenario
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_add                    |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | user |
    And the output should contain:
      | NAME | anypassword:user_add |
    Then the step should succeed
    And evaluation of `env.master_hosts` is stored in the :hosts clipboard
    Given the "/etc/origin/master/htpasswd.auto" file is restored on all hosts in the clipboard after scenario
    Given I run commands on all masters:
      | echo 'user_add:$apr1$M8uB6lNb$RC0rOu7WZXBa7gdIrX6Zp/' > /etc/origin/master/htpasswd.auto |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - name: my_htpasswd_provider
        challenge: true
        login: true
        mappingMethod: add
        provider:
          apiVersion: v1
          kind: HTPasswdPasswordIdentityProvider
          file: /etc/origin/master/htpasswd.auto
    """
    And the master service is restarted on all master nodes
    Then the step should succeed
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_add                    |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | user |
    And the output should contain:
      | NAME | anypassword:user_add, my_htpasswd_provider:user_add |
    Then the step should succeed

  # @author scheng@redhat.com
  # @case_id OCP-11191 OCP-11756
  @admin
  @destructive
  Scenario: mappingMethod "claim" && "generate"
    And I restore user's context after scenario
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        mappingMethod: claim
        name: anypassword
        provider:
          apiVersion: v1
          kind: AllowAllPasswordIdentityProvider
    """
    And the master service is restarted on all master nodes
    Given admin ensures "my_htpasswd_provider:user_generate" identity is deleted after scenario
    Given admin ensures "anypassword:user_generate" identity is deleted after scenario
    Given admin ensures "user_claim" user is deleted after scenario
    Given admin ensures "user_generate" user is deleted after scenario
    Given admin ensures "user_generate2" user is deleted after scenario
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_claim                  |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should succeed
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_generate               |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should succeed
    When I run the :get admin command with:
      | resource | user |
    And the output should contain:
      | NAME       | anypassword:user_claim |
    Then the step should succeed
    And evaluation of `env.master_hosts` is stored in the :hosts clipboard
    Given the "/etc/origin/master/htpasswd.auto" file is restored on all hosts in the clipboard after scenario
    Given I run commands on all masters:
      | echo 'user_generate:$apr1$sfBMP5Bk$AyYS0JHZLZlDRbzCYO/rH1' > /etc/origin/master/htpasswd.auto |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - name: my_htpasswd_provider
        challenge: true
        login: true
        mappingMethod: generate
        provider:
          apiVersion: v1
          kind: HTPasswdPasswordIdentityProvider
          file: /etc/origin/master/htpasswd.auto
    """
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_generate               |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - name: my_htpasswd_provider
        challenge: true
        login: true
        mappingMethod: claim
        provider:
          apiVersion: v1
          kind: HTPasswdPasswordIdentityProvider
          file: /etc/origin/master/htpasswd.auto
    """
    Given I run commands on all masters:
      | echo 'user_claim:$apr1$DN4V/N8S$3mQX19WKDewfwrhG1arKU1' > /etc/origin/master/htpasswd.auto |
    Then the step should succeed
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_claim                  |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should fail
    When I run the :get admin command with:
      | resource | user |
    And the output should contain:
      | NAME | anypassword:user_claim |
    And I run the :delete admin command with:
      | object_type       | identity               |
      | object_name_or_id | anypassword:user_claim |
    Then the step should succeed
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_claim                  |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should fail

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

  # @author scheng@redhat.com
  # @case_id OCP-15814 OCP-15815
  @admin
  @destructive
  Scenario: The accessTokenMaxAgeSeconds will take effective in Oauthclient and master-config
    And I restore user's context after scenario
    Given admin ensures "anypassword:age_test" identity is deleted after scenario
    Given admin ensures "age_test" user is deleted after scenario
    Given the "openshift-challenging-client" oauth client is recreated after scenario
    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        mappingMethod: claim
        name: anypassword
        provider:
          apiVersion: v1
          kind: AllowAllPasswordIdentityProvider
    """
    When I run the :patch admin command with:
      | resource      | oauthclient                        |
      | resource_name | openshift-challenging-client       |
      | p             | {"accessTokenMaxAgeSeconds": null} |
    Given master config is merged with the following hash:
    """
    oauthConfig:
      tokenConfig:
        accessTokenMaxAgeSeconds: 100
        authorizeTokenMaxAgeSeconds: 500
    """
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | age_test                    |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should succeed
    And the output should match "Login successful|Logged into"
    Given 50 seconds have passed
    When I run the :whoami client command
    Then the step should succeed
    Given 120 seconds have passed
    When I run the :whoami client command
    Then the step should fail
    When I run the :patch admin command with:
      | resource      | oauthclient                      |
      | resource_name | openshift-challenging-client     |
      | p             | {"accessTokenMaxAgeSeconds": 30} |
    Then the step should succeed
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | age_test                    |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should succeed
    And the output should match "Login successful|Logged into"
    When I run the :whoami client command
    Then the step should succeed
    Given 50 seconds have passed
    When I run the :whoami client command
    Then the step should fail

  # @author scheng@redhat.com
  # @case_id OCP-12448
  @admin
  @destructive
  Scenario: check authentication via htpasswd file
    Given I restore user's context after scenario
    And admin ensures "OCP12448_htpasswd:user_bcrypt" identity is deleted after scenario
    And admin ensures "OCP12448_htpasswd:user_default" identity is deleted after scenario
    And admin ensures "OCP12448_htpasswd:user_md5" identity is deleted after scenario
    And admin ensures "OCP12448_htpasswd:user_sha" identity is deleted after scenario
    And admin ensures "OCP12448_htpasswd:user_crypt" identity is deleted after scenario
    And admin ensures "OCP12448_htpasswd:user_plain" identity is deleted after scenario
    And admin ensures "user_crypt" user is deleted after scenario
    And admin ensures "user_plain" user is deleted after scenario
    And admin ensures "user_bcrypt" user is deleted after scenario
    And admin ensures "user_default" user is deleted after scenario
    And admin ensures "user_md5" user is deleted after scenario
    And admin ensures "user_sha" user is deleted after scenario

    Given master config is merged with the following hash:
    """
    oauthConfig:
      assetPublicURL: <%= env.api_endpoint_url %>/console/
      grantConfig:
        method: auto
      identityProviders:
      - name: OCP12448_htpasswd
        challenge: true
        login: true
        mappingMethod: claim
        provider:
          apiVersion: v1
          kind: HTPasswdPasswordIdentityProvider
          file: /etc/origin/master/htpasswd.enc
    """
    And evaluation of `env.master_hosts` is stored in the :hosts clipboard
    Given the "/etc/origin/master/htpasswd.enc" file is restored on all hosts in the clipboard after scenario
    Given I run commands on all masters:
      | echo 'user_default:$apr1$Dczb9VVj$eNT3WL8h4T2rPKD1ixBWE.' > /etc/origin/master/htpasswd.enc |
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_default                |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should succeed
    Given I run commands on all masters:
      | echo 'user_md5:$apr1$019ePuy4$7Hw/RzIQqNy5xmj3uv8xQ.' > /etc/origin/master/htpasswd.enc |
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_md5                    |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should succeed
    Given I run commands on all masters:
      | echo 'user_bcrypt:$2y$05$3LEJaT9wtLE0a1B8vpq.yeJRKpjF2yt70RyvunR3RqIDl51v5X/nW' > /etc/origin/master/htpasswd.enc |
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_bcrypt                 |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should succeed
    Given I run commands on all masters:
      | echo 'user_crypt:n7L.ka5Hv86VA' > /etc/origin/master/htpasswd.enc |
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_crypt                  |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should fail
    Given I run commands on all masters:
      | echo 'user_sha:{SHA}PHZ8Qa+xKtoUAZDtgts/2TDi76M=' > /etc/origin/master/htpasswd.enc |
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_sha                    |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should succeed
    Given I run commands on all masters:
      | echo 'user_plain:redhat' > /etc/origin/master/htpasswd.enc |
    When I run the :login client command with:
      | server          | <%= env.api_endpoint_url %> |
      | username        | user_plain                  |
      | password        | redhat                      |
      | skip_tls_verify | true                        |
    Then the step should fail

  # @author xiuwang@redhat.com
  # @case_id OCP-10972
  @destructive
  @admin
  Scenario: Add arbitrary labels to docker images via default/overides-buildconfig
    Given I have a project
    Given default docker-registry route is stored in the :registry_hostname clipboard
    And I have a skopeo pod in the project
    Given I find a bearer token of the deployer service account
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            env: []
            kind: BuildDefaultsConfig
            imageLabels:
            - name: pineapple
              value: default-more-yummy
            resources:
              limits: {}
              requests: {}
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
    """
    And the master service is restarted on all master nodes
    When I run the :new_build client command with:
      | app_repo     | https://github.com/openshift/ruby-hello-world.git |
      | image_stream | ruby                                              |
    Then the step should succeed
    Then the "ruby-hello-world-1" build was created
    And the "ruby-hello-world-1" build completed
    When I execute on the pod:
      | skopeo             |
      | --debug            |
      | --insecure-policy  |
      | inspect            |
      | --tls-verify=false |
      | --creds            |
      | dnm:<%= service_account.cached_tokens.first %>                                   |
      | docker://<%= cb.registry_hostname %>/<%= project.name %>/ruby-hello-world:latest |
    And the output should match:
      | pineapple.*default-more-yummy |
    Then the step should succeed

    When I run the :patch client command with:
      | resource      | bc               |
      | resource_name | ruby-hello-world |
      | p             | {"spec":{"output":{"imageLabels":[{"name":"pineapple","value":"soyummy"}]}}} |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    Then the "ruby-hello-world-2" build was created
    And the "ruby-hello-world-2" build completed
    When I execute on the pod:
      | skopeo             |
      | --debug            |
      | --insecure-policy  |
      | inspect            |
      | --tls-verify=false |
      | --creds            |
      | dnm:<%= service_account.cached_tokens.first %>                                   |
      | docker://<%= cb.registry_hostname %>/<%= project.name %>/ruby-hello-world:latest |
    And the output should match:
      | pineapple.*soyummy |
    And the output should not contain "default-more-yummy"
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            env: []
            kind: BuildDefaultsConfig
            imageLabels:
            - name: pineapple
              value: default-more-yummy
            resources:
              limits: {}
              requests: {}
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
            imageLabels:
            - name: pineapple
              value: override-more-yummy
    """
    And the master service is restarted on all master nodes
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    Then the "ruby-hello-world-3" build was created
    And the "ruby-hello-world-3" build completed
    When I execute on the pod:
      | skopeo             |
      | --debug            |
      | --insecure-policy  |
      | inspect            |
      | --tls-verify=false |
      | --creds            |
      | dnm:<%= service_account.cached_tokens.first %>                                   |
      | docker://<%= cb.registry_hostname %>/<%= project.name %>/ruby-hello-world:latest |
    And the output should match:
      | pineapple.*override-more-yummy |

  # @author xiuwang@redhat.com
  # @case_id OCP-10992
  @destructive
  @admin
  Scenario: Allow for a separate set of build nodes via node selectors
    Given I have a project
    And environment has at least 2 schedulable nodes
    Given I store the ready and schedulable nodes in the clipboard
    And label "label=test1" is added to the "<%= cb.nodes[0].name %>" node
    And label "label=test2" is added to the "<%= cb.nodes[1].name %>" node

    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            env: []
            kind: BuildDefaultsConfig
            nodeSelector:
              label: test1
            resources:
              limits: {}
              requests: {}
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
    """
    And the master service is restarted on all master nodes
    When I run the :new_build client command with:
      | app_repo | https://github.com/sclorg/rails-ex |
    Then the step should succeed
    When the pod named "rails-ex-1-build" becomes present
    Then the expression should be true> pod("rails-ex-1-build").nodeselector["label"] == "test1"

    When I run the :cancel_build client command with:
      | build_name | rails-ex-1 |
    Then the step should succeed
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            env: []
            kind: BuildDefaultsConfig
            nodeSelector:
              label: test1
            resources:
              limits: {}
              requests: {}
        BuildOverrides:
          configuration:
            apiVersion: v1
            kind: BuildOverridesConfig
            nodeSelector:
              label: test2
    """
    And the master service is restarted on all master nodes
    When I run the :start_build client command with:
      | buildconfig | rails-ex |
    Then the step should succeed
    When the pod named "rails-ex-2-build" becomes present
    Then the expression should be true> pod("rails-ex-2-build").nodeselector["label"] == "test2"

  # @author geliu@redhat.com
  # @case_id OCP-16416
  @destructive
  @admin
  Scenario: Central Audit Capability
    Given I have a project
    And I use the first master host
    And the "/etc/origin/master/audit-policy.yaml" file is restored on host after scenario
    And the "/etc/origin/master/audit-ocp.log" file is restored on host after scenario
    When I run commands on the host:
      | echo "apiVersion: audit.k8s.io/v1beta1" >/etc/origin/master/audit-policy.yaml  |
      | echo "kind: Policy" >>/etc/origin/master/audit-policy.yaml                     |
      | echo "rules:" >>/etc/origin/master/audit-policy.yaml                           |
      | echo "  - level: Metadata" >>/etc/origin/master/audit-policy.yaml              |
    Given master config is merged with the following hash:
    """
    auditConfig:
      auditFilePath: "/etc/origin/master/audit-ocp.log"
      enabled: true
      maximumFileRetentionDays: 10
      maximumFileSizeMegabytes: 10
      maximumRetainedFiles: 10
      logFormat: json
      policyConfiguration: null
      policyFile: "/etc/origin/master/audit-policy.yaml"
      webHookKubeConfig: ""
      webHookMode: ""       
    """
    And the master service is restarted on all master nodes
    And I run commands on the host:
      | cat /etc/origin/master/audit-ocp.log |
    Then the step should succeed
    And the output should contain:
      | audit.k8s.io |
  
  # @author xiuwang@redhat.com
  @destructive
  @admin
  Scenario Outline: Resource limits for s2i/docker build pods
    Given I have a project
    Given master config is merged with the following hash:
    """
    admissionConfig:
      pluginConfig:
        BuildDefaults:
          configuration:
            apiVersion: v1
            env: []
            kind: BuildDefaultsConfig
            resources:
              limits:
                cpu: "400m"
                memory: "300Mi"
              requests:
                cpu: "300m"
                memory: "280Mi"
    """
    And the master service is restarted on all master nodes
    When I run the :new_build client command with:
       | app_repo | <repo> |
    Then the step should succeed
    When the pod named "ruby-hello-world-1-build" becomes present
    When I run the :describe client command with:
      | resource | pod                      |
      | name     | ruby-hello-world-1-build |
    Then the output should match:
      | Limits:        |
      | cpu:\s+400m    |
      | memory:\s+300Mi|
      | Requests:      |
      | cpu:\s+300m    |
      | memory:\s+280Mi|
    Given I run the :patch client command with:
      | resource      | buildconfig      |
      | resource_name | ruby-hello-world |
      | p             | {"spec":{"resources":{"limits":{"cpu":"600m","memory":"480Mi"},"requests":{"cpu":"200m","memory":"200Mi"}}}}|
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | ruby-hello-world |
    Then the step should succeed
    When the pod named "ruby-hello-world-2-build" becomes present
    When I run the :describe client command with:
      | resource | pod                      |
      | name     | ruby-hello-world-2-build |
    Then the output should match:
      | Limits:        |
      | cpu:\s+600m    |
      | memory:\s+480Mi|
      | Requests:      |
      | cpu:\s+200m    |
      | memory:\s+200Mi|

    Examples:
      | repo                                                   |
      | ruby~https://github.com/openshift/ruby-hello-world.git | # @case_id OCP-15943
      | https://github.com/openshift/ruby-hello-world.git      | # @case_id OCP-11022

  # @author geliu@redhat.com
  # @case_id OCP-10852
  @destructive
  @admin
  Scenario: Check logs for basic audit capability	
    Given I have a project
    And I use the first master host
    And the "/etc/origin/master/audit-ocp.log" file is restored on host after scenario
    Given master config is merged with the following hash:
    """
    auditConfig:
      auditFilePath: "/etc/origin/master/audit-ocp.log" 
      enabled: true
      logFormat: legacy
      maximumFileRetentionDays: 10
      maximumFileSizeMegabytes: 10
      maximumRetainedFiles: 10
    """
    And the master service is restarted on all master nodes
    And I run commands on the host:
      | cat /etc/origin/master/audit-ocp.log |
    Then the step should succeed
    And the output should match:
      | AUDIT:\s+id= |
  
  # @author geliu@redhat.com
  # @case_id OCP-16587
  @destructive
  @admin
  Scenario: Central Audit Capability with different audit levels
    Given I have a project
    And I use the first master host
    And the "/etc/origin/master/audit-policy.yaml" file is restored on host after scenario
    And the "/etc/origin/master/audit-ocp.log" file is restored on host after scenario
    Given master config is merged with the following hash:
    """
    auditConfig:
      auditFilePath: "/etc/origin/master/audit-ocp.log"
      enabled: true
      maximumFileRetentionDays: 10
      maximumFileSizeMegabytes: 10
      maximumRetainedFiles: 10
      logFormat: json
      policyConfiguration: null
      policyFile: "/etc/origin/master/audit-policy.yaml"
      webHookKubeConfig: ""
      webHookMode: ""
    """
    When I run commands on the host:
      | echo "apiVersion: audit.k8s.io/v1beta1"  >/etc/origin/master/audit-policy.yaml |
      | echo "kind: Policy" >>/etc/origin/master/audit-policy.yaml                     |
      | echo "rules:" >>/etc/origin/master/audit-policy.yaml                           |
      | echo "  - level: None" >>/etc/origin/master/audit-policy.yaml                  |
    And the master service is restarted on all master nodes
    Given I run commands on all masters:
      | ls /etc/origin/master/audit-ocp.log |
    Then the step should fail
    Then I run commands on the host:
      | sed -i "s/level: .*/level: Metadata/" /etc/origin/master/audit-policy.yaml |
    And the master service is restarted on all master nodes
    And I run commands on the host:
      | tail -20 /etc/origin/master/audit-ocp.log |
    Then the step should succeed
    And the output should contain:
      |  "level":"Metadata" |
    And the output should not contain:
      |  "level":"Request"         |
      |  "level":"RequestResponse" |
    Then I run commands on the host:
      | sed -i "s/level: .*/level: Request/" /etc/origin/master/audit-policy.yaml |	    
    And the master service is restarted on all master nodes
    And I run commands on the host:
      | tail -20 /etc/origin/master/audit-ocp.log |
    Then the step should succeed
    And the output should contain:
      |  "level":"Request" |
    And the output should not contain:
      |  "level":"Metadata"        |
      |  "level":"RequestResponse" |  
    Then I run commands on the host:
      | sed -i "s/level: .*/level: RequestResponse/" /etc/origin/master/audit-policy.yaml |	    
    And the master service is restarted on all master nodes
    And I run commands on the host:
      | tail -20 /etc/origin/master/audit-ocp.log |
    Then the step should succeed
    And the output should contain:
      |  "level":"RequestResponse" |
    And the output should not contain:
      |  "level":"Request"  |
      |  "level":"Metadata" |
     
  # @author geliu@redhat.com
  # @case_id OCP-16690
  @destructive
  @admin
  Scenario: Central Audit Capability with mixed filtering rules
    Given I have a project
    And evaluation of `project.name` is stored in the :project1 clipboard 
    And I use the first master host
    And the "/etc/origin/master/audit-policy.yaml" file is restored on host after scenario
    And the "/etc/origin/master/audit-ocp.log" file is restored on host after scenario
    Given master config is merged with the following hash:
    """
    auditConfig:
      auditFilePath: "/etc/origin/master/audit-ocp.log"
      enabled: true
      maximumFileRetentionDays: 10
      maximumFileSizeMegabytes: 10
      maximumRetainedFiles: 10
      logFormat: json
      policyConfiguration: null
      policyFile: "/etc/origin/master/audit-policy.yaml"
      webHookKubeConfig: ""
      webHookMode: ""       
    """
    When I run commands on the host:
      | echo "apiVersion: audit.k8s.io/v1beta1"  >/etc/origin/master/audit-policy.yaml       |
      | echo "kind: Policy" >>/etc/origin/master/audit-policy.yaml                           |
      | echo "rules:" >>/etc/origin/master/audit-policy.yaml                                 |
      | echo "  - level: Metadata" >>/etc/origin/master/audit-policy.yaml                    |
      | echo "    resources:" >>/etc/origin/master/audit-policy.yaml                         |
      | echo '    - group: ""' >>/etc/origin/master/audit-policy.yaml                        |
      | echo '      resources: ["secrets"]' >> /etc/origin/master/audit-policy.yaml          |
      | echo '    namespaces: ["<%= cb.project1 %>"]' >>/etc/origin/master/audit-policy.yaml |
    And the master service is restarted on all master nodes
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/tc519256/testsecret1.json |
    Then the step should succeed
    Given I create a new project
    And evaluation of `project.name` is stored in the :project2 clipboard
    When I run the :create client command with:
     | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/tc519256/testsecret2.json |
    Then the step should succeed
    And I run commands on the host:
      | tail -20 /etc/origin/master/audit-ocp.log |
    Then the step should succeed
    And the output should contain:
      | <%= cb.project1 %>/secrets |
    And the output should not contain:
      | <%= cb.project2 %> |
    When I run commands on the host:
      | echo "" > /etc/origin/master/audit-ocp.log |
    And the step should succeed
    When I run commands on the host:
      | echo "apiVersion: audit.k8s.io/v1beta1"  >/etc/origin/master/audit-policy.yaml |
      | echo "kind: Policy" >>/etc/origin/master/audit-policy.yaml                     |
      | echo "rules:" >>/etc/origin/master/audit-policy.yaml                           |
      | echo "  - level: Metadata" >>/etc/origin/master/audit-policy.yaml              |
      | echo "    nonResourceURLs:">>/etc/origin/master/audit-policy.yaml              |
      | echo '    - "/api*"'>>/etc/origin/master/audit-policy.yaml                     |
    And the master service is restarted on all master nodes
    Given I create a new project
    And evaluation of `project.name` is stored in the :project3 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/tc519256/testsecret2.json |
    Then the step should succeed
    And I run commands on the host:
      | tail -20 /etc/origin/master/audit-ocp.log |
    Then the step should succeed
    And the output should not contain:
      | "/api" |
    When I run the :get client command with:
      | resource | :false |
      | raw      | /api   |
    Then the step should succeed
    And I run commands on the host:
      | tail -20 /etc/origin/master/audit-ocp.log |
    Then the step should succeed
    And the output should contain:
      | "/api" |
    When I run commands on the host:
      | echo "apiVersion: audit.k8s.io/v1beta1"  >/etc/origin/master/audit-policy.yaml |
      | echo "kind: Policy" >>/etc/origin/master/audit-policy.yaml                     |
      | echo "rules:" >>/etc/origin/master/audit-policy.yaml                           |
      | echo "  - level: Request" >>/etc/origin/master/audit-policy.yaml               |
      | echo '    users: ["<%= user.name %>"]' >> /etc/origin/master/audit-policy.yaml |
      | echo '    verbs: ["create"]' >>/etc/origin/master/audit-policy.yaml            |
    And the master service is restarted on all master nodes
    Given I create a new project
    And evaluation of `project.name` is stored in the :project4 clipboard
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/secrets/tc519256/testsecret1.json |
    Then the step should succeed
    And I run commands on the host:
      | tail -20 /etc/origin/master/audit-ocp.log |
    Then the step should succeed
    And the output should contain:
      | "verb":"create" |
    Given I ensure "testsecret1" secret is deleted
    Then the step should succeed
    And I run commands on the host:
      | tail -20 /etc/origin/master/audit-ocp.log |
    Then the step should succeed
    And the output should not contain:
      | "verb":"delete" |
 
