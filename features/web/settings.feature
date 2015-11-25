Feature: check settings page on web console
  #@author: yapei@redhat.com
  #@case_id: 470357
  @admin
  Scenario: create project limit and quota, check settings on web console
    # create project on web console
    When I create a new project via web
    Then the step should succeed

    # create limit and quota via CLI
    Given I use the "<%= project.name %>" project
    And I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/quota.yaml |
      | n | <%= project.name %> |
    And I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed

    # check quota and limit via CLI
    When I run the :describe client command with:
      | resource | quota |
      | name     | quota |
    Then the output should match:
      | cpu\\s+0\\s+1 |
      | memory\\s+0\\s+750Mi |
      | pods\\s+0\\s+10 |
      | replicationcontrollers\\s+0\\s+10 |
      | resourcequotas\\s+1\\s+1 |
      | services\\s+0\\s+10 |

    When I run the :describe client command with:
      | resource | limits |
      | name     | limits |
    Then the output should match:
      | Pod\\s+cpu\\s+10m\\s+500m\\s+ |
      | Pod\\s+memory\\s+5Mi\\s+750Mi\\s+ |
      | Container\\s+memory\\s+5Mi\\s+750Mi\\s+100Mi\\s+100Mi |
      | Container\\s+cpu\\s+10m\\s+500m\\s+100m\\s+100m |

    # check setting page layout
    And I perform the :check_settings_page web console action with:
      | project_name | <%= project.name %> |
    Then the step should succeed

    # check quota - cpu
    When I perform the :check_used_value web console action with:
      | resource_type | cpu |
      | used_value    | 0 cores |
    Then the step should succeed
    When I perform the :check_max_value web console action with:
      | resource_type | cpu |
      | max_value     | 1 core |
    Then the step should succeed
    # check quota - memory
    When I perform the :check_used_value web console action with:
      | resource_type | memory |
      | used_value    | 0 B |
    Then the step should succeed
    When I perform the :check_max_value web console action with:
      | resource_type | memory |
      | max_value     | 750 MiB |
    Then the step should succeed
    # check quota - pods
    When I perform the :check_used_value web console action with:
      | resource_type | pods |
      | used_value    | 0    |
    Then the step should succeed
    When I perform the :check_max_value web console action with:
      | resource_type | pods |
      | max_value     | 10   |
    Then the step should succeed
    # check quota - replicationcontrollers
    When I perform the :check_used_value web console action with:
      | resource_type | replicationcontrollers |
      | used_value    | 0    |
    Then the step should succeed
    When I perform the :check_max_value web console action with:
      | resource_type | replicationcontrollers |
      | max_value     | 10   |
    Then the step should succeed
    # check quota - resourcequotas
    When I perform the :check_used_value web console action with:
      | resource_type | resourcequotas |
      | used_value    | 1    |
    Then the step should succeed
    When I perform the :check_max_value web console action with:
      | resource_type | resourcequotas |
      | max_value     | 1    |
    Then the step should succeed
    # check quota - services
    When I perform the :check_used_value web console action with:
      | resource_type | services |
      | used_value    | 0    |
    Then the step should succeed
    When I perform the :check_max_value web console action with:
      | resource_type | services |
      | max_value     | 10    |
    Then the step should succeed

    # check resource limits - Pod cpu
    When I perform the :check_min_limit_value web console action with:
      | resource_type | Pod cpu |
      | min_limit     | 10 millicores |
    Then the step should succeed
    When I perform the :check_max_limit_value web console action with:
      | resource_type | Pod cpu |
      | max_limit     | 500 millicores |
    Then the step should succeed
    # check resource limits - Pod memory
    When I perform the :check_min_limit_value web console action with:
      | resource_type | Pod memory |
      | min_limit     | 5 MiB |
    Then the step should succeed
    When I perform the :check_max_limit_value web console action with:
      | resource_type | Pod memory |
      | max_limit     | 750 MiB |
    Then the step should succeed
    # check resource limits - Container cpu 
    When I perform the :check_min_limit_value web console action with:
      | resource_type | Container cpu |
      | min_limit     | 10 millicores |
    Then the step should succeed
    When I perform the :check_max_limit_value web console action with:
      | resource_type | Container cpu |
      | max_limit     | 500 millicores |
    Then the step should succeed
    # check resource limits - Container memory 
    When I perform the :check_min_limit_value web console action with:
      | resource_type | Container memory |
      | min_limit     | 5 MiB |
    Then the step should succeed
    When I perform the :check_max_limit_value web console action with:
      | resource_type | Container memory |
      | max_limit     | 750 MiB |
    Then the step should succeed
