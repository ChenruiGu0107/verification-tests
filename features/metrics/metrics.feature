Feature: metrics related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-11821
  @admin
  @destructive
  Scenario: User can insert data to hawkular metrics in their own tanent when USER_WRITE_ACCESS parameter is 'true'
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/inventory              |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /gauges                                                                                           |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /gauges             |
    Then the expression should be true> cb.metrics_data[0][:parsed]['minTimestamp'] == 1460111065369
    Then the expression should be true> cb.metrics_data[0][:parsed]['maxTimestamp'] == 1460413065369

  # @author pruan@redhat.com
  # @case_id OCP-11979
  @admin
  @destructive
  Scenario: User can not create metrics in the tenant which owned by other user
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/inventory              |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    And I switch to the second user
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /gauges                                                                                           |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    # for older oc version, the status code was 401
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-12084
  @admin
  @destructive
  Scenario: User can only read metrics data when USER_WRITE_ACCESS is specified to false
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /gauges     |
    Then the expression should be true> @result[:exitstatus] == 204
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /gauges                                                                                           |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    # for older oc version, the status code was 401
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-10512
  @admin
  @destructive
  Scenario: Check hawkular alerts endpoint is accessible
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system
    And evaluation of `user.get_bearer_token.token` is stored in the :user_token clipboard
    Given I store default router subdomain in the :metrics clipboard
    Given cluster role "cluster-admin" is added to the "first" user
    And I perform the GET metrics rest request with:
      | project_name | _system              |
      | token        | <%= cb.user_token %> |
      | path         | /alerts/status       |
    Then the expression should be true> @result[:parsed]['status'] == 'STARTED'

  # @author pruan@redhat.com
  # @case_id OCP-10928
  @admin
  @destructive
  Scenario: User cannot create metrics in _system tenant even if USER_WRITE_ACCESS parameter is 'true'
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/inventory              |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    And I perform the POST metrics rest request with:
      | project_name | _system                                                                                           |
      | path         | /gauges                                                                                           |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    Then the expression should be true> @result[:exitstatus] == 403

  # @author pruan@redhat.com
  # @case_id OCP-12168
  @admin
  @destructive
  Scenario: User can only read metrics data when USER_WRITE_ACCESS parameter is not specified
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /gauges             |
    Then the expression should be true> @result[:exitstatus] == 204
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /gauges                                                                                           |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    # for older oc version, the status code was 401
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-10927
  @admin
  @destructive
  Scenario: Access the external Hawkular Metrics API interface as cluster-admin
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/inventory              |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    And evaluation of `user.get_bearer_token.token` is stored in the :user_token clipboard
    Given cluster role "cluster-admin" is added to the "first" user
    And I perform the POST metrics rest request with:
      | project_name | _system                                                                                           |
      | path         | /availability                                                                                     |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    And I perform the GET metrics rest request with:
      | project_name | _system              |
      | path         | /metrics             |
      | token        | <%= cb.user_token %> |
    Then the step should succeed
    And evaluation of `@result[:parsed].map { |e| e['type'] }.uniq.sort!` is stored in the :metrics_result clipboard
    And the expression should be true> cb.metrics_result == ['counter', 'gauge']
    And I perform the GET metrics rest request with:
      | project_name | _system              |
      | path         | /gauges              |
      | token        | <%= cb.user_token %> |
    Then the step should succeed
    And evaluation of `@result[:parsed].map { |e| e['type'] }.uniq` is stored in the :gauge_result clipboard
    And the expression should be true> cb.gauge_result == ['gauge']
    And I perform the GET metrics rest request with:
      | project_name | _system              |
      | path         | /counters            |
      | token        | <%= cb.user_token %> |
    Then the step should succeed
    And evaluation of `@result[:parsed].map { |e| e['type'] }.uniq` is stored in the :counter_result clipboard
    And the expression should be true> cb.counter_result == ['counter']

  # @author pruan@redhat.com
  # @case_id OCP-11336
  @admin
  @destructive
  Scenario: Insert data into Cassandra DB through external Hawkular Metrics API interface without Hawkular-tenant specified
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/inventory              |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    Given I perform the POST metrics rest request with:
      | project_name | :false                                                                                            |
      | path         | /gauges                                                                                           |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    Then the expression should be true> @result[:exitstatus] == 400


  # @author penli@redhat.com
  # @case_id OCP-10515
  # bz #1401383 #1421953
  # run this case in m1.large on OpenStack, m4.large on AWS, or n1-standard-2 on GCE
  @admin
  @destructive
  Scenario: Scale up and down hawkular-metrics replicas
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system
    Given cluster role "cluster-admin" is added to the "first" user
    And I use the "openshift-infra" project
    And I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | hawkular-metrics       |
      | replicas | 2                      |
    Then I wait until number of replicas match "2" for replicationController "hawkular-metrics"
    Given a pod becomes ready with labels:
      | metrics-infra=hawkular-metrics |
    And I wait for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name    | pods/<%= pod.name %>|
    And the output should match:
      | Metrics service started   |
    """
    And I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | hawkular-metrics       |
      | replicas | 1                      |
    Then I wait until number of replicas match "1" for replicationController "hawkular-metrics"

  # @author xiazhao@redhat.com
  # @author: lizhou@redhat.com
  # @author: pruan@redhat.com
  # @case_id OCP-11868
  @admin
  @destructive
  @smoke
  Scenario: deploy metrics stack with persistent storage
    Given I create a project with non-leading digit name
    And I have a NFS service in the project
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/metrics_pv.json" where:
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
    Given metrics service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-14055/inventory              |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-10776/deployer_ocp10776.yaml |
    # need to change the project to where metrics is installed under which we hard-coded to 'openshift-infra'
    And admin ensure "metrics-cassandra-1" pvc is deleted from the "openshift-infra" project after scenario
    And I switch to cluster admin pseudo user
    And I use the "openshift-infra" project
    And the "metrics-cassandra-1" PVC becomes :bound


  # @author chunchen@redhat.com
  # @case_id OCP-14162
  # @author xiazhao@redhat.com
  # @case_id OCP-11574
  # @author penli@redhat.com
  @admin
  @destructive
  @smoke
  Scenario: Access heapster interface,Check jboss wildfly version from hawkular-metrics pod logs
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/inventory              |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    And I switch to cluster admin pseudo user
    And I use the "openshift-infra" project
    Given a pod becomes ready with labels:
      | metrics-infra=hawkular-metrics |
    And I wait for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name    | pods/<%= pod.name %>|
    And the output should match:
      | JBoss EAP .*GA   |
    """
    Given I wait for the steps to pass:
    """
    When I perform the :access_heapster rest request with:
      | project_name | <%=project.name%> |
    Then the step should succeed
    """
    When I perform the :access_pod_network_metrics rest request with:
      | project_name | <%=project.name%> |
      | pod_name     | <%=pod.name%>     |
      | type         | tx                |
    Then the step should succeed
    When I perform the :access_pod_network_metrics rest request with:
      | project_name | <%=project.name%> |
      | pod_name     | <%=pod.name%>     |
      | type         | rx                |
    Then the step should succeed

  # @author: penli@redhat.com
  # @author: lizhou@redhat.com
  # @case_id: OCP-13983
  # combined using unified step for deploying metrics
  @admin
  @destructive
  Scenario: move the commitlog to another volume-emptydir
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system
    # Scale down
    Given I switch to cluster admin pseudo user
    And I use the "openshift-infra" project
    Given a pod becomes ready with labels:
      | metrics-infra=hawkular-metrics |
    And I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | hawkular-cassandra-1   |
      | replicas | 0                      |
    Then the step should succeed

    # Move commitLog to another volume-emptydir
    When I run the :patch client command with:
      | resource      | rc                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
      | resource_name | hawkular-cassandra-1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
      | p             | {"spec":{"template":{"spec":{"containers":[{"name":"hawkular-cassandra-1","command":["/opt/apache-cassandra/bin/cassandra-docker.sh","--cluster_name=hawkular-metrics","--data_volume=/cassandra_data","--commitlog_volume=/cassandra_commitlog","--internode_encryption=all","--require_node_auth=true", "--enable_client_encryption=true","--require_client_auth=true","--keystore_file=/secret/cassandra.keystore","--keystore_password_file=/secret/cassandra.keystore.password","--truststore_file=/secret/cassandra.truststore","--truststore_password_file=/secret/cassandra.truststore.password","--cassandra_pem_file=/secret/cassandra.pem"]}]}}}} |
    Then the step should succeed
    When I run the :volume client command with:
      | resource      | rc                   |
      | resource_name | hawkular-cassandra-1 |
      | action        | --add                |
      | name          | cassandra-commitlog  |
      | mount-path    | /cassandra_commitlog |
      | type          | emptydir             |
    Then the step should succeed

    #Scale up and check
    When I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | hawkular-cassandra-1   |
      | replicas | 1                      |
    Then the step should succeed
    And I wait for the "hawkular-cassandra" service to become ready
    Then I wait until number of replicas match "1" for replicationController "hawkular-cassandra-1"

  # @author: pruan@redhat.com
  # @case_id: OCP-12276
  # combined using unified step for deploying metrics
  @admin
  @destructive
  Scenario: Metrics Admin Command - fresh deploy with resource limits
    Given I create a project with non-leading digit name
    Given metrics service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12276/inventory |
    And I switch to cluster admin pseudo user
    And I use the "openshift-infra" project
    And evaluation of `rc('hawkular-metrics').container_spec(user: user, name: 'hawkular-metrics').cpu_limit_raw` is stored in the :cpu_limit clipboard
    And evaluation of `rc('hawkular-cassandra-1').container_spec(user: user, name: 'hawkular-cassandra-1').memory_limit_raw` is stored in the :memory_limit clipboard
    Then the expression should be true> cb.cpu_limit == "100m"
    Then the expression should be true> cb.memory_limit == "1G"

  # @author: pruan@redhat.com
  # @case_id: OCP-14519
  @admin
  @destructive
  Scenario: Show CPU,memory, network metrics statistics on pod page of openshift web console
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :proj_1_name clipboard
    And metrics service is installed in the system
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed
    And the pod named "hello-openshift" becomes present
    Given I login via web console
    When I perform the :check_pod_metrics_tab web action with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= pod.name %>     |
    Then the step should succeed
    And I run the :logout web console action
    # switch user
    And I switch to the second user
    Given I create a project with non-leading digit name
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/pod_with_two_containers.json |
    Then the step should succeed
    And  the pod named "doublecontainers" becomes ready
    Given the second user is cluster-admin
    And I login via web console
    When I perform the :check_pod_metrics_tab web action with:
      | project_name | <%= project.name %> |
      | pod_name     | <%= pod.name %>     |
    Then the step should succeed
    When I perform the :check_pod_metrics_tab web action with:
      | project_name | <%= cb.proj_1_name %> |
      | pod_name     | hello-openshift       |
    Then the step should succeed
