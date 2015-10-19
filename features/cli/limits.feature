Feature: limit range related scenarios:
  # @author pruan@redhat.com
  # @case_id 508038, 508039, 508040
  @admin
  Scenario Outline:  Limit range default request tests
    Given I run the :new_project client command with:
      | project_name | proj1 |
    Given the first user is cluster-admin
    Then the step should succeed
    Then I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/<path>/limit.yaml|
    Then the step should succeed
    And I run the :describe client command with:
      |resource | namespace |
      | name    | proj1     |
    And the output should match:
      | <expr1> |
      | <expr2> |
    And I run the :delete client command with:
      | object_type | LimitRange |
      | object_name_or_id | limits |
    Then the step should succeed

    Examples:
      | path | expr1 | expr2 |
      | tc508038 | Container\\s+cpu\\s+\-\\s+\\-\\s+200m | Container\\s+memory\\s+\-\\s+\\-\\s+1Gi |
      | tc508039 | Container\\s+cpu\\s+200m\\s+\\-\\s+\- | Container\\s+memory\\s+1Gi\\s+\\-\\s+\- |
      | tc508040 | Container\\s+cpu\\s+\-\\s+200m\\s+200m | Container\\s+memory\\s+\-\\s+1Gi\\s+1Gi |

  # @author pruan@redhat.com
  # @case_id 508041, 508045
  @admin
  Scenario Outline: Limit range invalid values tests
    Given I run the :new_project client command with:
      | project_name | proj1 |
    Given the first user is cluster-admin
    Then the step should succeed
    Then I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/<path>/limit.yaml|
    And the step should fail
    And the output should contain:
      | The LimitRange "limits" is invalid |
      | spec.limits[0].defaultRequest[cpu]: invalid value '<expr1>', Details: <expr2> value <expr3> is greater than <expr4> value <expr5> |
      | spec.limits[0].default[cpu]: invalid value '<expr6>', Details: <expr7> value <expr8> is greater than <expr9> value <expr10>       |
      | spec.limits[0].defaultRequest[memory]: invalid value '<expr11>', Details: <expr12> value <expr13> is greater than <expr14> value <expr15> |
      | spec.limits[0].default[memory]: invalid value '<expr16>', Details: <expr17> value <expr18> is greater than <expr19> value <expr20>         |

    Examples:
      | path | expr1 | expr2 | expr3 | expr4 | expr5 | expr6 | expr7 | expr8 | expr9 | expr10 | expr11 |expr12 | expr13| expr14 | expr15 | expr16 | expr17 | expr18 | expr19| expr20 |
      | tc508041 | 400m | default request | 400m | max | 200m | 200m | default | 400m | max | 200m | 2Gi | default request | 2Gi | max | 1Gi | 1Gi | default | 2Gi  | max   | 1Gi    |
      | tc508045 | 200m | min | 400m | default request | 200m | 400m | min | 400m | default | 200m | 1Gi | min | 2Gi | default request | 1Gi | 2Gi | min | 2Gi  | default   | 1Gi    |

  # @author pruan@redhat.com
  # @case_id 508047
  @admin
  Scenario Outline: Limit range incorrect values
    Given I run the :new_project client command with:
      | project_name | proj1 |
    Given the first user is cluster-admin
    Then the step should succeed
    Then I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/<path>/limit.yaml|
    And the step should fail
    And the output should contain:
      | spec.limits[0].min[memory]: invalid value '<expr1>', Details: <expr2> value <expr3> is greater than <expr4> value <expr5> |
      | spec.limits[0].min[cpu]: invalid value '<expr6>', Details: <expr7> value <expr8> is greater than <expr9> value <expr10>         |

    Examples:
      | path | expr1 | expr2 | expr3 | expr4 | expr5 | expr6 | expr7 | expr8 | expr9 | expr10 |
      | tc508047 | 2Gi | min | 2Gi | max | 1Gi | 400m | min | 400m | max | 200m |


  # @author pruan@redhat.com
  # @case_id 508046
  @admin
  Scenario: Limit range does not allow min > defaultRequest
    Given I run the :new_project client command with:
      | project_name | proj1 |
    Given the first user is cluster-admin
    Then the step should succeed
    Then I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/tc508046/limits.yaml|
    Then the step should fail
    And the output should contain:
      | invalid value '200m', Details: min value 400m is greater than default request value 200m |
      |  invalid value '1Gi', Details: min value 2Gi is greater than default request value 1Gi   |
