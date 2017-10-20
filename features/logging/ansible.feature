Feature: ansible install related feature
  # @author pruan@redhat.com
  # @case_id OCP-11061
  @admin
  @destructive
  Scenario: Deploy logging via Ansible: clean install when OPS cluster is enabled
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And logging service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11061/inventory |
    Given a pod becomes ready with labels:
      | component=curator-ops,logging-infra=curator,provider=openshift |
    Given a pod becomes ready with labels:
      | component=es-ops, logging-infra=elasticsearch,provider=openshift |
    Given a pod becomes ready with labels:
      | component=kibana-ops,logging-infra=kibana,provider=openshift   |

  # @author pruan@redhat.com
  # @case_id OCP-12377
  @admin
  @destructive
  Scenario: Uninstall logging via Ansible
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    # the clean up steps registered with the install step will be using uninstall
    And logging service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12377/inventory |

  # @author pruan@redhat.com
  # @case_id OCP-11431
  @admin
  @destructive
  Scenario: Deploy logging via Ansible - clean install when OPS cluster is not enabled
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    Given logging service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11431/inventory |
    And I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    And the output should not contain:
      | logging-curator-ops |
      | logging-es-ops      |
      | logging-fluentd-ops |
      | logging-kibana-ops  |

  # @author pruan@redhat.com
  # @case_id OCP-15772
  @admin
  @destructive
  Scenario: kibana status is red when the es pod is not running
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And a replicationController becomes ready with labels:
      | component=es |
    # disable es pod by scaling it to 0
    Then I run the :scale client command with:
      | resource | replicationController |
      | name     | <%= rc.name %>        |
      | replicas | 0                     |
    And I wait until number of replicas match "0" for replicationController "<%= rc.name %>"
    And I login to kibana logging web console
    And I get the visible text on web html page
    And the output should contain:
      | Status: Red                                                   |
      | Unable to connect to Elasticsearch at https://logging-es:9200 |
