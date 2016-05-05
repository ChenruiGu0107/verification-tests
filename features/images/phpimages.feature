Feature: phpimages.feature

  # @author cryan@redhat.com
  # @case_id 499480
  # @bug_id 1253248
  Scenario: session.save_path works well in non privileged mode - php-55-rhel7
    Given I have a project
    When I run the :new_app client command with:
      | app_repo | https://github.com/openshift-qe/ose-php-session |
    Then the step should succeed
    Given the "ose-php-session-1" build completes
    Given 1 pods become ready with labels:
      | app=ose-php-session |
    When I run the :expose client command with:
      | resource | pod |
      | resource_name | <%= pod.name %> |
      | target_port | 8080 |
      | name | myservice |
    Given I wait for the "myservice" service to become ready
    When I execute on the "<%= pod.name %>" pod:
      | curl | -k | <%= service.url %> |
    Then the output should not contain:
      | Warning |
      | Permission |
      | error |
