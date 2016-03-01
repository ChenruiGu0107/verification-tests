Feature: REST policy related features

  # @author xiaocwan@redhat.com
  # @case_id 476292
  @admin
  Scenario:Project admin/edtor/viewer only could get the project subresources
    Given I have a project
    When I process and create "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/build/sample-php-rhel7.json"
    Then the output should match:
      | imagestream\\s+"origin-php-sample"\\s+created |

    ## post rest request by api with token
    When I perform the :get_subresources_oapi rest request with:
      | project name     | <%= project.name %> |
      | resource_type    | imagestreams        |
      | resource_name    | origin-php-sample   |
    And the step should fail
    Then the expression should be true> @result[:exitstatus] == 405
   
    ## make sure user has right for replicationcontrollers/status which does not include DELETE verb 
    Given the first user is cluster-admin
    When I perform the :delete_subresources_api rest request with:
      | project name     | <%= project.name %>   |
      | resource_type    |replicationcontrollers |
      | resource_name    | database-1            |
    And the step should fail
    Then the expression should be true> @result[:exitstatus] == 405
