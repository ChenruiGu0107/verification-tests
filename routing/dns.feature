Feature: Testing DNS features

  # @author hongli@redhat.com
  # @case_id OCP-21136
  Scenario: DNS can resolve the ClusterIP services
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    Given I use the "service-unsecure" service
    And evaluation of `service.ip(user: user)` is stored in the :service_ip clipboard

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | time | curl | service-unsecure:27017 |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"
    # the real time should be always less than 1s if Bug #1661928 (5s delay sometimes) fixed
    # for now, just rerun this case if below step failed
    And the output should match:
      | real\s+0m 0.\d\ds |

    When I execute on the pod:
      | curl |
      | service-unsecure.<%= cb.proj_name %>:27017 |
    Then the step should succeed
    And the output should contain "Hello-OpenShift"

    When I execute on the pod:
      | nslookup |
      | service-unsecure.<%= cb.proj_name %>.svc |
    Then the step should succeed
    And the output should contain "<%= cb.service_ip %>"

    When I execute on the pod:
      | getent |
      | ahosts |
      | service-unsecure.<%= cb.proj_name %>.svc.cluster.local |
    Then the step should succeed
    And the output should contain "<%= cb.service_ip %>"

  # @author hongli@redhat.com
  # @case_id OCP-21137
  Scenario: DNS can resolve the external domain
    Given I have a project
    And I have a pod-for-ping in the project
    When I execute on the pod:
      | curl | -LI | www.redhat.com |
    Then the step should succeed
    And the output should contain "200 OK"

    When I execute on the pod:
      | time | curl | -LI | www.google.com |
    Then the step should succeed
    And the output should contain "200 OK"
    # the real time should be always less than 1s if Bug #1661928 (5s delay sometimes) fixed
    # for now, just rerun this case or ignored the step
    And the output should match:
      | real\s+0m 0.\d\ds |

  # @author hongli@redhat.com
  # @case_id OCP-21138
  Scenario: DNS can resolve the ExternalName services
    Given I have a project
    And evaluation of `project.name` is stored in the :proj_name clipboard
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/caddy-docker.json |
    Then the step should succeed
    And the pod named "caddy-docker" becomes ready
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/unsecure/service_unsecure.json |
    Then the step should succeed
    Given I use the "service-unsecure" service
    And evaluation of `service.ip(user: user)` is stored in the :service_ip clipboard

    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/dns/externalname-service-int.json" replacing paths:
      | ["spec"]["externalName"] | service-unsecure.<%= cb.proj_name %>.svc.cluster.local |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/dns/externalname-service-ext.json |
    Then the step should succeed

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | getent | ahosts | external-internal |
    Then the step should succeed
    And the output should contain "<%= cb.service_ip %>"

    When I execute on the pod:
      | getent | ahosts | external-external |
    Then the step should succeed
    And the output should contain "www.google.com"

  # @author hongli@redhat.com
  # @case_id OCP-21139
  Scenario: DNS can resolve headless service to the IP of selected pods
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/dns/headless-services.json |
    Then the step should succeed
    Given 2 pods become ready with labels:
      | name=caddy-pods |
    And evaluation of `pod(0).ip` is stored in the :pod0_ip clipboard
    And evaluation of `pod(1).ip` is stored in the :pod1_ip clipboard

    Given I have a pod-for-ping in the project
    When I execute on the pod:
      | getent | ahosts | service-unsecure |
    Then the step should succeed
    And the output should contain "<%= cb.pod0_ip %>"
    And the output should contain "<%= cb.pod1_ip %>"
