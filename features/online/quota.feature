Feature: ONLY ONLINE Quota related scripts in this file

  # @author zhaliu@redhat.com
  Scenario Outline: Request/limit would be overridden based on container's memory limit when master provides override ratio
    Given I have a project
    When I run the :get client command with:
      | resource | limitrange |
      | o        | json       |
    Then the step should succeed
    And evaluation of `@result[:parsed]['items'][0]['spec']['limits'][1]['default']['cpu'].split(/\D/)[0]` is stored in the :limit_cpu clipboard
    And evaluation of `@result[:parsed]['items'][0]['spec']['limits'][1]['default']['memory'].split(/\D/)[0]` is stored in the :limit_memory clipboard
    And evaluation of `@result[:parsed]['items'][0]['spec']['limits'][1]['default']['memory'].split(/\d+/)[1]` is stored in the :memoryunit clipboard
    And evaluation of `@result[:parsed]['items'][0]['spec']['limits'][1]['defaultRequest']['cpu'].split(/\D/)[0]` is stored in the :request_cpu clipboard
    And evaluation of `@result[:parsed]['items'][0]['spec']['limits'][1]['defaultRequest']['memory'].split(/\D/)[0]` is stored in the :request_memory clipboard

    When I run oc create over "<paths>" replacing paths:
      | ["spec"]["containers"][0]["resources"] | <memory> |
    Then the step should succeed

    When I run the :get client command with:
      | resource | pod  |
      | o        | json |
    Then the expression should be true> @result[:parsed]['items'][0]['spec']['containers'][0]['resources']['limits']['cpu'].match /<limits_cpu>/
    Then the expression should be true> @result[:parsed]['items'][0]['spec']['containers'][0]['resources']['limits']['memory'].match /<limits_memory>/
    Then the expression should be true> @result[:parsed]['items'][0]['spec']['containers'][0]['resources']['requests']['cpu'].match /<requests_cpu>/
    Then the expression should be true> @result[:parsed]['items'][0]['spec']['containers'][0]['resources']['requests']['memory'].match /<requests_memory>/
    Examples:
      | paths | memory | limits_cpu | limits_memory | requests_cpu | requests_memory |
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/tc517576/pod-limit-memory.yaml | {"limits":{"memory":"<%= cb.limit_memory.to_i*2 %><%= cb.memoryunit %>"}} | <%= cb.limit_cpu.to_i*2 %>\|<%= cb.limit_cpu.to_i*2/1000 %> | <%= cb.limit_memory.to_i*2 %>\|<%= cb.limit_memory.to_i*2+1 %>\|<%= cb.limit_memory.to_i*2/1024 %> | <%= cb.requests_cpu.to_i*2 %>\|<%= cb.requests_cpu.to_i*2/1000 %> | <%= cb.request_memory.to_i*2 %>\|<%= cb.request_memory.to_i*2+1 %>\|<%= cb.request_memory.to_i*2/1024 %> | # @case_id OCP-9822
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/tc517577/pod-no-limit-request.yaml | {} | <%= cb.limit_cpu %> | <%= cb.limit_memory %> | <%= cb.request_cpu %> | <%= cb.request_memory %> | # @case_id OCP-9823
      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/tc517567/pod-limit-request.yaml | {"limits":{"memory":"<%= cb.limit_memory %><%= cb.memoryunit %>"}} | <%= cb.limit_cpu %> | <%= cb.limit_memory %> | <%= cb.requests_cpu %> | <%= cb.requests_memory %> | # @case_id OCP-9820

  # @author zhaliu@redhat.com
  # @case_id OCP-12684
  Scenario: LimitRange should restrict the amount of the storage PVC requests
    Given I have a project
    When I run the :get client command with:
      | resource | limitrange |
      | o        | json       |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["items"][0]["spec"]["limits"][2]["max"]["storage"] == "1Gi"
    And the expression should be true> @result[:parsed]["items"][0]["spec"]["limits"][2]["min"]["storage"] == "1Gi"
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-less.yaml |
    Then the step should fail
    And the output should match:
      | persistentvolumeclaims.*is forbidden:   |
      | minimum .* PersistentVolumeClaim is 1Gi |
      | but request is 600Mi                    |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-equal.yaml |
    Then the step should succeed
    And the "claim-equal-limit" PVC becomes :bound within 300 seconds
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-over.yaml |
    Then the step should fail
    And the output should match:
      | persistentvolumeclaims.*is forbidden:   |
      | maximum .* PersistentVolumeClaim is 1Gi |
      | but request is 5Gi                      |

  # @author zhaliu@redhat.com
  # @case_id OCP-12686
  Scenario: ResourceQuota should restrict amount of PVCs created in a project
    Given I have a project
    When I run the :get client command with:
      | resource      | quota         |
      | resource_name | object-counts |
      | o             | json          |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["spec"]["hard"]["persistentvolumeclaims"] == "1"
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-equal.yaml |
    Then the step should succeed
    And the "claim-equal-limit" PVC becomes :bound within 300 seconds
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/online/dynamic_persistent_volumes/pvc-equal.yaml" replacing paths:
      | ["metadata"]["name"] | claim-equal-limit1 |
    Then the step should fail
    And the output should match:
      | persistentvolumeclaims.*is forbidden: |
      | exceeded quota                        |
      | persistentvolumeclaims=1              |

  # @author bingli@redhat.com
  # @case_id OCP-13171
  # @case_id OCP-12700
  Scenario: CRUD operation to the resource quota as project owner
    Given I have a project
    When I run the :describe client command with:
      | resource | rolebinding   |
      | name     | project-owner |
    Then the step should succeed
    And the output should match:
      | create\s*delete\s*get\s*list\s*patch\s*update\s*watch.+resourcequotas |
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/project-quota/quota.yaml |
    Then the step should succeed
    And the output should contain:
      | resourcequota "quota" created |
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the step should succeed
    And I run the :describe client command with:
      | resource | quota   |
      | name     | quota   |
    Then the step should succeed
    And the output should match:
      | cpu\s*80m\s*1                   |
      | memory\s*409Mi\s*750Mi          |
      | pods\s*1\s*10                   |
      | replicationcontrollers\s*1\s*10 |
      | resourcequotas\s*1\s*1          |
      | services\s*1\s*10               |
    Then I wait up to 30 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource | events |
    Then the step should succeed
    And the output should contain:
      | exceeded quota |
    """
    When I run the :patch client command with:
      | resource      | quota                                                                                                                                                                    |
      | resource_name | quota                                                                                                                                                                    |
      | p             | {"spec":{"hard":{"cpu":"4","memory":"8Gi","persistentvolumeclaims":"10","pods":"20","replicationcontrollers":"20","resourcequotas":"5","secrets":"20","services":"20"}}} |
    Then the step should succeed
    And the output should contain:
      | "quota" patched |
    Given a pod becomes ready with labels:
      | deployment=mysql-1 |
    Then I wait up to 30 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | quota   |
      | name     | quota   |
    Then the step should succeed
    And the output should match:
      | cpu\s*80m\s*4                   |
      | memory\s*409Mi\s*8Gi            |
      | persistentvolumeclaims\s*1\s*10 |
      | pods\s*1\s*20                   |
      | replicationcontrollers\s*1\s*20 |
      | resourcequotas\s*1\s*5          |
      | secrets\s*10\s*20               |
      | services\s*1\s*20               |
    """
    When I run the :delete client command with:
      | object_type       | quota |
      | object_name_or_id | quota |
    Then the step should succeed
    And the output should contain:
      | resourcequota "quota" deleted |

  # @author bingli@redhat.com
  # @case_id OCP-12982
  Scenario: Normal pods with restartPolicy=Always can't occupy the run-once clusterResourceQuota
    Given I have a project
    And evaluation of `CucuShift::AppliedClusterResourceQuota.list(user: user, project: project)` is stored in the :acrq clipboard
    And evaluation of `cb.acrq.find{|o|o.name.end_with?("-compute")}` is stored in the :memory_crq clipboard
    And evaluation of `cb.acrq.find{|o|o.name.end_with?('-timebound')}` is stored in the :memory_terminate_crq clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed
    Given the pod named "hello-openshift" status becomes :running
    Then the expression should be true> cb.memory_crq.total_used(cached: false).memory_limit_raw == "512Mi"
    And the expression should be true> cb.memory_terminate_crq.total_used(cached: false).memory_limit == 0

  # @author bingli@redhat.com
  # @case_id OCP-12698
  Scenario: User's ClusterResourceQuota should identify all this user's projects
    Given I have a project
    And evaluation of `project.name` is stored in the :project1 clipboard
    And evaluation of `CucuShift::AppliedClusterResourceQuota.list(user: user, project: project)` is stored in the :acrq clipboard
    And evaluation of `cb.acrq.find{|o|o.name.end_with?("-compute")}` is stored in the :memory_crq clipboard
    And evaluation of `cb.acrq.find{|o|o.name.end_with?('-timebound')}` is stored in the :memory_terminate_crq clipboard
    And evaluation of `cb.acrq.find{|o|o.name.end_with?('-noncompute')}` is stored in the :storage_crq clipboard

    When I run the :new_app client command with:
      | template | dancer-mysql-persistent |
    Then the step should succeed
    And the pod named "dancer-mysql-persistent-1-build" status becomes :running
    And the pod named "database-1-deploy" status becomes :running

    Given I create a new project
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the pod named "mysql-1-deploy" status becomes :running

    Given I check that the "<%= cb.memory_terminate_crq.name %>" applied_cluster_resource_quota exists
    Then the expression should be true> applied_cluster_resource_quota.total_used.memory_limit_raw == "1536Mi"

    Given the "mysql" PVC becomes :bound
    And a pod becomes ready with labels:
      | deployment=mysql-1 |
    And I use the "<%= cb.project1 %>" project
    And the "database" PVC becomes :bound
    And a pod becomes ready with labels:
      | deployment=database-1 |
    And a pod becomes ready with labels:
      | deployment=dancer-mysql-persistent-1 |
    Then the expression should be true> cb.memory_crq.total_used(cached: false).memory_limit_raw == "1536Mi"
    And the expression should be true> cb.storage_crq.total_used(cached: false).storage_requests_raw == "2Gi"

  # @author bingli@redhat.com
  # @case_id OCP-10293
  Scenario: User can share another user's resourcequota after granted the privilege
    Given I have a project
    And evaluation of `project.name` is stored in the :project1 clipboard
    And evaluation of `CucuShift::AppliedClusterResourceQuota.list(user: user, project: project)` is stored in the :acrq clipboard
    And evaluation of `cb.acrq.find{|o|o.name.end_with?("-compute")}` is stored in the :memory_crq clipboard
    And evaluation of `cb.acrq.find{|o|o.name.end_with?('-timebound')}` is stored in the :memory_terminate_crq clipboard
    And evaluation of `cb.acrq.find{|o|o.name.end_with?('-noncompute')}` is stored in the :storage_crq clipboard

    When I run the :policy_add_role_to_user client command with:
      | role       | edit                               |
      | user_name  | <%= user(1, switch: false).name %> |
      | n          | <%= cb.project1 %>                 |
    Then the step should succeed

    Given I switch to second user
    And I use the "<%=cb.project1 %>" project
    Then I run the :new_app client command with:
      | template | mongodb-persistent |
    Then the step should succeed
    Given I switch to first user
    Given the pod named "mongodb-1-deploy" status becomes :running
    When I run the :new_app client command with:
      | template | mysql-persistent |
    Then the step should succeed
    And the pod named "mysql-1-deploy" status becomes :running
    And the expression should be true> cb.memory_terminate_crq.total_used(cached: false).memory_limit_raw == "1Gi"

    Given a pod becomes ready with labels:
      | deployment=mysql-1 |
    And a pod becomes ready with labels:
      | deployment=mongodb-1 |
    And the "mongodb" PVC becomes :bound
    And the "mysql" PVC becomes :bound
    Then the expression should be true> cb.memory_crq.total_used(cached: false).memory_limit_raw == "1Gi"
    And the expression should be true> cb.storage_crq.total_used(cached: false).storage_requests_raw == "2Gi"
