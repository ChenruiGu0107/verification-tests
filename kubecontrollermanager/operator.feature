Feature: Testing kube-controller-manager-operator 

  # @author yinzhou@redhat.com
  # @case_id OCP-28001
  @admin
  @destructive
  Scenario: KCM should recover when its temporary secrets are deleted
    Given I switch to cluster admin pseudo user
    Then I run the :delete admin command with:
      | object_type       | secrets                                 |
      | object_name_or_id | csr-signer                              |
      | object_name_or_id | kube-controller-manager-client-cert-key |
      | object_name_or_id | service-account-private-key             |
      | object_name_or_id | serving-cert                            |
      | n                 | openshift-kube-controller-manager       |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get admin command with:
      | resource      | secrets                                 |
      | resource_name | csr-signer                              |
      | resource_name | kube-controller-manager-client-cert-key |
      | resource_name | service-account-private-key             |
      | resource_name | serving-cert                            |
      | n             | openshift-kube-controller-manager       |
    Then the step should succeed
    """
    And I wait up to 300 seconds for the steps to pass:
    """
    Then the expression should be true> cluster_operator("kube-controller-manager").condition(cached: false, type: 'Progressing')['status'] == "False"
    And the expression should be true> cluster_operator("kube-controller-manager").condition(type: 'Degraded')['status'] == "False"
    And the expression should be true> cluster_operator("kube-controller-manager").condition(type: 'Available')['status'] == "True"
    """
