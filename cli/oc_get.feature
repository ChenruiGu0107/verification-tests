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
    Given I obtain test data file "hpa/php-dc.yaml"
    Given I obtain test data file "hpa/hpa.yaml"
    When I run the :create client command with:
      | f | php-dc.yaml |
      | f | hpa.yaml    |
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

  # @author knarra@redhat.com
  # @case_id OCP-29478
  @admin
  Scenario: Events should always have timestamps
    Given I have a project
    Given I switch to cluster admin pseudo user
    And I use the "<%= project.name %>" project
    Given I obtain test data file "storage/hostpath/security/hostpath.yaml"
    When I run the :create admin command with:
      | f | hostpath.yaml |
    Then the step should succeed
    Given the pod named "hostpathpd" status becomes :running
    When I run the :get client command with:
      | resource | events |
    Then the step should succeed
    And the output should not contain "<unknown>"

  # @author knarra@redhat.com
  # @case_id OCP-34129
  @admin
  Scenario: List of SecurityContextConstraints should list all columns, not just Name & Age
    Given the master version >= "4.5"
    Given I switch to cluster admin pseudo user
    When I run the :get admin command with:
      | resource | securitycontextconstraints.security.openshift.io |
    Then the step should succeed
    And the output should match:
      | NAME\\s+PRIV\\s+CAPS\\s+SELINUX\\s+RUNASUSER\\s+FSGROUP\\s+SUPGROUP\\s+PRIORITY\\s+READONLYROOTFS\\s+VOLUMES |
    When I run the :get admin command with:
      | resource | securitycontextconstraints.security.openshift.io |
      | o        | wide                                             |
    Then the step should succeed
    And the output should match:
      | NAME\\s+PRIV\\s+CAPS\\s+SELINUX\\s+RUNASUSER\\s+FSGROUP\\s+SUPGROUP\\s+PRIORITY\\s+READONLYROOTFS\\s+VOLUMES |

  # @author knarra@redhat.com
  # @case_id OCP-34139
  @admin
  Scenario Outline: oc get rolebinding and clusterrolebinding should work well
    Given the master version >= "4.5"
    Given I switch to cluster admin pseudo user
    When I use the "openshift-kube-scheduler" project
    When I run the :get admin command with:
      | resource | <resourcename> |
    Then the step should succeed
    And the output should match:
      | NAME\\s+ROLE\\s+AGE |
    When I run the :get admin command with:
      | resource | <resourcename> |
      | o        | wide           |
    Then the step should succeed
    And the output should match:
      | NAME\\s+ROLE\\s+AGE\\s+USERS\\s+GROUPS\\s+SERVICEACCOUNTS |

    Examples:
      | resourcename       |
      | rolebinding        |
      | clusterrolebinding |

  # @author knarra@redhat.com
  # @case_id OCP-34701
  @admin
  Scenario: oc diff should not apply changes to cluster
    Given the master version >= "4.5"
    Given I switch to cluster admin pseudo user
    When I run the :get client command with:
      | resource      | project  |
      | resource_name | ocp34701 |
    Then the output should contain:
      | Error from server (NotFound): namespaces "ocp34701" not found |
    Given I obtain test data file "cli/project34701.yaml"
    When I run the :diff client command with:
      | f | project34701.yaml  |
    Then the step should fail
    When I run the :get client command with:
      | resource      | project  |
      | resource_name | ocp34701 |
    Then the output should contain:
      | Error from server (NotFound): namespaces "ocp34701" not found |
