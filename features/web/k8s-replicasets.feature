Feature: Features about k8s replicasets
  # @author yapei@redhat.com
  # @case_id OCP-10991
  Scenario: Attach storage for k8s replicasets
    Given the master version >= "3.4"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/replicaSet/tc536589/replica-set.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo-ui.json |
    Then the step should succeed
    When I perform the :click_to_goto_one_replicaset_page web console action with:
      | project_name         | <%= project.name %> |
      | k8s_replicasets_name | frontend            |
    Then the step should succeed
    When I perform the :add_storage_to_k8s_replicasets web console action with:
      | mount_path  |  /hello-openshift-data |
      | volume_name | hello-openshift-volume |
    Then the step should succeed
    When I perform the :check_mount_info_configuration_for_replicaset web console action with:
      | mount_path  |  /hello-openshift-data |
      | volume_name | hello-openshift-volume |
    Then the step should succeed
    When I perform the :click_pvc_link_on_dc_page web console action with:
      | pvc_name | nfsc |
    Then the step should succeed
    And the expression should be true> browser.url.include? "browse/persistentvolumeclaims"
    When I run the :volume client command with:
      | resource      | replicaset                 |
      | resource_name | frontend                   |
      | action        | --remove                   |
      | name          | hello-openshift-volume     |
    Then the step should succeed
    When I perform the :check_mount_info_on_one_replicaset_page web console action with:
      | project_name         | <%= project.name %>    |
      | k8s_replicasets_name | frontend               |
      | mount_path           | /hello-openshift-data  |
      | volume_name          | hello-openshift-volume |
    Then the step should fail
