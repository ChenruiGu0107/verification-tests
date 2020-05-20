Feature: Upgrade images feature
  # @author wewang@redhat.com
  Scenario Outline: Image upgrade test for rhel7 images in OCP
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | registry.access.redhat.com/<image>~<repo> |
      | context_dir  | <context_dir>                             |
    Then the step should succeed
    And the "<app_name>-1" build was created
    And the "<app_name>-1" build completed
    And a pod becomes ready with labels:
      | app=<app_name> |
    When I run the :patch client command with:
      | resource      | buildconfig |
      | resource_name | <app_name>  |
      | p | {"spec":{"strategy":{"sourceStrategy":{"from":{"kind":"ImageStreamTag","name":"<istag>","namespace":"openshift"}}}}} |
    Then the step should succeed
    And the "<app_name>-2" build was created
    And the "<app_name>-2" build completed
    And a pod becomes ready with labels:
      | app=<app_name> |
    When I expose the "<app_name>" service
    Then I wait for a web server to become available via the "<app_name>" route
    Then the output should contain "<display_info>"

    Examples:
      | image                 | image_stream    |repo                                               |context_dir | app_name         | display_info                 | istag      |
      | rhscl/python-27-rhel7 | python-27-rhel7 |https://github.com/sclorg/django-ex.git         |            | django-ex        | Welcome to your Django       | python:2.7 | # @case_id OCP-9670
      | rhscl/python-34-rhel7 | python-34-rhel7 |https://github.com/sclorg/django-ex.git         |            | django-ex        | Welcome to your Django       | python:3.4 | # @case_id OCP-9671
      | rhscl/perl-520-rhel7  | perl-520-rhel7  |https://github.com/sclorg/dancer-ex.git         |            | dancer-ex        | Welcome to your Dancer       | perl:5.20  | # @case_id OCP-9672

  # @author wewang@redhat.com
  Scenario Outline: Image upgrade test for postgresql rhel7 in OCP
    Given I have a project
    And I run the :import_image client command with:
      | image_name |  postgresql                              |
      | from       | registry.access.redhat.com/rhscl/<image> |
      | confirm    | true                                     |
      | insecure   | true                                     |
      | all        | true                                     |
    Then the step should succeed
    And I download a file from "https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/postgresql-persistent-template.json"
    And I replace lines in "postgresql-persistent-template.json":
      | "value": "9.6"       | "value": "<version>"           |
      | "value": "openshift" | "value": "<%= project.name %>" |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | postgresql-persistent-template.json |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=postgresql-1 |
    And I wait up to 60 seconds for the steps to pass:
    """
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'CREATE TABLE tbl (col1 VARCHAR(20), col2 VARCHAR(20));' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    """
    And the output should contain:
      | CREATE TABLE |
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c "INSERT INTO tbl (col1,col2) VALUES ('foo1', 'bar1');" -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    And the output should contain:
      | INSERT 0 1 |
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'SELECT * FROM tbl;' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    And the output should contain:
      | col1 | col2 |
      | foo1 | bar1 |
    When I run the :import_image client command with:
      | image_name | postgresql                                                         |
      | from       | <%= product_docker_repo %>rhscl/<image>                            |
      | confirm    | true                                                               |
      | insecure   | true                                                               |
      | all        | true                                                               |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=postgresql-2 |
    When I execute on the pod:
      | bash | -c | psql -U $POSTGRESQL_USER -c 'SELECT * FROM tbl;' -d $POSTGRESQL_DATABASE |
    Then the step should succeed
    And the output should contain:
      | col1 | col2 |
      | foo1 | bar1 |

    Examples:
      | version | image               |
      | 9.4     | postgresql-94-rhel7 | # @case_id OCP-9680
