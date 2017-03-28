Feature: quickstarts.feature

  # @author cryan@redhat.com haowang@redhat.com
  # @case_id 497613 OCP-12609 OCP-12605 OCP-12606 OCP-12539 OCP-12541 OCP-9569 OCP-9570 508737
  Scenario Outline: quickstart test
    Given I have a project
    When I run the :new_app client command with:
      | template | <template> |
    Then the step should succeed
    And the "<buildcfg>-1" build was created
    And the "<buildcfg>-1" build completed
    And <podno> pods become ready with labels:
      |app=<template>|
    When I use the "<buildcfg>" service
    Then I wait for a web server to become available via the "<buildcfg>" route
    Then the output should contain "<output>"

    Examples: OS Type
      | template                  | buildcfg                 | output  | podno |
      | django-psql-example       | django-psql-example      | Django  | 2     |
      | dancer-example            | dancer-example           | Dancer  | 1     |
      | dancer-mysql-example      | dancer-mysql-example     | Dancer  | 2     |
      | cakephp-mysql-example     | cakephp-mysql-example    | CakePHP | 2     |
      | nodejs-mongodb-example    | nodejs-mongodb-example   | Node.js | 2     |
      | rails-postgresql-example  | rails-postgresql-example | Rails   | 2     |

  # @author cryan@redhat.com
  # @case_id OCP-9605 OCP-12650
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
  # @case_id OCP-11178
  Scenario: Cakephp-ex quickstart hot deploy test - php-55-rhel7
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift/cakephp-ex/master/openshift/templates/cakephp.json"
    Given I replace lines in "cakephp.json":
      | 5.6 | 5.5 |
    When I run the :new_app client command with:
      | file | cakephp.json |
    Then the step should succeed
    When I use the "cakephp-example" service
    Then I wait for a web server to become available via the "cakephp-example" route
    Then the output should contain "Welcome to OpenShift"
    Given I wait for the "cakephp-example" service to become ready
    When I execute on the pod:
      | sed | -i | s/Welcome/hotdeploy_test/g | /opt/app-root/src/app/View/Layouts/default.ctp |
    Then the step should succeed
    When I use the "cakephp-example" service
    Then I wait for a web server to become available via the "cakephp-example" route
    Then the output should contain "hotdeploy_test"

  # @author wzheng@redhat.com
  # @case_id OCP-9810
  Scenario: Build with golang-ex repo
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/golang-ex/master/openshift/templates/beego.json |
    Then the step should succeed
    And the "beego-example-1" build was created
    And the "beego-example-1" build completed
    Then I wait for the "beego-example" service to become ready
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    Then the output should contain "Welcome to chat - beego sample app: Web IM"

  # @author wzheng@redhat.com
  # @case_id OCP-12818
  Scenario: Cakephp-ex quickstart with cakephp.json - php-70-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/cakephp-ex/master/openshift/templates/cakephp.json |
    Then the step should succeed
    And the "cakephp-example-1" build was created
    And the "cakephp-example-1" build completed
    Then I wait for the "cakephp-example" service to become ready
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    Then the output should contain "Welcome to your CakePHP application on OpenShift"

  # @author dyan@redhat.com
  # @case_id OCP-10611
  Scenario: Use the template parameters for the entire config
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc479059/application-template-parameters.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed

  # @author cryan@redhat.com
  # @case_id 528401 528402 528403 492613 508743 OCP-12603 OCP-12264 529323 OCP-12296
  # @bug_id 1343184
  Scenario Outline: quickstart version test
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift/<repo>/master/openshift/templates/<template>"
    And I replace lines in "<template>":
      | <lang_old>       | <lang_new>       |
      | <db_version_old> | <db_version_new> |
    When I run the :new_app client command with:
      | file  | <template>                                                |
      | param | SOURCE_REPOSITORY_URL=https://github.com/openshift/<repo> |
    Then the step should succeed
    Given the "<name>-1" build completes
    And a pod becomes ready with labels:
      | app=<name> |
    And I wait for the "<name>" service to become ready
    And I wait for a web server to become available via the "<name>" route
    Then the output should match "Welcome to your \w+ application on OpenShift"

    Examples:
      | lang_old   | lang_new   | db_version_old | db_version_new | template               | name                     | repo      |
      | python:3.5 | python:2.7 |                |                | django.json            | django-example           | django-ex |
      | python:3.5 | python:3.3 |                |                | django.json            | django-example           | django-ex |
      | python:3.5 | python:3.4 |                |                | django.json            | django-example           | django-ex |
      | python:3.5 | python:2.7 | postgresql:9.5 | postgresql:9.2 | django-postgresql.json | django-psql-example      | django-ex |
      | python:3.5 | python:3.3 | postgresql:9.5 | postgresql:9.2 | django-postgresql.json | django-psql-example      | django-ex |
      | python:3.5 | python:3.4 | postgresql:9.5 | postgresql:9.4 | django-postgresql.json | django-psql-example      | django-ex |
      | ruby:2.3   | ruby:2.0   |                |                | rails-postgresql.json  | rails-postgresql-example | rails-ex  |
      | ruby:2.3   | ruby:2.2   |                |                | rails-postgresql.json  | rails-postgresql-example | rails-ex  |
      | perl:5.20  | perl:5.16  |                |                | dancer.json            | dancer-example           | dancer-ex |
      | perl:5.20  | perl:5.16  |                |                | dancer-mysql.json      | dancer-mysql-example     | dancer-ex |

  # @author dyan@redhat.com
  # @case_id OCP-12602 OCP-12603
  Scenario Outline: Dancer-ex quickstart test with perl-516-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | file | <template> |
    Then the step should succeed
    And the "<buildcfg>-1" build was created
    And the "<buildcfg>-1" build completed
    And <podno> pods become ready with labels:
      | app=<buildcfg> |
    When I use the "<buildcfg>" service
    Then I wait for a web server to become available via the "<buildcfg>" route
    Then the output should contain "<output>"

    Examples: OS Type
      | template                                                                                                | buildcfg             | output  | podno |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc492612/dancer.json       | dancer-example       | Dancer  | 1     |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc508973/dancer-mysql.json | dancer-mysql-example | Dancer  | 2     |

  # @author xiuwang@redhat.com
  Scenario Outline: quickstart with persistent volume test
    Given I have a project
    When I run the :new_app client command with:
      | template | <template> |
    When I run the :patch client command with:
      | resource      | pvc                                                                             |
      | resource_name | <pvc>                                                                           |
      | p             | {"metadata":{"annotations":{"volume.alpha.kubernetes.io/storage-class":"foo"}}} |
    Then the step should succeed
    And the "<pvc>" PVC becomes :bound within 300 seconds
    Then the step should succeed
    And the "<buildcfg>-1" build was created
    And the "<buildcfg>-1" build completed
    And <podno> pods become ready with labels:
      |app=<template>|
    When I use the "<buildcfg>" service
    Then I wait for a web server to become available via the "<buildcfg>" route
    Then the output should contain "<output>"

    Examples: OS Type
      | template                 |pvc       | buildcfg               | output | podno |
      | django-psql-persistent   |postgresql| django-psql-persistent | Django | 2     | # @case_id OCP-12825
      | rails-pgsql-persistent   |postgresql| rails-pgsql-persistent | Rails  | 2     | # @case_id OCP-12822
      | cakephp-mysql-persistent |mysql     |cakephp-mysql-persistent| CakePHP| 2     | # @case_id OCP-12492
      | dancer-mysql-persistent  |database  |dancer-mysql-persistent | Dancer | 2     | # @case_id OCP-13658
      | nodejs-mongo-persistent  |mongodb   |nodejs-mongo-persistent | Node.js| 2     | # @case_id OCP-12216
