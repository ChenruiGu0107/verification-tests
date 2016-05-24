Feature: ONLY ONLINE Quota related scripts in this file

  # @author bingli@redhat.com
  # @case_id 517567 517576 517577
  Scenario Outline: Request/limit would be overridden based on container's memory limit when master provides override ratio
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/<path>/<filename> |
    Then the step should succeed
    When I run the :get client command with:
      | resource      | pod       |
      | resource_name | <podname> |
      | o             | json      |
    And the output is parsed as JSON
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
      | tc517567 | pod-limit-request.yaml    | pod-limit-request    | 1170m | 600Mi | 70m   | 360Mi |
      | tc517576 | pod-limit-memory.yaml     | pod-limit-memory     | 584m  | 300Mi | 35m   | 180Mi |
      | tc517577 | pod-no-limit-request.yaml | pod-no-limit-request | 1     | 512Mi | 60m   | 307Mi |
