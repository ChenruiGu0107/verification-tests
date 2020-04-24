Feature: metrics scaling tests
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
    When I run the :set_volume client command with:
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
