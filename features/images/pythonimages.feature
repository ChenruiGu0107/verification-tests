Feature: Openshift build and configuration of enviroment variables check

  # @author wewang@redhat.com
  # @case_id 500963
  Scenario: Application with python-34-rhel7 base images lifecycle
    Given I have a project
    When I run the :new_app client command with:
      | file |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/python-34-rhel7-stibuild.json |
    Then the step should succeed
    Given I wait for the "frontend" service to become ready
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain:
      | OpenShift |

  # @author cryan@redhat.com
  # @case_id 534871 534872 534869 534870
  Scenario Outline: Add PIP_INDEX_URL env var to Python S2I
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/python:<py_image>~https://github.com/openshift/django-ex |
      | e        | PIP_INDEX_URL=http://not/a/valid/index                             |
    Then the step should succeed
    Given the "django-ex-1" build finishes
    When I run the :logs client command with:
      | resource_name | bc/django-ex |
    Then the output should contain "Cannot fetch index base URL http://not/a/valid/index/"
    Examples:
      | py_image |
      | 2.7      |
      | 3.3      |
      | 3.4      |
      | 3.5      |

  # @author wewang@redhat.com
  # @case_id 530156 530157 530158 530159
  Scenario Outline: Update python image to autoconfigure based on available memory
    Given I have a project
    When I create a new application with:
      | app_repo     | <app_repo>     |
      | image_stream | <image_stream> |
    Then the step should succeed
    And the "django-ex-1" build was created
    And the "django-ex-1" build completed
    And I wait for the pod named "django-ex-1-deploy" to die
    And a pod becomes ready with labels:
      | app=django-ex          |
      | deployment=django-ex-1 |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %>      |
    Then the step should succeed
    And the output should match 4 times:
      | Booting worker with pid:\\s+[1-9]\d* |
    When I run the :patch client command with:
      | resource      | dc        |
      | resource_name | django-ex |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"django-ex","resources":{"limits":{"memory":"128Mi"}}}]}}}} |
    Then the step should succeed
    And I wait for the pod named "django-ex-2-deploy" to die
    And a pod becomes ready with labels:
      | app=django-ex          |
      | deployment=django-ex-2 |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %>     |
    Then the step should succeed
    And the output should match 4 times:
      |Booting worker with pid:\\s+[1-9]\d* |
    When I run the :env client command with:
      | resource | dc/django-ex             |
      | e        | WEB_CONCURRENCY=3        |
    Then the step should succeed
    And I wait for the pod named "django-ex-3-deploy" to die
    And a pod becomes ready with labels:
      | app=django-ex                       |
      | deployment=django-ex-3              |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %>     |
    Then the step should succeed
    And the output should match 3 times:
      |Booting worker with pid:\\s+[1-9]\d* |

    Examples:
      | app_repo | image_stream |
      | https://github.com/openshift/django-ex  | openshift/python:2.7 |
      | https://github.com/openshift/django-ex  | openshift/python:3.4 |
      | https://github.com/openshift/django-ex  | openshift/python:3.5 |
      | https://github.com/openshift/django-ex  | openshift/python:3.3 |
