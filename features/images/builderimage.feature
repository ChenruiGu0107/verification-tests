Feature: builderimage.feature
  # @case_id 497680
  # @author haowang@redhat.com
  Scenario: Create nodejs + postgresql applicaion - nodejs-010-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | file | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/language-image-templates/nodejs-template-stibuild.json|
    Then the step should succeed
    And the "nodejs-sample-build-1" build was created
    And the "nodejs-sample-build-1" build completed
    And a pod becomes ready with labels:
      |name=frontend|
    And a pod becomes ready with labels:
      |name=database|
    When I expose the "frontend" service
    Then I wait for a server to become available via the "frontend" route
    And  the output should contain "nodejs"
    And  the output should contain "postgresql"

  # @case_id 497642
  # @author wzheng@redhat.com
  Scenario Outline: Make mysql image work with php image
    Given I have a project
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sample-php-rhel7.json"
    And I replace lines in "sample-php-rhel7.json":
      | php:5.5 | <php_image> |
      | registry.access.redhat.com/openshift3/mysql-55-rhel7 | <mysql_image> |
    When I run the :new_app client command with:
      | file | sample-php-rhel7.json |
    Then the step should succeed
    When I run the :start_build client command with:
      | buildconfig | php-sample-build |
    Then the step should succeed
    And the "php-sample-build-1" build completed
    When I expose the "frontend" service
    Then I wait for a server to become available via the "frontend" route
    And  the output should contain "Mail_sendmail Object"
    And  the output should contain "Database connection is successful"

    Examples:
      | php_image | mysql_image |
      | php:5.5   | <%= product_docker_repo %>openshift3/mysql-55-rhel7 |
      | php:5.6   | <%= product_docker_repo %>rhscl/mysql-56-rhel7      |
