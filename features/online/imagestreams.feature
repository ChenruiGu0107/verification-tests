Feature: ONLY ONLINE Imagestreams related scripts in this file

  # @author etrott@redhat.com
  # @case_id 533084
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
    Given 1 pods become ready with labels:
      | app=openjdk18              |
      | deployment=openjdk18-1     |
      | deploymentconfig=openjdk18 |
    When I expose the "openjdk18" service
    Then the step should succeed
    Then I wait for a web server to become available via the "openjdk18" route
    And the output should contain:
      | Hello World |

  # @author bingli@redhat.com
  # @case_id OCP-10509
  Scenario: Check Online Pro default images
    When I run the :get client command with:
      | resource      | imagestreamtag  |
      | n             | openshift       |
    Then the step should succeed
    And the output should contain:
      | dotnet:1.0                              |
      | dotnet:latest                           |
      | dotnet:2.0                              |
      | dotnet:1.1                              |
      | dotnet-runtime:latest                   |
      | dotnet-runtime:2.0                      |
      | jboss-eap70-openshift:1.6               |
      | jboss-eap70-openshift:1.5               |
      | jboss-eap70-openshift:1.4               |
      | jboss-eap70-openshift:1.3               |
      | jboss-webserver30-tomcat7-openshift:1.2 |
      | jboss-webserver30-tomcat7-openshift:1.1 |
      | jboss-webserver30-tomcat7-openshift:1.3 |
      | jboss-webserver30-tomcat8-openshift:1.2 |
      | jboss-webserver30-tomcat8-openshift:1.1 |
      | jboss-webserver30-tomcat8-openshift:1.3 |
      | jboss-webserver31-tomcat7-openshift:1.0 |
      | jboss-webserver31-tomcat8-openshift:1.0 |
      | jenkins:1                               |
      | jenkins:2                               |
      | jenkins:latest                          |
      | mariadb:latest                          |
      | mariadb:10.1                            |
      | mongodb:2.4                             |
      | mongodb:latest                          |
      | mongodb:3.2                             |
      | mongodb:2.6                             |
      | mysql:latest                            |
      | mysql:5.7                               |
      | mysql:5.6                               |
      | mysql:5.5                               |
      | nodejs:6                                |
      | nodejs:latest                           |
      | mysql:5.5                               |
      | mysql:latest                            |
      | mysql:5.7                               |
      | mysql:5.6                               |
      | nodejs:0.10                             |
      | nodejs:4                                |
      | perl:latest                             |
      | perl:5.24                               |
      | perl:5.20                               |
      | perl:5.16                               |
      | php:latest                              |
      | php:7.0                                 |
      | php:5.6                                 |
      | php:5.5                                 |
      | postgresql:latest                       |
      | postgresql:9.5                          |
      | postgresql:9.4                          |
      | postgresql:9.2                          |
      | python:3.5                              |
      | python:3.4                              |
      | python:3.3                              |
      | python:2.7                              |
      | python:latest                           |
      | redhat-openjdk18-openshift:1.0          |
      | redhat-openjdk18-openshift:1.1          |
      | redis:latest                            |
      | redis:3.2                               |
      | ruby:latest                             |
      | ruby:2.4                                |
      | ruby:2.3                                |
      | ruby:2.2                                |
      | ruby:2.0                                |
      | wildfly:latest                          |
      | wildfly:10.1                            |
      | wildfly:10.0                            |
      | wildfly:9.0                             |
      | wildfly:8.1                             |

  # @author bingli@redhat.com
  # @case_id OCP-17285
  Scenario: Check Online Starter default images
    When I run the :get client command with:
      | resource      | imagestreamtag  |
      | n             | openshift       |
    Then the step should succeed
    And the output should contain:
      | dotnet:latest                           |
      | dotnet:2.0                              |
      | dotnet:1.1                              |
      | dotnet:1.0                              |
      | dotnet-runtime:latest                   |
      | dotnet-runtime:2.0                      |
      | httpd:latest                            |
      | httpd:2.4                               |
      | jboss-webserver30-tomcat7-openshift:1.2 |
      | jboss-webserver30-tomcat7-openshift:1.1 |
      | jboss-webserver30-tomcat7-openshift:1.3 |
      | jboss-webserver30-tomcat8-openshift:1.3 |
      | jboss-webserver30-tomcat8-openshift:1.2 |
      | jboss-webserver30-tomcat8-openshift:1.1 |
      | jboss-webserver31-tomcat7-openshift:1.0 |
      | jboss-webserver31-tomcat8-openshift:1.0 |
      | jenkins:latest                          |
      | jenkins:1                               |
      | jenkins:2                               |
      | mariadb:latest                          |
      | mariadb:10.1                            |
      | mongodb:latest                          |
      | mongodb:3.2                             |
      | mongodb:2.6                             |
      | mongodb:2.4                             |
      | mysql:5.5                               |
      | mysql:latest                            |
      | mysql:5.7                               |
      | mysql:5.6                               |
      | nodejs:latest                           |
      | nodejs:0.10                             |
      | nodejs:4                                |
      | nodejs:6                                |
      | perl:latest                             |
      | perl:5.24                               |
      | perl:5.20                               |
      | perl:5.16                               |
      | php:latest                              |
      | php:7.0                                 |
      | php:5.6                                 |
      | php:5.5                                 |
      | postgresql:9.2                          |
      | postgresql:latest                       |
      | postgresql:9.5                          |
      | postgresql:9.4                          |
      | python:latest                           |
      | python:3.5                              |
      | python:3.4                              |
      | python:3.3                              |
      | python:2.7                              |
      | redhat-openjdk18-openshift:1.0          |
      | redhat-openjdk18-openshift:1.1          |
      | redis:latest                            |
      | redis:3.2                               |
      | ruby:latest                             |
      | ruby:2.4                                |
      | ruby:2.3                                |
      | ruby:2.2                                |
      | ruby:2.0                                |
      | wildfly:9.0                             |
      | wildfly:8.1                             |
      | wildfly:latest                          |
      | wildfly:10.1                            |
      | wildfly:10.0                            |


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
      | <%= user.name %>:<%= user.cached_tokens.first %>                  |
      | docker://docker.io/busybox                                           |
      | docker://<%= cb.registry_route %>/<%= project.name %>/busybox:latest |
    Then the step should succeed  
    When I run the :get client command with:
      | resource | imagestreamtag |
    Then the step should succeed  
    And the output should contain:
      | busybox:latest |

  # @author zhaliu@redhat.com
  Scenario Outline: ImageStream annotation and tag function
    Given I have a project
    And I attempt the registry route based on API url and store it in the :registry_route clipboard  
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image-streams/<file> |
    Then the step should succeed  
    When I have a skopeo pod in the project
    Then the step should succeed  
    And a pod becomes ready with labels:
      | name=skopeo |
    When I execute on the pod:  
      | skopeo                                                               |
      | --insecure-policy                                                    |
      | copy                                                                 |
      | --dcreds                                                             |
      | <%= user.name %>:<%= user.cached_tokens.first %>                  |
      | docker://docker.io/busybox                                           |
      | docker://<%= cb.registry_route %>/<%= project.name %>/<tag>          |
    Then the step should succeed  
    When I run the :get client command with:
      | resource | imagestreamtag |
      | template | <isttemplate>  |
    Then the step should succeed  
    And the output should match:
      | <istoutput> |
    When I run the :get client command with:
      | resource      | imagestream  |
      | resource_name | <isname>     |
      | template      | <istemplate> |
    Then the step should succeed
    And the output should match:
      | <isoutput> |
    Examples:
      | file             | tag         | isttemplate                                        | istoutput                                                  | isname  | istemplate                                                                               | isoutput                                         |
      | annotations.json | testa:prod  | {{range .items}} {{.metadata.annotations}} {{end}} | map\[color:blue\]                                          | testa   | "{{range .spec.tags}} {{.annotations}} {{end}}; {{range .status.tags}} {{.tag}} {{end}}" | map\[color:blue\].*prod\|prod.*map\[color:blue\] | # @case_id OCP-10090
      | busybox.json     | busybox:2.0 | "{{range .items}} {{.metadata.name}} {{end}}"      | busybox:latest.*busybox:2\.0\|busybox:2\.0.*busybox:latest | busybox | "{{range .status.tags}} {{.tag}} {{end}}"                                                | latest.*2\.0\|2\.0.*latest                       | # @case_id OCP-10093

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
      | <%= user.name %>:<%= user.cached_tokens.first %>                     |
      | docker://docker.io/busybox                                              |
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
      | <%= user.name %>:<%= user.cached_tokens.first %>                     |
      | docker://docker.io/busybox                                              |
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
      | <%= user.name %>:<%= user.cached_tokens.first %>                     |
      | docker://docker.io/busybox                                              |
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
