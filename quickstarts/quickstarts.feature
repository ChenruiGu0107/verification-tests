Feature: quickstarts.feature

  # @author shiywang@redhat.com
  # @case_id OCP-12824
  Scenario: Django-ex quickstart test
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://raw.githubusercontent.com/openshift/django-ex/master/openshift/templates/django.json |
    Then the step should succeed
    And the "django-example-1" build was created
    And the "django-example-1" build completed
    And I wait for the "django-example" service to become ready up to 300 seconds
    Then I wait for a web server to become available via the "django-example" route
    Then the output should contain "Django"


  # @author cryan@redhat.com
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
    Given I wait for the "frontend" service to become ready up to 300 seconds
    And I get the service pods
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    Then the output should contain "OpenShift"
    Examples:
      | json |
      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/image/language-image-templates/python-27-rhel7-stibuild.json | # @case_id OCP-9605
      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/templates/tc499622/python-27-centos7-stibuild.json | # @case_id OCP-12650

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
    Given I wait for the "cakephp-example" service to become ready up to 300 seconds
    And I get the service pods
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
    Then I wait for the "beego-example" service to become ready up to 300 seconds
    And I get the service pods
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    Then the output should contain "Welcome to chat - beego sample app: Web IM"

  # @author wzheng@redhat.com
  # @case_id OCP-12819
  Scenario: Dancer-ex quickstart dancer-example template test
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/dancer-ex/master/openshift/templates/dancer.json |
    Then the step should succeed
    And the "dancer-example-1" build was created
    And the "dancer-example-1" build completed
    Then I wait for the "dancer-example" service to become ready up to 300 seconds
    And I get the service pods
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    Then the output should contain "Welcome to your Dancer application on OpenShift"

  # @author wzheng@redhat.com
  # @case_id OCP-12818
  Scenario: Cakephp-ex quickstart with cakephp.json - php-70-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/cakephp-ex/master/openshift/templates/cakephp.json |
    Then the step should succeed
    And the "cakephp-example-1" build was created
    And the "cakephp-example-1" build completed
    Then I wait for the "cakephp-example" service to become ready up to 300 seconds
    And I get the service pods
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    Then the output should contain "Welcome to your CakePHP application on OpenShift"

  # @author wzheng@redhat.com
  # @case_id OCP-12823
  Scenario: Nodejs-ex quickstart test with nodejs.json - nodejs-6-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift/nodejs-ex/master/openshift/templates/nodejs.json |
    Then the step should succeed
    And the "nodejs-example-1" build was created
    And the "nodejs-example-1" build completed
    Then I wait for the "nodejs-example" service to become ready up to 300 seconds
    And I get the service pods
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    Then the output should contain "Welcome to your Node.js application on OpenShift"

  # @author dyan@redhat.com
  # @case_id OCP-10611
  Scenario: Use the template parameters for the entire config
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/templates/tc479059/application-template-parameters.json |
    Then the step should succeed
    And the "ruby-sample-build-1" build was created
    And the "ruby-sample-build-1" build completed

  # @author cryan@redhat.com
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
    And I wait for the "<name>" service to become ready up to 300 seconds
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
      | perl:5.24  | perl:5.16  |                |                | dancer.json            | dancer-example           | dancer-ex |
      | perl:5.24  | perl:5.16  |                |                | dancer-mysql.json      | dancer-mysql-example     | dancer-ex |

  # @author dyan@redhat.com
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
      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/templates/tc492612/dancer.json       | dancer-example       | Dancer  | 1     | # @case_id OCP-12602
      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/templates/tc508973/dancer-mysql.json | dancer-mysql-example | Dancer  | 2     | # @case_id OCP-12603

  # @author xiuwang@redhat.com
  # @case_id OCP-13750
  Scenario: Dotnet-example quickstart test with dotnet-1.1
    Given I have a project
    When I run the :new_app client command with:
      | template | dotnet-example                       |
      | p        | DOTNET_IMAGE_STREAM_TAG=dotnet:1.1   |
      | p        | SOURCE_REPOSITORY_REF=dotnetcore-1.1 |
    Then the step should succeed
    And the "dotnet-example-1" build was created
    And the "dotnet-example-1" build completed
    And I wait for the "dotnet-example" service to become ready up to 300 seconds
    Then I wait for a web server to become available via the "dotnet-example" route
    Then the output should contain "ASP.NET"

  # @author wewang@redhat.com
  # @case_id OCP-14712
  Scenario: Httpd-example with 2.4 quick start test
    Given I have a project
    When I run the :new_app client command with:
      | template | httpd-example |
    Then the step should succeed
    And the "httpd-example-1" build was created
    And the "httpd-example-1" build completed
    And I wait for the "httpd-example" service to become ready up to 300 seconds
    Then I wait for a web server to become available via the "httpd-example" route
    Then the output should contain "httpd application"

