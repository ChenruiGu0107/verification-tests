Feature: rhel8images.feature

  # @author xiuwang@redhat.com
  # @case_id OCP-22950
  Scenario: Using new-app cmd to create app with ruby rhel8 image
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | ruby-25-rhel8                                |
      | app_repo     | https://github.com/sclorg/s2i-ruby-container |
      | context_dir  | 2.5/test/puma-test-app                       |
      | name         | ruby25rhel8                                  |
    Then the step should succeed
    And the "ruby25rhel8-1" build completed
    And a pod becomes ready with labels:
      | deployment=ruby25rhel8-1 |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %> |
    Then the output should contain:
      | Min threads: 0, max threads: 16 |
    When I run the :set_env client command with:
      | e        | PUMA_MIN_THREADS=1  | 
      | e        | PUMA_MAX_THREADS=12 |
      | e        | PUMA_WORKERS=5      |
      | resource | dc/ruby25rhel8      |
    And a pod becomes ready with labels:
      | deployment=ruby25rhel8-2 |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %> |
    Then the output should contain:
      | Process workers: 5              |
      | Min threads: 1, max threads: 12 |

  # @author xiuwang@redhat.com
  # @case_id OCP-22953
  Scenario: Enable hot deploy for ruby app with ruby rhel8 image
    Given I have a project
    When I run the :new_app client command with:
      | image_stream | ruby-25-rhel8                                        |
      | app_repo     | https://github.com/openshift-qe/hot-deploy-ruby.git  |
      | env          | RACK_ENV=development                                 |
      | name         | hotdeploy                                            |
    Then the step should succeed
    And a pod becomes ready with labels:
      | deployment=hotdeploy-1 |
    When I execute on the pod:
      | sed | -i | s/Hello/hotdeploy_test/g  | app.rb |
    Then the step should succeed
    When I expose the "hotdeploy" service
    Then I wait for a web server to become available via the "hotdeploy" route
    And the output should contain "hotdeploy_test"
