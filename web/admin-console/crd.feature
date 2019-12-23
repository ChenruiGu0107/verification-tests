Feature: CRD related

  # @author hasha@redhat.com
  # @case_id OCP-24330
  @admin
  Scenario: Check tab of instances on the CRD details page
    Given the master version >= "4.2"
    Given I have a project
    Given the first user is cluster-admin
    Given I open admin console in a browser
    When I perform the :goto_crd_instances_page web action with:
      | crd_definition | clusterversions.config.openshift.io |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | version |
      | link_url | k8s/cluster/config.openshift.io~v1~ClusterVersion/version |
    Then the step should succeed
    When I perform the :goto_crd_instances_page web action with:
      | crd_definition | catalogsources.operators.coreos.com |
    Then the step should succeed
    When I perform the :check_link_and_text web action with:
      | text     | certified-operators |
      | link_url | k8s/ns/openshift-marketplace/operators.coreos.com~v1alpha1~CatalogSource/certified-operators |
    Then the step should succeed
