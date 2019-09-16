Feature: Testing image registry operator

  # @author wzheng@redhat.com
  # @case_id OCP-21593
  @admin
  @destructive
  Scenario:Check registry status by changing managementState for image-registry
    Given I switch to cluster admin pseudo user
    Given Admin updated the operator crd "configs.imageregistry" managementstate operand to Removed
    Then the step should succeed
    And I register clean-up steps:
    """
    Given Admin updated the operator crd "configs.imageregistry" managementstate operand to Managed
    """
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource  | pods                     |
      | namespace | openshift-image-registry |
    And the output should not match:
      | ^image-registry |
    """
    Given Admin updated the operator crd "configs.imageregistry" managementstate operand to Managed
    Then the step should succeed
    Given I use the "openshift-image-registry" project
    And a pod is present with labels:
      | docker-registry=default |
    When I run the :patch client command with:
      | resource      | configs.imageregistry.operator.openshift.io |
      | resource_name | cluster                                     |
      | p             | {"spec":{"logging":8}}                      |
      | type          | merge                                       |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :set_env client command with:
      | resource  | pod                      |
      | all       | true                     |
      | list      | true                     | 
      | namespace | openshift-image-registry |
    And the output should contain:
      | REGISTRY_LOG_LEVEL=debug |
    """
    
    # Check when managementState is Unmanaged, nothing change will take effect

    When I run the :patch client command with:
      | resource      | configs.imageregistry          |
      | resource_name | cluster                                              |
      | p             | {"spec":{"managementState":"Unmanaged","logging":2}} |
      | type          | merge                                                |
    Then the step should succeed
    When I run the :set_env client command with:
      | resource  | pod                      |
      | all       | true                     |
      | list      | true                     | 
      | namespace | openshift-image-registry |
    And the output should contain:
      | REGISTRY_LOG_LEVEL=debug |

  # @author wzheng@redhat.com
  # @case_id OCP-22031
  @admin
  @destructive
  Scenario: Config CPU and memory for internal regsistry
    Given I switch to cluster admin pseudo user
    When I use the "openshift-image-registry" project
    Given current generation number of "image-registry" deployment is stored into :before_change clipboard
    Given as admin I successfully merge patch resource "configs.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"resources":{"limits":{"cpu":"100m","memory":"512Mi"}}}} | 
    And admin ensures "cluster" config_imageregistry_operator_openshift_io is deleted after scenario
    Given current generation number of "image-registry" deployment is stored into :after_change clipboard
    And the expression should be true> cb.after_change - cb.before_change >=1
    Given a pod is present with labels:
      | docker-registry=default |
    Then the expression should be true> pod.container_specs.first.cpu_limit_raw == "100m"
    And the expression should be true> pod.container_specs.first.memory_limit_raw == "512Mi"

  # @author wzheng@redhat.com
  # @case_id OCP-22032
  @admin
  @destructive
  Scenario: Config NodeSelector for internal regsistry
    Given I switch to cluster admin pseudo user
    Given as admin I successfully merge patch resource "configs.imageregistry.operator.openshift.io/cluster" with:
      | {"spec":{"nodeSelector":{"node-role.kubernetes.io/master": "abc"}}} | 
    And admin ensures "cluster" config_imageregistry_operator_openshift_io is deleted after scenario
    When I use the "openshift-image-registry" project
    Given a pod is present with labels:
      | docker-registry=default |
    When I run the :describe client command with:
      | resource | pod             |
      | name     | <%= pod.name %> |
    Then the output should contain:
      | didn't match node selector |
