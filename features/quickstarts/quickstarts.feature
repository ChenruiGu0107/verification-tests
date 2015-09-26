Feature: quickstarts.feature

  # @author cryan@redhat.com
  # @author haowang@redhat.com
  # @author akostadi@redhat.com
  # @case_id 497474 492284
  Scenario Outline: Rails-ex quickstart test - ruby-20
    Given I have a project

    And I download a file from "https://raw.githubusercontent.com/openshift-qe/rails-ex/master/openshift/templates/rails-postgresql.json"
    And I replace lines in "rails-postgresql.json":
      |openshift/postgresql-92-centos7|<image_tag>|
    When I run the :process client command with:
      | f | rails-postgresql.json |
      | v | SOURCE_REPOSITORY_URL=https://github.com/openshift-qe/rails-ex.git|
    Then the step should succeed
    Given I save the output to file> processed-stibuild.json
    When I run the :create client command with:
      | f | processed-stibuild.json |
    Then the step should succeed

    When I run the :start_build client command with:
      | buildconfig | rails-postgresql-example |
    Then the step should succeed
    And the "rails-postgresql-example-1" build was created
    And the "rails-postgresql-example-1" build completed
    And all pods in the project are ready

    When I use the "rails-postgresql-example" service
    Then I wait for a server to become available via the "rails-postgresql-example" route

    When I run the :env client command with:
      | resource | dc/rails-postgresql-example |
      | keyval   | RAILS_ENV=development |
    And I run the :start_build client command with:
      | buildconfig | rails-postgresql-example |
    Then the "rails-postgresql-example-2" build was created
    And the "rails-postgresql-example-2" build completed
    And all pods in the project are ready

    When I get project builds
    Then the step should succeed
    And the output should not contain "static"

    Examples: OS Type
      | image_tag                                                   |
      | <%= project_docker_repo %>openshift/postgresql-92-centos7   |
      | <%= product_docker_repo %>openshift3/postgresql-92-rhel7         |

  # @author cryan@redhat.com
  # @case_id 492613 494849
  Scenario Outline: Django-ex quickstart test - python-33
    Given I have a project

    And I download a file from "https://raw.githubusercontent.com/openshift/django-ex/master/openshift/templates/django-postgresql.json"
    And I replace lines in "django-postgresql.json":
      |openshift/postgresql-92-centos7|<image_tag>|
    When I run the :process client command with:
      | f | django-postgresql.json |
      | v | SOURCE_REPOSITORY_URL=https://github.com/openshift/django-ex.git|
    Then the step should succeed
    Given I save the output to file> processed-stibuild.json
    When I run the :create client command with:
      | f | processed-stibuild.json |
    Then the step should succeed

    When I run the :start_build client command with:
      | buildconfig | django-psql-example |
    Then the step should succeed
    And the "django-psql-example-1" build was created
    And the "django-psql-example-1" build completed
    And all pods in the project are ready

    When I use the "django-psql-example" service
    Then I wait for a server to become available via the "django-psql-example" route

    And I run the :start_build client command with:
      | buildconfig | django-psql-example |
    Then the "django-psql-example-2" build was created
    And the "django-psql-example-2" build completed
    And all pods in the project are ready

    Examples: OS Type
      | image_tag                                                   |
      | <%= project_docker_repo %>openshift/postgresql-92-centos7   |
      | <%= product_docker_repo %>openshift3/postgresql-92-rhel7    |
