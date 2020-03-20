Feature: certificates related scenarios

  # @author yinzhou@redhat.com
  # @case_id OCP-26290
  @admin
  Scenario: Check kube-controller-manager and kube-scheduler secure port served by openshift signed certificates
    Given I switch to cluster admin pseudo user
    When I run the :get admin command with:
      | resource      | service                           |
      | resource_name | kube-controller-manager           |
      | template      | {{.metadata.annotations}}         |
      | n             | openshift-kube-controller-manager |
    Then the output should contain "serving-cert-signed-by:openshift-service-serving-signer"
    When I run the :get admin command with:
      | resource      | service                   |
      | resource_name | scheduler                 |
      | template      | {{.metadata.annotations}} |
      | n             | openshift-kube-scheduler  |
    Then the output should contain "serving-cert-signed-by:openshift-service-serving-signer"
