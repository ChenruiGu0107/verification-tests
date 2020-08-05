Feature: Configuration of environment variables check
  # @author cryan@redhat.com
  # @case_id OCP-11143
  Scenario: Substitute environment variables into a container's command
    Given I have a project
    Given I obtain test data file "container/commandtest.json"
    When I run the :create client command with:
      | f | commandtest.json |
    Then the step should succeed
    Given the pod named "expansion-pod" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | expansion-pod |
    Then the step should succeed
    And the output should contain "http"

  # @author pruan@redhat.com
  # @case_id OCP-10646
  Scenario: Substitute environment variables into a container's args
    Given I have a project
    Given I obtain test data file "container/argstest.json"
    When I run the :create client command with:
      | f |  argstest.json |
    Then the step should succeed
    Given the pod named "expansion-pod" status becomes :running
    When I run the :logs client command with:
      | resource_name | expansion-pod |
    Then the step should succeed
    And the output should contain:
      |  serving on 8080 |
      |  serving on 8888 |

  # @author pruan@redhat.com
  # @case_id OCP-11497
  Scenario: Substitute environment variables into a container's env
    Given I have a project
    Given I obtain test data file "templates/tc493678/envtest.json"
    When I run the :create client command with:
      | f | envtest.json |
    Then the step should succeed
    Given the pod named "hello-openshift" status becomes :running
    When I run the :set_env client command with:
      | resource | pod             |
      | keyval   | hello-openshift |
      | list     | true            |
    Then the step should succeed
    And the output should match:
      | zzhao=redhat                    |
      | test2=\$\(zzhao\)               |
      | test3=___\$\(zzhao\)___         |
      | test4=\$\$\(zzhao\)_\$\(test2\) |
      | test6=\$\(zzhao\$\(zzhao\)      |
      | test7=\$\$\$\$\$\$\(zzhao\)     |
      | test8=\$\$\$\$\$\$\$\(zzhao\)   |

  # @author haowang@redhat.com
  @no-online
  Scenario Outline: Users can override the the env tuned by ruby base image
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | <imagestream>~https://github.com/sclorg/ruby-ex |
    Then the step should succeed
    Given the "ruby-ex-1" build completes
    Given a pod becomes ready with labels:
      | app=ruby-ex |
    When I run the :set_env client command with:
      | resource | dc/ruby-ex          |
      | e        | PUMA_MIN_THREADS=1  |
      | e        | PUMA_MAX_THREADS=14 |
      | e        | PUMA_WORKERS=5      |
    Given a pod becomes ready with labels:
      | deployment=ruby-ex-2 |
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | pod/<%= pod.name %>|
    Then the output should contain:
      | Min threads: 1     |
      | max threads: 14    |
      | Process workers: 5 |
    """
    Examples:
      | imagestream        |
      | openshift/ruby:2.5 | # @case_id OCP-11784

  # @author haowang@redhat.com
  # @case_id OCP-13141
  Scenario: Users can override the the env tuned by ruby base image -ruby-20-rhel7
    Given I have a project
    Given I obtain test data file "image/language-image-templates/OCP-13141/template.json"
    When I run the :create client command with:
      | f | template.json |
    Then the step should succeed
    Given the "rails-ex-1" build was created
    And the "rails-ex-1" build completed
    Given 1 pods become ready with labels:
      | app=rails-ex          |
      | deployment=rails-ex-1 |
    When I run the :set_env client command with:
      | resource | dc/rails-ex         |
      | e        | PUMA_MIN_THREADS=1  |
      | e        | PUMA_MAX_THREADS=14 |
      | e        | PUMA_WORKERS=5      |
    Given a pod becomes ready with labels:
      | deployment=rails-ex-2 |
    Given I wait up to 30 seconds for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name | pod/<%= pod.name %>|
    Then the output should contain:
      | Min threads: 1     |
      | max threads: 14    |
      | Process workers: 5 |
    """
