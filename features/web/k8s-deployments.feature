Feature: Features about k8s deployments
  # @author yapei@redhat.com
  # @case_id OCP-12273
  Scenario: Attach storage for k8s deployment
    Given the master version >= "3.4"
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/deployment/tc536590/k8s-deployment.yaml |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/persistent-volumes/nfs/claim-rwo-ui.json |
    Then the step should succeed
    When I perform the :click_to_goto_one_deployment_page web console action with:
      | project_name         | <%= project.name %> |
      | k8s_deployments_name | hello-openshift     |
    Then the step should succeed
    When I perform the :add_storage_to_k8s_deployments web console action with:
      | mount_path  |  /hello-openshift-data |
      | volume_name | hello-openshift-volume |
    Then the step should succeed
    When I perform the :check_mount_info_configuration web console action with:
      | mount_path  |  /hello-openshift-data |
      | volume_name | hello-openshift-volume |
    Then the step should succeed
    When I perform the :click_pvc_link_on_dc_page web console action with:
      | pvc_name | nfsc |
    Then the step should succeed
    And the expression should be true> browser.url.include? "browse/persistentvolumeclaims"
    When I run the :volume client command with:
      | resource      | deployment                 |
      | resource_name | hello-openshift            |
      | action        | --remove                   |
      | name          | hello-openshift-volume     |
    Then the step should succeed
    When I perform the :check_mount_info_on_one_deployment_page web console action with:
      | project_name         | <%= project.name %>    |
      | k8s_deployments_name | hello-openshift        |
      | mount_path           | /hello-openshift-data  |
      | volume_name          | hello-openshift-volume |
    Then the step should fail
