Feature: php image related tests

  # @author cryan@redhat.com
  # @case_id OCP-9773 OCP-9774
  # @bug_id 1249794
  Scenario Outline: Files can be uploaded to tm folder inside container
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | openshift/php-<image>-centos7~https://github.com/openshift-qe/openshift-php-upload-demo |
      | name     | phpuploaddemo                                                         |
    Then the step should succeed
    Given the "phpuploaddemo-1" build completes
    And a pod becomes ready with labels:
      | app=phpuploaddemo |
    When I expose the "phpuploaddemo" service
    Then the step should succeed
    Given a "test.txt" file is created with the following lines:
    """
    test output
    """
    Given I have a browser with:
      | rules    | lib/rules/web/images/php/         |
      | base_url | http://<%= route.dns(by: user) %> |
    And I wait up to 60 seconds for a web server to become available via the "phpuploaddemo" route
    Then the output should contain "OpenShift File Upload Demonstration"
    When I perform the :upload web action with:
      | upload_file | <%= expand_path("test.txt") %> |
    Then the step should succeed
    Given I execute on the pod:
      | ls | uploaded |
    Then the output should contain "test.txt"
    Given I execute on the pod:
      | cat | uploaded/test.txt |
    Then the output should contain "test output"
    Examples:
      | image |
      | 55    |
      | 56    |

  # @author dyan@redhat.com
  # @case_id OCP-11027 OCP-11408 OCP-11673
  Scenario Outline: Add COMPOSER_MIRROR env var to Php S2I
    Given I have a project
    When I run the :new_build client command with:
      | app_repo    | openshift/php:<image>~https://github.com/openshift-qe/cakephp-ex |
      | e           | COMPOSER_MIRROR=http://not/a/valid/index                         |
    Then the step should succeed
    Given the "cakephp-ex-1" build failed
    When I run the :logs client command with:
      | resource_name | bc/cakephp-ex |
    Then the output should contain "not allow connections to http://not/a/valid/index/"
    Examples:
      | image |
      | 5.5   |
      | 5.6   |
      | 7.0   |