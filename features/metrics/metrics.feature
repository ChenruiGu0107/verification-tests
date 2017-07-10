Feature: metrics related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-11821
  Scenario: User can insert data to hawkular metrics in their own tanent when USER_WRITE_ACCESS parameter is 'true'
    Given I have a project
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /metrics/gauges                                                                                   |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /metrics/gauges     |
    Then the expression should be true> cb.metrics_data[0][:parsed]['minTimestamp'] == 1460111065369
    Then the expression should be true> cb.metrics_data[0][:parsed]['maxTimestamp'] == 1460413065369

  # @author pruan@redhat.com
  # @case_id OCP-11979
  Scenario: User can not create metrics in the tenant which owned by other user
    Given I have a project
    And I store default router subdomain in the :metrics clipboard
    And I switch to the second user
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /metrics/gauges                                                                                   |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    # for older oc version, the status code was 401
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-12084
  Scenario: User can only read metrics data when USER_WRITE_ACCESS is specified to false
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
  Scenario: Check hawkular alerts endpoint is accessible
    Given I have a project
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
  Scenario: User cannot create metrics in _system tenant even if USER_WRITE_ACCESS parameter is 'true'
    Given I have a project
    And I perform the POST metrics rest request with:
      | project_name | _system                                                                                           |
      | path         | /metrics/gauges                                                                                   |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    Then the expression should be true> @result[:exitstatus] == 403

  # @author pruan@redhat.com
  # @case_id OCP-12168
  Scenario: User can only read metrics data when USER_WRITE_ACCESS parameter is not specified
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
  # @case_id OCP-10927
  @admin
  Scenario: Access the external Hawkular Metrics API interface as cluster-admin
    Given I have a project
    And evaluation of `user.get_bearer_token.token` is stored in the :user_token clipboard
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
  Scenario: Insert data into Cassandra DB through external Hawkular Metrics API interface without Hawkular-tenant specified
    Given I have a project
    Given I perform the POST metrics rest request with:
      | project_name | :false                                                                                            |
      | path         | /metrics/gauges                                                                                   |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    Then the expression should be true> @result[:exitstatus] == 400

  @admin
  # @author penli@redhat.com
  # @case_id OCP-10515
  # bz #1401383 #1421953
  # run this case in m1.large on OpenStack, m4.large on AWS, or n1-standard-2 on GCE
  Scenario: Scale up and down hawkular-metrics replicas
    Given I have a project
    And I store default router subdomain in the :subdomain clipboard
    And I store master major version in the :master_version clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin-metrics/master/metrics-deployer-setup.yaml |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | edit                                                     |
      | user_name | system:serviceaccount:<%=project.name%>:metrics-deployer |
    When I run the :policy_add_role_to_user client command with:
      | role      | view                                             |
      | user_name | system:serviceaccount:<%=project.name%>:hawkular |
    Then the step should succeed
    Given cluster role "cluster-reader" is added to the "heapster" service account
    When I run the :new_secret client command with:
      | secret_name     | metrics-deployer  |
      | credential_file | nothing=/dev/null |
    Then the step should succeed
    When I create a new application with:
      | template | metrics-deployer-template                                     |
      | param    | HAWKULAR_METRICS_HOSTNAME=hawkular-metrics.<%= cb.subdomain%> |
      | param    | IMAGE_PREFIX=<%= product_docker_repo %>openshift3/            |
      | param    | USE_PERSISTENT_STORAGE=false                                  |
      | param    | IMAGE_VERSION=<%= cb.master_version%>                         |
      | param    | MASTER_URL=<%= env.api_endpoint_url %>                        |
    Then the step should succeed
    And all pods in the project are ready
    And I wait for the "hawkular-cassandra" service to become ready
    And I wait for the "hawkular-metrics" service to become ready
    And I wait for the "heapster" service to become ready
    Given a pod becomes ready with labels:
      | metrics-infra=hawkular-metrics |
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
  # @case_id OCP-10776
  @admin
  @smoke
  Scenario: Version < 3.4 deploy metrics stack with persistent storage
    Given I have a project
    And I have a NFS service in the project
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/metrics_pv.json" where:
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |
    And I store default router subdomain in the :subdomain clipboard
    And I store master major version in the :master_version clipboard
    When I run the :create_serviceaccount client command with:
      | serviceaccount_name | metrics-deployer |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | edit                                                     |
      | user_name | system:serviceaccount:<%=project.name%>:metrics-deployer |
    Then the step should succeed
    Given cluster role "cluster-reader" is added to the "heapster" service account
    Given the "empty" file is created with the following lines:
    """
    """
    When I run the :new_secret client command with:
      | secret_name     | metrics-deployer |
      | credential_file | empty            |
    Then the step should succeed
    When I create a new application with:
      | template | metrics-deployer-template                                                                                                                  |
      | param    | HAWKULAR_METRICS_HOSTNAME=hawkular-metrics.<%= cb.subdomain%>                                                                              |
      | param    | IMAGE_PREFIX=<%= product_docker_repo %>openshift3/,USE_PERSISTENT_STORAGE=true,CASSANDRA_PV_SIZE=5Gi,IMAGE_VERSION=<%= cb.master_version%> |
      | param    | MASTER_URL=<%= env.api_endpoint_url %>                                                                                                     |
    Then the step should succeed
    And all pods in the project are ready
    And I wait for the "hawkular-cassandra" service to become ready
    And I wait for the "hawkular-metrics" service to become ready
    And I wait for the "heapster" service to become ready
    Given a pod becomes ready with labels:
      | metrics-infra=hawkular-cassandra |
    And I wait for the steps to pass:
    """
    When I get project pod named "<%= pod.name %>" as YAML
    Then the output should contain:
      | persistentVolumeClaim |
    """


  # @author chunchen@redhat.com
  # @case_id OCP-12205,521419
  # @author xiazhao@redhat.com
  # @case_id OCP-11574
  # @author penli@redhat.com
  @admin
  @smoke
  Scenario: Access heapster interface,Check jboss wildfly version from hawkular-metrics pod logs
    Given I have a project
    And I store default router subdomain in the :subdomain clipboard
    And I store master major version in the :master_version clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin-metrics/master/metrics-deployer-setup.yaml |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | edit                                                     |
      | user_name | system:serviceaccount:<%=project.name%>:metrics-deployer |
    When I run the :policy_add_role_to_user client command with:
      | role      | view                                             |
      | user_name | system:serviceaccount:<%=project.name%>:hawkular |
    Then the step should succeed
    Given cluster role "cluster-reader" is added to the "heapster" service account
    When I run the :new_secret client command with:
      | secret_name     | metrics-deployer  |
      | credential_file | nothing=/dev/null |
    Then the step should succeed
    When I create a new application with:
      | template | metrics-deployer-template                                     |
      | param    | HAWKULAR_METRICS_HOSTNAME=hawkular-metrics.<%= cb.subdomain%> |
      | param    | IMAGE_PREFIX=<%= product_docker_repo %>openshift3/            |
      | param    | USE_PERSISTENT_STORAGE=false                                  |
      | param    | IMAGE_VERSION=<%= cb.master_version%>                         |
      | param    | MASTER_URL=<%= env.api_endpoint_url %>                        |
    Then the step should succeed
    And all pods in the project are ready
    And I wait for the "hawkular-cassandra" service to become ready
    And I wait for the "hawkular-metrics" service to become ready
    And I wait for the "heapster" service to become ready
    Given a pod becomes ready with labels:
      | metrics-infra=hawkular-metrics |
    And I wait for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name    | pods/<%= pod.name %>|
    And the output should match:
      | JBoss EAP .*GA   |
    """
    Given the first user is cluster-admin
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
  # @case_id: OCP-10988
  @admin
  @destructive
  Scenario: Version = 3.4 move the commitlog to another volume-emptydir
    Given I have a project
    And I store default router subdomain in the :subdomain clipboard
    And I store master major version in the :master_version clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin-metrics/master/metrics-deployer-setup.yaml |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | edit                                                     |
      | user_name | system:serviceaccount:<%=project.name%>:metrics-deployer |
    When I run the :policy_add_role_to_user client command with:
      | role      | view                                             |
      | user_name | system:serviceaccount:<%=project.name%>:hawkular |
    Then the step should succeed
    Given cluster role "cluster-reader" is added to the "heapster" service account
    When I run the :new_secret client command with:
      | secret_name     | metrics-deployer  |
      | credential_file | nothing=/dev/null |
    Then the step should succeed
    When I create a new application with:
      | template | metrics-deployer-template                                     |
      | param    | HAWKULAR_METRICS_HOSTNAME=hawkular-metrics.<%= cb.subdomain%> |
      | param    | IMAGE_PREFIX=<%= product_docker_repo %>openshift3/            |
      | param    | USE_PERSISTENT_STORAGE=false                                  |
      | param    | IMAGE_VERSION=<%= cb.master_version%>                         |
      | param    | MASTER_URL=<%= env.api_endpoint_url %>                        |
    Then the step should succeed
    And all pods in the project are ready
    And I wait for the "hawkular-cassandra" service to become ready
    And I wait for the "hawkular-metrics" service to become ready
    And I wait for the "heapster" service to become ready
    Given a pod becomes ready with labels:
      | metrics-infra=hawkular-metrics |
    And I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | hawkular-cassandra-1   |
      | replicas | 0                      |
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
    And I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | hawkular-cassandra-1   |
      | replicas | 1                      |
    And I wait for the "hawkular-cassandra" service to become ready
    Then I wait until number of replicas match "1" for replicationController "hawkular-cassandra-1"



  # @author: lizhou@redhat.com
  # @case_id: OCP-13983
  # This case only support version >=3.5, for version =3.4 see OCP-10988.
  @admin
  @destructive
  Scenario: Version >= 3.5 move the commitlog to another volume-emptydir
    # Deploy metrics
    Given the master version >= "3.5"
    Given I have a project
    Given cluster role "cluster-admin" is added to the "first" user
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_inventory |
    # Scale down
    # Given I switch to cluster admin pseudo user
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

  # @author lizhou@redhat.com
  # @case_id OCP-13911
  # This is the dup case of OCP-10776, to support deploy steps changes on OCP v3.4
  # Run this case in m1.large on OpenStack, m3.large on AWS, or n1-standard-2 on GCE
  @admin
  @smoke
  Scenario: Version = 3.4 deploy metrics stack with persistent storage
    Given I have a project
    And I have a NFS service in the project

    # Create PV
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/metrics_pv.json" where:
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |

    And I store default router subdomain in the :subdomain clipboard
    And I store master major version in the :master_version clipboard

    # Create ServiceAccount
    When I run the :create_serviceaccount client command with:
      | serviceaccount_name | metrics-deployer |
    Then the step should succeed

    # Add role to user
    When I run the :policy_add_role_to_user client command with:
      | role      | edit                                                     |
      | user_name | system:serviceaccount:<%=project.name%>:metrics-deployer |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | view                                             |
      | user_name | system:serviceaccount:<%=project.name%>:hawkular |
    Then the step should succeed

    # Add cluster role to user cluster-reader
    Given cluster role "cluster-reader" is added to the "heapster" service account

    # Create secret
    When I run the :new_secret client command with:
      | secret_name     | metrics-deployer  |
      | credential_file | nothing=/dev/null |
    Then the step should succeed

    # Create new app
    When I create a new application with:
      | template | metrics-deployer-template                                     |
      | param    | HAWKULAR_METRICS_HOSTNAME=hawkular-metrics.<%= cb.subdomain%> |
      | param    | IMAGE_PREFIX=<%= product_docker_repo %>openshift3/            |
      | param    | USE_PERSISTENT_STORAGE=true                                   |
      | param    | CASSANDRA_PV_SIZE=5Gi                                         |
      | param    | IMAGE_VERSION=<%= cb.master_version%>                         |
      | param    | MASTER_URL=<%= env.api_endpoint_url %>                        |
      | param    | MODE=deploy                                                   |
    Then the step should succeed

    # Verify all pods and serivce are ready
    And all pods in the project are ready
    And I wait for the "hawkular-cassandra" service to become ready
    And I wait for the "hawkular-metrics" service to become ready
    And I wait for the "heapster" service to become ready

    # Verify the storage are being used
    Given a pod becomes ready with labels:
      | metrics-infra=hawkular-cassandra |
    And I wait for the steps to pass:
    """
    When I get project pod named "<%= pod.name %>" as YAML
    Then the output should contain:
      | persistentVolumeClaim |
    """
    # nfs bug 1337479, 1367161, so delete cassandra pod before post clean up work
    # keep this step until bug fixed.
    And I ensure "hawkular-cassandra-1" rc is deleted

  # @author pruan@redhat.com
  # @case_id OCP-11868
  @admin
  @destructive
  Scenario: Metrics Admin Command - Deploy set PV type 'pv'
    Given the master version >= "3.5"
    Given I have a project
    And I have a NFS service in the project
    # Create PV
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/metrics_pv.json" where:
      | ["spec"]["nfs"]["server"]       | <%= service("nfs-service").ip %> |
      | ["spec"]["capacity"]["storage"] | 10Gi                             |

    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11868/inventory |
    And I switch to cluster admin pseudo user
    And I use the "openshift-infra" project
    And the "metrics-cassandra-1" PVC becomes :bound

  # @author lizhou@redhat.com
  # @case_id OCP-14162
  # This is the dup case of OCP-12205, to support OCP >= v3.5
  @admin
  @smoke
  Scenario: Version >= 3.5 access heapster interface, check jboss wildfly version from hawkular-metrics pod logs
    # Deploy metrics
    Given the master version >= "3.5"
    Given I have a project
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_inventory |

    Given I switch to cluster admin pseudo user
    Given I use the "openshift-infra" project
    And a pod becomes ready with labels:
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

