Feature: builderimage.feature
  # @case_id OCP-11502,OCP-11553
  # @author wzheng@redhat.com
  Scenario Outline: Make mysql image work with php image
    Given I have a project
    And I download a file from "<%= BushSlicer::HOME %>/features/tierN/testdata/build/sample-php-rhel7.json"
    And I replace lines in "sample-php-rhel7.json":
      | php:5.5 | <php_image> |
      | registry.access.redhat.com/openshift3/mysql-55-rhel7 | <mysql_image> |
    When I run the :new_app client command with:
      | file | sample-php-rhel7.json |
    Then the step should succeed
    And the "php-sample-build-1" build completed
    Given a pod becomes ready with labels:
      | name=database |
    When I expose the "frontend" service
    Then I wait for a web server to become available via the "frontend" route
    And  the output should match:
      | [Mm]ail_sendmail [Oo]bject           |
      | [Dd]atabase connection is successful |

    Examples:
      | php_image | mysql_image |
      | php:5.5   | <%= product_docker_repo %>openshift3/mysql-55-rhel7 |
      | php:5.6   | <%= product_docker_repo %>rhscl/mysql-56-rhel7      |
