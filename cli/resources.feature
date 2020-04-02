Feature: resouces related scenarios
  # @author xxia@redhat.com
  Scenario Outline: oc replace with miscellaneous options
    Given I have a project
    And I run the :run client command with:
      | name         | mydc                      |
      | image        | openshift/hello-openshift |
      | -l           | label=mydc                |
    Then the step should succeed

    Given I wait until the status of deployment "mydc" becomes :running
    And a pod becomes ready with labels:
      | label=mydc |
    And I run the :get client command with:
      | _tool         | <tool>             |
      | resource      | dc                 |
      | resource_name | mydc               |
      | output        | yaml               |
    Then the step should succeed
    When I save the output to file> dc.yaml
    And I run the :replace client command with:
      | _tool | <tool>  |
      | f     | dc.yaml |
      | force |         |
    Then the step should succeed
    And the output should contain:
      | deleted  |
      | replaced |

    Given a pod becomes ready with labels:
      | label=mydc |
    And evaluation of `pod.name` is stored in the :pod_name clipboard
    When I run the :replace client command with:
      | _tool   | <tool>  |
      | f       | dc.yaml |
      | force   |         |
      | cascade |         |
    Then the step should succeed
    When I wait for the resource "pod" named "<%= cb.pod_name %>" to disappear
    And I run the :get client command with:
      | _tool    | <tool>  |
      | resource | pod     |
      | l        | dc=mydc |
    Then the step should succeed
    And the output should not contain "<%= cb.pod_name %>"

    When I run the :run client command with:
      | _tool        | <tool>                    |
      | name         | mypod                     |
      | image        | openshift/hello-openshift |
      | generator    | run-pod/v1                |
    Then the step should succeed
    Given the pod named "mypod" becomes ready
    When I run the :run client command with:
      | _tool        | <tool>                    |
      | name         | mypod                     |
      | image        | openshift/hello-openshift |
      | generator    | run-pod/v1                |
      | dry_run      |                           |
      | -o           | yaml                      |
    Then the step should succeed
    When I save the output to file> pod.yaml
    And I run the :replace client command with:
      | _tool        | <tool>   |
      | f            | pod.yaml |
      | force        |          |
      | grace_period | 100      |
    # Currently, there is a bug https://bugzilla.redhat.com/show_bug.cgi?id=1285702 that makes the step *fail*
    Then the step should succeed

    Examples:
      | tool     |
      | oc       | # @case_id OCP-11211
      | kubectl  | # @case_id OCP-21032


  # @author xxia@redhat.com
  Scenario Outline: Delete resources with cascade selectors
    Given I have a project
    And I run the :run client command with:
      | name      | test              |
      | image     | <%= project_docker_repo %>openshift/hello-openshift |
      | generator | run-controller/v1 |
      | -l        | run=test          |
    Then the step should succeed
    Given a pod becomes ready with labels:
      | run=test |
    When I run the :delete client command with:
      | _tool             | <tool>|
      | object_type       | rc    |
      | object_name_or_id | test  |
      | cascade           | true  |
    Then the step should succeed
    And I wait for the resource "pod" named "<%= pod.name %>" to disappear

    When I run the :run client command with:
      | name      | test              |
      | image     | <%= project_docker_repo %>openshift/hello-openshift |
      | generator | run-controller/v1 |
      | -l        | run=test          |
    Then the step should succeed
    When I run the :delete client command with:
      | _tool             | <tool>|
      | object_type       | rc    |
      | object_name_or_id | test  |
      | cascade           | false |
    Then the step should succeed
    And a pod becomes ready with labels:
      | run=test |

    When I run the :run client command with:
      | name      | test-a            |
      | image     | <%= project_docker_repo %>openshift/hello-openshift |
      | generator | run-controller/v1 |
      | -l        | label=same        |
    Then the step should succeed
    When I run the :run client command with:
      | name      | test-b            |
      | image     | <%= project_docker_repo %>openshift/hello-openshift |
      | generator | run-controller/v1 |
      | -l        | label=same,label2=test-b |
    Then the step should succeed
    When I run the :delete client command with:
      | _tool             | <tool>  |
      | object_type       | rc      |
      | object_name_or_id | test-a  |
      | object_name_or_id | test-b  |
      | cascade           | false   |
    Then the step should succeed

    Examples:
      | tool     |
      | oc       | # @case_id OCP-10719
      | kubectl  | # @case_id OCP-21033

  # @author xiaocwan@redhat.com
  # @case_id OCP-9615
  @admin
  Scenario: Cluster admin can get resources in all namespaces

    Given I switch to the first user
    Given a 5 characters random string of type :dns is stored into the :proj1 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj1 %> |
    Then the step should succeed
    When I process and create "<%= BushSlicer::HOME %>/features/tierN/testdata/build/ruby20rhel7-template-sti.json"
    Then the step should succeed

    Given I switch to the second user
    Given a 5 characters random string of type :dns is stored into the :proj2 clipboard
    When I run the :new_project client command with:
      | project_name | <%= cb.proj2 %> |
    Then the step should succeed
    When I process and create "<%= BushSlicer::HOME %>/features/tierN/testdata/build/ruby20rhel7-template-sti.json"
    Then the step should succeed

    When I run the :get admin command with:
      | resource         | build |
      | all_namespaces    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | pod |
      | all_namespaces    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | service |
      | all_namespaces    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | bc |
      | all_namespaces    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | rc |
      | all_namespaces    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | template |
      | all_namespaces    | true |
    Then the output should contain:
      | openshift       |

    When I run the :get admin command with:
      | resource         | is |
      | all_namespaces    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | route |
      | all_namespaces    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | dc |
      | all_namespaces    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |

    When I run the :get admin command with:
      | resource         | all |
      | all_namespaces    | true |
    Then the output should contain:
      | <%= cb.proj1 %> |
      | <%= cb.proj2 %> |


  # @author cryan@redhat.com
  # @case_id OCP-12336
  # @bug_id 1294063
  Scenario: Update resources from file
    Given I have a project
    When I run the :create client command with:
      | f | https://raw.githubusercontent.com/openshift/origin/master/examples/hello-openshift/hello-pod.json |
    Given the pod named "hello-openshift" becomes ready
    When I replace resource "pod" named "hello-openshift":
      | labels:\n    name: hello-openshift | labels:\n    name: tc474047-mod1 |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod |
      | name | hello-openshift |
    Then the step should succeed
    And the output should contain "tc474047-mod1"
    When I replace resource "pod" named "hello-openshift":
      | labels:\n    name: tc474047-mod1 | labels:\n    name: tc474047-mod2 |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod |
      | name | hello-openshift |
    Then the step should succeed
    And the output should contain "tc474047-mod2"
    When I run the :get client command with:
      | resource | pods |
      | resource_name | hello-openshift |
      | o | json |
    Then the step should succeed
    Given I save the output to file> a.json
    When I run the :replace client command with:
      | force ||
      | f | a.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | pod |
      | name | hello-openshift |
    Then the step should succeed
    And the output should contain "tc474047-mod2"

  # @author xxia@redhat.com
  # @case_id OCP-10741
  @smoke
  Scenario: Get/watch resources with oc get
    Given I have a project
    And I run the :run client command with:
      | name      | hello             |
      | image     | <%= project_docker_repo %>openshift/hello-openshift |
      | -l        | app=tryit         |
    Then the step should succeed
    And I wait until the status of deployment "hello" becomes :running
    When I run the :get client command with:
      | resource        | dc         |
      | no_headers      | true       |
    Then the step should succeed
    And the output should contain:
      | hello |
    And the output should not contain "NAME"

    Given a pod becomes ready with labels:
      | deployment=hello-1        |
    And I wait for the resource "pod" named "hello-1-deploy" to disappear
    When I run the :get client command with:
      | resource        | pod                        |
      | L               | app,deployment,no-this,APP |
    Then the step should succeed
    And the output should match "hello-1.*tryit.*hello-1"

    # Create a "Completed" pod using command which returns 0 and "Never" restartPolicy
    When I run the :run client command with:
      | name      | mypod1        |
      | image     | <%= project_docker_repo %>openshift/origin-base |
      | generator | run-pod/v1    |
      | command   | true          |
      | cmd       | /bin/true     |
      | restart   | Never         |
    Then the step should succeed
    # Create a "Error" pod using command which returns non-0 and "Never" restartPolicy
    When I run the :run client command with:
      | name      | mypod2        |
      | image     | <%= project_docker_repo %>openshift/origin-base |
      | generator | run-pod/v1    |
      | command   | true          |
      | cmd       | /bin/false    |
      | restart   | Never         |
    Then the step should succeed
    Given the pod named "mypod1" status becomes :succeeded
    And the pod named "mypod2" status becomes :failed
    When I run the :get client command with:
      | resource        | pod     |
      | a               | false   |
    Then the step should succeed
    And the output should not contain "mypod"
    When I run the :get client command with:
      | resource        | pod     |
      | a               | true    |
    Then the step should succeed
    And the output should contain "mypod"

    When I run the :get background client command with:
      | resource      | dc                 |
      | resource_name | hello              |
      | w             | true               |
    Then the step should succeed

    When I run the :label client command with:
      | resource      | dc                 |
      | name          | hello              |
      | key_val       | newlab=helloworld  |
    Then the step should succeed
    When I terminate last background process
    Then the output should contain 2 times:
      | hello     |

  # @author xxia@redhat.com
  # @case_id OCP-11535
  Scenario: Check resources with different output formats using oc get, oc run etc.
    Given I have a project
    When I run the :run client command with:
      | name      | myrun             |
      | image     | <%= project_docker_repo %>openshift/hello-openshift             |
      | -o        | jsonpath={.kind} {.metadata.name}  |
    Then the step should succeed
    And the output should contain "DeploymentConfig myrun"

    Given a pod becomes ready with labels:
      | deployment=myrun-1    |
    When I run the :get client command with:
      | resource       | pod          |
      | o              | wide         |
    Then the step should succeed
    And the output should contain "NODE"

    Given a "a.txt" file is created with the following lines:
    """
    {{.metadata.name}} {{.kind}} {{.metadata.labels.newlab}}
    """
    When I run the :label client command with:
      | resource       | dc           |
      | name           | myrun        |
      | key_val        | newlab=Hello |
      | o              | go-template-file=a.txt |
    Then the step should succeed
    And the output should contain "myrun DeploymentConfig Hello"

    When I run the :expose client command with:
      | resource       | dc           |
      | resource_name  | myrun        |
      | port           | 8080         |
      | o              | go-template  |
      | template       | {{.metadata.name}} {{.kind}}  |
    Then the step should succeed
    And the output should contain "myrun Service"

    When I run the :get client command with:
      | resource       | pod          |
      | o              | no-this      |
    Then the step should fail
    And the output should contain "no-this"

  # @author yanpzhan@redhat.com
  # @case_id OCP-11716
  Scenario: Templates could parameterize cpu and memory usage values for each container
    Given I have a project
    When I run the :create client command with:
      | f | <%= BushSlicer::HOME %>/features/tierN/testdata/templates/tc481680/application-template-with-resources.json |
    Then the step should succeed
    When I run the :describe client command with:
      | resource | template |
      | name     | ruby-helloworld-sample-with-resources |
    Then the output should match:
      | Name:\\s+MYSQL_RESOURCES_LIMITS_MEMORY|
      | Value:\\s+200Mi|
      | Name:\\s+MYSQL_RESOURCES_LIMITS_CPU|
      | Value:\\s+400m|
      | Name:\\s+DEPLOY_MYSQL_RESOURCES_LIMITS_MEMORY|
      | Value:\\s+150Mi|
      | Name:\\s+DEPLOY_MYSQL_RESOURCES_LIMITS_CPU|
      | Value:\\s+20m|
      | Name:\\s+FRONTEND_RESOURCES_LIMITS_MEMORY|
      | Value:\\s+100Mi|
      | Name:\\s+FRONTEND_RESOURCES_LIMITS_CPU|
      | Value:\\s+200m|
      | Name:\\s+DEPLOY_FRONTEND_RESOURCES_LIMITS_MEMORY|
      | Value:\\s+150Mi|
      | Name:\\s+DEPLOY_FRONTEND_RESOURCES_LIMITS_CPU|
      | Value:\\s+20m|
      | Name:\\s+BUILD_RUBY_RESOURCES_LIMITS_MEMORY|
      | Value:\\s+150Mi|
      | Name:\\s+BUILD_RUBY_RESOURCES_LIMITS_CPU|
      | Value:\\s+20m|

    When I run the :new_app client command with:
      | template | ruby-helloworld-sample-with-resources |
    Then the step should succeed

    And I wait until the status of deployment "database" becomes :running
    When I run the :get client command with:
      | resource      | pod |
      | resource_name | database-1-deploy |
      | o             | json |
    Then the expression should be true> @result[:parsed]['spec']['containers'][0]['resources'] == {"limits"=>{"cpu"=>"20m", "memory"=>"150Mi"}, "requests"=>{"cpu"=>"20m", "memory"=>"150Mi"}}

    Given 1 pods become ready with labels:
      | deploymentconfig=database |
    When I run the :get client command with:
      | resource      | pod |
      | resource_name | <%= pod.name%> |
      | o             | json |
    Then the expression should be true> @result[:parsed]['spec']['containers'][0]['resources'] == {"limits"=>{"cpu"=>"400m", "memory"=>"200Mi"}, "requests"=>{"cpu"=>"400m", "memory"=>"200Mi"}}

    When I run the :start_build client command with:
      | buildconfig | ruby-sample-build |
    Then the step should succeed

    Given the pod named "ruby-sample-build-2-build" becomes present
    When I run the :get client command with:
      | resource      | pod |
      | resource_name | ruby-sample-build-2-build |
      | o             | json |
    Then the expression should be true> @result[:parsed]['spec']['containers'][0]['resources'] == {"limits"=>{"cpu"=>"20m", "memory"=>"150Mi"}, "requests"=>{"cpu"=>"20m", "memory"=>"150Mi"}}
