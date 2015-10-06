Feature: quickstarts.feature

  # @author cryan@redhat.com
  # @author haowang@redhat.com
  # @author akostadi@redhat.com
  # @case_id 497474 492284
  Scenario Outline: rails quickstart test
    Given I have a project

    And I download a file from "https://raw.githubusercontent.com/openshift/<repo>/master/openshift/templates/<template>"
    And I replace lines in "<template>":
      |openshift/postgresql-92-centos7|<image_tag>|
    When I run the :process client command with:
      | f | <template> |
      | v | SOURCE_REPOSITORY_URL=https://github.com/openshift/<repo>.git|
    Then the step should succeed
    Given I save the output to file> processed-stibuild.json
    When I run the :create client command with:
      | f | processed-stibuild.json |
    Then the step should succeed

    When I run the :start_build client command with:
      | buildconfig | <buildcfg> |
    Then the step should succeed
    And the "<buildcfg>-1" build was created
    And the "<buildcfg>-1" build completed
    And all pods in the project are ready

    When I use the "<buildcfg>" service
    Then I wait for a server to become available via the "<buildcfg>" route

    When I run the :env client command with:
      | resource | dc/<buildcfg> |
      | keyval   | RAILS_ENV=development |
    And I run the :start_build client command with:
      | buildconfig | <buildcfg> |
    Then the "<buildcfg>-2" build was created
    And the "<buildcfg>-2" build completed
    And all pods in the project are ready

    When I get project builds
    Then the step should succeed
    And the output should not contain "static"

    Examples: OS Type
      | image_tag                                                 | repo     | template              | buildcfg                 |
      | <%= project_docker_repo %>openshift/postgresql-92-centos7 | rails-ex | rails-postgresql.json | rails-postgresql-example |
      | <%= product_docker_repo %>openshift3/postgresql-92-rhel7  | rails-ex | rails-postgresql.json | rails-postgresql-example |

  # @author cryan@redhat.com
  # @case_id 492613 494849
  Scenario Outline: quickstart test
    Given I have a project

    And I download a file from "https://raw.githubusercontent.com/openshift/<repo>/master/openshift/templates/<template>"
    And I replace lines in "<template>":
      |<orig_image>|<image_tag>|
    And I replace lines in "<template>":
      |"name": "python:3.3"|"name": "<name>"|
    When I run the :process client command with:
      | f | <template> |
      | v | SOURCE_REPOSITORY_URL=https://github.com/openshift/<repo>.git|
    Then the step should succeed
    Given I save the output to file> processed-stibuild.json
    When I run the :create client command with:
      | f | processed-stibuild.json |
    Then the step should succeed

    When I run the :start_build client command with:
      | buildconfig | <buildcfg> |
    Then the step should succeed
    And the "<buildcfg>-1" build was created
    And the "<buildcfg>-1" build completed
    And all pods in the project are ready

    When I use the "<buildcfg>" service
    Then I wait for a server to become available via the "<buildcfg>" route

    And I run the :start_build client command with:
      | buildconfig | <buildcfg> |
    Then the "<buildcfg>-2" build was created
    And the "<buildcfg>-2" build completed
    And all pods in the project are ready

    When I get project builds
    Then the step should succeed
    And the output should not contain "static"

    Examples: OS Type
      | orig_image                      | image_tag                                                 | repo       | template               | buildcfg                 | name        |
      | openshift/postgresql-92-centos7 | <%= project_docker_repo %>openshift/postgresql-92-centos7 | django-ex  | django-postgresql.json | django-psql-example      | python:3.3  |
      | openshift/postgresql-92-centos7 | <%= product_docker_repo %>openshift3/postgresql-92-rhel7  | django-ex  | django-postgresql.json | django-psql-example      | python:3.3  |
      | openshift/mysql-55-centos7      | <%= project_docker_repo %>openshift/mysql-55-centos7      | dancer-ex  | dancer-mysql.json      | dancer-mysql-example     | perl:5.16   |
      | openshift/mysql-55-centos7      | <%= product_docker_repo %>openshift3/mysql-55-rhel7       | dancer-ex  | dancer-mysql.json      | dancer-mysql-example     | perl:5.16   |
      | openshift/mysql-55-centos7      | <%= project_docker_repo %>openshift/mysql-55-centos7      | dancer-ex  | dancer-mysql.json      | dancer-mysql-example     | perl:5.20   |
      | openshift/mysql-55-centos7      | <%= product_docker_repo %>openshift3/mysql-55-rhel7       | dancer-ex  | dancer-mysql.json      | dancer-mysql-example     | perl:5.20   |
      | openshift/mysql-55-centos7      | <%= project_docker_repo %>openshift/mysql-55-centos7      | cakephp-ex | cakephp-mysql.json     | cakephp-mysql-example    | php:5.5     |
      | openshift/mysql-55-centos7      | <%= product_docker_repo %>openshift3/mysql-55-rhel7       | cakephp-ex | cakephp-mysql.json     | cakephp-mysql-example    | php:5.5     |
      | openshift/mysql-55-centos7      | <%= project_docker_repo %>openshift/mysql-55-centos7      | cakephp-ex | cakephp-mysql.json     | cakephp-mysql-example    | php:5.6     |
      | openshift/mysql-55-centos7      | <%= product_docker_repo %>openshift3/mysql-55-rhel7       | cakephp-ex | cakephp-mysql.json     | cakephp-mysql-example    | php:5.6     |
      | openshift/mongodb-24-centos7    | <%= project_docker_repo %>openshift/mongodb-24-centos7    | nodejs-ex  | nodejs-mongodb.json    | nodejs-mongodb-example   | nodejs:0.10 |
      | openshift/mongodb-24-centos7    | <%= product_docker_repo %>openshift3/mongodb-24-rhel7     | nodejs-ex  | nodejs-mongodb.json    | nodejs-mongodb-example   | nodejs:0.10 |
      | openshift/postgresql-92-centos7 | <%= project_docker_repo %>openshift/postgresql-92-centos7 | rails-ex   | rails-postgresql.json  | rails-postgresql-example | ruby:2.2    |
      | openshift/postgresql-92-centos7 | <%= product_docker_repo %>openshift3/postgresql-92-rhel7   | rails-ex   | rails-postgresql.json  | rails-postgresql-example | ruby:2.2    |
