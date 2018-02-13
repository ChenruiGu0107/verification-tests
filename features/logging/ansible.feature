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
    And a deploymentConfig becomes ready with labels:
      | component=es |
    # disable es pod by scaling it to 0
    Then I run the :scale client command with:
      | resource | deploymentConfig |
      | name     | <%= dc.name %>   |
      | replicas | 0                |
    And I wait until number of replicas match "0" for replicationController "<%= rc.name %>"
    And I login to kibana logging web console
    And I get the visible text on web html page
    And the output should contain:
      | Status: Red                                                   |
      | Unable to connect to Elasticsearch at https://logging-es:9200 |

  # @author pruan@redhat.com
  # @case_id OCP-11687
  @admin
  @destructive
  Scenario: Deploy logging via Ansible: clean install with custom cert
    Given the master version >= "3.5"
    Given I have a project
    And logging service is installed in the project with ansible using:
      | inventory        | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11687/inventory |
      | copy_custom_cert | true                                                                                                   |
    And I login to kibana logging web console
    # execute the curl command in a pod to avoid possiblity that the client
    # platform does not have 'curl'
    And a pod becomes ready with labels:
      | component=kibana, logging-infra=kibana |
    And I execute on the pod:
      | curl | -k | <%= env.logging_console_url %> | -vv |
    Then the expression should be true> @result[:response].include? "Server certificate"
    Then the expression should be true> @result[:response].include? "subject: CN=#{cb.logging_route_prefix}.#{cb.subdomain}"

  # @author pruan@redhat.com
  # @case_id OCP-15988
  @admin
  @destructive
  Scenario: install and uninstalled eventrouter with default values
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :org_project clipboard
    And logging service is installed in the project with ansible using:
      | inventory        | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-15988/inventory |
    Given event logs can be found in the ES pod
    # cb.master_version is set in the installed step.
    And I switch to cluster admin pseudo user
    And I use the "default" project
    And a pod becomes ready with labels:
      | component=eventrouter,deploymentconfig=logging-eventrouter,logging-infra=eventrouter,provider=openshift |
    And evaluation of `pod.name` is stored in the :eventrouter_pod_name clipboard
    And the expression should be true> dc('logging-eventrouter').containers_spec[0].image == product_docker_repo + "openshift3/logging-eventrouter:v" + cb.master_version
    # now delete the service and check that pod is removed from the 'default' project
    And I switch to the first user
    And I use the "<%= cb.org_project %>" project
    And I remove logging service installed in the project using ansible
    And I switch to cluster admin pseudo user
    And I use the "default" project
    And I wait for the pod named "<%= cb.eventrouter_pod_name %>" to die regardless of current status

  # @author pruan@redhat.com
  # @case_id OCP-10104
  @admin
  @destructive
  Scenario: deploy logging with dynamic volume
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    Given logging service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-10104/inventory |
    And I run the :volume client command with:
      | resource | dc           |
      | selector | component=es |
    Then the output should contain:
      | pvc/logging-es-0         |
      | as elasticsearch-storage |

  # @author pruan@redhat.com
  # @case_id OCP-11385
  @admin
  @destructive
  Scenario: Scale up curator, kibana and elasticsearch pods
    Given the master version <= "3.4"
    Given I create a project with non-leading digit name
    Given logging service is installed in the project using deployer:
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
  # @case_id OCP-16688
  @admin
  @destructive
  Scenario: The journald log can be retrived from elasticsearch
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And I run commands on the host:
      | logger --tag deadbeef[123] deadbeef-message-OCP16688 |
    Then the step should succeed
    ### hack alert with 3.9, I get inconsistent behavior such that the data is
    # not pushed w/o removing the  es-containers.log.pos journal.pos files
    And I run commands on the host:
      | rm -f /var/log/journal.pos         |
      | rm -f /var/log/es-containers-*.pos |
    Then the step should succeed
    And I wait up to 600 seconds for the steps to pass:
    """
    And I perform the HTTP request on the ES pod:
      | relative_url | _search?pretty&size=5&q=message:deadbeef-message-OCP16688 |
      | op           | GET                                                       |

    And the expression should be true> @result[:parsed]['hits']['hits'][0]['_source']['message'] == 'deadbeef-message-OCP16688'
    """
    And evaluation of `@result[:parsed]['hits']['hits'][0]['_source']` is stored in the :query_res clipboard
    Then the expression should be true> (["hostname", "@timestamp"] - cb.query_res.keys).empty?
    # check for SYSLOG, SYSLOG_IDENTIFIER
    Then the expression should be true> (["SYSLOG_FACILITY", "SYSLOG_IDENTIFIER", "SYSLOG_PID"] - cb.query_res['systemd']['u'].keys).empty?
    And the expression should be true> cb.query_res['systemd']['u']['SYSLOG_IDENTIFIER'] == 'deadbeef'
    And the expression should be true> cb.query_res['systemd']['u']['SYSLOG_PID'] == '123'

  # @author pruan@redhat.com
  # @case_id OCP-13700
  @admin
  @destructive
  Scenario: Make sure the searchguard index that is created upon pod start worked fine
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And a deploymentConfig becomes ready with labels:
      | component=es |
    And I wait up to 240 seconds for the steps to pass:
    """"
    When I get the ".searchguard.<%= dc.name %>" logging index information from a pod with labels "component=es"
    Then the expression should be true> cb.index_data['docs.count'] == "5"
    """
    And the expression should be true> convert_to_bytes(cb.index_data['store.size']) > 159
    # check operation and project.install-test.xxx index
    When I wait for the ".operations." index to appear in the ES pod
    Then the expression should be true> convert_to_bytes(cb.index_data['store.size']) > 10
    When I wait for the "project.install-test." index to appear in the ES pod
    Then the expression should be true> convert_to_bytes(cb.index_data['store.size']) > 10

  # @author pruan@redhat.com
  # @case_id OCP-12868
  @admin
  @destructive
  Scenario: Check Fluentd should write times/timestamps in UTC when logdriver=journald
    Given the master version >= "3.5"
    Given I have a project
    Given logging service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12868/inventory |
    # need to add app so it will generate some data which will trigger the project index be pushed up to the es pod
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    Then the step should succeed
    When I wait for the ".operation" index to appear in the ES pod with labels "component=es"
    Then I perform the HTTP request on the ES pod:
      | relative_url | <%= cb.index_data['index'] %>/_search?pretty&size=5 |
      | op           | GET                                                 |
    And evaluation of `Time.parse(@result.dig(:parsed, 'hits', 'hits')[0].dig('_source','@timestamp'))` is stored in the :query_result clipboard
    Then the expression should be true> cb.query_result.inspect.end_with? "0000" or cb.query_result.inspect.end_with? "UTC"
    # query the user project
    When I wait for the "project.<%= project.name %>" index to appear in the ES pod
    Then I perform the HTTP request on the ES pod:
      | relative_url | <%= cb.index_data['index'] %>/_search?pretty&size=5 |
      | op           | GET                                                 |
    And evaluation of `Time.parse(@result.dig(:parsed, 'hits', 'hits')[0].dig('_source','@timestamp'))` is stored in the :query_result clipboard
    Then the expression should be true> cb.query_result.inspect.end_with? "0000" or cb.query_result.inspect.end_with? "UTC"

  # @author pruan@redhat.com
  # @case_id OCP-11869
  @admin
  @destructive
  Scenario: Deploy logging via Ansible - clean install with jounal log driver, not read logs from head
    Given the master version >= "3.5"
    Given a 7 character random string is stored into the :rand_msg clipboard
    Given I have a project
    And I select a random node's host
    And I run commands on the host:
      | logger -i message-before-<%= cb.rand_msg %> |
    Given I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/pods/hello-pod.json |
    Then the step should succeed
    Given logging service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-11869/inventory |
    When I wait for the ".operations" index to appear in the ES pod with labels "component=es"
    And I run commands on the host:
      | logger -i message-after-<%= cb.rand_msg %> |
    Then I perform the HTTP request on the ES pod:
      | relative_url | <%= cb.index_data['index'] %>/_search?pretty&size=50&q=message-before-<%= cb.rand_msg %> |
      | op           | GET                                                                                      |
    And the expression should be true> @result.dig(:parsed, 'hits', 'total') == 0
    # check message is logged after installation of kibana is registered with they system
    And I wait up to 600 seconds for the steps to pass:
    """
    Then I perform the HTTP request on the ES pod:
      | relative_url | <%= cb.index_data['index'] %>/_search?pretty&size=50&q=message-after-<%= cb.rand_msg %> |
      | op           | GET                                                                                     |
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
    Given logging service is installed in the project with ansible using:
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
    And logging service is installed in the project with ansible using:
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
    And logging service is installed in the project with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-12113/inventory |
    And a pod becomes ready with labels:
      | component=es |
    # make sure containers are there regardless of ordering
    Then the expression should be true> ["proxy", "elasticsearch"] - pod.containers.keys == []
    And the expression should be true> pod.containers['elasticsearch'].spec.memory_limit_raw == "1024M"
    And the expression should be true> pod.containers['elasticsearch'].spec.cpu_limit_raw == "200m"
    # check fluentd limits
    Given a pod becomes ready with labels:
      | component=fluentd |
    Then the expression should be true> pod.container(name: 'fluentd-elasticsearch').spec.memory_limit_raw == "1024M"
    Then the expression should be true> pod.container(name: 'fluentd-elasticsearch').spec.cpu_limit_raw == "200m"
    Given a pod becomes ready with labels:
      | component=curator |
    Then the expression should be true> pod.container(name: 'curator').spec.memory_limit_raw == "1024M"
    Then the expression should be true> pod.container(name: 'curator').spec.cpu_limit_raw == "200m"
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

