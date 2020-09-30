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
    Given I switch to cluster admin pseudo user
    And I use the "openshift-logging" project
    Given I obtain test data file "logging/clusterlogging/example_indexmanagement.yaml"
    When I create clusterlogging instance with:
      | remove_logging_pods | true                         |
      | crd_yaml            | example_indexmanagement.yaml |
    Then the step should succeed
    Given fluentd receiver is deployed as secure in the "openshift-logging" project
    Given admin ensures "instance" cluster_log_forwarder is deleted after scenario
    Given I obtain test data file "logging/clusterlogforwarder/clf-invalid-output-name.yaml"
    When I run the :create client command with:
      | f | clf-invalid-output-name.yaml |
    Then the step should succeed
    And I wait up to 300 seconds for the steps to pass:
    """
      Given the expression should be true> cluster_log_forwarder('instance').outputs_status(cached: false)["output_0_"][0]['message'] == "output name \"default\" is reserved"
    """
