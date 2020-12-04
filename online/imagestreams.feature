Feature: ONLY ONLINE Imagestreams related scripts in this file

  # @author etrott@redhat.com
  # @case_id OCP-10165
  Scenario Outline: Imagestream should not be tagged with 'builder'
    When I create a new project via web
    Then the step should succeed
    When I get the visible text on web html page
    Then the output should not contain:
      | <is> |
    When I run the :get client command with:
      | resource      | is        |
      | resource_name | <is>      |
      | n             | openshift |
      | o             | json      |
    Then the step should succeed
    And the output should not contain "builder"
    Examples:
      | is                     |
      | jboss-eap70-openshift  |
      | redhat-sso70-openshift |

  # @author bingli@redhat.com
  # @case_id OCP-13212
  Scenario: Build and run Java applications using redhat-openjdk18-openshift image
    Given I have a project
    And I create a new application with:
      | image_stream | openshift/redhat-openjdk18-openshift:1.2                 |
      | code         | https://github.com/jboss-openshift/openshift-quickstarts |
      | context_dir  | undertow-servlet                                         |
      | name         | openjdk18                                                |
    When I get project buildconfigs as YAML
    Then the output should match:
      | uri:\\s+https://github.com/jboss-openshift/openshift-quickstarts |
      | type: Git                                                        |
      | name: redhat-openjdk18-openshift:1.2                             |
    Given the "openjdk18-1" build was created
    And the "openjdk18-1" build completed
    When I run the :build_logs client command with:
      | build_name | openjdk18-1 |
    Then the output should contain:
      | Starting S2I Java Build |
      | Push successful         |
    Given 1 pod becomes ready with labels:
      | app=openjdk18              |
      | deployment=openjdk18-1     |
      | deploymentconfig=openjdk18 |
    When I expose the "openjdk18" service
    Then the step should succeed
    Then I wait for a web server to become available via the "openjdk18" route
    And the output should contain:
      | Hello World |

  # @author zhaliu@redhat.com
  # @case_id OCP-10091
  Scenario: imageStream is auto provisioned if it does not exist during 'docker push'--Online
    Given I have a project
    And I attempt the registry route based on API url and store it in the :registry_route clipboard
    When I have a skopeo pod in the project
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=skopeo |
    When I execute on the pod:
      | skopeo                                                               |
      | --insecure-policy                                                    |
      | copy                                                                 |
      | --dcreds                                                             |
      | <%= user.name %>:<%= user.cached_tokens.first %>                     |
      | docker://quay.io/openshifttest/busybox                               |
      | docker://<%= cb.registry_route %>/<%= project.name %>/busybox:latest |
    Then the step should succeed
    When I run the :get client command with:
      | resource | imagestreamtag |
    Then the step should succeed
    And the output should contain:
      | busybox:latest |

  # @author zhaliu@redhat.com
  # @case_id OCP-10092
  Scenario: User should be denied pushing when it does not have 'admin' role--online paid tier
    Given I have a project
    And I attempt the registry route based on API url and store it in the :registry_route clipboard
    And evaluation of `project.name` is stored in the :project_name clipboard

    Given I switch to second user
    Given I have a project
    When I have a skopeo pod in the project
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=skopeo |
    When I execute on the pod:
      | skopeo                                                                  |
      | --insecure-policy                                                       |
      | copy                                                                    |
      | --dcreds                                                                |
      | <%= user.name %>:<%= user.cached_tokens.first %>                        |
      | docker://quay.io/openshifttest/busybox                                  |
      | docker://<%= cb.registry_route %>/<%= cb.project_name %>/busybox:latest |
    Then the step should fail
    And the output should contain:
      | not authorized to read from destination repository |
    Given I switch to first user
    When I run the :policy_add_role_to_user client command with:
      | role      | edit                               |
      | user_name | <%= user(1, switch: false).name %> |
    Then the step should succeed
    Given I switch to second user
    And I use the "<%=cb.project_name %>" project
    When I execute on the pod:
      | skopeo                                                                  |
      | --insecure-policy                                                       |
      | copy                                                                    |
      | --dcreds                                                                |
      | <%= user.name %>:<%= user.cached_tokens.first %>                        |
      | docker://quay.io/openshifttest/busybox                                  |
      | docker://<%= cb.registry_route %>/<%= cb.project_name %>/busybox:latest |
    Then the step should succeed
    When I run the :get client command with:
      | resource | imagestreamtag         |
      | n        | <%= cb.project_name %> |
    Then the step should succeed
    And the output should contain:
      | busybox:latest |

  # @author zhaliu@redhat.com
  # @case_id OCP-15022
  Scenario: User should be denied pushing when it does not have 'admin' role--online free tier
    Given I have a project
    And I attempt the registry route based on API url and store it in the :registry_route clipboard
    And evaluation of `project.name` is stored in the :project_name clipboard

    Given I switch to second user
    Given I have a project
    When I have a skopeo pod in the project
    Then the step should succeed
    And a pod becomes ready with labels:
      | name=skopeo |
    When I execute on the pod:
      | skopeo                                                                  |
      | --insecure-policy                                                       |
      | copy                                                                    |
      | --dcreds                                                                |
      | <%= user.name %>:<%= user.cached_tokens.first %>                        |
      | docker://quay.io/openshifttest/busybox                                  |
      | docker://<%= cb.registry_route %>/<%= cb.project_name %>/busybox:latest |
    Then the step should fail
    And the output should contain:
      | not authorized to read from destination repository |


  # @author yuwan@redhat.com
  # @case_id OCP-18765
  Scenario: quickstart for imagestream eap-cd-openshift-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | eap-cd-openshift:latest |
    Then the step should succeed
    And I wait for the "eap-cd-openshift" is to appear
    When I expose the "eap-cd-openshift" service
    Then the step should succeed
    And I wait for a web server to become available via the route

  # @author yuwan@redhat.com
  # @case_id OCP-19721
  Scenario: Quickstart for IS java-rhel7
  Given I have a project
  When I run the :new_app client command with:
    | image_stream | openshift/java:latest                                    |
    | app_repo     | https://github.com/jboss-openshift/openshift-quickstarts |
    | context_dir  | undertow-servlet                                         |
  Then the step should succeed
  And a pod becomes ready with labels:
    | app=openshift-quickstarts |
