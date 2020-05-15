Feature: metrics logging and uninstall tests

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
    Given admin creates a PV from "<%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/metrics_pv.json" where:
      | ["spec"]["nfs"]["server"] | <%= service("nfs-service").ip %> |

    # Deploy metrics
    Given cluster role "cluster-admin" is added to the "first" user
    And metrics service is installed with ansible using:
      | inventory | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/OCP-14055/inventory |

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
  # @case_id OCP-18163
  @admin
  @destructive
  Scenario: Check terminationGracePeriodSeconds value for hawkular-cassandra pod
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And metrics service is installed in the system
    And a pod becomes ready with labels:
      | metrics-infra=hawkular-cassandra |
    Then the expression should be true> pod.termination_grace_period_seconds == 1800

  # @author pruan@redhat.com
  # @case_id OCP-18507
  @admin
  @destructive
  Scenario: Check the default image prefix and version - prometheus
    Given the master version >= "3.4"
    Given I create a project with non-leading digit name
    And metrics service is installed in the system using:
      | inventory     | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/OCP-18507/inventory |
      | negative_test | true                                                                                                   |
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
      | inventory | <%= BushSlicer::HOME %>/features/tierN/testdata/logging_metrics/OCP-18506/inventory |
      | negative_test | true                                                                                                   |
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
