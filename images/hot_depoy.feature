Feature: hotdeploy.feature

  # @author wzheng@redhat.com
  @smoke
  Scenario Outline: Hot deploy test
    Given I have a project
    When I create a new application with:
      | app_repo     | <app_repo>     |
      | image_stream | <image_stream> |
      | env          | <env>          |
    Then the step should succeed
    And the "<buildcfg>-1" build was created
    And the "<buildcfg>-1" build completed
    Given I wait for the "<buildcfg>" service to become ready up to 300 seconds
    And I get the service pods
    When I execute on the pod:
      | sed | -i | <parameter> | <file_name> |
    Then the step should succeed
    When I expose the "<buildcfg>" service
    Then I wait for a web server to become available via the "<buildcfg>" route
    And the output should contain "hotdeploy_test"

    Examples:
      | app_repo                                               | image_stream         | env                         | buildcfg           | parameter                  | file_name                                              |
      | https://github.com/openshift-qe/php-example-app.git    | openshift/php:5.5    | OPCACHE_REVALIDATE_FREQ=0   | php-example-app    | s/Hello/hotdeploy_test/g   | index.php                                              | # @case_id OCP-12253
      | https://github.com/openshift-qe/php-example-app.git    | openshift/php:5.6    | OPCACHE_REVALIDATE_FREQ=0   | php-example-app    | s/Hello/hotdeploy_test/g   | index.php                                              | # @case_id OCP-12318
      | https://github.com/openshift-qe/php-example-app.git    | openshift/php:7.0    | OPCACHE_REVALIDATE_FREQ=0   | php-example-app    | s/Hello/hotdeploy_test/g   | index.php                                              | # @case_id OCP-12327
      | https://github.com/openshift-qe/django-ex.git          | openshift/python:2.7 | APP_CONFIG=gunicorn.conf.py | django-ex          | s/Welcome/hotdeploy_test/g | /opt/app-root/src/welcome/templates/welcome/index.html | # @case_id OCP-12366
      | https://github.com/openshift-qe/django-ex.git          | openshift/python:3.3 | APP_CONFIG=gunicorn.conf.py | django-ex          | s/Welcome/hotdeploy_test/g | /opt/app-root/src/welcome/templates/welcome/index.html | # @case_id OCP-12406
      | https://github.com/openshift-qe/django-ex.git          | openshift/python:3.4 | APP_CONFIG=gunicorn.conf.py | django-ex          | s/Welcome/hotdeploy_test/g | /opt/app-root/src/welcome/templates/welcome/index.html | # @case_id OCP-12435
      | https://github.com/openshift-qe/django-ex.git          | openshift/python:3.5 | APP_CONFIG=gunicorn.conf.py | django-ex          | s/Welcome/hotdeploy_test/g | /opt/app-root/src/welcome/templates/welcome/index.html | # @case_id OCP-12324
      | https://github.com/openshift-qe/sinatra-hot-deploy.git | openshift/ruby:2.0   | RACK_ENV=development        | sinatra-hot-deploy | s/legen/hotdeploy_test/g   | config.ru                                              | # @case_id OCP-12454
  # @author wzheng@redhat.com
  @smoke
  Scenario Outline: Enable hot deploy for sinatra app - ruby-rhel7 which is created from imagestream via oc new-app
    Given I have a project
    When I create a new application with:
      | app_repo |https://github.com/openshift-qe/hot-deploy-ruby.git |
      | image_stream | openshift/<image> |
      | env | RACK_ENV=development |
    Then the step should succeed
    And the "hot-deploy-ruby-1" build was created
    And the "hot-deploy-ruby-1" build completed
    Given I wait for the "hot-deploy-ruby" service to become ready up to 300 seconds
    And I get the service pods
    When I execute on the pod:
      | sed | -i | s/Hello/hotdeploy_test/g | app.rb |
    Then the step should succeed
    When I expose the "hot-deploy-ruby" service
    Then I wait for a web server to become available via the "hot-deploy-ruby" route
    And the output should contain "hotdeploy_test"

    Examples:
      |image|
      |ruby:2.2| # @case_id OCP-12470
