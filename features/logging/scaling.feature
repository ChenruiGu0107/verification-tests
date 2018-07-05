Feature: scaling related tests
  # @author pruan@redhat.com
  # @case_id OCP-11385
  @admin
  @destructive
  Scenario: Scale up curator, kibana and elasticsearch pods
    Given the master version <= "3.4"
    Given I create a project with non-leading digit name
    Given logging service is installed using deployer:
      | deployer_config | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11385/deployer.yaml |
    # check DC values
    And evaluation of `dc('logging-kibana').container_spec(name: 'kibana')` is stored in the :cs_kibana clipboard
    And evaluation of `dc('logging-kibana-ops').container_spec(name: 'kibana')` is stored in the :cs_kibana_ops clipboard
    Then the expression should be true> cb.cs_kibana.env[0]['name'] == 'ES_HOST' and cb.cs_kibana.env[0]['value'] == 'logging-es'
    Then the expression should be true> cb.cs_kibana.env[1]['name'] == 'ES_PORT' and cb.cs_kibana.env[1]['value'] == '9200'
    Then the expression should be true> cb.cs_kibana_ops.env[0]['name'] == 'ES_HOST' and cb.cs_kibana_ops.env[0]['value'] == 'logging-es-ops'
    Then the expression should be true> cb.cs_kibana_ops.env[1]['name'] == 'ES_PORT' and cb.cs_kibana_ops.env[1]['value'] == '9200'

    # Scale up kibana, kibana-ops, ES-ops, ES, curator and curator-ops
    Given a replicationController becomes ready with labels:
      | component=curator |
    And I run the :scale client command with:
      | resource | rc             |
      | name     | <%= rc.name %> |
      | replicas | 2              |
    Given status becomes :running of exactly 2 pods labeled:
      | component=curator |

    Given a replicationController becomes ready with labels:
      | component=curator-ops |
    And I run the :scale client command with:
      | resource | rc             |
      | name     | <%= rc.name %> |
      | replicas | 2              |
    Given status becomes :running of exactly 2 pods labeled:
      | component=curator-ops |

    Given a replicationController becomes ready with labels:
      | component=es |
    And I run the :scale client command with:
      | resource | rc             |
      | name     | <%= rc.name %> |
      | replicas | 2              |
    Given status becomes :running of exactly 2 pods labeled:
      | component=es |

    Given a replicationController becomes ready with labels:
      | component=es-ops |
    And I run the :scale client command with:
      | resource | rc             |
      | name     | <%= rc.name %> |
      | replicas | 2              |
    Given status becomes :running of exactly 2 pods labeled:
      | component=es-ops |

    Given a replicationController becomes ready with labels:
      | component=kibana |
    And I run the :scale client command with:
      | resource | rc             |
      | name     | <%= rc.name %> |
      | replicas | 2              |
    Given status becomes :running of exactly 2 pods labeled:
      | component=kibana |

    Given a replicationController becomes ready with labels:
      | component=kibana-ops |
    And I run the :scale client command with:
      | resource | rc             |
      | name     | <%= rc.name %> |
      | replicas | 2              |
    Given status becomes :running of exactly 2 pods labeled:
      | component=kibana-ops |

  # @author pruan@redhat.com
  # @case_id OCP-16747
  @admin
  @destructive
  Scenario: Scale up kibana pods and elasticsearch pods
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-16747/inventory |
    # redeploy with scalling after the initial installation
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-16747/inventory_scaling |
    And a pod becomes ready with labels:
      | component=es |
    And I wait up to 120 seconds for the steps to pass:
    """
    Then I perform the HTTP request on the ES pod:
      | relative_url | /_cluster/health?format=JSON |
      | op           | GET                          |
    Then the step should succeed
    And the expression should be true> @result[:parsed]['status'] == 'green'
    And the expression should be true> @result[:parsed]['number_of_nodes'] == 3
    """
