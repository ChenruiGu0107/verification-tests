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
      | all_namespace  | true    |
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

  # @author xiaocwan@redhat.com
  # @case_id OCP-10497
  Scenario Outline: Show friendly message when user can not list in cluster scope
    Given I have a project
    When I run the :get client command with:
      | resource    | <resource-type> |
    Then the step should fail
    And the output should contain "cannot list"
    # This is blocked by bug#1393289, but will pass when next 2 lines are commented
    And the output should not match:
      | [Nn]o resources found         |

    Examples:
      | resource-type    |
      | user             |
      | cs               |
      | ing              |
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
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/hpa/php-dc.yaml |
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/hpa/hpa.yaml    |
    Then the step should succeed
    When I run the :get client command with:
      | resource | all |
    Then the step should succeed
    And the output should contain "hpa/php-apache"
    When I run the :delete client command with:
      | object_type | all  |
      | all         | true |
    Then the step should succeed
    And the output should match "horizontalpodautoscaler.*php-apache.*deleted"
