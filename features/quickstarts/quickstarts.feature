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

  # @author cryan@redhat.com haowang@redhat.com
  # @case_id 492613 494849 497668 497669
  Scenario Outline: quickstart test
    Given I have a project

    And I download a file from "https://raw.githubusercontent.com/openshift/<repo>/master/openshift/templates/<template>"
    And I replace lines in "<template>":
      |<orig_image>|<image_tag>|
    And I replace lines in "<template>":
      |"name": "<old_name>"|"name": "<new_name>"|
    When I run the :process client command with:
      | f | <template> |
      | v | SOURCE_REPOSITORY_URL=https://github.com/openshift/<repo>.git|
    Then the step should succeed
    Given I save the output to file> processed-stibuild.json
    When I run the :create client command with:
      | f | processed-stibuild.json |
    Then the step should succeed
    And the "<buildcfg>-1" build was created
    And the "<buildcfg>-1" build completed

    And all pods in the project are ready

    When I use the "<buildcfg>" service
    Then I wait for a server to become available via the "<buildcfg>" route
    Then the output should contain "<output>"

    Examples: OS Type
      | orig_image                      | image_tag                                                 | repo       | template               | buildcfg                 | old_name    | new_name    | output  |
      | openshift/postgresql-92-centos7 | <%= project_docker_repo %>openshift/postgresql-92-centos7 | django-ex  | django-postgresql.json | django-psql-example      | python:3.3  | python:3.3  | Django  |
      | openshift/postgresql-92-centos7 | <%= product_docker_repo %>openshift3/postgresql-92-rhel7  | django-ex  | django-postgresql.json | django-psql-example      | python:3.3  | python:3.3  | Django  |
      | openshift/mysql-55-centos7      | <%= project_docker_repo %>openshift/mysql-55-centos7      | dancer-ex  | dancer-mysql.json      | dancer-mysql-example     | perl:5.16   | perl:5.16   | Dancer  |
      | openshift/mysql-55-centos7      | <%= product_docker_repo %>openshift3/mysql-55-rhel7       | dancer-ex  | dancer-mysql.json      | dancer-mysql-example     | perl:5.16   | perl:5.16   | Dancer  |
      | openshift/mysql-55-centos7      | <%= project_docker_repo %>openshift/mysql-55-centos7      | dancer-ex  | dancer-mysql.json      | dancer-mysql-example     | perl:5.16   | perl:5.20   | Dancer  |
      | openshift/mysql-55-centos7      | <%= product_docker_repo %>openshift3/mysql-55-rhel7       | dancer-ex  | dancer-mysql.json      | dancer-mysql-example     | perl:5.16   | perl:5.20   | Dancer  |
      | openshift/mysql-55-centos7      | <%= project_docker_repo %>openshift/mysql-55-centos7      | cakephp-ex | cakephp-mysql.json     | cakephp-mysql-example    | php:5.5     | php:5.5     | CakePHP |
      | openshift/mysql-55-centos7      | <%= product_docker_repo %>openshift3/mysql-55-rhel7       | cakephp-ex | cakephp-mysql.json     | cakephp-mysql-example    | php:5.5     | php:5.5     | CakePHP |
      | openshift/mysql-55-centos7      | <%= project_docker_repo %>openshift/mysql-55-centos7      | cakephp-ex | cakephp-mysql.json     | cakephp-mysql-example    | php:5.5     | php:5.6     | CakePHP |
      | openshift/mysql-55-centos7      | <%= product_docker_repo %>openshift3/mysql-55-rhel7       | cakephp-ex | cakephp-mysql.json     | cakephp-mysql-example    | php:5.5     | php:5.6     | CakePHP |
      | openshift/mongodb-24-centos7    | <%= project_docker_repo %>openshift/mongodb-24-centos7    | nodejs-ex  | nodejs-mongodb.json    | nodejs-mongodb-example   | nodejs:0.10 | nodejs:0.10 | Node.js |
      | openshift/mongodb-24-centos7    | <%= product_docker_repo %>openshift3/mongodb-24-rhel7     | nodejs-ex  | nodejs-mongodb.json    | nodejs-mongodb-example   | nodejs:0.10 | nodejs:0.10 | Node.js |
      | openshift/mongodb-24-centos7    | <%= project_docker_repo %>openshift/mongodb-24-centos7    | nodejs-ex  | nodejs.json            | nodejs-example           | nodejs:0.10 | nodejs:0.10 | Node.js |
      | openshift/mongodb-24-centos7    | <%= product_docker_repo %>openshift3/mongodb-24-rhel7     | nodejs-ex  | nodejs.json            | nodejs-example           | nodejs:0.10 | nodejs:0.10 | Node.js |
      | openshift/postgresql-92-centos7 | <%= project_docker_repo %>openshift/postgresql-92-centos7 | rails-ex   | rails-postgresql.json  | rails-postgresql-example | ruby:2.0    | ruby:2.2    | Rails   |
      | openshift/postgresql-92-centos7 | <%= product_docker_repo %>openshift3/postgresql-92-rhel7  | rails-ex   | rails-postgresql.json  | rails-postgresql-example | ruby:2.0    | ruby:2.2    | Rails   |

  # @author cryan@redhat.com
  # @case_id 499621 499622
  Scenario Outline: Application with base images with oc command
    Given I have a project
    When I run the :new_app client command with:
      | file | <json> |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | python-sample-build |
    Then the step should succeed
    And the "python-sample-build-1" build was created
    And the "python-sample-build-1" build completed
    When I run the :get client command with:
      | resource | builds |
    Then the step should succeed
    And the output should contain "python-sample-build-1"
    When I run the :get client command with:
      | resource | service |
    Then the step should succeed
    And the output should contain:
      | database |
      | frontend |
    Given I wait for the "frontend" service to become ready
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    Then the output should contain "OpenShift"
    Examples:
      | json |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/python-27-rhel7-stibuild.json |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc499622/python-27-centos7-stibuild.json |

  # @author wzheng@redhat.com
  # @case_id 508716
  Scenario: Cakephp-ex quickstart hot deploy test - php-55-rhel7
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift/cakephp-ex/6578f1815463db2cafcab3860ca8b8dda822e434/openshift/templates/cakephp.json"
    Given I replace lines in "cakephp.json":
      | 5.6 | 5.5 |
    When I run the :new_app client command with:
      | file | cakephp.json |
    Then the step should succeed
    When I use the "cakephp-example" service
    Then I wait for a server to become available via the "cakephp-example" route
    Then the output should contain "Welcome to OpenShift"
    Given I wait for the "cakephp-example" service to become ready
    When I execute on the pod:
      | sed | -i | s/Welcome/hotdeploy_test/g | /opt/app-root/src/app/View/Layouts/default.ctp |
    Then the step should succeed
    When I use the "cakephp-example" service
    Then I wait for a server to become available via the "cakephp-example" route
    Then the output should contain "hotdeploy_test"
