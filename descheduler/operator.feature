Feature: Descheduler related scenarios

  # @author knarra@redhat.com
  # @case_id OCP-21481
  @admin
  Scenario: Install descheduler operator via olm
    Given the master version >= "4.4"
    Given I switch to cluster admin pseudo user
    And I use the "openshift-kube-descheduler-operator" project
    And all existing pods are ready with labels:
      | name=descheduler-operator |
      | app=descheduler           |
    And status becomes :running of exactly 1 pods labeled:
      | app=descheduler |
    Given evaluation of `pod.name` is stored in the :pod_name clipboard
    When I run the :logs client command with:
      | resource_name | pod/<%= cb.pod_name %> |
    And the output should contain:
      | duplicates.go         |
      | lownodeutilization.go |
      | pod_antiaffinity.go   |
      | node_affinity.go      |
      | node_taint.go         |
