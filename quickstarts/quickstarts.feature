Feature: quickstarts.feature
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
