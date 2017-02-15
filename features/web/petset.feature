Feature: petset related feature
  # @author yanpzhan@redhat.com
  # @case_id OCP-10985
  Scenario: Check PetSets on the overview page	
    Given the master version >= "3.4"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/petset/hello-petset.yaml |
    Then the step should succeed
    And I run the :get client command with:
      | resource | svc |
    Then the step should succeed
    And the output should contain:
      | foo |

    When I run the :get client command with:
      | resource | petset |
    Then the step should succeed
    And the output should contain:
      | hello-petset |

    Given 2 pods become ready with labels:
      | app=hello-pod|
    When I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    And the output should contain:
      | hello-petset-0 |
      | hello-petset-1 |

    Given I login via web console
    And I wait up to 120 seconds for the steps to pass:
    """
    When I perform the :check_petset_on_overview_page web console action with:
      | project_name  | <%= project.name%> |
      | resource_type | Pet Set            |
      | resource_name | hello-petset       |
      | scaled_number | 2                  |
    Then the step should succeed
    """

    When I run the :patch client command with:
      | resource      | petset                  |
      | resource_name | hello-petset            |
      | p             | {"spec":{"replicas":4}} |
    Then the step should succeed

    And I wait up to 120 seconds for the steps to pass:
    """
    When I perform the :check_petset_on_overview_page web console action with:
      | project_name  | <%= project.name%> |
      | resource_type | Pet Set            |
      | resource_name | hello-petset       |
      | scaled_number | 4                  |
    Then the step should succeed
    """

    #reduce pod number in case exceeding quota in online
    When I run the :patch client command with:
      | resource      | petset                  |
      | resource_name | hello-petset            |
      | p             | {"spec":{"replicas":2}} |
    Then the step should succeed

    When I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/petset/hello-petset.yaml"
    Then I replace lines in "hello-petset.yaml":
      | foo          | foo2          |
      | hello-petset | hello-petset2 |
      | hello-pod    | hello-pod2    |

    When I run the :create client command with:
      | f | hello-petset.yaml |
    Then the step should succeed

    And I wait up to 120 seconds for the steps to pass:
    """
    When I perform the :check_petset_on_overview_page web console action with:
      | project_name  | <%= project.name%> |
      | resource_type | Pet Set            |
      | resource_name | hello-petset2      |
      | scaled_number | 2                  |
    Then the step should succeed
    """
