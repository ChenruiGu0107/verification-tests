Feature: oc run related scenarios
  # @author pruan@redhat.com
  # @case_id 499995
  Scenario: Negative test for oc run
    Given I have a project
    And I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | run |
      | test_do_not_use | -u |
    Then the step should fail
    Then the output should contain:
      | oc run NAME --image=image [--env="key=value"] [--port=port] [--replicas=replicas] [--dry-run=bool] [--overrides=inline-json] [options] |
      | Error: unknown shorthand flag: 'u' in -u |
    And I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | run |
      | test_do_not_use | -l -t |
    Then the step should fail
    Then the output should contain:
      | error: NAME is required for run |
    Then the step should fail
    And I run the :run client command with:
      | name | <%= project.name %> |
      | image |                    |
    Then the step should fail
    And the output should contain:
      | Parameter: image is required |
    # oc run with less options
    And I run the :run client command with:
      | name | newtest |
    Then the step should fail
    And the output should contain:
      | Parameter: image is required |
    And I run the :exec_raw_oc_cmd_for_neg_tests client command with:
      | arg | run |
      | test_do_not_use | --image=test  |
    Then the step should fail
    And the output should contain:
      | error: NAME is required for run |

  # @author xxia@redhat.com
  # @case_id 499994
  Scenario: Create container with oc run command
    Given I have a project
    When I run the :run client command with:
      | name         | mysql                 |
      | image        | mysql                 |
      | dry_run      | true                  |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc                 |
      | resource_name | mysql              |
    Then the step should fail
    When I run the :run client command with:
      | name         | webapp                |
      | image        | training/webapp       |
      | -l           | test=one              |
    Then the step should succeed
    And I wait until replicationController "webapp-1" is ready

    When I run the :run client command with:
      | name         | webapp2               |
      | image        | training/webapp       |
      | replicas     | 2                     |
      | -l           | label=webapp2         |
    Then the step should succeed
    And I wait until replicationController "webapp2-1" is ready

    When I run the :run client command with:
      | name         | webapp3               |
      | image        | training/webapp       |
      | overrides    | {"apiVersion":"v1","spec":{"replicas":"2"}} |
    Then the step should fail
    And the output should contain:
      | cannot unmarshal  |
    When I run the :run client command with:
      | name         | webapp3               |
      | image        | training/webapp       |
      | overrides    | {"apiVersion":"v1","spec":{"replicas":2}} |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | dc                 |
      | resource_name | webapp3            |
      | output        | yaml               |
    Then the step should succeed
    And the output should contain:
      | replicas: 2       |

    When I run the :run client command with:
      | name         | webapp4               |
      | image        | training/webapp       |
      | attach       | true                  |
      | restart      | Never                 |
      | _timeout     | 10                    |
    Then the step should have timed out
    And the output should match:
      | [Ww]aiting for pod .*webapp4 to be running       |
    When I run the :run client command with:
      | name         | webapp5               |
      | image        | training/webapp       |
      | -i           | true                  |
      | tty          | true                  |
      | restart      | Never                 |
      | _timeout     | 10                    |
    Then the step should have timed out
    And the output should match:
      | [Ww]aiting for pod .*webapp5 to be running       |

  # @author pruan@redhat.com
  # @case_id 510405
  Scenario: oc run can create dc, standalone rc, standalone pod
    Given I have a project
    When I run the :run client command with:
      | name         | myrun                 |
      | image        | yapei/hello-openshift |
    Then the step should succeed
    When I run the :get client command with:
      | resource | dc |
    Then the step should succeed
    And the output should contain:
      | myrun |
    When I run the :get client command with:
      | resource | rc |
    Then the step should succeed
    And the output should contain:
      | myrun-1 |
    And the output should contain:
      | myrun |
    When I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    And the output should contain:
      | myrun-1-deploy|
    # Create a standalone rc
    When I run the :run client command with:
      | name         | myrun-rc              |
      | image        | yapei/hello-openshift |
      | generator    | run-controller/v1 |
    Then the step should succeed
    When I run the :get client command with:
      | resource | dc |
    Then the step should succeed
    And the output should not contain:
      | myrun-rc |
    When I run the :get client command with:
      | resource | rc |
    Then the step should succeed
    And the output should contain:
      | myrun-rc |
    When I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    And the output should contain:
      | myrun-rc-|
    # Create a standalone pod
    When I run the :run client command with:
      | name         | myrun-pod             |
      | image        | yapei/hello-openshift |
      | generator    | run-pod/v1 |
    Then the step should succeed
    When I run the :get client command with:
      | resource | dc |
    Then the step should succeed
    And the output should not contain:
      | myrun-pod |
    When I run the :get client command with:
      | resource | rc |
    Then the step should succeed
    And the output should not contain:
      | myrun-pod |
    When I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    And the output should contain:
      | myrun-pod |

