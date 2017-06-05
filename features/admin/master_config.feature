Feature: test master config related steps

  # @author yinzhou@redhat.com
  # @case_id OCP-9906
  @admin
  @destructive
  Scenario: Check project limitation for users with and without label admin=true for online env
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
            - maxProjects: 1
    """
    Then the step should succeed
    And the master service is restarted on all master nodes
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
      | curl -Ss https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admin/tc521728_add_user_to_ldap.ldif \| ldapadd -h 127.0.0.1 -p 389 -D cn=Manager,dc=example,dc=com -w admin |
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
    Then the step should succeed
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
    Then the step should succeed
    Given the master service is restarted on all master nodes

    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/tc534581/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota-terminating.yaml"
    And I replace lines in "quota-terminating.yaml":
      | pods: "4" | pods: "2" |
    And I run the :create admin command with:
      | f | quota-terminating.yaml |
      | n | <%= project.name %>    |
    Then the step should succeed

    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/dc-with-pre-mid-post.yaml |
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
    Then the step should succeed
    Given the master service is restarted on all master nodes

    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/tc534581/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/quota-terminating.yaml"
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
    Then the step should succeed
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
    Then the step should succeed
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | 509118_user                 |
      | password | password                    |
    Then the step should succeed
    When I run the :delete admin command with:
      | object_type       | identity                |
      | object_name_or_id | anypassword:509118_user |
    Then the step should succeed
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | 509118_user                 |
      | password | password                    |
    Then the step should succeed

  # @author chezhang@redhat.com
  # @case_id OCP-10619
  @admin
  @destructive
  Scenario: defaultNodeSelector options on master will make pod landing on nodes with label "infra=false"
    Given master config is merged with the following hash:
    """
    projectConfig:
      defaultNodeSelector: "infra=test"
      projectRequestMessage: ""
      projectRequestTemplate: ""
      securityAllocator:
        mcsAllocatorRange: "s0:/2"
        mcsLabelsPerProject: 5
        uidAllocatorRange: "1000000000-1999999999/10000"
    """
    And the master service is restarted on all master nodes
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :pending
    Given I store the schedulable nodes in the :nodes clipboard
    When label "infra=test" is added to the "<%= cb.nodes[0].name %>" node
    Then the pod named "hello-openshift" status becomes :running
    Given I ensure "hello-openshift" pod is deleted
    And label "infra-" is added to the "<%= cb.nodes[0].name %>" node
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | project_name  | <%= cb.proj_name %>       |
      | node_selector | <%= cb.proj_name %>=hello |
      | admin         | <%= user.name %>          |
    Then the step should succeed
    Given I use the "<%= cb.proj_name %>" project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
      | n | <%= cb.proj_name %>                                                                               |
    Then the step should succeed
    And the pod named "hello-openshift" status becomes :pending
    When label "<%= cb.proj_name %>=hello" is added to the "<%= cb.nodes[0].name %>" node
    Then the pod named "hello-openshift" status becomes :running

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
    Then the step should succeed
    And the master service is restarted on all master nodes
    When I run the :login client command with:
      | server   | <%= env.api_endpoint_url %> |
      | username | 509116_user                 |
      | password | password                    |
    Then the step should fail
    Given I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admin/tc509116/tc509116_user.json |
    Then the step should succeed
    And I register clean-up steps:
      """
      Given I run the :delete admin command with:
        | object_type       | user        |
        | object_name_or_id | 509116_user |
      Then the step should succeed
      """
    Given I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admin/tc509116/tc509116_identity.json |
    Then the step should succeed
    And I register clean-up steps:
      """
      Given I run the :delete admin command with:
        | object_type       | identity                |
        | object_name_or_id | anypassword:509116_user |
      Then the step should succeed
      """
    Given I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/admin/tc509116/tc509116_useridentitymapping.json |
    Then the step should succeed
    When I run the :get client command with:
      | resource   | projects |
    Then the step should succeed
    When I run the :get admin command with:
     | resource | users                        |
    Then the step should succeed
    And the output should contain:
     | NAME       | 509116_user                |

  # @author: chuyu@redhat.com
  # @case_id: OCP-10594
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
    Then the step should succeed
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
    Then the step should succeed
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
    Then the step should succeed
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
    Then the step should succeed
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
    Then the step should succeed
    Given I try to restart the master service on all master nodes
    Then the step should fail

  # @author chuyu@redhat.com
  # @case_id OCP-9800
  @admin
  @destructive
  Scenario: User can customize the projectrequestlimit admission controller configuration
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
            - selector: {}
              maxProjects: 1
    """
    Then the step should succeed
    And the master service is restarted on all master nodes
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
                level: "platinum"
              maxProjects: 1
    """
    Then the step should succeed
    And the master service is restarted on all master nodes
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
                level: "platinum"
              maxProjects: 2
            - selector: {}
              maxProjects: 1
    """
    Then the step should succeed
    And the master service is restarted on all master nodes
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
                level: "platinum"
              maxProjects: 1
            - selector:
                tag: golden
              maxProjects: 2
    """
    Then the step should succeed
    And the master service is restarted on all master nodes
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
    Then the step should succeed
    Given I try to restart the master service on all master nodes
    Then the step should fail
