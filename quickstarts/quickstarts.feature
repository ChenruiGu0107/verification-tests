Feature: quickstarts.feature
  # @author cryan@redhat.com
  Scenario Outline: Application with base images with oc command
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/<json> |
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
      | json                                                         |
      | image/language-image-templates/python-27-rhel7-stibuild.json | # @case_id OCP-9605

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

