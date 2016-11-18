Feature: oc get related command

  # @author xiaocwan@redhat.com
  # @case_id 530512
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
  # @case_id 535721
  Scenario Outline: Show friendly message when request resource is empty instead of return nothing
    When I run the :get client command with:
      | resource    | <resource-type> |
    Then the step should fail
  # This is blocked by bug#1393289, but will pass when next 2 lines are commented
    And the output should not match:
      | [Nn]o resources found         |
    And the output should contain "cannot list"

    Given I have a project
    When I run the :get client command with:
      | resource    | <resource-type> |
    Then the step should succeed
    And the output should match:
      | [Nn]o resources found         |
    When I run the :delete client command with:
      | object_type       | project              |
      | object_name_or_id | <%= project.name %>  |
    Then the step should succeed

    Examples:
      | resource-type |
      | bc            |
      | builds        |
      | configmaps    |
      | ds            |
      | dc            |
      | deployments   |
      | ev            |
      | ep            |
      | hpa           |
      | is            |
      | istag         |
      | jobs          |
      | limits        |
      | po            |
      | pvc           |
      | policies      |
      | quota         |
      | rs            |
      | rc            |
      | routes        |
      | svc           |

