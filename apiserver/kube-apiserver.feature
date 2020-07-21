Feature: KUBE API server related features
  # @author kewang@redhat.com
  # @case_id OCP-24698
  @admin
  Scenario: Check the http accessible /readyz for kube-apiserver	
    Given I store the schedulable masters in the :nodes clipboard
    When I run the :project admin command with:
      | project_name | openshift-kube-apiserver |
    Then the output should contain:
      | project "openshift-kube-apiserver" on server |
    And I run the :port_forward background admin command with:
      | pod       | kube-apiserver-<%= cb.nodes[1].name %> |
      | port_spec | 6080                                   |
      | _timeout  | 60                                     |
    Then the step should succeed
    Given I wait up to 30 seconds for the steps to pass:
    """
    Given the expression should be true> @host = localhost
    And I run commands on the host:
      | curl http://127.0.0.1:6080/readyz --noproxy "127.0.0.1" |
    Then the step should succeed
    And the output should contain "ok"
    """

  # @author kewang@redhat.com
  # @case_id OCP-27665
  @admin
  Scenario: Check if the kube-storage-version-migrator operator related manifests has been loaded
    Given the master version >= "4.4"
    When I run the :get admin command with:
      | resource       | customresourcedefinition                          |
      | resource_name  | storagestates.migration.k8s.io                    |
      | resource_name  | storageversionmigrations.migration.k8s.io         |
      | resource_name  | kubestorageversionmigrators.operator.openshift.io |
    Then the step should succeed
    Given admin checks that the "kube-storage-version-migrator" clusteroperator exists
    When I run the :get admin command with:
      | resource      | configmap                                             |
      | resource_name | config                                                |
      | resource_name | openshift-kube-storage-version-migrator-operator-lock |
      | n             | openshift-kube-storage-version-migrator-operator      |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | service                                          |
      | resource_name | metrics                                          |
      | n             | openshift-kube-storage-version-migrator-operator |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | serviceaccount                                   |
      | resource_name | kube-storage-version-migrator-operator           |
      | n             | openshift-kube-storage-version-migrator-operator |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | deployment                                       |
      | resource_name | kube-storage-version-migrator-operator           |
      | n             | openshift-kube-storage-version-migrator-operator |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | serviceaccount                          |
      | resource_name | kube-storage-version-migrator-sa        |
      | n             | openshift-kube-storage-version-migrator |
    Then the step should succeed
    When I run the :get admin command with:
      | resource      | deployment                              |
      | resource_name | migrator                                |
      | n             | openshift-kube-storage-version-migrator |
    Then the step should succeed

  # @author kewang@redhat.com
  # @case_id OCP-21246
  @admin
  Scenario Outline: Check the exposed prometheus metrics of operators
    When I run the :serviceaccounts_get_token admin command with: 
      | serviceaccount_name | cluster-monitoring-operator |
      | n                   | openshift-monitoring        |
    Then the step should succeed
    And evaluation of `@result[:response]` is stored in the :sa_token clipboard

    # Get pod name of operators
    Given I switch to cluster admin pseudo user
    And I use the "<ns>" project
    Given a pod becomes ready with labels:
      | app=<label> |

    # Using snippet script to grab the data from the results
    Given a "snippet" file is created with the following lines:
    """
    curl -k -H "Authorization: Bearer <%= cb.sa_token %>" https://localhost:8443/metrics > /tmp/OCP-21246.metrics
    grep workqueue_depth /tmp/OCP-21246.metrics | head -n 5 > /tmp/OCP-21246.grep
    grep workqueue_adds /tmp/OCP-21246.metrics | head -n 5 >> /tmp/OCP-21246.grep
    grep workqueue_queue_duration /tmp/OCP-21246.metrics | head -n 5 >> /tmp/OCP-21246.grep
    grep workqueue_work_duration /tmp/OCP-21246.metrics | head -n 5 >> /tmp/OCP-21246.grep
    grep workqueue_retries /tmp/OCP-21246.metrics | head -n 5 >> /tmp/OCP-21246.grep
    cat /tmp/OCP-21246.grep
    """
    When I execute on the pod:
      | bash | -c | <%= File.read("snippet") %> |
    Then the step should succeed
    And the output should contain:
      | workqueue_depth          |
      | workqueue_adds           |
      | workqueue_queue_duration |
      | workqueue_work_duration  |
      | workqueue_retries        |

    Examples:
      | ns                                               | label                                  |
      | openshift-apiserver-operator                     | openshift-apiserver-operator           |
      | openshift-kube-apiserver-operator                | kube-apiserver-operator                |
      | openshift-kube-controller-manager-operator       | kube-controller-manager-operator       |
      | openshift-kube-storage-version-migrator-operator | kube-storage-version-migrator-operator |
