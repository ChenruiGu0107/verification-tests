Feature: test master config related steps

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
