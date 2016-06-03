Feature: Diagnostics system and clients

  # @author chunchen@redhat.com
  # @case_id 501021
  @admin
  @destructive
  Scenario: Diagnose docker registry and router entities
  Given default docker-registry replica count is restored after scenario
  And default router replica count is restored after scenario
  Given I have a project
  When I run the :oadm_diagnostics client command with:
    | images | openshift3/ose-${component}:${version} |
    | latest-images | false |
  Then the output should not match "Errors seen:\s+[1-9]\d*"
  When I run the :scale admin command with:
    | resource | deploymentconfigs |
    | name | docker-registry |
    | replicas | 0 |
    | n | default|
  Then the step should succeed
  When I run the :scale admin command with:
    | resource | deploymentconfigs |
    | name | router |
    | replicas | 0 |
    | n | default|
  Then the step should succeed
  When I run the :oadm_diagnostics admin command with:
    | images | openshift3/ose-${component}:${version} |
    | latest-images | false |
  Then the output should match:
    | the registry will fail |
    | Apps will not be externally accessible |
    | Errors seen:\s+[1-9]\d* |

  # @author chunchen@redhat.com
  # @case_id 501020
  Scenario: Diagnose openshift client
    Given I have a project
    When I run the :oadm_diagnostics client command with:
      | images | openshift3/ose-${component}:${version} |
      | latest-images | false |
      | loglevel | 5 |
      | diaglevel | 0 |
    Then the output should match:
      | debug: |
      | I\d+\s+\d{2}:\d{2}:\d{2}\.\d+\s+\d+ |
    And the output should not match "Errors seen:\s+[1-9]\d*"
    When I run the :oadm_diagnostics client command with:
      | images | openshift3/ose-${component}:${version} |
      | latest-images | false |
      | config | /path/to/non-existed-file |
    Then the output should match:
      | not find config file |
      | Errors seen:\s+[1-9]\d* |
