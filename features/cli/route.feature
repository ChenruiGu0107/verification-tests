Feature: route related features via cli
  # @author yinzhou@redhat.com
  # @case_id 470733
  Scenario: Create a route without route's name named ---should be failed
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_nil_routename.json |
    Then the step should fail
    And the output should contain:
      | required value |
    And the project is deleted
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_no_routename.json |
    Then the step should fail
    And the output should contain:
      | required value |
    And the project is deleted

  # @author yinzhou@redhat.com
  # @case_id 470734
  Scenario: Create a route without service named ---should be failed
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_nil_servicename.json |
    Then the step should fail
    And the output should contain:
      | required value |
    And the project is deleted
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_no_servicename.json |
    Then the step should fail
    And the output should contain:
      | required value |
    And the project is deleted

  # @author yinzhou@redhat.com
  # @case_id 470731
  Scenario: Create a route with invalid host ---should be failed
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/negative/route_with_invaid__host.json |
    Then the step should fail
    And the output should contain:
      | DNS 952 subdomain |
    And the project is deleted
