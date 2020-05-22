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
