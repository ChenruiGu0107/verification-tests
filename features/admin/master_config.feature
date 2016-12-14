Feature: test master config related steps

  # @author: yinzhou@redhat.com
  # @case_id: 521540
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

  # @author: chuyu@redhat.com
  # @case_id: 521728
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
      | insecure | true                        |
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

  # @author: yinzhou@redhat.com
  # @case_id: 534581
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

  # @author: yinzhou@redhat.com
  # @case_id: 534582
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
