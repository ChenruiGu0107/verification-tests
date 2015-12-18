Feature: hotdeploy.feature

  # @author: wzheng@redhat.com
  # @case_id: 508723,508727,508729,508731,508733,508725
  Scenario Outline: Hot deploy test
    Given I have a project
    When I run the :new_app client command with:
      | app_repo     | <app_repo>     |
      | image_stream | <image_stream> |
      | env          | <env>          |
    Then the step should succeed
    And the "<buildcfg>-1" build was created
    And the "<buildcfg>-1" build completed
    Given I wait for the "<buildcfg>" service to become ready
    When I execute on the pod:
      | bash |
      | -c   |
      | sed -i <parameter> <file_name> |
    Then the step should succeed
    When I expose the "<buildcfg>" service
    Then I wait for a server to become available via the "<buildcfg>" route
    And the output should contain "hotdeploy_test"

    Examples:
      | app_repo | image_stream | env | buildcfg | parameter |  file_name |
      | https://github.com/openshift-qe/php-example-app.git  | openshift/php:5.5 | OPCACHE_REVALIDATE_FREQ=0 | php-example-app | 's/Hello/hotdeploy_test/g' | index.php |
      | https://github.com/openshift-qe/php-example-app.git  | openshift/php:5.6 | OPCACHE_REVALIDATE_FREQ=0 | php-example-app | 's/Hello/hotdeploy_test/g' | index.php |
      | https://github.com/openshift-qe/django-ex.git        | openshift/python:2.7 | APP_CONFIG=gunicorn.conf.py | django-ex  | 's/Welcome/hotdeploy_test/g' | /opt/app-root/src/welcome/templates/welcome/index.html |
      | https://github.com/openshift-qe/django-ex.git        | openshift/python:3.3 | APP_CONFIG=gunicorn.conf.py | django-ex  | 's/Welcome/hotdeploy_test/g' | /opt/app-root/src/welcome/templates/welcome/index.html |
      | https://github.com/openshift-qe/django-ex.git        | openshift/python:3.4 | APP_CONFIG=gunicorn.conf.py | django-ex  | 's/Welcome/hotdeploy_test/g' | /opt/app-root/src/welcome/templates/welcome/index.html |
      | https://github.com/openshift-qe/sinatra-hot-deploy.git | openshift/ruby:2.0 | RACK_ENV=development       | sinatra-hot-deploy | 's/legen/hotdeploy_test/g' | config.ru |
