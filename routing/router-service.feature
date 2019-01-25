Feature: Testing router service related feature
  # @author zzhao@redhat.com
  # @case_id OCP-16871
  @admin
  Scenario: Rourter service should contain prometheus annotations
    Given the master version >= "3.7"
    Given I switch to cluster admin pseudo user
    And I use the router project
    # don't need to check the values, just they exist is enough
    And the expression should be true> service('router').annotation('prometheus.openshift.io/password')
    And the expression should be true> service('router').annotation('prometheus.openshift.io/username')
