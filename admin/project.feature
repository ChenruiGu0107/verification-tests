Feature: project permissions

  # @author wyue@redhat.com
  # @case_id OCP-12457
  @admin
  Scenario: Only cluster-admin could get namespaces
    ## create a project with non cluster-admin user
    Given I have a project
    Then the step should succeed

    ## get no projects with another user who has no projects
    When I switch to the second user
    And I run the :get client command with:
      | resource | project |
    Then the output should not contain:
      | <%= project.name %> |

    ## can get all project with cluster-admin
    When I run the :get admin command with:
      | resource | project |
    Then the output should contain:
      | <%= project.name %> |
      | default             |

  # @author pruan@redhat.com
  # @case_id OCP-11476
  @admin
  Scenario: oadm new-project should fail when invalid node selector is given
    Given a 5 characters random string of type :dns is stored into the :proj_name clipboard
    When I run the :oadm_new_project admin command with:
      | node_selector | env:qa |
      | project_name  | <%= @clipboard[:proj_name] %> |
    Then the step should fail
    And the output should match:
      | nvalid value.*env:qa |
    When I run the :oadm_new_project admin command with:
      | node_selector | env,qa |
      | project_name  | <%= @clipboard[:proj_name] %> |
    Then the step should fail
    And the output should match:
      | nvalid value.*env,qa |
    When I run the :oadm_new_project admin command with:
      | node_selector | env [qa] |
      | project_name  | <%= @clipboard[:proj_name] %> |
    Then the step should fail
    And the output should match:
      | nvalid value.*env \[qa\] |
    When I run the :oadm_new_project admin command with:
      | node_selector | env, |
      | project_name  | <%= @clipboard[:proj_name] %> |
    Then the step should fail
    And the output should match:
      | nvalid value.*env, |

  # @author yinzhou@redhat.com
  # @case_id OCP-27999
  @admin
  @destructive
  Scenario: Show project.spec.projectRequestMessage correctly by oc client
    Given the master version >= "4.5"
    Given the "cluster" "project.config.openshift.io" CR is restored after scenario
    Given as admin I successfully merge patch resource "project.config/cluster" with:
      | {"spec":{"projectRequestMessage":"To request a project contact your system administrator at projectname@example.com."}} |
    When I run the :serviceaccounts_get_token admin command with:
      | serviceaccount_name | default |
      | n                   | default |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :token clipboard
    And I wait for the steps to pass:
    """
    When I run the :login client command with:
      | token  | <%= cb.token %>             |
      | server | <%= env.api_endpoint_url %> |
    Then the step should succeed
    And the output should contain:
      | To request a project contact your system administrator at projectname@example.com |
    """
    And I wait for the steps to pass:
    """
    And I create a new project
    Then the step should fail
    And the output should contain:
      | To request a project contact your system administrator at projectname@example.com |
    """
