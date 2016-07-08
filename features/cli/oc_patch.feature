Feature: oc patch related scenarios
  # @author xxia@redhat.com
  # @case_id 507672
  Scenario: oc patch can update one or more fields of rescource
    Given I have a project
    And I run the :run client command with:
      | name      | hello             |
      | image     | <%= project_docker_repo %>openshift/hello-openshift |
    Then the step should succeed
    Given I wait until the status of deployment "hello" becomes :running
    When I run the :patch client command with:
      | resource      | dc              |
      | resource_name | hello           |
      | p             | {"spec":{"replicas":2}} |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | dc                 |
      | resource_name | hello              |
      | template      | {{.spec.replicas}} |
    Then the step should succeed
    And the output should contain "2"
    """
    When I run the :patch client command with:
      | resource      | dc              |
      | resource_name | hello           |
      | p             | {"metadata":{"labels":{"template":"newtemp","name1":"value1"}},"spec":{"replicas":3}} |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | dc                 |
      | resource_name | hello              |
      | template      | {{.metadata.labels.template}} {{.metadata.labels.name1}} {{.spec.replicas}} |
    Then the step should succeed
    And the output should contain "newtemp value1 3"
    """

  # @author xxia@redhat.com
  # @case_id 507674
  Scenario: oc patch to update resource fields using JSON format
    Given I have a project
    And I create a new application with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Given I wait until the status of deployment "database" becomes :running
    When I run the :patch client command with:
      | resource      | dc              |
      | resource_name | database        |
      | p             | {"spec":{"strategy":{"resources":{"limits":{"memory":"300Mi"}}}}} |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | dc                 |
      | resource_name | database           |
      | template      | {{.spec.strategy.resources.limits.memory}} |
    Then the step should succeed
    And the output should contain "300Mi"
    """

    When I run the :patch client command with:
      | resource      | bc                      |
      | resource_name | ruby-sample-build       |
      | p             | {"spec":{"output":{"to":{"name":"origin-ruby-sample:tag1"}}}} |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | bc                 |
      | resource_name | ruby-sample-build  |
      | template      | {{.spec.output.to.name}} |
    Then the step should succeed
    And the output should contain "origin-ruby-sample:tag1"
    """

    When I run the :patch client command with:
      | resource      | is                      |
      | resource_name | origin-ruby-sample      |
      | p             | {"spec":{"dockerImageRepository":"xxia/origin-ruby-sample"}} |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | is                 |
      | resource_name | origin-ruby-sample |
      | template      | {{.spec.dockerImageRepository}} |
    Then the step should succeed
    And the output should contain "xxia/origin-ruby-sample"
    """

  # @author xxia@redhat.com
  # @case_id 507685
  Scenario: oc patch cannot update non-existing fields and resources
    Given I have a project
    And I run the :run client command with:
      | name      | hello             |
      | image     | <%= project_docker_repo %>openshift/hello-openshift |
    Then the step should succeed
    Given I wait until the status of deployment "hello" becomes :running
    When I run the :patch client command with:
      | resource      | dc              |
      | resource_name | hello           |
      | p             | {"nothisfield":{"replicas":2}} |
    And I run the :get client command with:
      | resource      | dc                 |
      | resource_name | hello              |
      | template      | {{.nothisfield}} |
    Then the step should succeed
    And the output should contain "no value"

    When I run the :patch client command with:
      | resource      | pod             |
      | resource_name | no-this-pod     |
      | p             | {"metadata":{"labels":{"template":"temp1"}} |
    Then the step should fail
    And the output should contain "not found"

  # @author xxia@redhat.com
  # @case_id 507671
  Scenario: oc patch to update resource fields using YAML format
    Given I have a project
    And I create a new application with:
      | file | https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json |
    Then the step should succeed
    Given I wait until the status of deployment "database" becomes :running
    When I run the :patch client command with:
      | resource      | dc                   |
      | resource_name | database             |
      | p             | spec:\n  strategy:\n    resources:\n      limits:\n        memory: 300Mi |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | dc                 |
      | resource_name | database           |
      | template      | {{.spec.strategy.resources.limits.memory}} |
    Then the step should succeed
    And the output should contain "300Mi"
    """

    When I run the :patch client command with:
      | resource      | bc                   |
      | resource_name | ruby-sample-build    |
      | p             | spec:\n  output:\n    to:\n      name: origin-ruby-sample:tag1 |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | bc                 |
      | resource_name | ruby-sample-build  |
      | template      | {{.spec.output.to.name}} |
    Then the step should succeed
    And the output should contain "origin-ruby-sample:tag1"
    """

    When I run the :patch client command with:
      | resource      | is                   |
      | resource_name | origin-ruby-sample   |
      | p             | spec:\n  dockerImageRepository: xxia/origin-ruby-sample |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | is                 |
      | resource_name | origin-ruby-sample |
      | template      | {{.spec.dockerImageRepository}} |
    Then the step should succeed
    And the output should contain "xxia/origin-ruby-sample"
    """

  # @author xiaocwan@redhat.com
  # @case_id 519480
  # @bug_id 1297910
  @admin
  Scenario: patch operation should use patched object to check admission control
    Given I have a project
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/quota/myquota.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :create admin command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/limits/limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed

    Given the pod named "hello-openshift" status becomes :running
    When I run the :patch client command with:
      | resource      | pod             |
      | resource_name | hello-openshift |
      | p             | {"spec":{"containers":[{"name":"hello-openshift","image":"aosqe/hello-openshift"}]}} |
    Then the step should succeed
    When I run the :describe client command with:
      | resource   | pod                |
      | name       | hello-openshift    |
    Then the step should succeed
    And the output should match:
      | [Ii]mage.*aosqe/hello-openshift |
    And I wait for the steps to pass:
    """
    When I get project pods
    Then the step should succeed
    And the output should match:
      | STATUS\\s+RESTARTS  |
      | [Rr]unning\\s+1     |
    """

  # @author yanpzhan@redhat.com
  # @case_id 531246
  Scenario: oc patch resource with different values for --type
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/services/multi-portsvc.json |
    Then the step should succeed

    # check "json" type
    When I run the :patch client command with:
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | type          | json          |
      | p             | [{"op": "replace", "path": "/spec/ports/0/targetPort", "value": 444}] |
    Then the step should succeed

    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | template      | {{.spec.ports}} |
    Then the step should succeed
    And the output should contain:
      | name:https |
      | protocol:TCP |
      | port:27443 |
      | targetPort:444 |
    And the output should not contain "targetPort:443"
    """

    # check "strategic" type
    When I run the :patch client command with:
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | type          | strategic     |
      | p             | spec:\n  ports:\n  - port: 27443\n    targetPort: 445 |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | template      | {{.spec.ports}} |
    Then the step should succeed
    And the output should contain:
      | name:https |
      | protocol:TCP |
      | port:27443 |
      | targetPort:445 |
      | name:http |
      | port:27017 |
      | targetPort:80 |
    And the output should not contain "targetPort:444"
    """

    # check "merge" type
    When I run the :patch client command with:
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | type          | merge         |
      | p             | spec:\n  ports:\n  - port: 27443\n    targetPort: 446 |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | template      | {{.spec.ports}} |
    Then the step should succeed
    And the output should contain:
      | port:27443 |
      | targetPort:446 |
      | protocol:TCP |
    And the output should not contain:
      | name:https |
      | name:http |
      | port:27017 |
      | targetPort:80 |
    """

    When I run the :patch client command with:
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | type          | json          |
      | p             | [{"op": "delete", "path": "/spec/ports/0/targetPort", "value": 444}] |
    Then the step should fail
    And the output should match:
      | Unexpected kind:\\s+delete |

    When I run the :patch client command with:
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | type          | jso          |
    Then the step should fail
    And the output should match:
      | type must be one of .*json merge strategic.*|

    When I run the :patch client command with:
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | type          | strategic     |
      | p             | spec:\n  ports:\n  -\n    targetPort: 446 |
    Then the step should fail
     And the output should match:
      | does not contain declared merge key |
