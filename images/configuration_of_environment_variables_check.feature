Feature: Configuration of environment variables check

  # @author xiuwang@redhat.com
  # @case_id OCP-12646 OCP-12647
  Scenario Outline: Check environment variables of ruby-20 image
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-<os>.json |
      | n | <%= project.name %> |
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/ruby20rhel7-env-sti.json |
    Then the step should succeed
    Given I wait for the "frontend" service to become ready up to 300 seconds
    When I run the :describe client command with:
      | resource | build |
      | name | ruby-sample-build-1 |
    Then the step should succeed
    And the output should contain "<image>"
    When I execute on the pod:
      | env |
    Then the step should succeed
    And the output should contain:
      | RACK_ENV=production            |
      | RAILS_ENV=production           |
      | DISABLE_ASSET_COMPILATION=true |
    Examples:
      | os | image |
      | rhel7   | <%= product_docker_repo %>openshift3/ruby-20-rhel7 |
    #| centos7 | docker.io/openshift/ruby-20-centos7 |

  # @author xiuwang@redhat.com
  Scenario Outline: Check environment variables of perl image
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/<template> |
    Then the step should succeed
    Given I wait for the "frontend" service to become ready up to 300 seconds
    And I get the service pods
    When I execute on the pod:
      | env |
    Then the step should succeed
    And the output should contain:
      | ENABLE_CPAN_TEST=on |
      | CPAN_MIRROR=        |
    Examples:
      | template                       |
      | perl516rhel7-env-sti.json      | # @case_id OCP-12648
      | perl-516-centos7-stibuild.json | # @case_id OCP-12649

  # @author wzheng@redhat.com
  Scenario Outline: Configuration of enviroment variables check
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/<template> |
    Then the step should succeed
    Given the "php-sample-build-1" build was created
    Given the "php-sample-build-1" build completed
    Given I wait for the "frontend" service to become ready up to 300 seconds
    And I get the service pods
    When I execute on the pod:
      | env |
    Then the step should succeed
    And the output should contain:
      | ERROR_REPORTING=E_ALL & ~E_NOTICE |
      | DISPLAY_ERRORS=ON |
      | DISPLAY_STARTUP_ERRORS=OFF |
      | TRACK_ERRORS=OFF |
      | HTML_ERRORS=ON |
      | INCLUDE_PATH=/opt/app-root/src |
      | SESSION_PATH=/tmp/sessions |
      | OPCACHE_MEMORY_CONSUMPTION=16M |
      | PHPRC=/opt/rh/php55/root/etc/ |
      | PHP_INI_SCAN_DIR=/opt/rh/php55/root/etc/ |
    Examples:
      | template                     |
      | php-55-rhel7-stibuild.json   | # @case_id OCP-12645
      | php-55-centos7-stibuild.json | # @case_id OCP-9599

  # @author wewang@redhat.com
  Scenario Outline: Openshift build and configuration of enviroment variables check - python
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/<template> |
    Then the step should succeed
    Given I wait for the "frontend" service to become ready up to 300 seconds
    And I get the service pods
    And I wait for the steps to pass:
    """
    When I execute on the pod:
      | curl | -s | <%= service.url %> |
    Then the step should succeed
    """
    And the output should contain:
      | Hello World |
    Given a pod becomes ready with labels:
      | deployment=frontend-1 |
    When I execute on the pod:
      | env |
    Then the step should succeed
    And the output should contain:
      | APP_FILE=app.py                       |
      | APP_MODULE=testapp:application        |
      | DISABLE_COLLECTSTATIC=false           |
      | DISABLE_MIGRATE=false                 |
      | APP_CONFIG=<conf>/test/setup-test-app |
    Examples:
      | template                   | conf |
      | python-27-rhel7-var.json   | 2.7  | # @case_id OCP-9603
      | python-27-centos7-var.json | 2.7  | # @case_id OCP-9602
      | python-33-rhel7-var.json   | 3.3  | # @case_id OCP-9601

  # @author cryan@redhat.com
  # @case_id OCP-11143
  Scenario: Substitute environment variables into a container's command
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/container/commandtest.json |
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
    When I run the :create client command with:
      | f |  https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/container/argstest.json |
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
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc493678/envtest.json |
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
      | openshift/ruby:2.2 | # @case_id OCP-11784
      | openshift/ruby:2.3 | # @case_id OCP-12424

  # @author haowang@redhat.com
  # @case_id OCP-11575 OCP-13141
  Scenario Outline: Users can override the the env tuned by ruby base image -ruby-20-rhel7
    Given I have a project
    When I run the :create client command with:
      | f | <template> |
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
    Examples:
      | template        |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/tc521461/template.json |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/OCP-13141/template.json    |
