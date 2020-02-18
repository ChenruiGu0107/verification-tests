Feature: Openshift build and configuration of enviroment variables check

  # @author cryan@redhat.com
  Scenario Outline: Add PIP_INDEX_URL env var to Python S2I
    Given I have a project
    When I run the :new_build client command with:
      | app_repo | openshift/python:<py_image>~https://github.com/sclorg/django-ex |
      | e        | PIP_INDEX_URL=http://not/a/valid/index                             |
    Then the step should succeed
    Given the "django-ex-1" build failed
    When I run the :logs client command with:
      | resource_name | bc/django-ex |
    Then the output should match "Cannot fetch index base URL http://not/a/valid/index/|Max retries exceeded with url: http://not/a/valid/index/django/"
    Examples:
      | py_image |
      | 2.7      | # @case_id OCP-10272
      | 3.3      | # @case_id OCP-10271
      | 3.4      | # @case_id OCP-10273
      | 3.5      | # @case_id OCP-10274

  # @author wewang@redhat.com
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
    And the expression should be true> [2*cb.number_of_cores, 12].min + 1 == cb.number_of_python_progress
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
    Then the expression should be true> 3==cb.number_of_python_progress
    When I run the :set_env client command with:
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
      | https://github.com/sclorg/django-ex  | openshift/python:2.7 | # @case_id OCP-10878
      | https://github.com/sclorg/django-ex  | openshift/python:3.4 | # @case_id OCP-11603
      | https://github.com/sclorg/django-ex  | openshift/python:3.5 | # @case_id OCP-11806
      | https://github.com/sclorg/django-ex  | openshift/python:3.3 | # @case_id OCP-11300
