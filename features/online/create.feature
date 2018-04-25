Feature: ONLY ONLINE Create related feature's scripts in this file

  # @author bingli@redhat.com
  Scenario Outline: Maven repository can be used to providing dependency caching for xPaas templates
    Given I have a project
    When I run the :new_app client command with:
      | template | <template>                                       |
      | param    | <env_name>=https://repo1.maven.org/non-existing/ |
      | param    | <parameter_name>=myapp                           |
    Then the step should succeed
    Given the "myapp-1" build was created
    And the "myapp-1" build failed
    When I run the :logs client command with:
      | resource_name | build/myapp-1 |
    Then the output should contain:
      | https://repo1.maven.org/non-existing/ |
    # @case_id OCP-10106
    @smoke
    Examples: MAVEN
      | template                                | parameter_name   | env_name         |
      | eap71-amq-persistent-s2i                | APPLICATION_NAME | MAVEN_MIRROR_URL |
      | eap71-basic-s2i                         | APPLICATION_NAME | MAVEN_MIRROR_URL |
      | eap71-https-s2i                         | APPLICATION_NAME | MAVEN_MIRROR_URL |
      | eap71-postgresql-persistent-s2i         | APPLICATION_NAME | MAVEN_MIRROR_URL |
      | jws31-tomcat7-https-s2i                 | APPLICATION_NAME | MAVEN_MIRROR_URL |
      | jws31-tomcat8-https-s2i                 | APPLICATION_NAME | MAVEN_MIRROR_URL |
      | jws31-tomcat8-mongodb-persistent-s2i    | APPLICATION_NAME | MAVEN_MIRROR_URL |
      | jws31-tomcat8-mysql-persistent-s2i      | APPLICATION_NAME | MAVEN_MIRROR_URL |
      | jws31-tomcat8-postgresql-persistent-s2i | APPLICATION_NAME | MAVEN_MIRROR_URL |
    # @case_id OCP-12688
    Examples: CPAN
      | template                | parameter_name | env_name    |
      | dancer-mysql-persistent | NAME           | CPAN_MIRROR |
    # @case_id OCP-12687
    Examples: PIP
      | template               | parameter_name | env_name      |
      | django-psql-persistent | NAME           | PIP_INDEX_URL |
    # @case_id OCP-12689
    Examples: RUBYGEM
      | template               | parameter_name | env_name       |
      | rails-pgsql-persistent | NAME           | RUBYGEM_MIRROR |

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
      | template | laravel-mysql-persistent |
    Then the step should succeed
    Then the "laravel-mysql-persistent-1" build was created
    And the "laravel-mysql-persistent-1" build completed
    And a pod becomes ready with labels:
      | deployment=laravel-mysql-persistent-1 |
    And I wait for the "laravel-mysql-persistent" service to become ready
    Then I wait for a web server to become available via the "laravel-mysql-persistent" route
