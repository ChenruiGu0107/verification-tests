Feature: Testing Ingress Operator related scenarios

  # @author hongli@redhat.com
  # @case_id OCP-21766
  @admin
  Scenario: Integrate router metrics with the monitoring component
    Given the master version >= "4.0"
    And I switch to cluster admin pseudo user
    And I use the "openshift-ingress" project
    Then the expression should be true> service_monitor('router-default').exists?
    Then the expression should be true> role_binding('prometheus-k8s').exists?
    Then the expression should be true> namespace('openshift-ingress').labels['openshift.io/cluster-monitoring'] == 'true'


  # @author hongli@redhat.com
  # @case_id OCP-21873
  @admin
  Scenario: the replicas of router deployment is controlled by ingresscontroller
    Given the master version >= "4.0"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And admin ensures "test-21873" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    # create custom ingresscontroller named test-21873 (replicas=1)
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/operator/ingresscontroller-test.yaml" replacing paths:
      | ["metadata"]["name"]                   | test-21873                                    |
      | ["spec"]["defaultCertificate"]["name"] | router-certs-default                          |
      | ["spec"]["domain"]                     | <%= cb.subdomain.gsub("apps","test-21873") %> |
    Then the step should succeed
    Given I use the "openshift-ingress" project
    And I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> deployment("router-test-21873").current_replicas(cached: false) == 1
    """
    # change replicas of custom ingresscontroller to 0
    When I run the :patch admin command with:
      | resource      | ingresscontroller          |
      | resource_name | test-21873                 |
      | n             | openshift-ingress-operator |
      | p             | {"spec":{"replicas": 0}}   |
      | type          | merge                      |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    Then the expression should be true> deployment("router-test-21873").current_replicas(cached: false) == 0
    """


  # @author hongli@redhat.com
  # @case_id OCP-21143
  @admin
  Scenario: the wildcard route certificate of router is controlled by ingresscontroller
    Given the master version >= "4.0"
    And I have a project
    And I store default router subdomain in the :subdomain clipboard
    Given I switch to cluster admin pseudo user
    And I use the "openshift-ingress" project
    And admin ensures "test-certs-21143" secret is deleted from the "openshift-ingress" project after scenario
    And admin ensures "test-21143" ingresscontroller is deleted from the "openshift-ingress-operator" project after scenario
    # create custom wildcard route certificate
    Given I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.pem"
    And I download a file from "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/ca.key"
    When I run the :create_secret client command with:
      | secret_type    | tls              |
      | name           | test-certs-21143 |
      | cert           | ca.pem           |
      | key            | ca.key           |
    Then the step should succeed
    # create custom ingresscontroller which use above secrect
    When I run oc create over "https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/routing/operator/ingresscontroller-test.yaml" replacing paths:
      | ["metadata"]["name"]                   | test-21143                                    |
      | ["spec"]["domain"]                     | <%= cb.subdomain.gsub("apps","test-21143") %> |
      | ["spec"]["defaultCertificate"]["name"] | test-certs-21143                              |
    Then the step should succeed
    Given I wait up to 60 seconds for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | deployment                                                  |
      | resource_name | router-test-21143                                           |
      | template      | {{(index .spec.template.spec.volumes 0).secret.secretName}} |
    Then the step should succeed
    And the output should contain "test-certs-21143"
    """
