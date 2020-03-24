Feature: system metric related tests

  # @author pruan@redhat.com
  # @case_id OCP-15533
  @admin
  @destructive
  Scenario: Undeploy Prometheus via ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And metrics service is installed with ansible using:
      | inventory | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/default_inventory_prometheus |
    And I remove metrics service using ansible
    # verify the project is gone
    And I wait for the resource "project" named "openshift-metrics" to disappear within 60 seconds


  # @author pruan@redhat.com
  # @case_id OCP-15538
  @admin
  @destructive
  Scenario: Deploy Prometheus with node selector via ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    # inventory file expect cb.node_label to be set
    And evaluation of `"ocp15538"` is stored in the :node_label clipboard
    And metrics service is installed with ansible using:
      | inventory | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-15538/inventory |

  # @author pruan@redhat.com
  # @case_id OCP-15544
  @admin
  @destructive
  Scenario: Deploy Prometheus via ansible to non-default namespace
    Given the master version >= "3.7"
    Given I have a project
    And metrics service is installed with ansible using:
      | inventory | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-15544/inventory |

  # @author pruan@redhat.com
  # @case_id OCP-15534
  @admin
  @destructive
  Scenario: Update Prometheus via ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And metrics service is installed with ansible using:
      | inventory | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/default_inventory_prometheus |
    And I wait for the "alerts" service to become ready
    Given I ensure "alerts" service is deleted
    # rerun the ansible install again
    And metrics service is installed with ansible using:
      | inventory | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/default_inventory_prometheus |
    # check the service is brought back to life
    Then the expression should be true> service('alerts').name == 'alerts'

  # @author pruan@redhat.com
  # @case_id OCP-15529
  @admin
  @destructive
  Scenario: Deploy Prometheus with container resources limit via ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And metrics service is installed with ansible using:
      | inventory | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-15529/inventory |
    And a pod becomes ready with labels:
      | app=prometheus |
    # check the parameter for the 5 containers
    #  ["prom-proxy", "prometheus", "alerts-proxy", "alert-buffer", "alertmanager"]
    # check prometheus container
    And the expression should be true> pod.container(name: 'prometheus').spec.cpu_limit_raw == '400m'
    And the expression should be true> pod.container(name: 'prometheus').spec.memory_limit_raw == '512Mi'
    And the expression should be true> pod.container(name: 'prometheus').spec.cpu_request_raw == '200m'
    And the expression should be true> pod.container(name: 'prometheus').spec.memory_request_raw == '256Mi'
    # check alertmanager container
    And the expression should be true> pod.container(name: 'alertmanager').spec.cpu_limit_raw == '500m'
    And the expression should be true> pod.container(name: 'alertmanager').spec.memory_limit_raw == '1Gi'
    And the expression should be true> pod.container(name: 'alertmanager').spec.cpu_request_raw == '256m'
    And the expression should be true> pod.container(name: 'alertmanager').spec.memory_request_raw == '512Mi'
    # check alertbuffer container
    And the expression should be true> pod.container(name: 'alert-buffer').spec.cpu_limit_raw == '400m'
    And the expression should be true> pod.container(name: 'alert-buffer').spec.memory_limit_raw == '1Gi'
    And the expression should be true> pod.container(name: 'alert-buffer').spec.cpu_request_raw == '256m'
    And the expression should be true> pod.container(name: 'alert-buffer').spec.memory_request_raw == '512Mi'
    # check oauth_proxy container
    And the expression should be true> pod.container(name: 'prom-proxy').spec.cpu_limit_raw == '200m'
    And the expression should be true> pod.container(name: 'prom-proxy').spec.memory_limit_raw == '500Mi'
    And the expression should be true> pod.container(name: 'prom-proxy').spec.cpu_request_raw == '200m'
    And the expression should be true> pod.container(name: 'prom-proxy').spec.memory_request_raw == '500Mi'

  # @author pruan@redhat.com
  # @case_id OCP-17206
  @admin
  @destructive
  Scenario: Deploy Prometheus with dynamic pv via ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And metrics service is installed in the system using:
      | inventory | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-17206/inventory |
    And I use the "openshift-metrics" project
    # check pvcs are all BOUND
    Then the expression should be true> pvc('prometheus').ready?[:success]
    Then the expression should be true> pvc('prometheus-alertbuffer').ready?[:success]
    Then the expression should be true> pvc('prometheus-alertmanager').ready?[:success]

    # Verify PVC prometheus  are mount to prometheus-data, prometheus-alertmanager are mount to alertmanager-data,
    # prometheus-alertbuffer are mount to alerts-data

    Given evaluation of `{"prometheus"=>"prometheus-data","alertmanager"=>"alertmanager-data", "alert-buffer"=>"alerts-data"}` is stored in the :container_mounts clipboard
    And I repeat the following steps for each :container_mount in cb.container_mounts:
    """
    And evaluation of `pod('prometheus-0').container(name: cb.container_mount.first).spec.volume_mounts.select { |v| v['name'] == cb.container_mount.last}` is stored in the :volume_mnt clipboard
    Then the expression should be true> cb.volume_mnt.first['mountPath'] == "/#{cb.container_mount.first}"
    """
    # check prom-proxy naming is an exception so need to do it separately.
    And evaluation of `pod('prometheus-0').container(name: 'prom-proxy').spec.volume_mounts.select { |v| v['name'] == "prometheus-data"}` is stored in the :volume_mnt clipboard
    Then the expression should be true> cb.volume_mnt.first['mountPath'] == "/prometheus"
    # Verify prometheus-data are mount in the container prometheus and prom-proxy
    Given evaluation of `%w[prometheus prom-proxy]` is stored in the :containers clipboard
    And I repeat the following steps for each :container in cb.containers:
    """
    When I run the :exec client command with:
      | pod              | #{pod.name }    |
      | container        | #{cb.container} |
      | exec_command     | --              |
      | exec_command     | df              |
      | exec_command_arg | -h              |
    Then the output should contain "/prometheus"
    """
    Given evaluation of `%w[alertmanager alert-buffer]` is stored in the :containers clipboard
    And I repeat the following steps for each :container in cb.containers:
    """
    When I run the :exec client command with:
      | pod              | #{pod.name}     |
      | container        | #{cb.container} |
      | exec_command     | --              |
      | exec_command     | df              |
      | exec_command_arg | -h              |
    Then the output should contain "/#{cb.container}"
    """

  # @author pruan@redhat.com
  # @case_id OCP-18805
  @admin
  @destructive
  Scenario: Hawkular Metrics log should include date as part of the timestamp
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
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
    Given I create a project with non-leading digit name
    And metrics service is installed with ansible using:
      | inventory     | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-15535/inventory |
      | negative_test | true                                                                                                   |
    Then the output should contain:
      | Could not find or access 'this_is_bogus_path' |

  # @author pruan@redhat.com
  # @case_id OCP-18546
  @admin
  @destructive
  Scenario: hawkular-alerts war packages are removed from hawkular-metrics
    Given the master version >= "3.10"
    Given I create a project with non-leading digit name
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
      | inventory | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/logging_metrics/OCP-12234/inventory |
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
