Feature: ansible install related feature
  # @author pruan@redhat.com
  # @case_id OCP-12234
  @admin
  @destructive
  Scenario: Metrics Admin Command - fresh deploy with default values
    Given the master version >= "3.5"
    Given I have a project
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12234/inventory |

  # @author pruan@redhat.com
  # @case_id OCP-12305
  @admin
  @destructive
  Scenario: Metrics Admin Command - clean and install
    Given the master version >= "3.5"
    Given I have a project
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12305/inventory |
    Given I remove metrics service installed in the "openshift-infra" project using ansible
    # reinstall it again
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12305/inventory |

  # @author lizhou@redhat.com
  # @case_id OCP-14055
  # This is the dup case of OCP-10776, to support deploy steps changes on OCP v3.5 and later
  # Run this case in m1.large on OpenStack, m3.large on AWS, or n1-standard-2 on GCE
  @admin
  @destructive
  @smoke
  Scenario: Version >= 3.5 deploy metrics stack with persistent storage
    Given the master version >= "3.5"
    Given I have a project
    And I have a NFS service in the project

    # Create PV
    Given admin creates a PV from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/metrics_pv.json" where:
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |

    # Deploy metrics
    Given cluster role "cluster-admin" is added to the "first" user
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-14055/inventory |

    # Verify the storage are being used
    Given I use the "openshift-infra" project
    And a pod becomes ready with labels:
    | metrics-infra=hawkular-cassandra |
    And I wait for the steps to pass:
    """
    When I get project pod named "<%= pod.name %>" as YAML
    Then the output should contain:
      | persistentVolumeClaim |
    """
    # nfs bug 1337479, 1367161, so delete cassandra rc before post clean up work
    # keep this step until bug fixed.
    And I ensure "hawkular-cassandra-1" rc is deleted

  # @author pruan@redhat.com
  # @case_id OCP-12186
  @admin
  @destructive
  Scenario: Metrics Admin Command - fresh deploy with custom cert
    Given the master version >= "3.5"
    Given I have a project
    And I store default router IPs in the :router_ip clipboard
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory        | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12186/inventory |
      | copy_custom_cert | true                                                                                                   |
    # we have to run the curl in the first master because that is where the cert file is located
    Given I use the "<%= env.master_hosts.first.hostname %>" node
    And I wait up to 120 seconds for the steps to pass:
    """
    And I run commands on the host:
      | curl --resolve <%= cb.metrics_route_prefix + "." + cb.subdomain %>:443: <%= cb.router_ip[0] %> https://<%= cb.metrics_route_prefix + "." + cb.subdomain %> --cacert <%= host.workdir + "/ca.crt" %> |
    And the output should contain:
      | Hawkular Metrics                                |
    """

  # @author pruan@redhat.com
  # @case_id OCP-12879
  @admin
  @destructive
  Scenario: Metrics Admin Command - Deploy standalone heapster
    Given the master version >= "3.5"
    Given I have a project
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12879/inventory |

    Given I switch to cluster admin pseudo user
    Given I use the "openshift-infra" project
    Then status becomes :running of exactly 1 pods labeled:
      | metrics-infra=heapster |
      | name=heapster          |
    And the expression should be true>  pod.service_account_name == 'heapster'

  # @author pruan@redhat.com
  # @case_id OCP-11430
  @admin
  @destructive
  Scenario: Metrics Admin Command - Deploy set openshift_metrics_hawkular_replicas
    Given the master version >= "3.5"
    Given I have a project
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11430/inventory |
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-infra" project
    Then status becomes :running of exactly 2 pods labeled:
      | metrics-infra=hawkular-metrics |
      | name=hawkular-metrics          |

  # @author pruan@redhat.com
  # @case_id OCP-10214
  @admin
  @destructive
  Scenario: deploy metrics with dynamic volume
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-10214/inventory |
    Given I login via web console
    And I open metrics console in the browser
    Given the metrics service status in the metrics web console is "STARTED"


  # @author pruan@redhat.com
  # @case_id OCP-12012
  @admin
  @destructive
  Scenario: Metrics Admin Command - Deploy set user_write_access
    Given the master version >= "3.5"
    Given I have a project
    And metrics service is installed in the "openshift-infra" project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12012/inventory |

    Given I wait up to 180 seconds for the steps to pass:
    """
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /metrics/ |
    And the step succeeded
    """
    Given I perform the POST metrics rest request with:
      | project_name | <%= project.name %>                                                                               |
      | path         | /metrics/gauges                                                                                   |
      | payload      | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/test_data.json |
    Given I perform the GET metrics rest request with:
      | project_name | <%= project.name %> |
      | path         | /metrics/gauges     |
    Then the expression should be true> cb.metrics_data[0][:parsed]['minTimestamp'] == 1460111065369
    Then the expression should be true> cb.metrics_data[0][:parsed]['maxTimestamp'] == 1460413065369

  # # @author pruan@redhat.com
  # # @case_id OCP-15527
  # @admin
  # @destructive
  # Scenario: Deploy Prometheus via ansible with default values
  #   Given the master version >= "3.7"
  #   Given I create a project with non-leading digit name
  #   And metrics service is installed in the project with ansible using:
  #     | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_inventory_prometheus |

  # @author pruan@redhat.com
  # @case_id OCP-15533
  @admin
  @destructive
  Scenario: Undeploy Prometheus via ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And metrics service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_inventory_prometheus |
    And I remove metrics service installed in the project using ansible
    And I switch to cluster admin pseudo user
    # verify the project is gone
    And I wait for the resource "project" named "openshift-metrics" to disappear within 60 seconds

  # @author pruan@redhat.com
  # @case_id OCP-15534
  @admin
  @destructive
  Scenario: Update Prometheus via ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And metrics service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_inventory_prometheus |
    And I switch to cluster admin pseudo user
    And I wait for the "alerts" service to become ready
    Given I ensure "alerts" service is deleted
    # rerun the ansible install again
    And metrics service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_inventory_prometheus |
    # check the service is brought back to life
    Then the expression should be true> service('alerts').name == 'alerts'

  # @author pruan@redhat.com
  # @case_id OCP-15538
  @admin
  @destructive
  Scenario: Deploy Prometheus with node selector via ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    # inventory file expect cb.node_label to be set
    And evaluation of `"ocp15538"` is stored in the :node_label clipboard
    And metrics service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15538/inventory |

  # @author pruan@redhat.com
  # @case_id OCP-15544
  @admin
  @destructive
  Scenario: Deploy Prometheus via ansible to non-default namespace
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And metrics service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15544/inventory |

  # @author pruan@redhat.com
  # @case_id OCP-15529
  @admin
  @destructive
  Scenario: Deploy Prometheus with container resources limit via ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And metrics service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15529/inventory |
    And I switch to cluster admin pseudo user
    And a pod becomes ready with labels:
      | app=prometheus |
    And evaluation of `pod.containers(user: user)` is stored in the :containers clipboard
    # check the parameter for the 5 pods
    #  ["prom-proxy", "prometheus", "alerts-proxy", "alert-buffer", "alertmanager"]
    # check prometheus pod
    And the expression should be true> cb.containers['prometheus'].spec.cpu_limit_raw == '400m'
    And the expression should be true> cb.containers['prometheus'].spec.memory_limit_raw == '512Mi'
    And the expression should be true> cb.containers['prometheus'].spec.cpu_request_raw == '200m'
    And the expression should be true> cb.containers['prometheus'].spec.memory_request_raw == '256Mi'
    # check alertmanager pod
    And the expression should be true> cb.containers['alertmanager'].spec.cpu_limit_raw == '500m'
    And the expression should be true> cb.containers['alertmanager'].spec.memory_limit_raw == '1Gi'
    And the expression should be true> cb.containers['alertmanager'].spec.cpu_request_raw == '256m'
    And the expression should be true> cb.containers['alertmanager'].spec.memory_request_raw == '512Mi'
    # check alertbuffer pod
    And the expression should be true> cb.containers['alert-buffer'].spec.cpu_limit_raw == '400m'
    And the expression should be true> cb.containers['alert-buffer'].spec.memory_limit_raw == '1Gi'
    And the expression should be true> cb.containers['alert-buffer'].spec.cpu_request_raw == '256m'
    And the expression should be true> cb.containers['alert-buffer'].spec.memory_request_raw == '512Mi'
    # check oauth_proxy pod
    And the expression should be true> cb.containers['prom-proxy'].spec.cpu_limit_raw == '200m'
    And the expression should be true> cb.containers['prom-proxy'].spec.memory_limit_raw == '500Mi'
    And the expression should be true> cb.containers['prom-proxy'].spec.cpu_request_raw == '200m'
    And the expression should be true> cb.containers['prom-proxy'].spec.memory_request_raw == '500Mi'

  # @author pruan@redhat.com
  # @case_id OCP-18163
  @admin
  @destructive
  Scenario: Check terminationGracePeriodSeconds value for hawkular-cassandra pod
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And metrics service is installed in the system
    And I switch to cluster admin pseudo user
    Given I use the "openshift-infra" project
    And a pod becomes ready with labels:
      | metrics-infra=hawkular-cassandra |
    Then the expression should be true> pod.termination_grace_period_seconds == 1800

  # @author pruan@redhat.com
  # @case_id OCP-17163
  @admin
  @destructive
  Scenario: deploy metrics with dynamic volume along with OCP
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And metrics service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17163/inventory |
    And I switch to cluster admin pseudo user
    Given I use the "openshift-infra" project
    And a pod becomes ready with labels:
      | metrics-infra=hawkular-cassandra |
    # 3 steps to verify hawkular-cassandra pod using mount correctly
    # 1. pvc working
    Then the expression should be true> pvc('metrics-cassandra-1').ready?[:success]
    # 2. check pod volume name matches 'metrics-cassandra-1'
    Then the expression should be true> pod.volumes.select { |v| v["name"] == 'cassandra-data' }.first.dig('persistentVolumeClaim', 'claimName') == 'metrics-cassandra-1'
    # 3. check volume cassandra-data was mounted to /cassandra_data" in pod spec
    Then the expression should be true> pod.container(name: 'hawkular-cassandra-1').spec.volume_mounts.select { |v| v['mountPath'] == "/cassandra_data" }.count > 0

  # @author pruan@redhat.com
  # @case_id OCP-9982
  @admin
  @destructive
  Scenario: Heapster should use node name instead of external ID to indentify metrics
    Given I create a project with non-leading digit name
    And metrics service is installed in the system
    Given I select a random node's host
    And evaluation of `node.external_id` is stored in the :external_id clipboard
    Given cluster role "cluster-admin" is added to the "first" user
    # it usually take a little while for the query to comeback with contents
    And I wait for the steps to pass:
    """
    And I perform the GET metrics rest request with:
      | project_name | _system              |
      | path         | /metrics/metrics     |
    And the expression should be true> @result[:exitstatus] == 200
    """
    # extract all of the result id and parse it into an array which should NOT contain external ID
    And evaluation of `YAML.load(@result[:response]).map { |r| r['id'] }` is stored in the :result_ids clipboard
    Then the expression should be true> cb.result_ids.select {|id| id.include? cb.external_id}.count == 0

  # @author pruan@redhat.com
  # @case_id OCP-15860
  @admin
  @destructive
  Scenario: Undeploy HOSA via ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And metrics service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15860/inventory |
    And I switch to cluster admin pseudo user
    Then all Hawkular agent related resources exist in the project
    And metrics service is uninstalled from the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15860/uninstall_inventory |
    Then no Hawkular agent resources exist in the project


  # @author pruan@redhat.com
  # @case_id OCP-12112
  @admin
  @destructive
  Scenario: Metrics Admin Command - Deploy with custom metrics parameter
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And metrics service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12112/inventory |
    And I switch to cluster admin pseudo user
    And I use the "openshift-infra" project
    Then the expression should be true> rc('hawkular-cassandra-1').suplemental_groups.include? 65531
    Then the expression should be true> rc('heapster').annotation('kubectl.kubernetes.io/last-applied-configuration').include? '--metric_resolution=15s'
    Then the expression should be true> rc('hawkular-metrics').annotation('kubectl.kubernetes.io/last-applied-configuration').include? "-Dhawkular.metrics.default-ttl=14"

  # @author pruan@redhat.com
  # @case_id OCP-18507
  @admin
  @destructive
  Scenario: Check the default image prefix and version - prometheus
    Given the master version >= "3.4"
    Given I create a project with non-leading digit name
    And metrics service is installed in the system using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-18507/inventory |
      | negative_test | true                                                                                                   |
    And I switch to cluster admin pseudo user
    And I use the "<%= cb.target_proj %>" project
    And evaluation of `"registry.access.redhat.com/openshift3/"` is stored in the :expected_prefix clipboard
    # check all container spec has the expected url
    And the expression should be true> stateful_set('prometheus').containers_spec.all? {|s| s.image.start_with? cb.expected_prefix }
    And the expression should be true> stateful_set('prometheus').containers_spec.all? {|s| s.image.end_with? cb.master_version }
    # In test phase, the image is not ready in registry.access.redhat.com. so the pod couldn't be in running status.
    # so we need to check the image prefix/version in statefullset and ds
    Then the expression should be true> daemon_set('prometheus-node-exporter').container_spec(name: 'node-exporter').image.start_with? cb.expected_prefix



  # @author pruan@redhat.com
  # @case_id OCP-18506
  @admin
  @destructive
  Scenario: Check the default image prefix and version - metrics
    Given the master version >= "3.4"
    Given I create a project with non-leading digit name
    And metrics service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-18506/inventory |
      | negative_test | true                                                                                                   |
    And I switch to cluster admin pseudo user

    And I use the "<%= cb.target_proj %>" project
    And a pod becomes ready with labels:
      | metrics-infra=hawkular-metrics |
    And evaluation of `"registry.access.redhat.com/openshift3/"` is stored in the :expected_prefix clipboard
    And evaluation of `%w[hawkular-cassandra-1 hawkular-metrics heapster]` is stored in the :metrics_rcs clipboard
    Given I repeat the following steps for each :metrics_rc in cb.metrics_rcs:
    """
    Then the expression should be true> rc(cb.metrics_rc).container_spec(name: cb.metrics_rc).image.start_with? cb.expected_prefix
    Then the expression should be true> rc(cb.metrics_rc).container_spec(name: cb.metrics_rc).image.end_with? cb.master_version
    """
    And I use the "default" project
    Then the expression should be true> daemon_set('hawkular-openshift-agent').container_spec(name: 'hawkular-openshift-agent').image.start_with? cb.expected_prefix
    Then the expression should be true> daemon_set('hawkular-openshift-agent').container_spec(name: 'hawkular-openshift-agent').image.end_with? cb.master_version


