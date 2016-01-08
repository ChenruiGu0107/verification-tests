Feature: Logging and Metrics

  # @author chunchen@redhat.com
  # @case_id 509065
  @admin
  @smoke
  Scenario: Access heapster interface
    Given I have a project
    And I store default router subdomain in the :subdomain clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin-metrics/master/metrics-deployer-setup.yaml |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role            |   edit |
      | user_name       |   system:serviceaccount:<%=project.name%>:metrics-deployer |
    Then the step should succeed
    When I run the :oadm_add_cluster_role_to_user admin command with:
      | role_name            |   cluster-reader      |
      | user_name       |   system:serviceaccount:<%=project.name%>:heapster    |
    Then the step should succeed
    Given I register clean-up steps:
    """
    When I run the :oadm_remove_cluster_role_from_user admin command with:
      | role_name            |   cluster-reader      |
      | user_name       |   system:serviceaccount:<%=project.name%>:heapster    |
    Then the step should succeed
    """
    When I run the :new_secret client command with:
      | secret_name | metrics-deployer |
      | credential_file | nothing=/dev/null |
    Then the step should succeed
    When I create a new application with:
      | template | metrics-deployer-template |
      | param | HAWKULAR_METRICS_HOSTNAME=hawkular-metrics.<%= cb.subdomain%> |
      | param | IMAGE_PREFIX=<%= product_docker_repo %>openshift3/,USE_PERSISTENT_STORAGE=false,IMAGE_VERSION=latest |
      | param | MASTER_URL=<%= env.api_endpoint_url %> |
    Then the step should succeed
    And all pods in the project are ready
    And I wait for the "hawkular-cassandra" service to become ready
    And I wait for the "hawkular-metrics" service to become ready
    And I wait for the "heapster" service to become ready
#    Given I wait for the steps to pass:
#    """
#    When I run the :get client command with:
#      | resource  | pods |
#    Then the output should match "heapster.*Running.*[1-9]\d*\s+."
#    """
#    And 5 seconds have passed
    Given the first user is cluster-admin
    Given I wait for the steps to pass:
    """
    When I perform the :access_heapster rest request with:
      | project_name | <%=project.name%> |
    Then the output should match "Heapster Version: \d+\.\d+\.\d+"
    """

  # @author chunchen@redhat.com
  # @case_id 509059
  @admin
  @smoke
  @destructive
  Scenario: Scale up kibana and elasticsearch pods
    Given I have a project
    And I store default router subdomain in the :subdomain clipboard
    When I run the :new_secret client command with:
      | secret_name | logging-deployer |
      | credential_file | nothing=/dev/null |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/chunyunchen/v3-testfiles/master/templates/tc509059/sa.yaml |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role            |   edit |
      | user_name       |   system:serviceaccount:<%= project.name %>:logging-deployer |
    Then the step should succeed
    When I run the :oadm_add_cluster_role_to_user admin command with:
      | role_name       |   cluster-reader      |
      | user_name       |   system:serviceaccount:<%= project.name %>:aggregated-logging-fluentd |
    Then the step should succeed
    Given I register clean-up steps:
    """
    When I run the :oadm_remove_cluster_role_from_user admin command with:
      | role_name            |   cluster-reader      |
      | user_name       |   system:serviceaccount:<%= project.name %>:aggregated-logging-fluentd |
    Then the step should succeed
    """
    When I run the :oadm_policy_add_scc_to_user admin command with:
      | scc       | privileged      |
      | user_name | system:serviceaccount:<%= project.name %>:aggregated-logging-fluentd |
    Then the step should succeed
    Given I register clean-up steps:
    """
    When I run the :oadm_policy_remove_scc_from_user admin command with:
      | scc       | privileged      |
      | user_name | system:serviceaccount:<%= project.name %>:aggregated-logging-fluentd |
    Then the step should succeed
    """
    When I create a new application with:
      | template | logging-deployer-template|
      | param | IMAGE_PREFIX=<%= product_docker_repo %>openshift3/,KIBANA_HOSTNAME=kibana.<%= cb.subdomain%>,PUBLIC_MASTER_URL=<%= env.api_endpoint_url %>,ES_INSTANCE_RAM=1024M,ES_CLUSTER_SIZE=1,IMAGE_VERSION=latest,MASTER_URL=<%= env.api_endpoint_url %> |
    Then the step should succeed
    Given I register clean-up steps:
    """
    When I run the :delete admin command with:
      | object_type |  oauthclients |
      | object_name_or_id |   kibana-proxy |
      | n |   openshift-infra |
    Then the step should succeed
    """
    Given I wait for the steps to pass:
    """ 
    When I run the :get client command with:
      | resource  | templates |
    Then the output should contain "logging-support-template"
    """ 
    And the first user is cluster-admin
    When I create a new application with:
      | template | logging-support-template |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | imagestreams |
      | resource_name | logging-fluentd                      |
      | p             | {"metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"}}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | imagestreams |
      | resource_name | logging-elasticsearch                      |
      | p             | {"metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"}}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | imagestreams |
      | resource_name | logging-auth-proxy                     |
      | p             | {"metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"}}} |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | imagestreams |
      | resource_name | logging-kibana                      |
      | p             | {"metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"}}} |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource  | replicationcontrollers |
    Then the output should contain:
      | logging-fluentd-1 |
      | logging-kibana-1 |
    """
    And I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | logging-kibana-1      |
      | replicas | 2                      |
    And I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | logging-fluentd-1      |
      | replicas | 1                      |
    And I wait until number of replicas match "1" for replicationController "logging-fluentd-1"
    And I wait until number of replicas match "2" for replicationController "logging-kibana-1"
