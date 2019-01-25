Feature: install and uninstall related scenarios

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
    And a deploymentConfig becomes ready with labels:
      | component=es |
    # disable es pod by scaling it to 0
    Then I run the :scale client command with:
      | resource | deploymentConfig |
      | name     | <%= dc.name %>   |
      | replicas | 0                |
    And I wait until number of replicas match "0" for replicationController "<%= rc.name %>"
    # get back to normal user mode
    Given I switch to the first user
    And I login to kibana logging web console
    And I get the visible text on web html page
    And the output should contain:
      | Status: Red |

  # @author pruan@redhat.com
  # @case_id OCP-11687
  @admin
  @destructive
  Scenario: Deploy logging via Ansible: clean install with custom cert
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory        | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11687/inventory |
      | copy_custom_cert | true                                                                                                   |
    # execute the curl command in a pod to avoid possiblity that the client
    # platform does not have 'curl'
    And a pod becomes ready with labels:
      | component=kibana, logging-infra=kibana |
    And I execute on the pod:
      | curl | -k | <%= env.logging_console_url %> | -vv |
    And the expression should be true> cb.cert_regex = /CN=(#{cb.logging_route_prefix}|\*).(#{cb.subdomain})/
    Then the expression should be true> @result[:response].include? "Server certificate"
    Then the expression should be true> cb.cert_regex.match(@result[:response])

  # @author pruan@redhat.com
  # @case_id OCP-15988
  @admin
  @destructive
  Scenario: install and uninstalled eventrouter with default values
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
     | inventory        | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15988/inventory |
    Given event logs can be found in the ES pod
    # cb.master_version is set in the installed step.
    And I use the "default" project
    And a pod becomes ready with labels:
      | component=eventrouter,deploymentconfig=logging-eventrouter,logging-infra=eventrouter,provider=openshift |
    And evaluation of `pod.name` is stored in the :eventrouter_pod_name clipboard
    # now delete the service and check that pod is removed from the 'default' project
    And I use the "<%= cb.target_proj %>" project
    And I remove logging service using ansible
    And I use the "default" project
    And I wait for the pod named "<%= cb.eventrouter_pod_name %>" to die regardless of current status

  # @author pruan@redhat.com
  # @case_id OCP-11869
  @admin
  @destructive
  Scenario: Deploy logging via Ansible - clean install with jounal log driver, not read logs from head
    Given the master version >= "3.5"
    Given evaluation of `rand_str(16, :hex)` is stored in the :rand_msg_before clipboard
    Given evaluation of `rand_str(16, :hex)` is stored in the :rand_msg_after clipboard
    Given I have a project
    And I select a random node's host
    And I run commands on the host:
      | logger -i <%= cb.rand_msg_before %> |
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11869/inventory |
    When I wait for the ".operations" index to appear in the ES pod with labels "component=es"
    And I run commands on the host:
      | logger -i <%= cb.rand_msg_after %> |
    Then I perform the HTTP request on the ES pod:
      | relative_url | <%= cb.index_data['index'] %>/_search?pretty&size=50&q=<%= cb.rand_msg_before %> |
      | op           | GET                                                                              |
    And the expression should be true> @result.dig(:parsed, 'hits', 'total') == 0
    # check message is logged after installation of kibana is registered with they system
    And I wait up to 600 seconds for the steps to pass:
    """
    Then I perform the HTTP request on the ES pod:
      | relative_url | <%= cb.index_data['index'] %>/_search?pretty&size=50&q=<%= cb.rand_msg_after %> |
      | op           | GET                                                                             |
    And the expression should be true> @result.dig(:parsed, 'hits', 'total') > 0
    """

  # @author pruan@redhat.com
  # @case_id OCP-12013
  @admin
  @destructive
  Scenario: Deploy logging via Ansible: clean install with journal log driver reading logs from head
    Given the master version >= "3.5"
    Given a 7 character random string is stored into the :rand_msg clipboard
    Given I have a project
    And I select a random node's host
    And I run commands on the host:
      | logger -i message-before-<%= cb.rand_msg %> |
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12013/inventory |
    When I wait for the ".operations" index to appear in the ES pod with labels "component=es"
    And I wait up to 600 seconds for the steps to pass:
    """
    Then I perform the HTTP request on the ES pod:
      | relative_url | <%= cb.index_data['index'] %>/_search?pretty&size=50&q=message-before-<%= cb.rand_msg %> |
      | op           | GET                                                                                      |
    And the expression should be true> @result.dig(:parsed, 'hits', 'total') > 0
    """

  # @author pruan@redhat.com
  # @case_id OCP-17424
  @admin
  @destructive
  Scenario: fluentd ops feature checking
    Given the master version >= "3.6"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17424/inventory |
    # check fluentd pod
    Given a pod becomes ready with labels:
      | component=fluentd |
    And I execute on the "<%= pod.name %>" pod:
      | env |
    Then the step should succeed
    And the output should contain "OPS_HOST=logging-es-ops"
    And I execute on the "<%= pod.name %>" pod:
      | ls | /etc/fluent/configs.d/filter-post-z-retag-two.conf |
    Then the step should succeed
    And the output should contain "/etc/fluent/configs.d/filter-post-z-retag-two.conf"
    # check non-ops es pod
    And I get the ".operation" logging index information from a pod with labels "component=es"
    Then the expression should be true> cb.index_data.nil?
    # check ops es pod, .operation index can take a few minutes to appear
    And I wait up to 600 seconds for the steps to pass:
    """
    And I get the ".operation" logging index information from a pod with labels "component=es-ops"
    Then the expression should be true> cb.index_data and cb.index_data.count > 0
    """

  # @author pruan@redhat.com
  # @case_id OCP-12113
  @admin
  @destructive
  Scenario: Deploy logging via Ansible: clean install with json-file log driver + CEFK pod limits
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12113/inventory |
    And a pod becomes ready with labels:
      | component=es |
    # make sure containers are there regardless of ordering
    Then the expression should be true> ["proxy", "elasticsearch"] - pod.containers.map(&:name) == []
    And the expression should be true> pod.container(name: 'elasticsearch').spec.memory_limit_raw == "1024M"
    And the expression should be true> pod.container(name: 'elasticsearch').spec.cpu_limit_raw == "200m"
    # check fluentd limits
    Given a pod becomes ready with labels:
      | component=fluentd |
    Then the expression should be true> pod.container(name: 'fluentd-elasticsearch').spec.memory_limit_raw == "1024M"
    Then the expression should be true> pod.container(name: 'fluentd-elasticsearch').spec.cpu_limit_raw == "200m"
    Given a pod becomes ready with labels:
      | component=kibana |
    Then the expression should be true> pod.container(name: 'kibana').spec.memory_limit_raw == "1024M"
    Then the expression should be true> pod.container(name: 'kibana').spec.cpu_limit_raw == "200m"
    # check /etc/oci-umount.conf on master
    When I select a random node's host
    And I run commands on the host:
      | cat /etc/oci-umount.conf |
    Then the output should contain:
      | /var/lib/docker/containers/* |

  # @author pruan@redhat.com
  # @case_id OCP-17427
  @admin
  @destructive
  Scenario: Uninstall logging and remove pvc via Ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And logging service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17427/inventory |
    Then the expression should be true> pvc('logging-es-0').ready?[:success]
    Then the expression should be true> pvc('logging-es-ops-0').ready?[:success]
    And logging service is uninstalled with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17427/uninstall_inventory |
    And the pvc named "logging-es-0" does not exist in the project
    And the pvc named "logging-es-ops-0" does not exist in the project

  # @author pruan@redhat.com
  # @case_id OCP-15646
  @admin
  @destructive
  Scenario: Add and redeploy eventrouter on logging
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :org_project_name clipboard
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    Then the step should succeed
    Given logging service is installed in the system
    And logging service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15646/inventory |
    And I wait for the ".operations" index to appear in the ES pod with labels "component=es"
    And I wait up to 900 seconds for the steps to pass:
    """
    When I perform the HTTP request on the ES pod:
      | relative_url | _search?pretty&size=5000&q=kubernetes.event.verb:* |
      | op           | GET                                                |
    Then the expression should be true> @result[:parsed]['hits']['total'] > 0
    """

  # @author pruan@redhat.com
  # @case_id OCP-15644
  @admin
  @destructive
  Scenario: uninstall logging and reserve eventrouter
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And logging service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15644/inventory |
    And I wait for the ".operations" index to appear in the ES pod with labels "component=es"
    And I wait up to 900 seconds for the steps to pass:
    """
    When I perform the HTTP request on the ES pod:
      | relative_url | _search?pretty&size=5000&q=kubernetes.event.verb:* |
      | op           | GET                                                |
    Then the expression should be true> @result[:parsed]['hits']['total'] > 0
    """
    And logging service is uninstalled with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15644/uninstall_inventory |
    And I ensure "<%= cb.target_proj %>" project is deleted
    # check eventrouter pod is preserved.
    And I use the "default" project
    And a pod becomes ready with labels:
      | component=eventrouter |
    Then the expression should be true> pod.exists?

  # @author pruan@redhat.com
  # @case_id OCP-17445
  @admin
  @destructive
  Scenario: send Elasticsearch rootLogger to file
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17445/inventory |
    Then the expression should be true> YAML.load(config_map('logging-elasticsearch').data['logging.yml'])['rootLogger'] == "${es.logger.level}, file"

  # @author pruan@redhat.com
  # @case_id OCP-17429
  @admin
  @destructive
  Scenario: The pvc are kept by default when uninstall logging via Ansible
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17429/inventory |
    Then the expression should be true> pvc('logging-es-0').ready?[:success]
    Then the expression should be true> pvc('logging-es-ops-0').ready?[:success]
    And logging service is uninstalled with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/default_uninstall_inventory |
    And I check that there are no dc in the project
    And I check that there are no ds in the project
    # XXX: check check will fail unless https://bugzilla.redhat.com/show_bug.cgi?id=1549220 is fixed
    And I check that there are no configmap in the project
    Then the expression should be true> pvc('logging-es-0').ready?[:success]
    Then the expression should be true> pvc('logging-es-ops-0').ready?[:success]


  # @author pruan@redhat.com
  # @case_id OCP-15988
  @admin
  @destructive
  Scenario: The Openshift Event can be understood by fluentd
    Given I create a project with non-leading digit name
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15988/inventory |
    And I wait until the ES cluster is healthy
    And I use the "default" project
    And a pod becomes ready with labels:
      | component=eventrouter,deploymentconfig=logging-eventrouter,logging-infra=eventrouter,provider=openshift |
    And evaluation of `pod.name` is stored in the :eventrouter_pod_name clipboard
    And I use the "<%= cb.target_proj %>" project
    And I wait up to 900 seconds for the steps to pass:
    """
    When I perform the HTTP request on the ES pod with labels "component=es":
      | relative_url | /_search?pretty&size=50&q=kubernetes.pod_name:"<%= cb.eventrouter_pod_name %>" |
      | op           | GET                                                                            |
    Then the expression should be true> @result[:parsed]['hits']['hits'].count > 0
    """
    # check eventrouter logs include kubelete metadata
    Then the expression should be true> cb.expected_kubelete_metadata = ["container_name", "namespace_name", "pod_name", "pod_id", "labels", "host", "master_url", "namespace_id"]
    And the expression should be true> (cb.expected_kubelete_metadata - @result[:parsed]['hits']['hits'].first['_source']['kubernetes'].keys).empty?

    # check expected kubelete event metata data
    And the expression should be true> cb.expected_keys = ["metadata", "involvedObject", "reason", "source", "firstTimestamp", "lastTimestamp", "count", "type", "verb"]
    And the expression should be true> (cb.expected_keys - @result[:parsed]['hits']['hits'].last["_source"]['kubernetes']['event'].keys).empty?

  # @author pruan@redhat.com
  # @case_id OCP-16299
  @admin
  @destructive
  Scenario: install eventrouter with sink=glog
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-16299/inventory |
    And I register clean-up steps:
      | logging service is uninstalled with ansible using: |
      |   ! inventory ! https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-16299/uninstall_inventory ! |
    And I use the "default" project
    Then the expression should be true> eval(config_map('logging-eventrouter').data['config.json'])[:sink] == "glog"

  # @author pruan@redhat.com
  # @case_id OCP-17430
  @admin
  @destructive
  Scenario: send Elasticsearch rootLogger to file
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And logging service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17430/inventory |
    Then the expression should be true> YAML.load(config_map('logging-elasticsearch').data["logging.yml"])['rootLogger'] == "${es.logger.level}, file"
    And evaluation of `pod.labels['deploymentconfig']` is stored in the :dc_name_es clipboard
    # check the oc logs output
    When I run the :logs client command with:
      | c             | elasticsearch   |
      | resource_name | <%= pod.name %> |
      | tail          | 10              |
    And the output should not contain:
      | <%= cb.dc_name_es %>  |
    # dc name should be in es.log and es_ops.log
    And I execute on the pod:
      | tail | -10 | /elasticsearch/persistent/logging-es/logs/logging-es.log |
    And the expression should be true> @result[:response].include? cb.dc_name_es
    And a pod becomes ready with labels:
      | component=es-ops |
    And evaluation of `pod.labels['deploymentconfig']` is stored in the :dc_name_es_ops clipboard
    And I execute on the pod:
      | tail | -10 | /elasticsearch/persistent/logging-es/logs/logging-es-ops.log |
    And the expression should be true> @result[:response].include? cb.dc_name_es_ops

  # @author pruan@redhat.com
  # @case_id OCP-19463
  @admin
  @destructive
  Scenario: Deploy Logging on non-default namespace
    Given the master version >= "3.7"
    And the master version <= "3.9"
    And I create a project with non-leading digit name
    And logging service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-19463/inventory |
    Then the expression should be true> project.name == "openshift-logging"


  # @author pruan@redhat.com
  # @case_id OCP-17294
  @admin
  @destructive
  Scenario: Add ops-es to logging
    Given the master version >= "3.7"
    And I create a project with non-leading digit name
    And logging service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17294/inventory |
    And a pod becomes ready with labels:
      | component=fluentd |
    And evaluation of `pod` is stored in the :fluentd_pod clipboard
    And the expression should be true> pod.env_var('OPS_HOST') == 'logging-es'
    And the expression should be true> pod.env_var('ES_HOST') == 'logging-es'
    Then I execute on the pod:
      | ls | /etc/fluent/configs.d/openshift/filter-post-z-retag-one.conf |
    Then the step should succeed
    And logging service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17294/inventory_with_ops |
    # check non-ops pod didn't have restart
    Then the expression should be true> pod.container(name: 'elasticsearch').restart_count == 0
    And a pod becomes ready with labels:
      | component=kibana |
    Then the expression should be true> pod.container(name: 'kibana').restart_count == 0
    And a pod becomes ready with labels:
      | component=fluentd |
    And I execute on the pod:
      | ls | /etc/fluent/configs.d/filter-post-z-retag-two.conf |
    Then the step should succeed
    Then the expression should be true> pod.env_var('ES_HOST') == 'logging-es'
    Then the expression should be true> pod.env_var('OPS_HOST') == 'logging-es-ops'

  # @author pruan@redhat.com
  # @case_id OCP-15645
  @admin
  @destructive
  Scenario: install and uninstalled with eventrouter appoint values
    Given the master version >= "3.7"
    And I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :org_project_name clipboard
    And logging service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15645/inventory |
    And a pod becomes ready with labels:
      | component=es |
    And I wait up to 200 seconds for the steps to pass:
    """
    And I perform the HTTP request on the ES pod:
      | relative_url | _search?pretty&size=5000&q=kubernetes.event.verb:* |
      | op           | GET                                                |
    Then the step should succeed
    And the expression should be true> @result[:parsed].dig('hits','total') > 0
    """
    And I use the "<%= cb.org_project_name %>" project
    # verify eventrouter settings match those in the inventory
    And a pod becomes ready with labels:
      |  component=eventrouter |
    And evaluation of `pod.name` is stored in the :eventrouter_pod_name clipboard
    And the expression should be true> pod.container_specs.first.memory_limit_raw == "256Mi"
    And the expression should be true> rc('logging-eventrouter-1').replica_counters[:ready] == 2
    And logging service is installed in the system using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15645/uninstall_inventory |
    And I use the "<%= cb.org_project_name %>" project
    And I wait for the pod named "<%= cb.eventrouter_pod_name %>" to die regardless of current status

  # @author pruan@redhat.com
  # @case_id OCP-20991
  @admin
  @destructive
  Scenario: deploy cluster using NFS storage deploy-cluster.yml
    Given the master version >= "3.10"
    Given I create a project with non-leading digit name
    Given I run oc create as admin with "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-20991/pv.yaml" replacing paths:
      | ["spec"]["nfs"]["server"] | <%= env.master_hosts.first %> |
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-20991/inventory |
    Then the expression should be true> pvc('logging-es-0').capacity == '10Gi'
    Then the expression should be true> pv('logging-volume').capacity_raw == '10Gi'

  # @author pruan@redhat.com
  # @case_id OCP-19509
  @admin
  @destructive
  Scenario: Show warning message when deploy cluster with new NFS Host
    Given the master version >= "3.10"
    Given I create a project with non-leading digit name
    Given I run oc create as admin with "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-19509/pv.yaml" replacing paths:
      | ["spec"]["nfs"]["server"] | <%= env.master_hosts.first %> |
    And logging service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-19509/inventory |
      | negative_test | true                                                                                                   |
    Then the expression should be true> cb.playbook_output.include? 'nfs is an unsupported type for openshift_logging_storage_kind. openshift_enable_unsupported_configurations=True must'
