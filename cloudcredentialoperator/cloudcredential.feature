Feature: cloud credential operator

  # @author lwan@redhat.com
  # @case_id OCP-23357
  @admin
  Scenario: Cloud credential operator health check
    Given the "cloud-credential" operator version matches the current cluster version

    # operator pod image
    And I switch to cluster admin pseudo user
    And I use the "openshift-cloud-credential-operator" project
    And a pod becomes ready with labels:
      | control-plane=controller-manager |
    And evaluation of `pod.container_specs.first.image` is stored in the :cloud_credential_operator_image clipboard

    # Check cluster version
    And evaluation of `cluster_version('version').image` is stored in the :payload_image clipboard

    # Check the payload info
    Given evaluation of `"oc adm release info --registry-config=/var/lib/kubelet/config.json <%= cb.payload_image %>"` is stored in the :oc_adm_release_info clipboard
    When I store the ready and schedulable masters in the clipboard
    And I use the "<%= cb.nodes[0].name %>" node
    # due to sensitive, didn't choose to dump and save the config.json file
    # for using the step `I run the :oadm_release_info admin command ...`
    And I run commands on the host:
      | <%= cb.oc_adm_release_info %> --image-for=cloud-credential-operator |
    Then the step should succeed
    And the output should contain:
      | <%= cb.cloud_credential_operator_image %> |
   
    # Check cluster operators cloud-credential should be in correct status
    Given the expression should be true> cluster_operator('cloud-credential').condition(type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator('cloud-credential').condition(type: 'Available')['status'] == "True"
    And the expression should be true> cluster_operator('cloud-credential').condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator('cloud-credential').condition(type: 'Upgradeable')['status'] == "True"
    
    # Check imagePullPolicy is 'IfNotPresent'
    Given I use the "openshift-cloud-credential-operator" project
    And the expression should be true> pod.container_specs.first.image_pull_policy == "IfNotPresent"

  # @author lwan@redhat.com
  # @case_id OCP-26405
  @admin
  Scenario: Cloud credential operator has a service for the metrics endpoint from OCP4.3
    Given admin checks that the "cco-metrics" service exists in the "openshift-cloud-credential-operator" project

  # @author lwan@redhat.com
  # @case_id OCP-25724
  @admin
  Scenario: Scrape metrics for cloud credential operator in OpenShift 4 prometheus
    Given I switch to cluster admin pseudo user
    #get cluster version
    And evaluation of `cluster_version('version').version` is stored in the :cluster_version clipboard
    #get sa/prometheus-k8s token
    And I use the "openshift-monitoring" project 
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard
    Then I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/label/__name__/values|
    Then the step should succeed
    And the output should contain:
      |cco_controller_reconcile_seconds_bucket|
      |cco_controller_reconcile_seconds_count |
      |cco_controller_reconcile_seconds_sum   |
      |cco_credentials_requests               |
      |cco_credentials_requests_conditions    |
    #add cco_credentials_mode metric to ocp metrics from 4.6
    And the expression should be true> @result[:response].include? ("<%= cb.cluster_version %>" >= "4.6" ? "cco_credentials_mode" : "")

  # @author lwan@redhat.com
  # @case_id OCP-26185
  @admin
  @destructive
  Scenario: Alert should be fired when cloud-credential operator is down
    Given I switch to cluster admin pseudo user
    # scale down cvo and cco operator
    When I run the :scale admin command with:
      | resource | deployment                |
      | name     | cluster-version-operator  |
      | replicas | 0                         |
      | n        | openshift-cluster-version |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :scale admin command with:
      | resource | deployment                |
      | name     | cluster-version-operator  |
      | replicas | 1                         |
      | n        | openshift-cluster-version |
    Then the step should succeed
    """
    When I run the :scale admin command with:
      | resource | deployment                          |
      | name     | cloud-credential-operator           |
      | replicas | 0                                   |
      | n        | openshift-cloud-credential-operator |
    Then the step should succeed
    And I register clean-up steps:
    """
    When I run the :scale admin command with:
      | resource | deployment                          |
      | name     | cloud-credential-operator           |
      | replicas | 1                                   |
      | n        | openshift-cloud-credential-operator |
    Then the step should succeed
    """
    #check alert is firing
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                                  |
      | query | ALERTS{alertname="CloudCredentialOperatorDown"} |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["data"]["result"][0]["metric"]["alertstate"] =~ /pending|firing/
    """

  # @author lwan@redhat.com
  # @case_id OCP-26595
  @admin
  @destructive
  Scenario: Cloud credential Alert must disappear if a cause of this alert is resolved
    Given I switch to cluster admin pseudo user
    #create an worng credentialsreuqest request
    Given I obtain test data file "cloud-credential/cr-namespace-no-exist.yaml"
    When I run the :create client command with:
      | f | cr-namespace-no-exist.yaml |
    Then the step should succeed
    And admin ensures "my-cred-request-err" credentials_request is deleted from the "openshift-cloud-credential-operator" project after scenario
    #check alert is firing
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                                                    |
      | query | ALERTS{alertname="CloudCredentialOperatorTargetNamespaceMissing"} |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["data"]["result"][0]["metric"]["alertstate"] =~ /pending|firing/
    """
    #delete the wrong cr
    And admin ensures "my-cred-request-err" credentials_request is deleted from the "openshift-cloud-credential-operator" project
    #check the alert for CloudCredentialOperatorTargetNamespaceMissing disappear
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                                                                                 |
      | query | ALERTS{alertname="CloudCredentialOperatorTargetNamespaceMissing",alertstate="pending\|firing"} |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["data"]["result"].length == 0
    """

  # @author lwan@redhat.com
  # @case_id OCP-27763
  @admin
  @destructive
  Scenario: CloudCredentialOperatorProvisioningFailed alert doesn't fire When CCO is disable
    Given I switch to cluster admin pseudo user
    #create an worng credentialsreuqest request
    Given I obtain test data file "cloud-credential/cr-namespace-no-exist.yaml"
    When I run the :create client command with:
      | f | cr-namespace-no-exist.yaml |
    Then the step should succeed
    And admin ensures "my-cred-request-err" credentials_request is deleted from the "openshift-cloud-credential-operator" project after scenario
    #check alert is firing
    And I wait up to 180 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                                                    |
      | query | ALERTS{alertname="CloudCredentialOperatorTargetNamespaceMissing"} |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["data"]["result"][0]["metric"]["alertstate"] =~ /pending|firing/
    """
    #disable cco operator
    Given as admin I successfully merge patch resource "cloudcredential/cluster" with:
      | {"spec": {"credentialsMode": "Manual"}} |
    And I register clean-up steps:
    """
    Given as admin I successfully merge patch resource "cloudcredential/cluster" with:
      | {"spec": {"credentialsMode": ""}} |
    """
    #check the alert for CloudCredentialOperatorTargetNamespaceMissing disappear
    Given I wait up to 180 seconds for the steps to pass:
    """
    When I perform the GET prometheus rest client with:
      | path  | /api/v1/query?                                  |
      | query | ALERTS{alertname="CloudCredentialOperatorTargetNamespaceMissing",alertstate="pending\|firing"} |
    Then the step should succeed
    And the expression should be true> @result[:parsed]["data"]["result"].length == 0
    """

  # @author lwan@redhat.com
  # @case_id OCP-28074
  @admin
  @destructive
  Scenario: CCO needs to recreate a new credential automatically 
    Given I switch to cluster admin pseudo user
    And I use the "openshift-cloud-credential-operator" project
    #create a credentialsrequest request
    Given I obtain test data file "cloud-credential/cr.yaml"
    When I run the :create client command with:
      | f | cr.yaml |
    Then the step should succeed
    And admin ensures "my-cred-request" credentials_request is deleted from the "openshift-cloud-credential-operator" project after scenario
    And I wait up to 30 seconds for the steps to pass:
    """
    Given I run the :get client command with:
      | resource     | secret                             |
      | resource_name| my-cred-request-secret             | 
      | o            | jsonpath={.data.aws_access_key_id} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :aws_access_key_id_pre clipboard
    Given I run the :get client command with:
      | resource     | secret                                 |
      | resource_name| my-cred-request-secret                 | 
      | o            | jsonpath={.data.aws_secret_access_key} |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :aws_secret_access_key_pre clipboard
    """
    #delete the related secret
    Given I run the :delete client command with:
      | object_type       | secret                 |
      | object_name_or_id | my-cred-request-secret |
    And the step should succeed
    And I wait up to 30 seconds for the steps to pass:
    """
    Given I run the :get client command with:
      | resource     | secret                             |
      | resource_name| my-cred-request-secret             | 
      | o            | jsonpath={.data.aws_access_key_id} |
    Then the step should succeed
    And the output should not match:
      |<%= cb.aws_access_key_id_pre %>|
    Given I run the :get client command with:
      | resource     | secret                                 |
      | resource_name| my-cred-request-secret                 | 
      | o            | jsonpath={.data.aws_secret_access_key} |
    Then the step should succeed
    And the output should not match:
      |<%= cb.aws_secret_access_key_pre %>|
    """

  # @author lwan@redhat.com
  # @case_id OCP-34465
  @admin
  Scenario: Metrics is exposed on https 
    Given I switch to cluster admin pseudo user
    Then I use the "openshift-cloud-credential-operator" project
    And evaluation of `service('cco-metrics').ip(user: user)` is stored in the :cco_prom_ip clipboard
    And evaluation of `service("cco-metrics").ports(user: user)[0].dig("port")` is stored in the :cco_prom_port clipboard
    #get sa/prometheus-k8s token
    Given I use the "openshift-monitoring" project
    When evaluation of `secret(service_account('prometheus-k8s').get_secret_names.find {|s| s.match('token')}).token` is stored in the :sa_token clipboard
    #cco metrics are exposed on https starting from ocp 4.6
    Then I run the :exec admin command with:
      | n                | openshift-monitoring |
      | pod              | prometheus-k8s-0     |
      | c                | prometheus           |
      | oc_opts_end      |                      |
      | exec_command     | sh                   |
      | exec_command_arg | -c                   |
      | exec_command_arg | curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://<%= cb.cco_prom_ip %>:<%= cb.cco_prom_port %>/metrics|
    Then the step should succeed

  # @author lwan@redhat.com
  # @case_id OCP-34470
  @admin
  Scenario: Cloud credential operator health check for OCP4.6 or greater
    Given the "cloud-credential" operator version matches the current cluster version

    # operator pod image
    And I switch to cluster admin pseudo user
    And I use the "openshift-cloud-credential-operator" project
    And a pod becomes ready with labels:
      | app=cloud-credential-operator |
    And evaluation of `deployment("cloud-credential-operator").container_spec(name: 'cloud-credential-operator').image` is stored in the :cloud_credential_operator_image clipboard

    # Check cluster version
    And evaluation of `cluster_version('version').image` is stored in the :payload_image clipboard

    # Check the payload info
    Given evaluation of `"oc adm release info --registry-config=/var/lib/kubelet/config.json <%= cb.payload_image %>"` is stored in the :oc_adm_release_info clipboard
    When I store the ready and schedulable masters in the clipboard
    And I use the "<%= cb.nodes[0].name %>" node
    # due to sensitive, didn't choose to dump and save the config.json file
    # for using the step `I run the :oadm_release_info admin command ...`
    And I run commands on the host:
      | <%= cb.oc_adm_release_info %> --image-for=cloud-credential-operator |
    Then the step should succeed
    And the output should contain:
      | <%= cb.cloud_credential_operator_image %> |
   
    # Check cluster operators cloud-credential should be in correct status
    Given the expression should be true> cluster_operator('cloud-credential').condition(type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator('cloud-credential').condition(type: 'Available')['status'] == "True"
    And the expression should be true> cluster_operator('cloud-credential').condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator('cloud-credential').condition(type: 'Upgradeable')['status'] == "True"
    
    # Check imagePullPolicy is 'IfNotPresent'
    Given I use the "openshift-cloud-credential-operator" project
    And the expression should be true> deployment("cloud-credential-operator").container_spec(name: 'cloud-credential-operator').image_pull_policy == "IfNotPresent"
 