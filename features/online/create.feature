Feature: ONLY ONLINE Create related feature's scripts in this file

  # @author etrott@redhat.com
  # @case_id OCP-10106
  # @case_id OCP-12688
  # @case_id OCP-12687
  Scenario Outline: Maven repository can be used to providing dependency caching for xPaas templates
    Given I have a project
    When I perform the :create_app_from_template_without_label web console action with:
      | project_name  | <%= project.name %> |
      | template_name | <template>          |
      | namespace     | openshift           |
      | param_one     | :null               |
      | param_two     | :null               |
      | param_three   | :null               |
      | param_four    | :null               |
      | param_five    | :null               |
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | <app-name>          |
      | build_status | complete            |
    Then the step should succeed
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>     |
      | bc_and_build_name | <app-name>/<app-name>-1 |
      | build_status_name | Complete                |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | <default_env_log> |
    Then the step should succeed
    Given I perform the :change_env_vars_on_buildconfig_edit_page web console action with:
      | project_name      | <%= project.name %> |
      | bc_name           | <app-name>          |
      | env_variable_name | <env_name>          |
      | new_env_value     | <env_var_value>     |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I click the following "button" element:
      | text  | Start Build |
      | class | btn-default |
    Then the step should succeed
    When I run the :check_build_has_started_message web console action
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | <app-name>          |
      | build_status | complete            |
    Then the step should succeed
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>     |
      | bc_and_build_name | <app-name>/<app-name>-2 |
      | build_status_name | Complete                |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | <custom_env_log> |
    Then the step should succeed
    Given I perform the :add_env_vars_on_buildconfig_edit_page web console action with:
      | project_name  | <%= project.name %>                   |
      | bc_name       | <app-name>                            |
      | env_var_key   | <env_name>                            |
      | env_var_value | https://repo1.maven.org/non-existing/ |
    Then the step should succeed
    When I run the :click_save_button web console action
    Then the step should succeed
    When I click the following "button" element:
      | text  | Start Build |
      | class | btn-default |
    Then the step should succeed
    When I run the :check_build_has_started_message web console action
    Then the step should succeed
    When I perform the :wait_latest_build_to_status web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | <app-name>          |
      | build_status | failed              |
    Then the step should succeed
    When I perform the :check_build_log_tab web console action with:
      | project_name      | <%= project.name %>     |
      | bc_and_build_name | <app-name>/<app-name>-3 |
      | build_status_name | Failed                  |
    Then the step should succeed
    When I perform the :check_build_log_content web console action with:
      | build_log_context | https://repo1.maven.org/non-existing/ |
    Then the step should succeed
    Examples: MAVEN
      | template                             | app-name | env_name         | env_var_value                   | default_env_log                                                       | custom_env_log                               |
      | jws30-tomcat8-mongodb-persistent-s2i | jws-app  | MAVEN_MIRROR_URL | https://repo1.maven.org/maven2/ | Downloading: https://mirror.openshift.com/nexus/content/groups/public | Downloading: https://repo1.maven.org/maven2/ |
      | eap64-mysql-persistent-s2i           | eap-app  | MAVEN_MIRROR_URL | https://repo1.maven.org/maven2/ | Downloading: https://mirror.openshift.com/nexus/content/groups/public | Downloading: https://repo1.maven.org/maven2/ |
    Examples: CPAN
      | template                | app-name                | env_name    | env_var_value                                  | default_env_log                       | custom_env_log                                          |
      | dancer-mysql-persistent | dancer-mysql-persistent | CPAN_MIRROR | https://mirror.openshift.com/mirror/perl/CPAN/ | Fetching http://www.cpan.org/authors/ | Fetching https://mirror.openshift.com/mirror/perl/CPAN/ |
    Examples: PIP
      | template               | app-name                | env_name      | env_var_value                                          | default_env_log | custom_env_log                                             |
      | django-psql-persistent | django-psql-persistent  | PIP_INDEX_URL | https://mirror.openshift.com/mirror/python/web/simple/ |                 | Downloading https://mirror.openshift.com/mirror/python/web |

  # @author etrott@redhat.com
  # @case_id OCP-10149
  # @case_id OCP-10179
  Scenario Outline: Create resource from imagestream via oc new-app
    Given I have a project
    Then I run the :new_app client command with:
      | name         | resource-sample |
      | image_stream | <is>            |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=resource-sample-1 |
    When I expose the "resource-sample" service
    Then the step should succeed
    And I wait for a web server to become available via the route
    Examples:
      | is                               |
      | openshift/jboss-eap70-openshift  |
      | openshift/redhat-sso70-openshift |

  # @author etrott@redhat.com
  # @case_id OCP-10150
  # @case_id OCP-10180
  Scenario Outline: Create applications with persistent storage using pre-installed templates
    Given I have a project
    Then I run the :new_app client command with:
      | template | <template> |
    Then the step should succeed
    And all pods in the project are ready
    Then the step should succeed
    And I wait for the "<service_name>" service to become ready
    Then I wait for a web server to become available via the "<service_name>" route
    And I wait for the "secure-<service_name>" service to become ready
    Then I wait for a secure web server to become available via the "secure-<service_name>" route
    Examples:
      | template                   | service_name |
      | eap70-mysql-persistent-s2i | eap-app      |
      | sso70-mysql-persistent     | sso          |

  # @author etrott@redhat.com
  # @case_id OCP-10270
  Scenario: Create Laravel application with a MySQL database using default template laravel-mysql-example
    Given I have a project
    Then I run the :new_app client command with:
      | template | laravel-mysql-example |
    Then the step should succeed
    And all pods in the project are ready
    Then the step should succeed
    And I wait for the "laravel-mysql-example" service to become ready
    Then I wait for a web server to become available via the "laravel-mysql-example" route
