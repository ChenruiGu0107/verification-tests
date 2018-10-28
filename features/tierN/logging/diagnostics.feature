Feature: logging diagnostics tests
  # @author pruan@redhat.com
  # @case_id OCP-11384
  @admin
  @destructive
  Scenario: Aggregated logging diagnostics for a healthy logging system
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And I switch to cluster admin pseudo user
    # XXX calling the command from master due to bug https://bugzilla.redhat.com/show_bug.cgi?id=1510212
    And I run logging diagnostics
    And the output should not contain:
      | Skipping diagnostic: AggregatedLogging |
    Then the output should contain:
      | Completed with no errors or warnings seen |

  # @author pruan@redhat.com
  # @case_id OCP-12229
  @admin
  @destructive
  Scenario: Aggregated logging diagnostics for services-endpoints
    Given I create a project with non-leading digit name
    Given logging service is installed in the system using:
      | inventory       | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12229/inventory   |
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_deployer.yaml |
    And I switch to cluster admin pseudo user
    # make sure we have a good starting point
    And I run logging diagnostics
    And the output should not contain:
      | Skipping diagnostic: AggregatedLogging |
    Then the output should contain:
      | Completed with no errors or warnings seen |
    # delete endpoints of kibana
    And I use the "<%= project.name %>" project
    And I run the :delete client command with:
      | object_type       | endpoints      |
      | object_name_or_id | logging-kibana |
    Then the step should succeed
    And I run the :delete client command with:
      | object_type       | endpoints          |
      | object_name_or_id | logging-kibana-ops |
    Then the step should succeed
    And I run logging diagnostics
    And the output should not contain:
      | Skipping diagnostic: AggregatedLogging |
    And the output should contain:
      | endpoints "logging-kibana" not found     |
      | endpoints "logging-kibana-ops" not found |
    # delete the service of kibana
    And I run the :delete client command with:
      | object_type       | svc            |
      | object_name_or_id | logging-kibana |
    Then the step should succeed
    And I run the :delete client command with:
      | object_type       | svc                |
      | object_name_or_id | logging-kibana-ops |
    Then the step should succeed
    And I run logging diagnostics
    And the output should not contain:
      | Skipping diagnostic: AggregatedLogging |
    And the output should contain:
      | Expected to find 'logging-kibana' among the logging services for the project but did not       |
      | Looked for 'logging-kibana-ops' among the logging services for the project but did not find it |
  # @author pruan@redhat.com
  # @case_id OCP-11846
  @admin
  @destructive
  Scenario: Aggregated logging diagnostics for fluentd daemonset
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And I ensure "logging-fluentd" daemonset is deleted from the "<%= project.name %>" project
    And I run logging diagnostics
    Then the output should contain:
      | There were no DaemonSets in project |

  # @author pruan@redhat.com
  # @case_id OCP-12102
  @admin
  @destructive
  Scenario: Aggregated logging diagnostics for non-existed Oauthclient
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And I switch to cluster admin pseudo user
    And I ensure "kibana-proxy" oauthclient is deleted from the "<%= project.name %>" project
    And I run logging diagnostics
    Then the output should contain:
      | Error retrieving the OauthClient 'kibana-proxy' |

  # @author pruan@redhat.com
  # @case_id OCP-11995
  @admin
  @destructive
  Scenario: Aggregated logging diagnostics for missing service accounts
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And I ensure "aggregated-logging-elasticsearch" serviceaccounts is deleted from the "<%= cb.target_proj %>" project
    And I ensure "aggregated-logging-fluentd" serviceaccounts is deleted from the "<%= cb.target_proj %>" project
    And I run logging diagnostics
    Then the output should contain:
      | Did not find ServiceAccounts: aggregated-logging-elasticsearch,aggregated-logging-fluentd |

  # @author pruan@redhat.com
  # @case_id OCP-10994
  @admin
  @destructive
  Scenario: Aggregated logging diagnostics for missing service accounts
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12229/inventory |
    And logging service is installed in the system
    And I switch to cluster admin pseudo user
    And a deploymentConfig becomes ready with labels:
      | component=es |
    And I ensure "<%= dc.name %>" deploymentconfigs is deleted from the "<%= project.name %>" project
    And a deploymentConfig becomes ready with labels:
      | component=es-ops |
    And I ensure "<%= dc.name %>" deploymentconfigs is deleted from the "<%= project.name %>" project
    And I run logging diagnostics
    Then the output should contain:
      | Did not find a DeploymentConfig to support component 'es' |
      | Did not find a DeploymentConfig to support optional component 'es-ops' |

  # @author pruan@redhat.com
  # @case_id OCP-16680
  @admin
  @destructive
  Scenario: Aggregated logging diagnostics for cluster-reader RoleBindings
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And I switch to cluster admin pseudo user
    And cluster role "cluster-reader" is removed from the "system:serviceaccount:<%= project.name %>:aggregated-logging-fluentd" service account
    And I run logging diagnostics
    And the output should contain "ServiceAccount 'aggregated-logging-fluentd' is not a cluster-reader in the '<%= project.name %>' project"
    And cluster role "cluster-reader" is added to the "system:serviceaccount:<%= project.name %>:aggregated-logging-fluentd" service account
    And I run logging diagnostics
    Then the output should contain "Completed with no errors or warnings seen"
