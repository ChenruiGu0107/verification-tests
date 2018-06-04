Feature: logging related scenarios
  # @author pruan@redhat.com
  # @case_id OCP-10823
  @admin
  Scenario: Logging is restricted to current owner of a project
    Given I have a project
    Given evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :new_app client command with:
      | docker_image | docker.io/aosqe/java-mainclass:2.3-SNAPSHOT |
    Then the step should succeed
    Given I wait until the status of deployment "java-mainclass" becomes :complete
    Given I login to kibana logging web console
    When I perform the :kibana_verify_app_text web action with:
      | kibana_url | https://<%= cb.logging_route %> |
      | checktext  | java-mainclass                  |
      | time_out   | 300                             |
    Then the step should succeed
    When I perform the :logout_kibana web action with:
       | kibana_url | https://<%= cb.logging_route %> |
    When I run the :delete client command with:
      | object_type       | project             |
      | object_name_or_id | <%= cb.proj_name %> |
    Then the step should succeed
    Given I switch to the second user
    # there seems to be a lag in project deletion
    And I wait for the steps to pass:
    """
    And I run the :new_project client command with:
      | project_name | <%= cb.proj_name %> |
    Then the step should succeed
    """
    And I use the "<%= cb.proj_name %>" project
    When I run the :new_app client command with:
      | app_repo |  https://github.com/openshift/cakephp-ex.git |
    Then the step should succeed
    And I wait until the status of deployment "cakephp-ex" becomes :complete
    When I perform the :kibana_login web action with:
      | username   | <%= user.name %>                |
      | password   | <%= user.password %>            |
      | kibana_url | https://<%= cb.logging_route %> |
    When I perform the :kibana_verify_app_text web action with:
       | kibana_url | https://<%= cb.logging_route %> |
       | checktext  | cakephp                         |
       | time_out   | 300                             |
    Then the step should succeed
    When I get the visible text on web html page
    Then the expression should be true> !@result[:response].include? 'java-mainclass'

  # @author chunchen@redhat.com
  # @case_id OCP-11186,OCP-11266
  @admin
  @smoke
  @destructive
  Scenario: Scale up kibana and elasticsearch pods
    Given I have a project
    Given the master version < "3.5"
    And I store default router subdomain in the :subdomain clipboard
    And I store master major version in the :master_version clipboard
    When I run the :new_secret client command with:
      | secret_name     | logging-deployer  |
      | credential_file | nothing=/dev/null |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/templates/tc509059/sa.yaml |
    Then the step should succeed
    When I run the :policy_add_role_to_user client command with:
      | role      | edit                                                       |
      | user_name | system:serviceaccount:<%= project.name %>:logging-deployer |
    Then the step should succeed
    Given cluster role "cluster-reader" is added to the "aggregated-logging-fluentd" service account
    When I run the :oadm_policy_add_scc_to_user admin command with:
      | scc       | privileged                                                           |
      | user_name | system:serviceaccount:<%= project.name %>:aggregated-logging-fluentd |
    Then the step should succeed
    Given I register clean-up steps:
    """
    I run the :oadm_policy_remove_scc_from_user admin command with:
      | scc       | privileged                                                           |
      | user_name | system:serviceaccount:<%= project.name %>:aggregated-logging-fluentd |
    the step should succeed
    """
    When I create a new application with:
      | template | logging-deployer-template                                                                                                                                                                                                                                       |
      | param    | IMAGE_PREFIX=<%= product_docker_repo %>openshift3/,KIBANA_HOSTNAME=kibana.<%= cb.subdomain%>,PUBLIC_MASTER_URL=<%= env.api_endpoint_url %>,ES_INSTANCE_RAM=1024M,ES_CLUSTER_SIZE=1,IMAGE_VERSION=<%= cb.master_version%>,MASTER_URL=<%= env.api_endpoint_url %> |
    Then the step should succeed
    Given I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource  | templates |
    Then the output should contain "logging-support-template"
    """
    And the first user is cluster-admin
    Given I register clean-up steps:
    """
    I switch to cluster admin pseudo user
    I use the "<%=project.name%>" project
    I run the :delete admin command with:
      | object_type       | oauthclients      |
      | object_name_or_id | kibana-proxy      |
      | n                 | <%=project.name%> |
    I wait for the resource "oauthclient" named "kibana-proxy" to disappear
    """
    When I create a new application with:
      | template | logging-support-template |
      | n        | <%= project.name %>      |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | imagestreams                                                                     |
      | resource_name | logging-fluentd                                                                  |
      | p             | {"metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"}}} |
    Then the step should succeed
    When I run the :import_image client command with:
      | image_name | logging-fluentd:<%= cb.master_version%>                                      |
      | from       | <%= product_docker_repo %>openshift3/logging-fluentd:<%= cb.master_version%> |
      | insecure   | true                                                                         |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | imagestreams                                                                     |
      | resource_name | logging-elasticsearch                                                            |
      | p             | {"metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"}}} |
    Then the step should succeed
    When I run the :import_image client command with:
      | image_name | logging-elasticsearch:<%= cb.master_version%>                                      |
      | from       | <%= product_docker_repo %>openshift3/logging-elasticsearch:<%= cb.master_version%> |
      | insecure   | true                                                                               |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | imagestreams                                                                     |
      | resource_name | logging-auth-proxy                                                               |
      | p             | {"metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"}}} |
    Then the step should succeed
    When I run the :import_image client command with:
      | image_name | logging-auth-proxy:<%= cb.master_version%>                                      |
      | from       | <%= product_docker_repo %>openshift3/logging-auth-proxy:<%= cb.master_version%> |
      | insecure   | true                                                                            |
    Then the step should succeed
    When I run the :patch client command with:
      | resource      | imagestreams                                                                     |
      | resource_name | logging-kibana                                                                   |
      | p             | {"metadata": {"annotations": {"openshift.io/image.insecureRepository": "true"}}} |
    Then the step should succeed
    When I run the :import_image client command with:
      | image_name | logging-kibana:<%= cb.master_version%>                                      |
      | from       | <%= product_docker_repo %>openshift3/logging-kibana:<%= cb.master_version%> |
      | insecure   | true                                                                        |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I get project replicationcontrollers
    Then the output should contain:
      | logging-fluentd-1 |
      | logging-kibana-1  |
    """
    And I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | logging-kibana-1       |
      | replicas | 2                      |
    And I run the :scale client command with:
      | resource | replicationcontrollers |
      | name     | logging-fluentd-1      |
      | replicas | 1                      |
    And I wait until number of replicas match "1" for replicationController "logging-fluentd-1"
    And I wait until number of replicas match "2" for replicationController "logging-kibana-1"
    Given a pod becomes ready with labels:
      | component=es |
    And I wait for the steps to pass:
    """
    When I run the :logs client command with:
      | resource_name    | pods/<%= pod.name %>|
    Then the output should match:
      | \[<%= project.name %>\.\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\.\d{4}\.\d{2}\.\d{2}\] |
    """

  # @author pruan@redhat.com
  # @case_id OCP-14119
  @admin
  @destructive
  Scenario: Heap size limit should be set for Kibana pods
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    Given a pod becomes ready with labels:
      |  component=kibana,deployment=logging-kibana-1,deploymentconfig=logging-kibana,logging-infra=kibana,provider=openshift |
    # check kibana pods settings
    And evaluation of `pod.container(user: user, name: 'kibana').spec.memory_limit` is stored in the :kibana_container_res_limit clipboard
    And evaluation of `pod.container(user: user, name: 'kibana-proxy').spec.memory_limit` is stored in the :kibana_proxy_container_res_limit clipboard
    Then the expression should be true> cb.kibana_container_res_limit > 700
    Then the expression should be true> cb.kibana_proxy_container_res_limit > 100
    # check kibana dc settings
    And evaluation of `dc('logging-kibana').container_spec(user: user, name: 'kibana').memory_limit` is stored in the :kibana_dc_res_limit clipboard
    And evaluation of `dc('logging-kibana').container_spec(user: user, name: 'kibana-proxy').memory_limit` is stored in the :kibana_proxy_dc_res_limit clipboard
    Then the expression should be true> cb.kibana_container_res_limit == cb.kibana_dc_res_limit
    Then the expression should be true> cb.kibana_proxy_container_res_limit == cb.kibana_proxy_dc_res_limit

  # @author pruan@redhat.com
  # @case_id OCP-10523
  @admin
  @destructive
  Scenario: Logging fluentD daemon set should set quota for the pods
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    Given a pod becomes ready with labels:
      | component=fluentd,logging-infra=fluentd |
    And evaluation of `pod.container(user: user, name: 'fluentd-elasticsearch').spec.memory_limit` is stored in the :fluentd_pod_mem_limit clipboard
    And evaluation of `daemon_set('logging-fluentd').container_spec(user: user, name: 'fluentd-elasticsearch').memory_limit` is stored in the :fluentd_container_mem_limit clipboard
    Then the expression should be true> cb.fluentd_container_mem_limit[1] == cb.fluentd_pod_mem_limit[1]

  # @author pruan@redhat.com
  # @case_id OCP-16414
  @admin
  @destructive
  Scenario: Logout kibana web console with installation step included
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And I switch to the first user
    Given I login to kibana logging web console
    When I perform the :logout_kibana web action with:
      | kibana_url | <%= cb.logging_console_url %> |
    Then the step should succeed
    And I access the "<%= cb.logging_console_url %>" url in the web browser
    Given I wait for the title of the web browser to match "(Login|Sign\s+in|SSO|Log In)"

  # @author pruan@redhat.com
  # @case_id OCP-11405
  @admin
  @destructive
  Scenario: Use index names of project.project_name.project_uuid.xxx in Elasticsearch
    Given I create a project with non-leading digit name
    Given the master version >= "3.4"
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And a pod becomes ready with labels:
      | component=es |
    # index takes over 10 minutes to come up initially
    And I wait up to 900 seconds for the steps to pass:
    """
    And I execute on the pod:
      | bash                                                                    |
      | -c                                                                      |
      | ls /elasticsearch/persistent/logging-es/data/logging-es/nodes/0/indices |
    And the output should contain:
      | project.<%= project.name %>.<%= project.uid %> |
    """

  # @author pruan@redhat.com
  # @case_id OCP-11266
  @admin
  @destructive
  Scenario: Use index names of project_name.project_uuid.xxx in Elasticsearch
    Given the master version < "3.4"
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And a pod becomes ready with labels:
      | component=es |
    # index takes over 10 minutes to come up initially
    And I wait up to 900 seconds for the steps to pass:
    """
    And I execute on the pod:
      | bash                                                                    |
      | -c                                                                      |
      | ls /elasticsearch/persistent/logging-es/data/logging-es/nodes/0/indices |
    And the output should contain:
      | <%= project.name %>.<%= project.uid %> |
    """

  # @author pruan@redhat.com
  # @case_id OCP-11847
  @admin
  @destructive
  Scenario: Check for packages inside fluentd pod to support journald log driver
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And a pod becomes ready with labels:
      |  component=fluentd |
    And I execute on the pod:
      | bash                                 |
      | -c                                   |
      | rpm -qa \| grep -e journal -e fluent |
    And the output should contain:
      | rubygem-systemd-journal                  |
      | rubygem-fluent-plugin-systemd            |
      | rubygem-fluent-plugin-rewrite-tag-filter |

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
  # @case_id OCP-10995
  @admin
  @destructive
  Scenario: Check fluentd changes for common data model and index naming
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :org_project_name clipboard
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    And logging service is installed in the system
    When I wait 900 seconds for the "project.<%= cb.org_project.name %>" index to appear in the ES pod with labels "component=es"
    And the expression should be true> cb.index_data['index'] == "project.#{cb.org_project.name}.#{project.uid}.#{Time.new.strftime('%Y.%m.%d')}"
    And I wait for the ".operations" index to appear in the ES pod
    And the expression should be true> cb.index_data['index'] == ".operations.#{Time.new.strftime('%Y.%m.%d')}"

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
  # @case_id OCP-17307
  @admin
  @destructive
  Scenario: DC rollback behaviors are disabled for logging project DCs
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17307/inventory |
    And a deploymentConfig becomes ready with labels:
      | component=es |
    And the expression should be true> dc.revision_history_limit == 0

  # @author pruan@redhat.com
  # @case_id OCP-15281
  @admin
  @destructive
  Scenario: max_local_storage_nodes default value should be 1 to prevent permitting multiple nodes to share the same data directory
    Given the master version >= "3.6"
    Given I create a project with non-leading digit name
    And logging service is installed in the system
    And evaluation of `YAML.load(config_map('logging-elasticsearch').value_of('elasticsearch.yml'))` is stored in the :data clipboard
    And the expression should be true> cb.data.dig('node', 'max_local_storage_nodes') == 1
    And the expression should be true> cb.data.dig('gateway','recover_after_nodes') == '${NODE_QUORUM}'

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
  # @case_id OCP-17248
  @admin
  @destructive
  Scenario: Invalid value for FILE_BUFFER_LIMIT
    Given the master version >= "3.4"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17431/inventory |
      | negative_test | true                                                                                                   |
    Given a pod is present with labels:
      | component=fluentd,logging-infra=fluentd |
    When I run the :logs client command with:
      | resource_name    | pods/<%= pod.name %>|
    Then the output should contain:
      | Invalid file buffer limit  |
      | Failed to convert to bytes |

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

  # @author pruan@redhat.com
  # @case_id OCP-17243
  @admin
  @destructive
  Scenario: FILE_BUFFER_LIMIT is less than BUFFER_SIZE_LIMIT
    Given the master version >= "3.8"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17243/inventory |
      | negative_test | true                                                                                                   |
    And I use the "<%= cb.target_proj %>" project
    Given a pod is present with labels:
      | component=fluentd,logging-infra=fluentd |
    When I run the :logs client command with:
      | resource_name    | <%= pod.name %> |
    Then the output should contain:
      | ERROR:                                     |
      | TOTAL_BUFFER_SIZE_LIMIT                    |
      | is too small compared to BUFFER_SIZE_LIMIT |
    Given a pod is present with labels:
      | component=mux,deploymentconfig=logging-mux,logging-infra=mux,provider=openshift |
    When I run the :logs client command with:
      | resource_name    | <%= pod.name %> |
    Then the output should contain:
      | ERROR:                                     |
      | TOTAL_BUFFER_SIZE_LIMIT                    |
      | is too small compared to BUFFER_SIZE_LIMIT |

  # @author pruan@redhat.com
  # @case_id OCP-17235
  @admin
  @destructive
  Scenario: FILE_BUFFER_LIMIT, BUFFER_SIZE_LIMIT and BUFFER_QUEUE_LIMIT use the default value
    Given the master version >= "3.8"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17235/inventory |
    Given a pod becomes ready with labels:
      | component=fluentd,logging-infra=fluentd |
    Then the expression should be true> pod.env_var('BUFFER_QUEUE_LIMIT') == "32"
    Then the expression should be true> pod.env_var('BUFFER_SIZE_LIMIT') == "8m"
    Then the expression should be true> pod.env_var('FILE_BUFFER_LIMIT') == "256Mi"
    Given a pod becomes ready with labels:
      | component=mux,deploymentconfig=logging-mux,logging-infra=mux,provider=openshift |
    Then the expression should be true> pod.env_var('BUFFER_QUEUE_LIMIT') == "32"
    Then the expression should be true> pod.env_var('BUFFER_SIZE_LIMIT') == "8m"
    Then the expression should be true> pod.env_var('FILE_BUFFER_LIMIT') == "2Gi"

  # @author pruan@redhat.com
  # @case_id OCP-17238
  @admin
  @destructive
  Scenario: FILE_BUFFER_LIMIT, BUFFER_QUEUE_LIMIT and  BUFFER_SIZE_LIMIT use customed value
    Given the master version >= "3.8"
    Given I create a project with non-leading digit name
    And logging service is installed with ansible using:
      | inventory     | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17238/inventory |
    Given a pod becomes ready with labels:
      | component=fluentd,logging-infra=fluentd |
    Then the expression should be true> pod.env_var('BUFFER_QUEUE_LIMIT') == "64"
    Then the expression should be true> pod.env_var('BUFFER_SIZE_LIMIT') == "4m"
    Then the expression should be true> pod.env_var('FILE_BUFFER_LIMIT') == "1Gi"
    Given a pod becomes ready with labels:
      | component=mux,deploymentconfig=logging-mux,logging-infra=mux,provider=openshift |
    Then the expression should be true> pod.env_var('BUFFER_QUEUE_LIMIT') == "32"
    Then the expression should be true> pod.env_var('BUFFER_SIZE_LIMIT') == "8m"
    Then the expression should be true> pod.env_var('FILE_BUFFER_LIMIT') == "512Mi"

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


  # @author pruan@redhat.com
  # @case_id OCP-17449
  @admin
  @destructive
  Scenario: View the project mapping index as different roles
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And I switch to the first user
    Given I create a project with non-leading digit name
    # need to add app so it will generate some data which will trigger the project index be pushed up to the es pod
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I use the "<%= cb.target_proj %>" project
    Given a pod becomes ready with labels:
      | component=es |

    # index takes over 10 minutes to come up initially
    And I wait up to 900 seconds for the steps to pass:
    """
    And I execute on the pod:
      | ls                                                                   |
      | /elasticsearch/persistent/logging-es/data/logging-es/nodes/0/indices |
    And the output should contain:
      | project.<%= project.name %>.<%= project.uid %> |
    """
    # Give user1 admin role
    When I run the :policy_add_role_to_user client command with:
      | role             | admin                              |
      | user_name        | <%= user(1, switch: false).name %> |
      | rolebinding_name | admin                              |
    Then the step should succeed
    # Give user2 edit role
    When I run the :policy_add_role_to_user client command with:
      | role             | edit                               |
      | user_name        | <%= user(2, switch: false).name %> |
      | rolebinding_name | edit                               |
    Then the step should succeed
    # Give user3 view role
    When I run the :policy_add_role_to_user client command with:
      | role             | view                               |
      | user_name        | <%= user(3, switch: false).name %> |
      | rolebinding_name | view                               |
    Then the step should succeed
    Given evaluation of `%w[first second third]` is stored in the :users clipboard
    Given I repeat the following steps for each :user in cb.users:
    """
    And I switch to the #{cb.user} user
    And I perform the HTTP request on the ES pod:
      | relative_url | project.<%= cb.org_project %>.*/_count?format=JSON |
      | op           | GET                                                |
      | token        | <%= user.cached_tokens.first %>                    |
    Then the step should succeed
    Then the expression should be true> @result[:parsed]['count'] > 0
    """

  # @author pruan@redhat.com
  # @case_id OCP-17447
  @smoke
  @admin
  @destructive
  Scenario: access operations index with different roles
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    ## wait until the es pod index to show up
    Then I wait for the ".operations" index to appear in the ES pod with labels "component=es"
    And cluster role "cluster-admin" is added to the "first" user
    And cluster role "cluster-reader" is added to the "second" user
    Given evaluation of `%w[first second]` is stored in the :users clipboard
    Given I repeat the following steps for each :user in cb.users:
    """
    And I switch to the #{cb.user} user
    And I perform the HTTP request on the ES pod:
      | relative_url | .operations.*/_count?format=JSON |
      | op           | GET                              |
      | token        | <%= user.cached_tokens.first %>  |
    Then the step should succeed
    Then the expression should be true> @result[:parsed]['count'] > 0
    """

  # @author pruan@redhat.com
  # @case_id OCP-18199
  @admin
  @destructive
  Scenario: Couldn't access .operations index without permit
    Given the master version >= "3.5"
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    Given I switch to the first user
    And I perform the HTTP request on the ES pod:
      | relative_url | .operations.*/_count?format=JSON |
      | op           | GET                              |
      | token        | <%= user.cached_tokens.first %>  |
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-18201
  @admin
  @destructive
  Scenario: Couldn't View the project mapping index without permit
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And I switch to the first user
    Given I create a project with non-leading digit name
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    And I perform the HTTP request on the ES pod:
      | relative_url | project.<%= project.name %>/_count?format=JSON |
      | op           | GET                              |
      | token        | <%= user.cached_tokens.first %>  |
    Then the expression should be true> [401, 403].include? @result[:exitstatus]

  # @author pruan@redhat.com
  # @case_id OCP-17529
  @admin
  @destructive
  Scenario: Expose Elasticsearch service
    Given I create a project with non-leading digit name
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-17529/inventory |
    And I wait until the ES cluster is healthy
    Given I switch to the first user
    And the first user is cluster-admin
    And evaluation of `%w(es es-ops)` is stored in the :prefixes clipboard
    Given I repeat the following steps for each :prefix in cb.prefixes:
    """
    And I perform the HTTP request:
    <%= '"""' %>
      :url: https://#{cb.prefix}.<%= cb.subdomain %>/_count?output=JSON
      :method: get
      :headers:
        :Authorization: Bearer <%= user.cached_tokens.first %>
    <%= '"""' %>
    Then the step should succeed
    And the expression should be true> YAML.load(@result[:response])['count'] > 0
    """

  # @author pruan@redhat.com
  # @case_id OCP-16850
  @admin
  @destructive
  Scenario: Check the existence of index template named "viaq"
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And I wait until the ES cluster is healthy
    And evaluation of `%w(project operations)` is stored in the :urls clipboard
    Given I repeat the following steps for each :url in cb.urls:
    """
    And I perform the HTTP request on the ES pod:
      | relative_url | _template/com.redhat.viaq-openshift-#{cb.url}.template.json |
      | op           | GET                                                         |
    Then the step should succeed
    """

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
  # @case_id OCP-18806
  @admin
  @destructive
  Scenario: Deploy logging with replicas Elasticsearch
    Given the master version >= "3.7"
    Given environment has at least 3 nodes
    Given I create a project with non-leading digit name
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-18806/inventory |
    And a pod becomes ready with labels:
      | component=es |
    And I wait up to 120 seconds for the steps to pass:
    """
    Then I perform the HTTP request on the ES pod:
      | relative_url | /project.install_test.*/_settings?output=JSON |
      | op           | GET                                           |
    Then the expression should be true> @result[:parsed].first[1].dig('settings', 'index', 'number_of_replicas') == "1"
    Then the expression should be true> @result[:parsed].first[1].dig('settings', 'index', 'number_of_shards') == "1"
    """

  # @author pruan@redhat.com
  # @case_id OCP-16898
  @admin
  @destructive
  Scenario: Use index names of project.project_name.project_uuid.xxx in Elasticsearch
    Given the master version >= "3.7"
    Given I create a project with non-leading digit name
    And evaluation of `project.name` is stored in the :org_project_name clipboard
    When I run the :new_app client command with:
      | app_repo | httpd-example |
    Then the step should succeed
    And logging service is installed in the system
    And a pod becomes ready with labels:
      | component=es |
    # index takes over 10 minutes to come up initially
    And I use the "<%= cb.org_project_name %>" project

    And I wait up to 900 seconds for the steps to pass:
    """
    And I execute on the pod:
      | bash                                                                    |
      | -c                                                                      |
      | ls /elasticsearch/persistent/logging-es/data/logging-es/nodes/0/indices |
    And the output should contain:
      | project.<%= project.name %>.<%= project.uid %>.<%= Time.now.strftime('%Y')%>.<%= Time.now.strftime('%m')%>.<%= Time.now.strftime('%d')%> |
    """


  # @author pruan@redhat.com
  # @case_id OCP-18090
  @admin
  @destructive
  Scenario: Cluster-admin view Elasticsearch cluster/monitor endpoints
    Given I create a project with non-leading digit name
    Given logging service is installed with ansible using:
      | inventory | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/logging_metrics/OCP-18090/inventory |
    And I wait until the ES cluster is healthy
    Given I switch to the first user
    And the first user is cluster-admin
    And evaluation of `%w(_cat/indices _cat/aliases _cat/nodes _cluster/health)` is stored in the :urls clipboard
    Given I repeat the following steps for each :url in cb.urls:
    """
    And I perform the HTTP request:
    <%= '"""' %>
      :url: https://<%= route('logging-es').dns %>/#{cb.url}?output=JSON
      :method: get
      :headers:
        :Authorization: Bearer <%= user.cached_tokens.first %>
    <%= '"""' %>
    Then the expression should be true> @result[:exitstatus] == 200
    """

  # @author pruan@redhat.com
  # @case_id OCP-19205
  @admin
  @destructive
  Scenario: Add .all alias when index is created
    Given I create a project with non-leading digit name
    Given logging service is installed in the system
    And I wait for the "project.install-test" index to appear in the ES pod with labels "component=es"
    And I wait for the ".operations" index to appear in the ES pod
    And a pod becomes ready with labels:
      | component=es |
    Then I perform the HTTP request on the ES pod:
      | relative_url | /*/_alias?output=JSON |
      | op           | GET                   |
    And evaluation of ` @result[:parsed].select { |k, v| v.dig('aliases', '.all').is_a? Hash and k.start_with? 'project' }` is stored in the :res_proj clipboard
    And evaluation of ` @result[:parsed].select { |k, v| v.dig('aliases', '.all').is_a? Hash and k.start_with? '.operation' }` is stored in the :res_op clipboard
    Then the expression should be true> cb.res_proj.count > 0
    Then the expression should be true> cb.res_op.count > 0
