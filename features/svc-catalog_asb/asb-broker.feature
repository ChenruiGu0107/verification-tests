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

  # @author chezhang@redhat.com
  # @case_id OCP-15801
  @admin
  @destructive
  Scenario: svc-catalog sync with borker can be manually trigger
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And the "ansible-service-broker" cluster service broker is recreated after scenario
    And I save the first service broker registry prefix to :prefix clipboard

    # Edit servicebroker "openshift-ansible-service-broker", set spec.relistBehavior=Manual and spec.relistDuration=2m
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker             |
      | p        | spec:\n  relistBehavior: Manual\n  relistDuration: 2m0s |
    Then the step should fail

    # Edit servicebroker "openshift-ansible-service-broker", set spec.relistBehavior=Manual and unset spec.relistDuration=2m
    Given I successfully patch resource "clusterservicebroker/ansible-service-broker" with:
      | {"spec":{"relistBehavior":"Manual","relistDuration":null}} |

    # Delete one of clusterserviceclass, and check clusterserviceclass status and logs of asb pod after 16mins
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-mediawiki-apb'].name` is stored in the :class_id clipboard
    And I ensure "<%= cb.class_id %>" clusterserviceclasses is deleted
    Given 1000 seconds have passed
    Given a pod becomes ready with labels:
      | deploymentconfig=asb |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %> |
      | since         | 1000s           |
    Then the output should not contain "AnsibleBroker::Catalog"

  # @author chezhang@redhat.com
  # @case_id OCP-15791
  @admin
  @destructive
  Scenario: svc-catalog have default duration to sync with broker
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ansible-service-broker" project
    And the "ansible-service-broker" cluster service broker is recreated after scenario
    And I save the first service broker registry prefix to :prefix clipboard
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_behavior == "Duration"
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_duration_raw == "15m0s"
    Given cluster service classes are indexed by external name in the :csc clipboard
    And evaluation of `cb.csc['<%= cb.prefix %>-mediawiki-apb'].name` is stored in the :class_id clipboard
    And I ensure "<%= cb.class_id %>" clusterserviceclasses is deleted
    Given 1000 seconds have passed
    Given a pod becomes ready with labels:
      | deploymentconfig=asb |
    When I run the :logs client command with:
      | resource_name | <%= pod.name %> |
      | since         | 1000s           |
    Then the output should contain "AnsibleBroker::Catalog"
    And evaluation of `cb.csc['<%= cb.prefix %>-mediawiki-apb'].name` is stored in the :class_id clipboard
    And I check that the "<%= cb.class_id %>" clusterserviceclasses exists

  # @author chezhang@redhat.com
  # @case_id OCP-16635
  @admin
  @destructive
  Scenario: Should prevent relistDuration change to negative value in servicebroker
    Given I switch to cluster admin pseudo user
    And the "ansible-service-broker" cluster service broker is recreated after scenario

    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                 |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: -15m0s |
    Then the step should fail
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker              |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: abc |
    Then the step should fail
    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker               |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: *%$# |
    Then the step should fail

    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker               |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: 0.5m |
    Then the step should succeed
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_behavior == "Duration"
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_duration_raw(cached: false) == "30s"

    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker                |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: 0s11m |
    Then the step should succeed
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_behavior == "Duration"
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_duration_raw(cached: false) == "11m0s"

    When I run the :patch client command with:
      | resource | clusterservicebroker/ansible-service-broker               |
      | p        | spec:\n  relistBehavior: Duration\n  relistDuration: 600s |
    Then the step should succeed
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_behavior == "Duration"
    And the expression should be true> cluster_service_broker("ansible-service-broker").relist_duration_raw(cached: false) == "10m0s"
