Feature: Testing openshift-controller-manager-operator
  # @author wewang@redhat.com
  # @case_id OCP-21935
  @admin
  @destructive
  Scenario: Controller Manager Status reported by openshift-cluster-openshift-controller-manager-operator
    Given I switch to cluster admin pseudo user
    When admin updated the operator crd "openshiftcontrollermanager" managementstate operand to Unmanaged
    And I register clean-up steps:
    """
    admin updated the operator crd "openshiftcontrollermanager" managementstate operand to Managed
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
    When admin updated the operator crd "openshiftcontrollermanager" managementstate operand to Managed
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
    Then the expression should be true> cluster_operator("openshift-controller-manager").conditions(cached:false).any? {|c| c["reason"] =~ /DesiredStateNotYetAchieved/ && c["status"] == "True" && c["type"] == "Progressing"}
    """
    When I run the :delete client command with:
      | object_type       | svc                          |
      | object_name_or_id | controller-manager           |
      | namespace         | openshift-controller-manager |
    Then the step should succeed
    And admin wait for the "controller-manager" svc to appear in the "openshift-controller-manager" project

  # @author xiuwang@redhat.com
  # @case_id OCP-23653
  Scenario: oc explain works for openshift-controller-manager operator
    When I run the :explain client command with:
      | resource    | openshiftcontrollermanagers |
    Then the step should succeed
    And the output should contain:
      | OpenShiftControllerManager provides information to configure an operator to |
      | manage openshift-controller-manager.                                        |
      | APIVersion defines the versioned schema of this representation of an        |
      | object                                                                      |
      | Kind is a string value representing the REST resource this object           |
      | represents.                                                                 |
      | Standard object's metadata                                                  |

  # @author wewang@redhat.com
  # @case_id OCP-26828
  @admin
  @destructive
  Scenario: Controller Manager Status reported by cluster-openshift-controller-manager-operator 	
    Given the master version == "4.1"
    When I switch to cluster admin pseudo user
    And I register clean-up steps:
    """
    admin updated the operator crd "openshiftcontrollermanager" managementstate operand to Managed
    """
    Then admin updated the operator crd "openshiftcontrollermanager" managementstate operand to Unmanaged
    And the expression should be true> cluster_operator('openshift-controller-manager').condition(type: 'Available')['status'] == "Unknown"
    And the expression should be true> cluster_operator('openshift-controller-manager').condition(type: 'Progressing')['status'] == "Unknown"
    And the expression should be true> cluster_operator('openshift-controller-manager').condition(type: 'Degraded')['status'] == "Unknown"
