Feature: metrics related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-11821
  @admin
  @destructive
  Scenario: User can insert data to hawkular metrics in their own tenant when USER_WRITE_ACCESS parameter is 'true'
    Given metrics service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/inventory              |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    And I switch to the first user
    Given I have a project
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /metrics/gauges                                                                                   |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /metrics/gauges     |
      | token        | <%= user.cached_tokens.first %> |
    Then the expression should be true> cb.metrics_data[0][:parsed]['minTimestamp'] == 1460111065369
    Then the expression should be true> cb.metrics_data[0][:parsed]['maxTimestamp'] == 1460413065369

  # @author pruan@redhat.com
  # @case_id OCP-11979
  @admin
  @destructive
  Scenario: User can not create metrics in the tenant which owned by other user
    Given metrics service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/inventory              |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    And I switch to the second user
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /metrics/gauges                                                                                   |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    # for older oc version, the status code was 401
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-12084
  @admin
  @destructive
  Scenario: User can only read metrics data when USER_WRITE_ACCESS is specified to false
    Given metrics service is installed in the system
    Given I switch to the first user
    Given I have a project
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /metrics/gauges     |
    Then the expression should be true> @result[:exitstatus] == 204
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /metrics/gauges                                                                                   |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    # for older oc version, the status code was 401
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-10512
  @admin
  @destructive
  Scenario: Check hawkular alerts endpoint is accessible
    Given metrics service is installed in the system
    And I switch to the first user
    And evaluation of `user.cached_tokens.first` is stored in the :user_token clipboard
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
    Given metrics service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/inventory              |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    And I switch to the first user
    And I perform the POST metrics rest request with:
      | project_name | _system                                                                                           |
      | path         | /metrics/gauges                                                                                   |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    Then the expression should be true> @result[:exitstatus] == 403

  # @author pruan@redhat.com
  # @case_id OCP-12168
  @admin
  @destructive
  Scenario: User can only read metrics data when USER_WRITE_ACCESS parameter is not specified
    Given I have a project
    Given metrics service is installed in the system
    Given I switch to the first user
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /metrics/gauges     |
    Then the expression should be true> @result[:exitstatus] == 204
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /metrics/gauges                                                                                           |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    # for older oc version, the status code was 401
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-10927
  @admin
  @destructive
  Scenario: Access the external Hawkular Metrics API interface as cluster-admin
    Given I have a project
    Given metrics service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/inventory              |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    And I switch to the first user
    And evaluation of `user.cached_tokens.first` is stored in the :user_token clipboard
    Given cluster role "cluster-admin" is added to the "first" user
    And I perform the POST metrics rest request with:
      | project_name | _system                                                                                           |
      | path         | /metrics/availability                                                                             |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    And I perform the GET metrics rest request with:
      | project_name | _system              |
      | path         | /metrics/metrics     |
      | token        | <%= cb.user_token %> |
    Then the step should succeed
    And evaluation of `@result[:parsed].map { |e| e['type'] }.uniq.sort!` is stored in the :metrics_result clipboard
    And the expression should be true> cb.metrics_result == ['counter', 'gauge']
    And I perform the GET metrics rest request with:
      | project_name | _system              |
      | path         | /metrics/gauges      |
      | token        | <%= cb.user_token %> |
    Then the step should succeed
    And evaluation of `@result[:parsed].map { |e| e['type'] }.uniq` is stored in the :gauge_result clipboard
    And the expression should be true> cb.gauge_result == ['gauge']
    And I perform the GET metrics rest request with:
      | project_name | _system              |
      | path         | /metrics/counters    |
      | token        | <%= cb.user_token %> |
    Then the step should succeed
    And evaluation of `@result[:parsed].map { |e| e['type'] }.uniq` is stored in the :counter_result clipboard
    And the expression should be true> cb.counter_result == ['counter']

  # @author pruan@redhat.com
  # @case_id OCP-11336
  @admin
  @destructive
  Scenario: Insert data into Cassandra DB through external Hawkular Metrics API interface without Hawkular-tenant specified
    Given metrics service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/inventory              |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11821/deployer_ocp11821.yaml |
    Given I perform the POST metrics rest request with:
      | project_name | :false                                                                                            |
      | path         | /metrics/gauges                                                                                   |
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
    And I use the "openshift-infra" project
    Given a pod becomes ready with labels:
      | metrics-infra=hawkular-metrics |
    And I wait for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name    | <%= pod.name %>|
    And the output should contain:
      | JBoss EAP |
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

  # @author penli@redhat.com
  # @author lizhou@redhat.com
  # @case_id OCP-13983
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
    # need to make sure the rc is ready first before checking for the hawkular-casandar service, the previous step
    # 'And I wait for the "hawkular-cassandra" service to become ready' was timing out because the pod name changed due
    # when we scaled.
    And a replicationController becomes ready with labels:
      | type=hawkular-cassandra |
    Then I wait until number of replicas match "1" for replicationController "hawkular-cassandra-1"

  # @author pruan@redhat.com
  # @case_id OCP-12276
  # combined using unified step for deploying metrics
  @admin
  @destructive
  Scenario: Metrics Admin Command - fresh deploy with resource limits
    Given metrics service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12276/inventory |
    Then the expression should be true> rc('hawkular-cassandra-1').container_spec(name: 'hawkular-cassandra-1').memory_limit_raw == "1G"
    Then the expression should be true> rc('hawkular-metrics').container_spec(user: user, name: 'hawkular-metrics').cpu_request_raw == "100m"

  # @author pruan@redhat.com
  # @case_id OCP-14519
  @admin
  @destructive
  Scenario: Show CPU,memory, network metrics statistics on pod page of openshift web console
    And metrics service is installed in the system
    And I switch to the first user
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :proj_1_name clipboard
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


  # @author pruan@redhat.com
  # @case_id OCP-13082
  @admin
  @destructive
  Scenario: Make sure no password exposed in process command line
    Given the master version >= "3.5"
    And metrics service is installed in the system
    And I select a random node's host
    And I run commands on the host:
      | ps -aux \| grep hawkular |
    Then the output should not contain:
      | password= |

  # @author pruan@redhat.com
  # @case_id OCP-18805
  @admin
  @destructive
  Scenario: Hawkular Metrics log should include date as part of the timestamp
    Given the master version >= "3.5"
    And metrics service is installed in the system
    And a pod becomes ready with labels:
      | metrics-infra=hawkular-metrics |
    Then I run the :logs client command with:
      | resource_name | <%= pod.name %> |
    Then the expression should be true> Date.parse(@result[:response]) rescue false

  # @author pruan@redhat.com
  # @case_id OCP-15535
  @admin
  @destructive
  Scenario: Path for prometheus additional alert rules file is not exist
    Given the master version >= "3.7"
    And metrics service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15535/inventory |
      | negative_test | true                                                                                                   |
    Then the output should contain:
      | Could not find or access 'this_is_bogus_path' |

  # @author pruan@redhat.com
  # @case_id OCP-18546
  @admin
  @destructive
  Scenario: hawkular-alerts war packages are removed from hawkular-metrics
    Given the master version >= "3.10"
    And metrics service is installed in the system
    And a pod becomes ready with labels:
      | metrics-infra=hawkular-metrics |
    And I execute on the pod:
      | bash | -c | ls -alR /opt/eap/standalone/deployments/hawkular*.war |
    Then the output should contain:
      | hawkular-metrics.war |
    And the output should not contain:
      | hawkular-alert |

  # @author pruan@redhat.com
  # @case_id OCP-19040
  @admin
  @destructive
  Scenario: DeleteExpiredMetrics job is already dropped from code
    Given the master version >= "3.6"
    Given I create a project with non-leading digit name
    And metrics service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12234/inventory |
    And a pod becomes ready with labels:
      | metrics-infra=hawkular-cassandra |
    And I execute on the pod:
      | bash | -c | cqlsh --ssl -e "select * from hawkular_metrics.scheduled_jobs_idx" |
    Then the step should succeed
    And the output should not contain "DELETE_EXPIRED_METRICS"
    And I execute on the pod:
      | bash | -c | cqlsh --ssl -e "select table_name from system_schema.tables where keyspace_name = 'hawkular_metrics'"|
    Then the step should succeed
    And the output should not contain "metrics_expiration_idx"
    And I execute on the pod:
      | bash | -c | cqlsh --ssl -e "select * from hawkular_metrics.sys_config where config_id = 'org.hawkular.metrics.jobs.DELETE_EXPIRED_METRICS'" |
    Then the step should succeed
    And the output should contain "0 rows"
