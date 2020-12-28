@clusterlogging
Feature: cluster log forwarder testing

  # @author qitang@redhat.com
  # @case_id OCP-32365
  @admin
  @destructive
  Scenario: ClusterLogForwarder invalid CRs testing
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given evaluation of `["clf-missing-required-value.yaml", "clf-invalid-forward-type.yaml", "clf-invalid-name.yaml", "clf-url-checking.yaml"]` is stored in the :clf_yaml_files clipboard
    Given I repeat the following steps for each :clf_yaml in cb.clf_yaml_files:
    """
    Given I obtain test data file "logging/clusterlogforwarder/#{cb.clf_yaml}"
    When I run the :create client command with:
      | f | #{cb.clf_yaml} |
    Then the step should fail
    And the output should contain:
      | The ClusterLogForwarder "instance |
      | " is invalid                      |
    """

  # @author qitang@redhat.com
  # @case_id OCP-32127
  @admin
  @destructive
  Scenario: Couldn't add `outputs` named `default` in ClusterLogForwarder
    Given I switch to the first user
    And I have a project
    And evaluation of `project` is stored in the :fluentd_proj clipboard
    Given fluentd receiver is deployed as insecure in the "<%= cb.fluentd_proj.name %>" project

    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I obtain test data file "logging/clusterlogging/example_indexmanagement.yaml"
    When I create clusterlogging instance with:
      | remove_logging_pods | true                         |
      | crd_yaml            | example_indexmanagement.yaml |
    Then the step should succeed

    Given admin ensures "instance" cluster_log_forwarder is deleted from the "openshift-logging" project after scenario
    Given I obtain test data file "logging/clusterlogforwarder/clf-invalid-output-name.yaml"
    When I process and create:
      | f | clf-invalid-output-name.yaml |
      | p | URL=udp://fluentdserver.<%= cb.fluentd_proj.name %>.svc:24224 |
    Then the step should succeed
    And I wait up to 300 seconds for the steps to pass:
    """
      Given the expression should be true> cluster_log_forwarder('instance').outputs_status(cached: false)["output_0_"][0]['message'] == "output name \"default\" is reserved"
    """

  # @author qitang@redhat.com
  # @case_id OCP-32629
  @admin
  @destructive
  Scenario: Only collect app logs on pre-defined namespaces
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I obtain test data file "logging/clusterlogforwarder/clf-forward-with-pre-defined-namespaces.yaml"
    And admin ensures "instance" cluster_log_forwarder is deleted from the "openshift-logging" project after scenario
    When I run the :create client command with:
      | f | clf-forward-with-pre-defined-namespaces.yaml |
    Then the step should succeed
    Given I obtain test data file "logging/clusterlogging/example_indexmanagement.yaml"
    When I create clusterlogging instance with:
      | remove_logging_pods | true                         |
      | crd_yaml            | example_indexmanagement.yaml |
    Then the step should succeed
    Given I switch to the first user
    And evaluation of `["logging-test-project4", "logging-test-project3", "logging-test-project2", "logging-test-project1"]` is stored in the :project_names clipboard
    And I obtain test data file "logging/loggen/container_json_log_template.json"
    Given I repeat the following steps for each :project_name in cb.project_names:
    """
    When I run the :new_project client command with:
      | project_name | #{cb.project_name} |
    Then the step should succeed
    When I run the :new_app client command with:
      | file | container_json_log_template.json |
    Then the step should succeed
    """
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I wait up to 600 seconds for the steps to pass:
    """
    When I perform the HTTP request on the ES pod with labels "es-node-master=true":
      | relative_url | app*/_search?pretty&size=0' -d'{"aggs":{"distinct_namespace_name":{"terms":{"field":"kubernetes.namespace_name"}}}} |
      | op           | GET                                                                                                                 |
    Then the step should succeed
    And the output should contain:
      | logging-test-project1 |
      | logging-test-project2 |
    And the output should not contain:
      | logging-test-project3 |
      | logging-test-project4 |
    """
