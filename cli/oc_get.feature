Feature: oc get related command
  # @author xiaocwan@redhat.com
  # @case_id OCP-11987
  Scenario Outline: Show friendly message when request resource is empty instead of return nothing
    Given I have a project
    When I run the :get client command with:
      | resource    | <resource-type> |
    Then the step should succeed
    And the output should match:
      | [Nn]o resources found         |

    Examples:
      | resource-type |
      | bc            |
      | hpa           |
      | pvc           |

  # @author xxia@redhat.com
  # @case_id OCP-21061
  Scenario Outline: kubectl shows friendly message when resource is empty
    Given I have a project
    When I run the :get client command with:
      | _tool       | kubectl         |
      | resource    | <resource-type> |
    Then the step should succeed
    And the output should match:
      | [Nn]o resources found         |

    Examples:
      | resource-type |
      | bc            |
      | hpa           |
      | pvc           |

  # @author xxia@redhat.com
  # @case_id OCP-21059
  Scenario Outline: kubectl shows friendly message when user can not list cluster scope resource
    Given I have a project
    When I run the :get client command with:
      | _tool       | kubectl         |
      | resource    | <resource-type> |
    Then the step should fail
    And the output should contain "cannot list"
    # Bug 1612628
    And the output should not match:
      | [Nn]o resources found         |

    Examples:
      | resource-type    |
      | user             |
      | groups           |
      | no               |
      | ns               |
      | pv               |

  # @author xiaocwan@redhat.com
  # @case_id OCP-10497
  Scenario Outline: Show friendly message when user can not list in cluster scope
    Given I have a project
    When I run the :get client command with:
      | resource    | <resource-type> |
    Then the step should fail
    And the output should contain "cannot list"
    # Bug 1612628
    And the output should not match:
      | [Nn]o resources found         |

    Examples:
      | resource-type    |
      | user             |
      | groups           |
      | no               |
      | ns               |
      | pv               |

  # @author yapei@redhat.com
  # @case_id OCP-12887
  Scenario: Check HPA resource is included in 'all' alias
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/hpa/php-dc.yaml |
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/hpa/hpa.yaml    |
    Then the step should succeed
    When I run the :delete client command with:
      | object_type | all  |
      | all         | true |
    And the output should match "horizontalpodautoscaler.*php-apache.*deleted"

  # @author yinzhou@redhat.com
  # @case_id OCP-28012
  @admin
  @destructive
  Scenario: oc get node -w with -o custom-columns, -o yaml, -o name woks well
    Given I switch to cluster admin pseudo user
    Given I store the schedulable nodes in the :nodes clipboard
    And the node labels are restored after scenario
    When I run the :get background admin command with:
      | resource | node                                                        |
      | o        | custom-columns=NAME:.metadata.name,Adress:.status.addresses |
      | w        | true                                                        |
    Then the step should succeed
    And label "tc28012=vip1" is added to the "<%= cb.nodes[0].name %>" node
    When I terminate last background process
    And the expression should be true> @result[:response].scan('<%= cb.nodes[0].name %>').count >= 4

    When I run the :get background admin command with:
      | resource | node |
      | o        | name |
      | w        | true |
    Then the step should succeed
    And label "tc28012=vip2" is added to the "<%= cb.nodes[1].name %>" node
    When I terminate last background process
    Then the output should contain 2 times:
      | <%= cb.nodes[1].name %> |

  # @author yinzhou@redhat.com
  # @case_id OCP-29479
  @admin
  Scenario: Get clusterroles with '-o wide' 
    Given I switch to cluster admin pseudo user
    When I run the :get admin command with:
      | resource | clusterrolebinding.rbac |
      | o        | wide                    |
    Then the step should succeed
    And the output should match:
      | NAME\\s+ROLE\\s+AGE\\s+USERS\\s+GROUPS\\s+SERVICEACCOUNTS |
