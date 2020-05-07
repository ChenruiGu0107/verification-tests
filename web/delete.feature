Feature: Delete the resources via web console
  # @author yapei@redhat.com
  # @case_id OCP-14215
  Scenario: Delete deployment should also delete ReplicaSets and pod with alert dialog
    Given the master version >= "3.6"
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/deployment/OCP-14215/k8s-deployment.yaml |
    Then the step should succeed
    Given a pod is present with labels:
      | app=hello-openshift |
    When I perform the :goto_one_k8s_deployment_page web console action with:
      | project_name        | <%= project.name %> |
      | k8s_deployment_name | hello-openshift     |
    Then the step should succeed
    When I run the :get client command with:
      | resource | rs |
    Then the step should succeed
    And the output should contain:
      | hello-openshift |

    When I run the :check_delete_deployment_warning_in_delete_action web console action
    Then the step should succeed
    When I run the :click_delete web console action
    Then the step should succeed
    Given I wait for the resource "deployment" named "hello-openshift" to disappear
    When I run the :get client command with:
      | resource | rs |
    Then the step should succeed
    And the output should contain:
      | No resources found |
    And the output should not contain:
      | hello-openshift |
    When I run the :get client command with:
      | resource | pod |
    Then the step should succeed
    And the output should contain:
      | No resources found |
    And the output should not contain:
      | hello-openshift |

  # @author yapei@redhat.com
  # @case_id OCP-14207
  Scenario: Delete BC/statefulSet from console should remove builds/pods with alert dialog
    Given the master version >= "3.6"
    Given I have a project
    When I run the :new_app client command with:
      | file | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    Given the "ruby-sample-build-1" build was created
    When I perform the :goto_one_buildconfig_page web console action with:
      | project_name | <%= project.name %> |
      | bc_name      | ruby-sample-build   |
    Then the step should succeed
    When I run the :check_delete_bc_warning_in_delete_action web console action
    Then the step should succeed
    When I run the :click_delete web console action
    Then the step should succeed
    Given I wait for the resource "bc" named "ruby-sample-build" to disappear
    When I run the :get client command with:
      | resource | builds |
    Then the step should succeed
    And the output should contain:
      | No resources found |
    And the output should not contain:
      | ruby-sample-build-1 |

    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/statefulset/statefulset-hello.yaml |
    Then the step should succeed
    Given a pod is present with labels:
      | app=hello |
    When I perform the :goto_one_stateful_sets_page web console action with:
      | project_name       | <%= project.name %> |
      | stateful_sets_name | hello               |
    Then the step should succeed
    When I run the :check_delete_statefulsets_warning_in_delete_action web console action
    Then the step should succeed
    When I run the :click_delete web console action
    Then the step should succeed
    Given I wait for the resource "statefulsets" named "hello" to disappear
    When I run the :get client command with:
      | resource | pods |
    Then the step should succeed
    And the output should not contain:
      | hello |
