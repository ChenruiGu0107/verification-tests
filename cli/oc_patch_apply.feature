Feature: oc patch/apply related scenarios

  # @author xxia@redhat.com
  Scenario Outline: oc patch to update resource fields using JSON format
    Given I have a project
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    And I create a new application with:
      | file | application-template-stibuild-without-customize-route.json |
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
    Given I obtain test data file "templates/ui/application-template-stibuild-without-customize-route.json"
    And I create a new application with:
      | file | application-template-stibuild-without-customize-route.json |
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
    Given I obtain test data file "quota/myquota.yaml"
    When I run the :create admin command with:
      | f | myquota.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    Given I obtain test data file "limits/limits.yaml"
    When I run the :create admin command with:
      | f | limits.yaml |
      | n | <%= project.name %> |
    Then the step should succeed
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Then the step should succeed

    Given the pod named "hello-openshift" status becomes :running
    When I run the :patch client command with:
      | resource      | pod             |
      | resource_name | hello-openshift |
      | p             | {"spec":{"containers":[{"name":"hello-openshift","image":"quay.io/openshifttest/hello-openshift"}]}} |
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
    Given I obtain test data file "services/multi-portsvc.json"
    When I run the :create client command with:
      | _tool  | <tool>               |
      | f      | multi-portsvc.json |
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

  # @author yinzhou@redhat.com
  Scenario Outline: Apply a configuration to a resource
    Given I have a project
    When I run the :create_deployment client command with:
      | _tool | <tool>                    |
      | name  | myapp                     |
      | image | openshift/hello-openshift |
    Then the step should succeed
    When I run the :patch client command with:
      | _tool         | <tool>                                                                            |
      | resource      | deploy                                                                            |
      | resource_name | myapp                                                                             |
      | p             | [{"op": "add", "path": "/spec/template/metadata/labels/version", "value": "4.5"}] |
      | type          | json                                                                              |
    Then the step should succeed
    And a pod becomes ready with labels:
      | version=4.5 |
    When I run the :patch client command with:
      | _tool         | <tool>                                                                          |
      | resource      | deploy                                                                          |
      | resource_name | myapp                                                                           |
      | p             | [{"op": "add", "path": "/spec/template/metadata/labels/run", "value": "hello"}] |
      | type          | json                                                                            |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=hello,version=4.5 |
    When I get project deployment named "myapp" as YAML
    And I save the output to file> myapp.yaml
    Then I replace lines in "myapp.yaml":
      | version: "4.5" | version: "4.5.1" |
    When I run the :apply client command with:
      | f | myapp.yaml |      
    Then the step should succeed 
    When I run the :apply_view_last_applied client command with:
      | _tool     | <tool>           |
      | resource  | deployment/myapp |
    Then the step should succeed
    Then I replace lines in "myapp.yaml":
      | version: "4.5.1" | version: "4.5.2" |
    When I run the :apply_set_last_applied client command with:
      | f | myapp.yaml |      
    Then the step should succeed 

    Examples:
      | tool    |
      | oc      | # @case_id OCP-30394
      | kubectl | # @case_id OCP-30395

  # @author yinzhou@redhat.com
  # @case_id OCP-30279
  @admin
  Scenario: `oc apply` should apply as many resources as possible before exiting with an error
    Given admin ensures "ns-ocp30279" project is deleted after scenario
    Given I have a project
    Given I obtain test data file "cli/OCP-30279/apply-with-error.yaml"
    When I run the :apply client command with:
      | f | apply-with-error.yaml |
    Then the step should fail
    And the output should match:
      | cronjob.batch/hello created              |
      | no matches for kind "PerformanceProfile" |
      | namespaces "ns-ocp30279" is forbidden    |
    Then I check that the "hello" cronjob exists in the project

    Given a 5 characters random string of type :dns is stored into the :proj_name1 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj_name1 %> |
    Then the step should succeed
    When I switch to cluster admin pseudo user
    When I use the "<%= cb.proj_name1 %>" project
    When I run the :apply admin command with:
      | f | apply-with-error.yaml |
    Then the step should fail
    And the output should contain:
      | namespace/ns-ocp30279 created            |
      | cronjob.batch/hello created              |
      | no matches for kind "PerformanceProfile" |
    Given admin checks that the "ns-ocp30279" namespace exists
    And admin checks that the "hello" cronjob exists in the "<%= cb.proj_name1 %>" project
