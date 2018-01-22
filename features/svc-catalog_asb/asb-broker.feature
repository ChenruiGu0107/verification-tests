Feature: ASB broker config related scenarios

  # @author chezhang@redhat.com
  # @case_id OCP-15796
  @admin
  @destructive
  Scenario: relistBehavior&relistDuration&relistRequests should work well in resync and relist
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And the "ansible-service-broker" cluster service broker is recreated after scenario
    And I save the first service broker registry prefix to :prefix clipboard

    # Edit servicebroker "openshift-ansible-service-broker", set spec.relistBehavior=Duration and spec.relistDuration=2m
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker               |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: 2m0s |
    Then the step should succeed

    # Delete one of clusterserviceclass, and check clusterserviceclass status and logs of asb pod after 6mins
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-mediawiki-apb'].name` is stored in the :class_id clipboard
    And I ensure "<%= cb.class_id %>" clusterserviceclasses is deleted
    Given 120 seconds have passed
    Given a pod becomes ready with labels:
      | deploymentconfig=asb |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %> |
      | since         | 120s            |
    Then the output should not contain "AnsibleBroker::Catalog"
    Given 300 seconds have passed
    When I run the :logs client command with:
      | resource_name | <%= pod.name %> |
      | since         | 7m              |
    Then the output should contain "AnsibleBroker::Catalog"
    And I check that the "<%= cb.class_id %>" clusterserviceclasses exists

    # Edit servicebroker "openshift-ansible-service-broker", set spec.relistBehavior=Duration and spec.relistDuration=8m
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker             |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: 8m |
    Then the step should succeed

    # Delete one of clusterserviceclass, and check clusterserviceclass status and logs of asb pod after 10mins
    And I ensure "<%= cb.class_id %>" clusterserviceclasses is deleted
    Given 360 seconds have passed
    When I run the :logs client command with:
      | resource_name | <%= pod.name %> |
      | since         | 350s            |
    Then the output should not match "AnsibleBroker::Catalog"
    Given 420 seconds have passed
    When I run the :logs client command with:
      | resource_name | <%= pod.name %> |
      | since         | 8m              |
    Then the output should match "AnsibleBroker::Catalog"
    And I check that the "<%= cb.class_id %>" clusterserviceclasses exists
