Feature: oc inspect related scenarios

  # @author yinzhou@redhat.com
  # @case_id OCP-25746
  @admin
  Scenario: Inspect resource by oc command
    Given I switch to cluster admin pseudo user
    When I run the :oadm_inspect admin command with:
      | resource_type  | daemonsets                                |
      | all_namespaces | true                                      |
      | dest_dir       | <%= BushSlicer::HOME %>/testdata/ocp25746 |
    Then the step should succeed
    And the output should match "inspect data to .*/ocp25746"
    And the "<%= BushSlicer::HOME %>/testdata/ocp25746/namespaces" file is present
    When I run the :oadm_inspect admin command with:
      | resource_name | configmap/openshift-install-manifests |
      | resource_name | secret/pull-secret                    |
      | n             | openshift-config                      |
    Then the step should succeed
