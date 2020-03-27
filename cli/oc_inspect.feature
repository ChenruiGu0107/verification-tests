Feature: oc inspect related scenarios

  # @author yinzhou@redhat.com
  # @case_id OCP-25746
  @admin
  Scenario: Inspect resource by oc command
    Given I switch to cluster admin pseudo user
    When I run the :oadm_inspect admin command with:
      | resource       | daemonsets    |
      | all_namespaces | true          |
      | dest_dir       | /tmp/ocp25746 |
    Then the step should succeed
    And the output should match "inspect data to \/tmp\/ocp25746"
    And the "/tmp/ocp25746/namespaces/openshift-cluster-node-tuning-operator/apps/daemonsets/tuned.yaml" file is present
    When I run the :oadm_inspect admin command with:
      | resource_name | configmap/openshift-install |
      | resource_name | secret/pull-secret          |
      | n             | openshift-config            |
    Then the step should succeed
    Given cluster role "cluster-admin" is added to the "first" user
    Given I switch to the first user
    When I run the :oadm_inspect client command with:
      | resource      | co                      |
      | resource_name | csi-snapshot-controller |
      | loglevel      | 1                       |
    Then the step should succeed
    And the output should match:
      | Using token authentication |
