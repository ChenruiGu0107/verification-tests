Feature: oc patch/apply related scenarios

  # @author xxia@redhat.com
  Scenario Outline: oc patch to update resource fields using JSON format
    Given I have a project
    And I create a new application with:
      | file | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    Given I wait for the "database" dc to appear
    When I run the :patch client command with:
      | _tool         | <tool>          |
      | resource      | dc              |
      | resource_name | database        |
      | p             | {"spec":{"strategy":{"resources":{"limits":{"memory":"300Mi"}}}}} |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | _tool         | <tool>             |
      | resource      | dc                 |
      | resource_name | database           |
      | template      | {{.spec.strategy.resources.limits.memory}} |
    Then the step should succeed
    And the output should contain "300Mi"
    """

    When I run the :patch client command with:
      | _tool         | <tool>                  |
      | resource      | bc                      |
      | resource_name | ruby-sample-build       |
      | p             | {"spec":{"output":{"to":{"name":"origin-ruby-sample:tag1"}}}} |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | _tool         | <tool>             |
      | resource      | bc                 |
      | resource_name | ruby-sample-build  |
      | template      | {{.spec.output.to.name}} |
    Then the step should succeed
    And the output should contain "origin-ruby-sample:tag1"
    """

    When I run the :patch client command with:
      | _tool         | <tool>                  |
      | resource      | is                      |
      | resource_name | origin-ruby-sample      |
      | p             | {"spec":{"dockerImageRepository":"xxia/origin-ruby-sample"}} |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | _tool         | <tool>             |
      | resource      | is                 |
      | resource_name | origin-ruby-sample |
      | template      | {{.spec.dockerImageRepository}} |
    Then the step should succeed
    And the output should contain "xxia/origin-ruby-sample"
    """

    Examples:
      | tool     |
      | oc       | # @case_id OCP-11518
      | kubectl  | # @case_id OCP-21117

  # @author xxia@redhat.com
  # @case_id OCP-11173
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
  Scenario Outline: oc patch to update resource fields using YAML format
    Given I have a project
    And I create a new application with:
      | file | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/templates/ui/application-template-stibuild-without-customize-route.json |
    Then the step should succeed
    Given I wait for the "database" dc to appear
    When I run the :patch client command with:
      | _tool         | <tool>               |
      | resource      | dc                   |
      | resource_name | database             |
      | p             | spec:\n  strategy:\n    resources:\n      limits:\n        memory: 300Mi |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | _tool         | <tool>             |
      | resource      | dc                 |
      | resource_name | database           |
      | template      | {{.spec.strategy.resources.limits.memory}} |
    Then the step should succeed
    And the output should contain "300Mi"
    """

    When I run the :patch client command with:
      | _tool         | <tool>               |
      | resource      | bc                   |
      | resource_name | ruby-sample-build    |
      | p             | spec:\n  output:\n    to:\n      name: origin-ruby-sample:tag1 |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | _tool         | <tool>             |
      | resource      | bc                 |
      | resource_name | ruby-sample-build  |
      | template      | {{.spec.output.to.name}} |
    Then the step should succeed
    And the output should contain "origin-ruby-sample:tag1"
    """

    When I run the :patch client command with:
      | _tool         | <tool>               |
      | resource      | is                   |
      | resource_name | origin-ruby-sample   |
      | p             | spec:\n  dockerImageRepository: xxia/origin-ruby-sample |
    Then the step should succeed
    Then I wait for the steps to pass:
    """
    When I run the :get client command with:
      | _tool         | <tool>             |
      | resource      | is                 |
      | resource_name | origin-ruby-sample |
      | template      | {{.spec.dockerImageRepository}} |
    Then the step should succeed
    And the output should contain "xxia/origin-ruby-sample"
    """

    Examples:
      | tool     |
      | oc       | # @case_id OCP-10695
      | kubectl  | # @case_id OCP-21118

  # @author xiaocwan@redhat.com
  # @case_id OCP-9853
  # @bug_id 1297910
  @admin
  Scenario: patch operation should use patched object to check admission control
    Given I have a project
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/quota/myquota.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :create admin command with:
      | f | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/limits/limits.yaml |
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
  Scenario Outline: oc patch resource with different values for --type
    Given I have a project
    When I run the :create client command with:
      | _tool  | <tool>               |
      | f      | <%= ENV['BUSHSLICER_HOME'] %>/features/tierN/testdata/services/multi-portsvc.json |
    Then the step should succeed

    # check "json" type
    When I run the :patch client command with:
      | _tool         | <tool>        |
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | type          | json          |
      | p             | [{"op": "replace", "path": "/spec/ports/0/targetPort", "value": 444}] |
    Then the step should succeed

    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | _tool         | <tool>        |
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
      | _tool         | <tool>        |
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | type          | strategic     |
      | p             | spec:\n  ports:\n  - port: 27443\n    targetPort: 445 |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | _tool         | <tool>        |
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
      | _tool         | <tool>        |
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | type          | merge         |
      | p             | spec:\n  ports:\n  - port: 27443\n    targetPort: 446 |
    Then the step should succeed
    And I wait for the steps to pass:
    """
    When I run the :get client command with:
      | _tool         | <tool>        |
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
      | _tool         | <tool>                                                 |
      | resource      | svc                                                    |
      | resource_name | multi-portsvc                                          |
      | type          | json                                                   |
      | p             | [{"op": "add", "path": "/spec/ports/3", "value": 444}] |
    Then the step should fail
    And the output should match "[iI]nvalid"

    When I run the :patch client command with:
      | _tool         | <tool>        |
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | type          | json          |
      | p             | [{"op": "delete", "path": "/spec/ports/0/targetPort", "value": 444}] |
    Then the step should fail
    And the output should match:
      | Unexpected kind:\\s+delete\|nvalid |

    When I run the :patch client command with:
      | _tool         | <tool>        |
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | type          | jso           |
      | p             | anything      |
    Then the step should fail
    And the output should match:
      | type must be one of .*json merge strategic.*|

    When I run the :patch client command with:
      | _tool         | <tool>        |
      | resource      | svc           |
      | resource_name | multi-portsvc |
      | type          | strategic     |
      | p             | spec:\n  ports:\n  -\n    targetPort: 446 |
    Then the step should fail
    And the output should match:
      | (does not contain declared merge key\|is invalid.*spec.ports.*equired) |

    Examples:
      | tool     |
      | oc       | # @case_id OCP-12298
      | kubectl  | # @case_id OCP-21119

  # @author xxia@redhat.com
  Scenario Outline: Apply a configuration to a resource via oc apply
    Given I have a project
    And I run the :run client command with:
      | name      | hello                     |
      | image     | openshift/hello-openshift |
      | -l        | run=hello,version=3.1     |
    Then the step should succeed

    Given I wait until the status of deployment "hello" becomes :complete
    And I get project dc named "hello" as YAML
    And I save the output to file> mydc.yaml
    # Replace under spec.template.metadata.labels. Other occurrences not replaced.
    And I replace lines in "mydc.yaml":
      | /(        )version: "3.1"/ | \\1version: "3.2" |
    When I run the :apply client command with:
      | _tool      | <tool>    |
      | f          | mydc.yaml |
      | overwrite  | true      |
    Then the step should fail
    # Cover bug 1539529
    And the output should match "invalid.*does not match"
    When I run the :apply client command with:
      | _tool         | <tool>    |
      | f             | mydc.yaml |
      | overwrite     | true      |
      | force         | true      |
      | grace-period  | 30        |
    Then the step should fail
    And the output should match "invalid.*does not match"
    
    # Above --force would delete and re-create the resource, so need below steps
    Given I wait until the status of deployment "hello" becomes :complete
    And I get project dc named "hello" as YAML
    And I save the output to file> mydc.yaml
    # Valid example of modify and apply
    Given I replace lines in "mydc.yaml":
      | 21600 | 21601 |
    When I run the :apply client command with:
      | _tool  | <tool>    |
      | f      | mydc.yaml |
    Then the step should succeed
    When I run the :apply_view_last_applied client command with:
      | _tool     | <tool>   |
      | resource  | dc/hello |
    Then the step should succeed
    # Cover bug 1503601, i.e., ensure the output is valid YAML,
    # in case illegal fields and/or values occur, e.g. "(MISSING)" in the bug
    And the output is parsed as YAML
    And the output should contain "21601"
    
    Given I replace lines in "mydc.yaml":
      | "3.1" | "3.3" |
    When I run the :apply_set_last_applied client command with:
      | _tool  | <tool>    |
      | f      | mydc.yaml |
    Then the step should succeed
    When I run the :get client command with:
      | _tool         | <tool>                    |
      | resource      | dc                        |
      | resource_name | hello                     |
      | template      | {{.metadata.annotations}} |
    Then the step should succeed
    And the output should contain:
      | last-applied-configuration  |
      | "3.3"                       |
    When I run the :get client command with:
      | _tool         | <tool>    |
      | resource      | dc        |
      | resource_name | hello     |
      | template      | {{.spec}} |
    Then the step should succeed
    # set-last-applied does not set field other than annotation
    And the output should not contain:
      | "3.3"  |

    Examples:
      | tool     |
      | oc       | # @case_id OCP-15009
      | kubectl  | # @case_id OCP-21120

