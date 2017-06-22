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

  # @author bingli@redhat.com
  # @case_id OCP-13171
  # @case_id OCP-12700
  Scenario: CRUD operation to the resource quota as project owner
    Given I have a project
    When I run the :describe client command with:
      | resource | rolebinding   |
      | name     | project-owner |
    Then the step should succeed
    And the output should match:
      | create\s*delete\s*get\s*list\s*patch\s*update\s*watch.+resourcequotas |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/quota.yaml |
    Then the step should succeed
    And the output should contain:
      | resourcequota "quota" created |
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the step should succeed
    And I run the :describe client command with:
      | resource | quota   |
      | name     | quota   |
    Then the step should succeed
    And the output should match:
      | cpu\s*80m\s*1                   |
      | memory\s*409Mi\s*750Mi          |
      | pods\s*1\s*10                   |
      | replicationcontrollers\s*1\s*10 |
      | resourcequotas\s*1\s*1          |
      | services\s*1\s*10               |
    Then I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | events |
    Then the step should succeed
    And the output should contain:
      | exceeded quota |
    """
    When I run the :patch client command with:
      | resource      | quota                                                                                                                                                                    |
      | resource_name | quota                                                                                                                                                                    |
      | p             | {"spec":{"hard":{"cpu":"4","memory":"8Gi","persistentvolumeclaims":"10","pods":"20","replicationcontrollers":"20","resourcequotas":"5","secrets":"20","services":"20"}}} |
    Then the step should succeed
    And the output should contain:
      | "quota" patched |
    Given a pod becomes ready with labels:
      | deployment=mysql-1 |
    Then I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota   |
      | name     | quota   |
    Then the step should succeed
    And the output should match:  
      | cpu\s*80m\s*4                   |
      | memory\s*409Mi\s*8Gi            |
      | persistentvolumeclaims\s*1\s*10 |
      | pods\s*1\s*20                   |
      | replicationcontrollers\s*1\s*20 |
      | resourcequotas\s*1\s*5          |
      | secrets\s*10\s*20               |
      | services\s*1\s*20               |
    """
    When I run the :delete client command with:
      | object_type       | quota |
      | object_name_or_id | quota |
    Then the step should succeed
    And the output should contain:
      | resourcequota "quota" deleted |
