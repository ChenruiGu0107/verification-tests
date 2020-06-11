Feature: Descheduler extra image testing

  # @author knarra@redhat.com
  # @case_id OCP-29821
  @admin
  @destructive
  Scenario: Install descheduler using extra image
    # Create cluster role
    Given I switch to cluster admin pseudo user
    Given admin ensures "descheduler-cluster-role-ocp29821" clusterrole is deleted after scenario
    Given admin ensures "descheduler-sa-ocp29821" service_account is deleted from the "kube-system" project after scenario
    Given admin ensures "descheduler-policy-configmap-ocp29821" configmap is deleted from the "kube-system" project after scenario
    Given admin ensures "descheduler-cluster-role-binding-ocp29821" clusterrolebinding is deleted after scenario
    Given admin ensures "descheduler-cronjob-ocp29821" cronjob is deleted from the "kube-system" project after scenario
    Given I store master major version in the clipboard
    Given I obtain test data file "descheduler/clusterrole.yaml"
    When I run the :create admin command with:
      | f | clusterrole.yaml |
    Then the step should succeed
    And the output should contain "clusterrole.rbac.authorization.k8s.io/descheduler-cluster-role-ocp29821 created"
    # Create sa
    Given I obtain test data file "descheduler/descheduler-sa.yaml"
    When I run the :create admin command with:
      | f | descheduler-sa.yaml |
    Then the step should succeed
    And the output should contain "serviceaccount/descheduler-sa-ocp29821 created"
    # Bind the clusterrole to service account
    When I run the :create_clusterrolebinding client command with:
      | name           | descheduler-cluster-role-binding-ocp29821 |
      | clusterrole    | descheduler-cluster-role-ocp29821         |
      | serviceaccount | kube-system:descheduler-sa-ocp29821       |
    Then the step should succeed
    And the output should contain "clusterrolebinding.rbac.authorization.k8s.io/descheduler-cluster-role-binding-ocp29821 created"
    # Create configmap
    Given I obtain test data file "descheduler/policy.yaml"
    When I run the :create_configmap admin command with:
      | name      | descheduler-policy-configmap-ocp29821                                   |
      | from_file | policy.yaml |
      | namespace | kube-system                                                             |
    Then the step should succeed
    And the output should contain "configmap/descheduler-policy-configmap-ocp29821 created"
    Given I obtain test data file "descheduler/cronjob.yaml"
    When I run oc create over "cronjob.yaml" replacing paths:
      | ["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0]["image"] | registry.stage.redhat.io/openshift4/ose-descheduler:<%= cb.master_version %> |
    Then the step should succeed
    And the output should contain "cronjob.batch/descheduler-cronjob-ocp29821 created"
    And I wait up to 180 seconds for the steps to pass:
    """
    Given I use the "kube-system" project
    And a pod is present with labels:
      | job-name |
    """
    Given evaluation of `pod.name` is stored in the :pod_name clipboard
    And the pod named "<%= cb.pod_name %>" status becomes :succeeded
    When I run the :logs client command with:
      | resource_name | pod/<%= cb.pod_name %> |
    And the output should contain:
      | pod_antiaffinity.go   |
      | lownodeutilization.go |
      | duplicates.go         |
