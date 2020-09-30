Feature: Testing images config

  # @author wzheng@redhat.com
  # @case_id OCP-24879
  @admin
  @destructive
  Scenario: Mount trusted CA for cluster proxies to Image Registry Operator with invalid setting
    Given I switch to cluster admin pseudo user
    When I run the :describe admin command with:
      | resource | proxy.config.openshift.io |
      | name     | cluster                   |
    And the output should contain:
      | user-ca-bundle |
    And I switch to the first user
    Given I have a project
    When I run the :import_image client command with:
      | image_name       | busybox |
      | confirm          | true    |
      | reference-policy | local   |
    Then the step should succeed
    Given I switch to cluster admin pseudo user
    And I successfully merge patch resource "proxy.config.openshift.io/cluster" with:
      | {"spec":{"trustedCA":{"name":"invalid"}}} |
    And I register clean-up steps:
    """
    And I successfully merge patch resource "proxy.config.openshift.io/cluster" with:
      | {"spec":{"trustedCA":{"name":"user-ca-bundle"}}} |
    """
    And I wait for the steps to pass:
    """
    When I run the :logs admin command with:
     | resource_name | deployments/machine-config-operator |
     | namespace     | openshift-machine-config-operator   |
    And the output should contain:
     | configmap "invalid" not found |
    """
