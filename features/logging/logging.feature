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
