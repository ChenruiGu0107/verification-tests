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
    And I wait up to 120 seconds for the steps to pass:
    """
    And I run commands on the host:
      | curl --resolve hawkular-metrics.<%= cb.subdomain %>:443: <%= cb.router_ip[0] %> https://hawkular-metrics.<%= cb.subdomain %> --cacert <%= host.workdir + "/ca.crt" %> |
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
      | inventory        | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12879/inventory |
    Given I switch to cluster admin pseudo user
    Given I use the "openshift-infra" project
    Then status becomes :running of exactly 1 pods labeled:
      | metrics-infra=heapster |
      | name=heapster          |
    And the expression should be true>  pod.service_account_name == 'heapster'
