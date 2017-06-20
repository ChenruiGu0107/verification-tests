Feature: ONLY ONLINE Quota related scripts in this file

  # @author bingli@redhat.com
  # @case_id OCP-9820 OCP-9822 OCP-9823
  Scenario Outline: Request/limit would be overridden based on container's memory limit when master provides override ratio
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/<path>/<filename> |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | pod       |
      | resource_name | <podname> |
      | o             | json      |
    Then the expression should be true> @result[:parsed]['spec']['containers'][0]['resources']['limits']['cpu'] == "<expr1>"
    Then the expression should be true> @result[:parsed]['spec']['containers'][0]['resources']['limits']['memory'] == "<expr2>"
    Then the expression should be true> @result[:parsed]['spec']['containers'][0]['resources']['requests']['cpu'] == "<expr3>"
    Then the expression should be true> @result[:parsed]['spec']['containers'][0]['resources']['requests']['memory'] == "<expr4>"

    # request/limit of containers should be overridden based on memory limit when master provide override ratio:
    # cpuRequestToLimitPercent, limitCPUToMemoryPercent, memoryRequestToLimitPercent.
    # When case fails because of unexpected value of expr1-4, master configuration should be checked firstly.
    # If the the output of expr1-4 is indeed based on the override ratio, then it's a bug.
    Examples:
      | path     | filename                  | podname              | expr1 | expr2 | expr3 | expr4 |
      | tc517567 | pod-limit-request.yaml    | pod-limit-request    | 1171m | 600Mi | 70m   | 360Mi |
      | tc517576 | pod-limit-memory.yaml     | pod-limit-memory     | 585m  | 300Mi | 35m   | 180Mi |
      | tc517577 | pod-no-limit-request.yaml | pod-no-limit-request | 1     | 512Mi | 60m   | 307Mi |

  # @author zhaliu@redhat.com
  # @case_id OCP-12684
  Scenario: LimitRange should restrict the amount of the storage PVC requests
    Given I have a project
    When I run the :get client command with:
      | resource | limitrange |
      | o        | json       |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["items"][0]["spec"]["limits"][2]["max"]["storage"] == "1Gi"
    And the expression should be true> @result[:parsed]["items"][0]["spec"]["limits"][2]["min"]["storage"] == "1Gi"
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-less.yaml |
    Then the step should fail
    And the output should match:
      | persistentvolumeclaims.*is forbidden:   |
      | minimum .* PersistentVolumeClaim is 1Gi |
      | but request is 600Mi                    |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-equal.yaml |
    Then the step should succeed 
    And the "claim-equal-limit" PVC becomes :bound within 300 seconds
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-over.yaml |
    Then the step should fail
    And the output should match: 
      | persistentvolumeclaims.*is forbidden:   |
      | maximum .* PersistentVolumeClaim is 1Gi |
      | but request is 5Gi                      |

  # @author zhaliu@redhat.com
  # @case_id OCP-12686
  Scenario: ResourceQuota should restrict amount of PVCs created in a project
    Given I have a project
    When I run the :get client command with:
      | resource      | quota         |
      | resource_name | object-counts |
      | o             | json          |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["spec"]["hard"]["persistentvolumeclaims"] == "1"
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-equal.yaml |
    Then the step should succeed 
    And the "claim-equal-limit" PVC becomes :bound within 300 seconds
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-equal.yaml" replacing paths:
      | ["metadata"]["name"] | claim-equal-limit1 |
    Then the step should fail
    And the output should match:
      | persistentvolumeclaims.*is forbidden: |
      | exceeded quota                        |
      | persistentvolumeclaims=1              |
