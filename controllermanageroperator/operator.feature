Feature: Testing openshift-controller-manager-operator 
  # @author wewang@redhat.com
  # @case_id OCP-21935
  @admin
  @destructive
  Scenario: Controller Manager Status reported by openshift-cluster-openshift-controller-manager-operator
    Given I switch to cluster admin pseudo user
    When Admin updated the operator crd "openshiftcontrollermanager" managementstate operand to Unmanaged
    And I register clean-up steps:
    """
    Admin updated the operator crd "openshiftcontrollermanager" managementstate operand to Managed
    """
    And the expression should be true> cluster_operator('openshift-controller-manager').condition(type: 'Available')['status'] == "True"
    And the expression should be true> cluster_operator('openshift-controller-manager').condition(type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator('openshift-controller-manager').condition(type: 'Degraded')['status'] == "False"
    When I run the :delete client command with:
      | object_type       | ds                           |
      | object_name_or_id | controller-manager           |
      | namespace         | openshift-controller-manager |
    Then the step should succeed
    When I run the :get client command with:
      | resource  | ds                           |
      | namespace | openshift-controller-manager |
    Then the step should succeed
    And the output should contain:
      | controller-manager |
    When Admin updated the operator crd "openshiftcontrollermanager" managementstate operand to Managed
    And I wait up to 100 seconds for the steps to pass:
    """
    And the expression should be true> cluster_operator('openshift-controller-manager').condition(type: 'Available')['status'] == "True"
    And the expression should be true> cluster_operator('openshift-controller-manager').condition(type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator('openshift-controller-manager').condition(type: 'Degraded')['status'] == "False"
    """
    When I run the :patch client command with:
      | resource      | openshiftcontrollermanager     |
      | resource_name | cluster                        |
      | p             | {"spec":{"logLevel": "Debug"}} |
      | type          | merge                          |
    Then the step should succeed
    And I register clean-up steps:
    """
    Given I run the :patch client command with:
      | resource      | openshiftcontrollermanager     |
      | resource_name | cluster                        |
      | p             | {"spec":{"logLevel": ""}}      |
      | type          | merge                          |
    Then the step should succeed
    """
    When I wait for the steps to pass: 
    """
    Then the expression should be true> cluster_operator("openshift-controller-manager").conditions(cached:false).any? {|c| c["reason"] == "ProgressingDesiredStateNotYetAchieved" && c["status"] == "True" && c["type"] == "Progressing"}
    """
    When I run the :delete client command with:
      | object_type       | svc                          |
      | object_name_or_id | controller-manager           |
      | namespace         | openshift-controller-manager |
    Then the step should succeed
    And admin wait for the "controller-manager" svc to appear in the "openshift-controller-manager" project
