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
    Given the "django-ex-1" build failed
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
  @no-online
  Scenario Outline: Update python image to autoconfigure based on available memory
    Given I have a project
    When I create a new application with:
      | app_repo     | <app_repo>     |
      | image_stream | <image_stream> |
    Then the step should succeed
    When I run the :set_probe client command with:
      | resource  | dc/django-ex |
      | readiness |              |
      | open_tcp  | 8080         |
    Then the step should succeed
    And the "django-ex-1" build was created
    And the "django-ex-1" build completed
    And I wait for the pod named "django-ex-1-deploy" to die
    And a pod becomes ready with labels:
      | app=django-ex          |
      | deployment=django-ex-1 |
    When I execute on the pod:
      | bash            |
      | -c              |
      | cgroup-limits \| grep NUMBER_OF_CORES \| cut -d = -f 2 |
    Then the step should succeed
    Given evaluation of `@result[:response].strip.to_i` is stored in the :number_of_cores clipboard
    When I execute on the pod:
      | bash     |
      | -c       |
      | ps -ef \| grep gunicorn \| grep -v grep \| wc -l |
    Then the step should succeed
    Given evaluation of `@result[:response].strip.to_i` is stored in the :number_of_python_progress clipboard
    And the expression should be true> cb.number_of_cores * 2 + 1 == cb.number_of_python_progress
    When I run the :patch client command with:
      | resource      | dc        |
      | resource_name | django-ex |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"django-ex","resources":{"limits":{"memory":"128Mi"}}}]}}}} |
    Then the step should succeed
    And I wait for the pod named "django-ex-2-deploy" to die
    And a pod becomes ready with labels:
      | app=django-ex          |
      | deployment=django-ex-2 |
    When I execute on the pod:
      | bash            |
      | -c              |
      | cgroup-limits \| grep NUMBER_OF_CORES \| cut -d = -f 2 |
    Then the step should succeed
    Given evaluation of `@result[:response].strip.to_i` is stored in the :number_of_cores clipboard
    When I execute on the pod:
      | bash     |
      | -c       |
      | ps -ef \| grep gunicorn \| grep -v grep \| wc -l |
    Then the step should succeed
    Given evaluation of `@result[:response].strip.to_i` is stored in the :number_of_python_progress clipboard
    Then the expression should be true> (8 > cb.number_of_cores ? cb.number_of_cores * 2 : 8) == cb.number_of_python_progress - 1
    When I run the :env client command with:
      | resource | dc/django-ex             |
      | e        | WEB_CONCURRENCY=3        |
    Then the step should succeed
    And I wait for the pod named "django-ex-3-deploy" to die
    And a pod becomes ready with labels:
      | app=django-ex                       |
      | deployment=django-ex-3              |
    When I execute on the pod:
      | bash     |
      | -c       |
      | ps -ef \| grep gunicorn \| grep -v grep \| wc -l |
    Then the step should succeed
    Given evaluation of `@result[:response].strip.to_i` is stored in the :number_of_python_progress clipboard
    And the expression should be true> 4 == cb.number_of_python_progress

    Examples:
      | app_repo | image_stream |
      | https://github.com/openshift/django-ex  | openshift/python:2.7 |
      | https://github.com/openshift/django-ex  | openshift/python:3.4 |
      | https://github.com/openshift/django-ex  | openshift/python:3.5 |
      | https://github.com/openshift/django-ex  | openshift/python:3.3 |
