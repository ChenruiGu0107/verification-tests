Feature: ONLY ONLINE related feature's scripts in this file

  # @author bingli@redhat.com
  # @case_id 516510
  Scenario: cli disables Docker builds and custom builds and allow only sti builds
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/openshift/ruby-hello-world.git |
      | name     | sti-bc    |
    Then the step should succeed
    When I run the :new_build client command with:
      | app_repo | centos/ruby-22-centos7~https://github.com/openshift/ruby-hello-world.git |
      | name     | docker-bc |
      | strategy | docker    |
    Then the step should fail
    And the output should contain:
      | build strategy Docker is not allowed |
    When I process and create "https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json"
    Then the step should fail
    And the output should contain:
      | build strategy Custom is not allowed |
    When I replace resource "bc" named "sti-bc":
      | sourceStrategy | dockerStrategy |
      | type: Source   | type: Docker   |
    Then the step should fail
    And the output should contain:
      | build strategy Docker is not allowed |

  # @author etrott@redhat.com
  # @case_id 528263
  # @case_id 528268
  Scenario Outline: Maven repository can be used to providing dependency caching for xPaas and wildfly STI builds
    Given I create a new project
    Given I perform the :create_app_from_image_with_bc_env_and_git_options web console action with:
      | project_name | <%= project.name %>                                             |
      | image_name   | <image>                                                         |
      | image_tag    | <image_tag>                                                     |
      | namespace    | openshift                                                       |
      | app_name     | maven-dep-sample                                                |
      | bc_env_key   | MAVEN_MIRROR_URL                                                |
      | bc_env_value | https://mirror.openshift.com/nexus/content/groups/non-existing/ |
      | source_url   | <source_url>                                                    |
      | git_ref      | <git_ref>                                                       |
      | context_dir  | <context_dir>                                                   |
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | maven-dep-sample    |
      | build_status | failed              |
    Then the step should succeed
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>                 |
      | bc_and_build_name | maven-dep-sample/maven-dep-sample-1 |
      | build_status_name | Failed                              |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | Aborting due to error code 1 |
    Then the step should succeed
    Given I perform the :change_env_vars_on_buildconfig_edit_page web console action with:
      | project_name  | <%= project.name %>                                       |
      | bc_name       | maven-dep-sample                                          |
      | new_env_value | https://mirror.openshift.com/nexus/content/groups/public/ |
    Then the step should succeed
    When I run the :save_buildconfig_changes web console action
      | project_name | <%= project.name %> |
      | bc_name      | maven-dep-sample    |
    Then the step should succeed
    When I click the following "button" element:
      | text  | Start Build |
      | class | btn-default |
    Then the step should succeed
    When I run the :check_build_has_started_message web console action
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | maven-dep-sample    |
      | build_status | complete            |
    Then the step should succeed
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>                 |
      | bc_and_build_name | maven-dep-sample/maven-dep-sample-2 |
      | build_status_name | Complete                            |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | Downloading: https://mirror.openshift.com/nexus/content/groups/public/ |
    Examples: xPaas STI builds
      | image                               | image_tag | source_url                                                   | git_ref | context_dir           |
      | jboss-eap64-openshift               | 1.3       | https://github.com/jboss-developer/jboss-eap-quickstarts.git | 6.4.x   | kitchensink           |
      | jboss-webserver30-tomcat8-openshift | 1.2       | https://github.com/jboss-openshift/openshift-quickstarts.git | master  | tomcat-websocket-chat |
    Examples: wildfly STI builds
      | image   | image_tag | source_url                                          | git_ref | context_dir |
      | wildfly | 10.0      | https://github.com/bparees/openshift-jee-sample.git | master  | /           |
