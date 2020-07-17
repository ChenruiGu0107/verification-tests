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

  # @author yinzhou@redhat.com
  # @case_id OCP-28011
  @admin
  Scenario: Should protect the Schema info when cached
    Given I have a project
    Given the expression should be true> @host = localhost
    And I run commands on the host:
      | stat ~/.kube/cache/discovery/<%= env.api_endpoint_url.split("//")[1].gsub(/-/,"_").sub(/:/,"_") %> |
    And the output should match:
      | Access: \([02]750\/drwxr-[xs]---\) |

