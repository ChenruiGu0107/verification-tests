Feature: taint toleration related scenarios
  # @author wmeng@redhat.com
  # @case_id OCP-13532
  Scenario: [Taint Toleration] pod with toleration can be scheduled as normal pod
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/taint-toleration/pod-toleration.yaml |
    Then the step should succeed
    Given the pod named "toleration" becomes ready
    When I run the :describe client command with:
      | resource | pods       |
      | name     | toleration |
    Then the output should match:
      | Status:\\s+Running                                      |
      | Tolerations:\\s+dedicated=special-user:Equal:NoSchedule |

  # @author wmeng@redhat.com
  # @case_id OCP-13773
  Scenario: [Taint Toleration] 'operator' only support "Equal", "Exists"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/taint-toleration/pod-toleration-fail-operator.yaml |
    Then the step should fail
    And the output should contain:
      | The Pod "toleration-fail-operator" is invalid |
      | Unsupported value: "Bigger"                   |
      | supported values: Equal, Exists               |
    When I run the :get client command with:
      | resource | pods |
    Then the output should match:
      | No resources found. |

  # @author wmeng@redhat.com
  # @case_id OCP-13774
  Scenario: [Taint Toleration] Invalid value effect "PreferNoSchedule" when 'tolerationSeconds' is set
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/taint-toleration/pod-toleration-fail-second-prefer.yaml |
    Then the step should fail
    And the output should contain:
      | The Pod "toleration-fail-second-prefer" is invalid         |
      | Invalid value: "PreferNoSchedule"                          |
      | effect must be 'NoExecute' when `tolerationSeconds` is set |
    When I run the :get client command with:
      | resource | pods |
    Then the output should match:
      | No resources found. |

  # @author wmeng@redhat.com
  # @case_id OCP-13775
  Scenario: [Taint Toleration] Invalid value effect "NoSchedule" when 'tolerationSeconds' is set
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/taint-toleration/pod-toleration-fail-second-no.yaml |
    Then the step should fail
    And the output should contain:
      | The Pod "toleration-fail-second-no" is invalid             |
      | Invalid value: "NoSchedule"                                |
      | effect must be 'NoExecute' when `tolerationSeconds` is set |
    When I run the :get client command with:
      | resource | pods |
    Then the output should match:
      | No resources found. |

  # @author wmeng@redhat.com
  # @case_id OCP-13776
  Scenario: [Taint Toleration] effect supported values are NoSchedule, PreferNoSchedule, NoExecute, all others are unsupported
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/scheduler/taint-toleration/pod-toleration-fail-effect.yaml |
    Then the step should fail
    And the output should contain:
      | The Pod "toleration-fail-effect" is invalid               |
      | Unsupported value: "Run"                                  |
      | supported values: NoSchedule, PreferNoSchedule, NoExecute |
    When I run the :get client command with:
      | resource | pods |
    Then the output should match:
      | No resources found. |

