Feature: ONLY ONLINE Infra related scripts in this file

  # @author yasun@redhat.com
  # @case_id OCP-11952
  Scenario: RunOnceDuration plugin limits activeDeadlineSeconds when creating and update run-once pod
    Given I have a project
    When I run the :run client command with:
      | name    | run-once-pod     |
      | image   | openshift/origin |
      | command | true             |
      | cmd     | sleep            |
      | cmd     | 4000s            |
      | restart | Never            |
    And the pod named "run-once-pod" status becomes :running
    Then I run the :get client command with:
      | resource      | pod          |
      | resource_name | run-once-pod |
      | o             | yaml         |
    And the output should contain:
      | activeDeadlineSeconds: 3600 |

    When I run the :patch client command with:
      | resource      | pod                                     |
      | resource_name | run-once-pod                            |
      | p             | {"spec":{"activeDeadlineSeconds":2000}} |
    Then the step should succeed
    Then I run the :get client command with:
      | resource      | pod          |
      | resource_name | run-once-pod |
      | o             | yaml         |
    And the output should contain:
      | activeDeadlineSeconds: 2000 |

    When I run the :patch client command with:
      | resource      | pod                                     |
      | resource_name | run-once-pod                            |
      | p             | {"spec":{"activeDeadlineSeconds":3000}} |
    Then the step should fail
    And the output should contain:
      | must be less than or equal to previous value |

    When I run the :patch client command with:
      | resource      | pod                                     |
      | resource_name | run-once-pod                            |
      | p             | {"spec":{"activeDeadlineSeconds":1000}} |
    Then the step should succeed
    Then I run the :get client command with:
      | resource      | pod          |
      | resource_name | run-once-pod |
      | o             | yaml         |
    And the output should contain:
      | activeDeadlineSeconds: 1000 |

  # @author zhaliu@redhat.com
  # @case_id OCP-9788
    Scenario: Restrict user using nodeName in Pod in online env
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/online/clusterinfra/pod-with-nodename.yaml |
    Then the step should fail
    And the output should contain:
      | Pod nodeName specification is not permitted on this cluster |

  # @author zhaliu@redhat.com
  # @case_id OCP-9903
    Scenario: Restrict user using nodeName in DeploymentConfig in online env
    Given I have a project
    When I run the :create client command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/online/clusterinfra/deploymentconfig-with-nodename.yaml |
    Then the step should fail
    And the output should contain:
      | deploymentconfigs.apps.openshift.io "hello-openshift" is forbidden: node selection by nodeName is prohibited by policy for your role |
