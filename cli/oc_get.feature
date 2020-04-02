Feature: oc get related command

  # @author xiaocwan@redhat.com
  # @case_id OCP-10880
  @admin
  Scenario: `oc get all` command should display titles on headers for different sections
    ## 1. Check all resouces in default project
    When I run the :get admin command with:
      | resource    | all     |
      | namespace   | default |
    Then the step should succeed
    And the output should contain:
      | dc/docker-registry   |
      | svc/docker-registry  |
      | po/docker-registry   |
    ## 2. Create different kinds of resources in another project (no need cluster-admin)
    Given I have a project
    When I run the :new_app client command with:
      | file        | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
      | namespace   | <%= project.name %> |
    Then the step should succeed
    When I run the :get admin command with:
      | resource       | all     |
      | all_namespaces  | true    |
    Then the step should succeed
    And the output should match:
      | NAMESPACE                                       |
      | default\\s+dc/docker-registry                   |
      | default\\s+svc/docker-registry                  |
      | default\\s+po/docker-registry                   |
      | <%= project.name %>\\s+is/origin-ruby-sample    |
      | <%= project.name %>\\s+dc/database              |
      | <%= project.name %>\\s+svc/database             |
    ## 3. Check 'oc get all -l <label>' function
    When I run the :label client command with:
      | resource     | dc                       |
      | name         | database                 |
      | key_val      | test=<%= project.name %> |
    Then the step should succeed
    When I run the :label client command with:
      | resource     | svc                      |
      | name         | database                 |
      | key_val      | test=<%= project.name %> |
    Then the step should succeed
    When I run the :get client command with:
      | resource     | all                      |
      | l            | test=<%= project.name %> |
    Then the step should succeed
    And the output should contain:
      | dc/database    |
      | svc/database   |

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

  # @author xxia@redhat.com
  # @case_id OCP-10209
  Scenario: Get raw URI with oc as a wrapper of curl
    Given I have a project
    When I run the :get client command with:
      | resource   | :false             |
      | raw        | /oapi/v1/users/~   |
    Then the step should succeed
    Given the output is parsed as YAML
    Then evaluation of `@result[:parsed]` is stored in the :raw_content clipboard

    When I perform the :get_user rest request with:
      | username   | ~         |
    Then the step should succeed
    And the expression should be true> @result[:parsed] == cb.raw_content

    When I run the :get client command with:
      | resource   | :false    |
      | raw        | /apijk    |
    Then the step should fail

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
    Then the output should contain 6 times:
      | <%= cb.nodes[0].name %> |

    When I run the :get background admin command with:
      | resource | node |
      | o        | name |
      | w        | true |
    Then the step should succeed
    And label "tc28012=vip2" is added to the "<%= cb.nodes[1].name %>" node
    When I terminate last background process
    Then the output should contain 2 times:
      | <%= cb.nodes[1].name %> |
